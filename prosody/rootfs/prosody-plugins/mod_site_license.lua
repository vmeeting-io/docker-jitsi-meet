-- Token authentication
-- Copyright (C) 2015 Atlassian

local log = module._log;
local is_admin = require "core.usermanager".is_admin;
local it = require "util.iterators";
local split_jid = require "util.jid".split;
local json = require "util.json";
local st = require "util.stanza";
local MAX_OCCUPANTS = 50;
local sites = {};
local licenses = {};
local whitelist = module:get_option_set("muc_access_whitelist");
local room_jid_split_subdomain = module:require "util".room_jid_split_subdomain;

local log_level = "info";

local function count_keys(t)
    return it.count(it.keys(t));
end

local epoch = os.time{year=1970, month=1, day=1, hour=0}
function parse_json_date(json_date)
    local pattern = "(%d+)%-(%d+)%-(%d+)%a(%d+)%:(%d+)%:([%d%.]+)([Z%+%- ])(%d?%d?)%:?(%d?%d?)";
    local year, month, day, hour, minute, seconds, offsetsign, offsethour, offsetmin = json_date:match(pattern);
    local timestamp = os.time{year = year, month = month, day = day, hour = hour, min = minute, sec = seconds} - epoch;
    local offset = 0;

    if offsetsign ~= 'Z' then
        offset = tonumber(offsethour) * 60 + tonumber(offsetmin);
        if offsetsign == "-" then offset = -offset end
    end

    return timestamp - offset * 60;
end

-- load site and license information
local function load_config()
    local req_url = "http://vmapi:5000/sites?license=true"
    http.request(req_url, { method="GET", headers = { ["Content-Type"] = "application/json" } },
    function(resp_body, response_code, response)
        if response_code == 200 then
            local body = json.decode(resp_body);
            for k,v in pares(body) do
                local site = body[k];
                if site.use_yn and not site.delete_yn and site.service_user_count > 0 then
                    sites[site._id] = v;
                    licenses[site._id] = { max = site.service_user_count, used = 0 };
                end
            end
            log(log_level, "site license loaded", response_code);
        end
    end);
end

-- check site license validation
local function validate_site_license(id)
    local site = sites[id];

    if not site then
        return false;
    end

	log("debug", "site: %s", tostring(site));

    if site.service_user_count == 0 or site.use_yn == false or site.delete_yn == true then
        return false;
    end

    local start_dt = site.service_start_dt and parse_json_date(site.service_start_dt);
    local end_dt   = site.service_end_dt and parse_json_date(site.service_end_dt);
    local now      = os.time();

    if start_dt > now or end_dt < now then
        return false;
    end

    return true;
end

-- check max user occupants
local function check_consume_site_license(session, room, stanza)
	log("debug", "pre create room: %s", room.jid);

    -- check site validation
    local node, domain, resourse, site_id = room_jid_split_subdomain(room.jid);
    if not validate_site_license(site_id) then
        log("info", "Attempt using invalid site license");
        session.send(st.error_reply(stanza, "cancel", "service-unavailable"));
        return false; -- we need to just return non nil
    end

    local license = licenses[site_id];
    if not license then
        log("info", "Attempt using invalid license.", site_id);
        session.send(st.error_reply(stanza, "cancel", "service_unavailable"));
    end

    license.used = license.used + 1;
    if license.max < license.used then
        log("info", "Attempt to enter a maxed out license.");
        session.send(st.error_reply(stanza, "cancel", "service_unavailable"));
    end

    log(log_level,
        "allowed: %s to enter/create room: %s", site_id, stanza.attr.to);
end

local function return_site_license(room)
	log("debug", "destroyed room: %s", room.jid);

    local node, domain, resourse, site_id = room_jid_split_subdomain(room.jid);
    local license = licenses[site_id];

    if license then
        license.used = license.used - 1;
    end
end

local function check_for_max_occupants(session, room, stanza)
    -- check max occupants
    local node, _, resourse, site_id = room_jid_split_subdomain(room.jid);
    local user_jid = stanza.attr.from;
	local user, domain, res = split_jid(user_jid);

    --no user object means no way to check for max occupants
	if user == nil or is_admin(user_jid) then
		log("debug", "nil or admin user not required to check max occupants: %s", user_jid);
		return
    end

	-- If we're a whitelisted user joining the room, don't bother checking the max
	-- occupants.
    module:log("debug", "user = %s, domain = %s, res = %s", user, domain, res);
	if whitelist and whitelist:contains(domain) or whitelist:contains(user..'@'..domain) then
		return;
	end

	if room and not room._jid_nick[user_jid] then
		local count = count_keys(room._occupants);
		local slots = sites[site_id] and sites[site_id].max_occupants or MAX_OCCUPANTS;

		-- If there is no whitelist, just check the count.
		if not whitelist and count > slots then
			module:log("info", "Attempt to enter a maxed out MUC");
			origin.send(st.error_reply(stanza, "cancel", "service-unavailable"));
			return true;
		end

        -- TODO: Are Prosody hooks atomic, or is this a race condition?
		-- For each person in the room that's not on the whitelist, subtract one
		-- from the count.
		for _, occupant in room:each_occupant() do
			user, domain, res = split_jid(occupant.bare_jid);
			if not whitelist:contains(domain) and not whitelist:contains(user..'@'..domain) then
				slots = slots - 1
			end
		end

		-- If the room is full (<0 slots left), error out.
		if slots < 0 then
			module:log("info", "Attempt to enter a maxed out MUC");
			origin.send(st.error_reply(stanza, "cancel", "service-unavailable"));
			return true;
		end
    end
end

-- stanza :
-- <presence
--     to='testtt@muc.vmeeting.kr/84cc3d39'
--     from='84cc3d39-1eaa-4ce0-8c19-b40be915a644@vmeeting.kr/WLZr_mnS'>
--     <x xmlns='http://jabber.org/protocol/muc'/>
--     <stats-id>Cortney-9Sm</stats-id>
--     <c xmlns='http://jabber.org/protocol/caps' hash='sha-1' node='http://jitsi.org/jitsimeet' ver='cWj8xSCR2vP2KMorJrpHIw9Q/jA='/>
--     <avatar-id>f3f72f4d6a49d4c35df8440e583a6cda</avatar-id>
--     <avatar-url>/auth/api/avatar/5f4fe180952925001a32c648?v=2</avatar-url>
--     <email>theun@postech.ac.kr</email>
--     <nick xmlns='http://jabber.org/protocol/nick'>은태환</nick>
--     <audiomuted xmlns='http://jitsi.org/jitmeet/audio'>false</audiomuted>
--     <videoType xmlns='http://jitsi.org/jitmeet/video'>camera</videoType>
--     <videomuted xmlns='http://jitsi.org/jitmeet/video'>false</videomuted>
--     <identity>
--         <user>
--             <avatar>/auth/api/avatar/5f4fe180952925001a32c648?v=2</avatar>
--             <id>5f4fe164952925001a32c647</id>
--             <email>theun@postech.ac.kr</email>
--             <username>theun</username>
--             <name>은태환</name>
--             <isAdmin>false</isAdmin>
--         </user>
--         <group>vmeeting</group>
--     </identity>
-- </presence>
-- module:hook("muc-room-pre-create", function(event)
-- 	local origin, room, stanza = event.origin, event.room, event.stanza;
-- 	log("debug", "pre create: %s %s", tostring(origin), tostring(stanza));
-- 	return check_consume_site_license(origin, room, stanza);
-- end);

module:hook("muc-room-destroyed", function(event)
    log("info", "room destroyed: %s", event.room.jid);
    return return_site_license(room);
end);

module:hook("muc-occupant-pre-join", function(event)
	local origin, room, stanza = event.origin, event.room, event.stanza;
	log("debug", "pre join: %s %s", tostring(room), tostring(stanza));
	return check_for_max_occupants(origin, room, stanza);
end);

module:hook_global('config-reloaded', load_config);
