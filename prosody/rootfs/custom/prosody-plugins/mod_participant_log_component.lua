local st = require "util.stanza";
local socket = require "socket";
local json = require "util.json";
local ext_events = module:require "ext_events";
local it = require "util.iterators";
local jid = require "util.jid";
local jid_resource = require "util.jid".resource;
local is_healthcheck_room = module:require "util".is_healthcheck_room;
local http = require "net.http";

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

log("info", "Starting participant logger for %s", muc_component_host, default_tenant);

function occupant_joined(event)
    local room = event.room;
    local occupant = event.occupant;
    local node, host, resource = jid.split(room.jid);
    local nick = jid_resource(occupant.nick);

    if room._id then
        local body = {
            conference = room._id,
            joinTime = os.date("*t"),
            leaveTime = nil,
            name = occupant.sessions[occupant.jid]:get_child_text('nick', 'http://jabber.org/protocol/nick'),
            email = occupant.sessions[occupant.jid]:get_child_text('email'),
            nick = nick,
            jid = occupant.jid
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
                room.participants[occupant.jid] = body._id;
                log(log_level, "plog created", room._id, body._id, response_code);
            else
                log(log_level, "plog create is failed", tostring(response));
            end
        end);

        log("info", "occupant_joined:", room._id, body.nick);
    end
end

function occupant_leaving(event)
    local room = event.room;
    local occupant = event.occupant;

    if is_healthcheck_room(room.jid) then
        return;
    end

    if room._id and room.participants[occupant.jid] then
        local node, host, resource = jid.split(room.jid);
        local url = "http://vmapi:5000/plog/" .. room.participants[occupant.jid];

        -- https://prosody.im/doc/developers/net/http
        http.request(url, {
            method = "DELETE",
            headers = {
                Authorization = "Bearer " .. vmeeting_api_token
            }
        },
        function(resp_body, response_code, response)
            log(log_level, "plod updated", room._id, room.participants[occupant.jid], response_code);
        end);

        log("info", "occupant_leaving:", room._id, room.participants[occupant.jid]);
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
    room.participant = {};

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
                room.participants = {};
                log(log_level, node, "room created", room._id);
            else
                log(log_level, node, "PATCH failed!", tostring(response));
            end
        end);

    log("info", "room_created: %s, %s, %s, %s, %s", node, host, resource, site_id, room._data.meetingId);
end

function room_destroyed(event)
    local room = event.room;

    if is_healthcheck_room(room.jid) then
        return;
    end

    if room._id then
        local node, host, resource = jid.split(room.jid);
        local site_id, name = node:match("^%[([^%]]+)%](.+)$");
        local url1 = "http://vmapi:5000/"
        if site_id then
            url1 = url1 .. "sites/" .. site_id .. "/";
        end
        url1 = url1 .. "conferences/" .. room._id;

        http.request(url1, {
            method = "DELETE",
            headers = {
                Authorization = "Bearer " .. vmeeting_api_token
            }
        },
            function(resp_body, response_code, response)
                -- log(log_level, node, "room destroyed", room._id, response_code);
            end);

        log("info", "room_destoryed: %s, %s", node, room._data.meetingId);
    end
end

-- executed on every host added internally in prosody, including components
function process_host(host)
    if host == muc_component_host then -- the conference muc component
        module:log("info", "Hook to muc events on %s", host);

       local muc_module = module:context(host)
       muc_module:hook("muc-room-created", room_created, -1);
       muc_module:hook("muc-room-destroyed", room_destroyed, -1);
       muc_module:hook("muc-occupant-joined", occupant_joined, -1);
       muc_module:hook("muc-occupant-pre-leave", occupant_leaving, -1);
    end
end

if prosody.hosts[muc_component_host] == nil then
    module:log("info", "No muc component found, will listen for it: %s", muc_component_host);

    -- when a host or component is added
    prosody.events.add_handler("host-activated", process_host);
else
    process_host(muc_component_host);
end