local st = require "util.stanza";
local socket = require "socket";
local jid_bare = require "util.jid".bare;
local json = require "util.json";
local ext_events = module:require "ext_events";
local it = require "util.iterators";
local jid = require "util.jid";
local jid_split = require 'util.jid'.split;
local jid_bare = require 'util.jid'.bare;
local jid_resource = require "util.jid".resource;
local is_healthcheck_room = module:require "util".is_healthcheck_room;
local http = require "net.http";
local get_room_from_jid = module:require "util".get_room_from_jid;
local room_jid_match_rewrite = module:require "util".room_jid_match_rewrite;

local full_sessions = prosody.full_sessions;

local log_level = "info";

-- we use async to detect Prosody 0.10 and earlier
local have_async = pcall(require, "util.async");
if not have_async then
    module:log("warn", "conference duration will not work with Prosody version 0.10 or less.");
    return;
end

local muc_component_host = module:get_option_string("muc_component");
if muc_component_host == nil then
    log("error", "No muc_component specified. No muc to operate on!");
    return;
end

local default_tenant = module:get_option_string("default_tenant");
local vmeeting_api_token = module:get_option_string("vmeeting_api_token", "");
local whitelist;

log("info", "Starting participant logger for %s:", muc_component_host, default_tenant);

function get_stats_id(occupant)
    if not occupant then
        return nil;
    end

    return occupant.sessions[occupant.jid]:get_child_text('stats-id');
end

function occupant_joined(event)
    local room, stanza, occupant = event.room, event.stanza, event.occupant;
    local node, host, resource = jid.split(room.jid);
    local nick = jid_resource(occupant.nick);
    local stats_id = get_stats_id(occupant);

    local invitee = stanza.attr.from;
    local invitee_bare_jid = jid_bare(invitee);
    local _, invitee_domain = jid_split(invitee);

    -- whitelist participants
    if whitelist:contains(invitee_domain) or whitelist:contains(invitee_bare_jid) then
        log("info", "occupant_joined: %s is in whitelist", invitee);
        return;
    end

    if room._id then
        local email = occupant.sessions[occupant.jid]:get_child_text('email');
        local name = occupant.sessions[occupant.jid]:get_child_text('nick', 'http://jabber.org/protocol/nick');
        local body = {
            conference = room._id,
            joinTime = os.date("*t"),
            leaveTime = nil,
            name = name,
            email = email,
            nick = nick,
            jid = occupant.jid,
            stats_id = stats_id
        };

        local encoded_body = json.encode(body);

        -- https://prosody.im/doc/developers/net/http
        http.request("http://vmapi:5000/plog/", {
            body = encoded_body,
            method = "POST",
            headers = {
                ["Content-Type"] = "application/json",
                Authorization = "Bearer " .. vmeeting_api_token
            }
        },
        function(resp_body, response_code, response)
            if response_code == 201 then
                local body = json.decode(resp_body);
                room.participants[nick] = {
                    id = body._id,
                    name = name,
                    email = email
                };
                log(log_level, "plog created", room._id, body._id, response_code);
            else
                log(log_level, "plog create is failed", tostring(response));
            end
        end);

        log("info", "occupant_joined:", room._id, body.nick, stats_id);
    end
end

function occupant_leaving(event)
    local room, occupant, stanza = event.room, event.occupant, event.stanza;
    local nick = jid_resource(occupant.nick);

    if is_healthcheck_room(room.jid) then
        return;
    end

    local invitee = stanza.attr.from;
    local invitee_bare_jid = jid_bare(invitee);
    local _, invitee_domain = jid_split(invitee);

    -- whitelist participants
    if whitelist:contains(invitee_domain) or whitelist:contains(invitee_bare_jid) then
        log("info", "occupant_leaving: %s is in whitelist", invitee);
        return;
    end

    if room._id and room.participants[nick] then
        local node, host, resource = jid.split(room.jid);
        local url = "http://vmapi:5000/plog/" .. room.participants[nick].id;

        -- https://prosody.im/doc/developers/net/http
        http.request(url, {
            method = "DELETE",
            headers = {
                Authorization = "Bearer " .. vmeeting_api_token
            }
        },
        function(resp_body, response_code, response)
            log(log_level, "plod updated", room._id, room.participants[nick].id, response_code);
        end);

        log("info", "occupant_leaving:", room._id, room.participants[nick].id);
    end
end

function occupant_updated(event)
    local occupant, room, stanza = event.occupant, event.room, event.stanza;
    local name = occupant:get_presence():get_child_text('nick', 'http://jabber.org/protocol/nick');
    local node, host, resource = jid.split(room.jid);
    local nick = jid_resource(occupant.nick);

    if  not room or
        not name or
        not nick or
        name == '' or
        host ~= muc_component_host or
        not room.participants[nick] then
        return;
    end

    if room.participants[nick].name ~= name then
        local url = "http://vmapi:5000/plog/" .. room.participants[nick].id;
        local reqbody = { name = name };

        room.participants[nick].name = name;
        http.request(url, {
            method = "PATCH",
            body = http.formencode(reqbody),
            headers = {
                Authorization = "Bearer " .. vmeeting_api_token
            }
        },
        function(resp_body, response_code, response)
            log(log_level, "occupant updated", occupant.jid, response_code);
        end);
    end
end

function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

function room_created(event)
    local room = event.room;
    room.participants = {};
    room.blacklist = {};

    local node, host, resource = jid.split(room.jid);
    local site_id, name = node:match("^%[([^%]]+)%](.+)$");
    local url1 = "http://vmapi:5000/"
 
    if not site_id then
        name = node;
        site_id = default_tenant;
    end
    url1 = url1 .. "sites/" .. site_id .. "/";
    url1 = url1 .. "conferences";
    local reqbody = { name = name, meeting_id = room._data.meetingId };

    http.request(url1, {
        body = http.formencode(reqbody),
        method = "PATCH",
        headers = {
            Authorization = "Bearer " .. vmeeting_api_token
        }
    },
        function(resp_body, response_code, response)
            if response_code == 201 then
                local body = json.decode(resp_body);
                room.mail_owner = body.mail_owner;
                room._id = body._id;
                log(log_level, "room created: %s, %s", node, room._id);
            else
                log(log_level, "PATCH failed!", room.jid);
            end
        end);

    log("info", "room_created: %s, %s, %s, %s, %s", node, host, resource, site_id, room._data.meetingId);
end

function room_destroyed(event)
    local room = event.room;

    if is_healthcheck_room(room.jid) then
        return;
    end

    local node, host, resource = jid.split(room.jid);
    local site_id, name = node:match("^%[([^%]]+)%](.+)$");
    local url1 = "http://vmapi:5000/"
    if site_id then
        url1 = url1 .. "sites/" .. site_id .. "/";
    end

    if room._id then
        url1 = url1 .. "conferences/" .. room._id;

        http.request(url1, {
            method = "DELETE",
            headers = {
                Authorization = "Bearer " .. vmeeting_api_token
            }
        },
        function(resp_body, response_code, response)
            log(log_level, "room destroyed: %s, %s", node, room._id);
        end);

        log("info", "room_destroyed: %s, %s", room.jid, room._data.meetingId);
    else
        -- url1 = url1 .. "conferences/";

        -- http.request(url1, {
        --     method = "DELETE",
        --     headers = {
        --         Authorization = "Bearer " .. vmeeting_api_token
        --     }
        -- },
        -- function(resp_body, response_code, response)
        --     log(log_level, "room destroyed: %s, %s", node, room._id);
        -- end);

        log("info", "room_destroyed: room._id not exist. %s", room.jid);
    end
end

local function add_blacklist(stanza, from)
    local room_jid = room_jid_match_rewrite(jid_bare(from));
    local room = get_room_from_jid(room_jid);
    local occupant = room:get_occupant_by_real_jid(stanza.attr.to);
    -- log("info", "add_blacklist:", room, dump(occupant), from);

    if occupant == nil then
        -- log("info", "occupant not found: %s", stanza.attr.to);
        return;
    end

    local stats_id = get_stats_id(occupant);
    if stats_id then
        room.blacklist[stats_id] = from;
    end
    log("info", "Added blacklist %s = %s", stats_id, from);
end

local xmlns_muc_user = "http://jabber.org/protocol/muc#user";
local function check_for_incoming_ban(event)
	local stanza = event.stanza;
	local to_session = full_sessions[stanza.attr.to];
    log(log_level, "check_for_incoming_ban: %s", tostring(stanza));
	if to_session then
		local directed = to_session.directed;
		local from = stanza.attr.from;
		if directed and stanza.attr.type == "unavailable" then
			-- This is a stanza from somewhere we sent directed presence to (may be a MUC)
			local x = stanza:get_child("x", xmlns_muc_user);
			if x then
				for status in x:childtags("status") do
					if status.attr.code == '307' then
						add_blacklist(stanza, from);
					end
				end
			end
		end
	end
end

local function check_for_ban(event)
	local origin, stanza = event.origin, event.stanza;
	local to = room_jid_match_rewrite(jid_bare(stanza.attr.to));
    local room = get_room_from_jid(to);
    local stats_id = stanza:get_child_text('stats-id');

	-- rewrite jid
	if stats_id and room.blacklist[stats_id] then
		log("info", "check_for_ban: %s is forbidden from %s", stats_id, to);
		if stanza.attr.type ~= "error" then
			origin.send(st.error_reply(stanza, "auth", "forbidden")
				:tag("x", { xmlns = xmlns_muc_user })
					:tag("status", { code = '301' }));
		end
		return true;
	end
	-- log("info", "check_for_ban: %s is accepted from %s", stats_id, to, room);
end

local domain_base = module:get_option_string("muc_mapper_domain_base");
local guest_prefix = "guest";

-- executed on every host added internally in prosody, including components
function process_host(host)
    module:log("info", "Loading mod_participant_log_component for %s", host);
    local muc_module = module:context(host);

    if host == muc_component_host then -- the conference muc component
        module:log("info", "Hook to muc events on %s", host);
        muc_module:hook("muc-room-created", room_created, -1);
        muc_module:hook("muc-room-destroyed", room_destroyed, -1);
        muc_module:hook("muc-occupant-joined", occupant_joined, -1);
        muc_module:hook("muc-occupant-pre-leave", occupant_leaving, -1);
        muc_module:hook('muc-broadcast-presence', occupant_updated, -1);

        whitelist = muc_module:get_option_set('muc_lobby_whitelist', {});
        log("info", "whitelist for participant logger: %s", whitelist);
    elseif host == guest_prefix..'.'..domain_base then
        module:log("info", "Hook to guest events on %s", host);
		muc_module:hook("presence/full", check_for_incoming_ban, 100);
		muc_module:hook("pre-presence/full", check_for_ban, 100);
    end
end

prosody.events.add_handler("host-activated", process_host);
for host in pairs(prosody.hosts) do
    process_host(host);
end
