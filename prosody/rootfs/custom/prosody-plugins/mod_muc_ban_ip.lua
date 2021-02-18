module:set_global();
local log = module._log;

local jid_bare = require "util.jid".bare;
local st = require "util.stanza";
local xmlns_muc_user = "http://jabber.org/protocol/muc#user";
local room_jid_match_rewrite = module:require "util".room_jid_match_rewrite;
local ip_bans = module:shared("bans");

local full_sessions = prosody.full_sessions;

local function ban_ip(session, from)
	local ip = session.ip;
	if not ip then
		log("warn", "Failed to ban IP (IP unknown) for %s", session.full_jid);
		return;
	end
	local banned_from = ip_bans[from];
	if not banned_from then
		banned_from = {};
		ip_bans[from] = banned_from;
	end
	banned_from[ip] = true;
	log("info", "Added ban for IP address %s from %s", ip, from);
end

local function check_for_incoming_ban(event)
	local stanza = event.stanza;
	local to_session = full_sessions[stanza.attr.to];
	if to_session then
		local directed = to_session.directed;
		local from = stanza.attr.from;
		if directed and stanza.attr.type == "unavailable" then
			-- This is a stanza from somewhere we sent directed presence to (may be a MUC)
			local x = stanza:get_child("x", xmlns_muc_user);
			if x then
				for status in x:childtags("status") do
					if status.attr.code == '307' then
						ban_ip(to_session, jid_bare(from));
					end
				end
			end
		end
	end
end

local function check_for_ban(event)
	local origin, stanza = event.origin, event.stanza;
	local ip = origin.ip;
	local to = room_jid_match_rewrite(jid_bare(stanza.attr.to));
	-- rewrite jid
	if ip_bans[to] and ip_bans[to][ip] then
		log("debug", "IP banned: %s is banned from %s", ip, to)
		if stanza.attr.type ~= "error" then
			origin.send(st.error_reply(stanza, "auth", "forbidden")
				:tag("x", { xmlns = xmlns_muc_user })
					:tag("status", { code = '301' }));
		end
		return true;
	end
	log("info", "IP not banned: %s from %s", ip, to)
end

local function room_destroyed(event)
    local room = event.room;

    if is_healthcheck_room(room.jid) then
        return;
    end

	log("info", "room_destroy: ip_bans[%s] = %s", room.jid, ip_bans[room.jid]);
    if ip_bans[room.jid] then
		log("info", "ip_bans[%s] is removed", room.jid);
		ip_bans[room.jid] = nil;
    end
end

local domain_base = module:get_option_string("muc_mapper_domain_base");
local muc_prefix = module:get_option_string("muc_mapper_domain_prefix");
local guest_prefix = "guest";

function add_host(host)
    module:log("info", "Loading mod_muc_ban_ip for host %s", host);

    local host_module = module:context(host);
    if host == muc_prefix..'.'..domain_base then -- the conference muc component
		module:log("info", "Add hook muc-room-destroy for host %s", host);
		host_module:hook("muc-room-destroyed", room_destroyed, -1);
	end
	if host == guest_prefix..'.'..domain_base then
		module:log("info", "Add hook presence/full for host %s", host);
		host_module:hook("presence/full", check_for_incoming_ban, 100);
		module:log("info", "Add hook pre-presence/full for host %s", host);
		host_module:hook("pre-presence/full", check_for_ban, 100);
	end
end

for host in pairs(prosody.hosts) do
    add_host(host);
end
