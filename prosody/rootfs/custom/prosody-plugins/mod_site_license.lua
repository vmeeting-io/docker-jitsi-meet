local http = require "net.http";
local log = module._log;
local is_admin = require "core.usermanager".is_admin;
local it = require "util.iterators";
local split_jid = require "util.jid".split;
local json = require "util.json";
local st = require "util.stanza";
local async_handler_wrapper = module:require "util".async_handler_wrapper;

local MAX_OCCUPANTS = 50;
local MAX_DURATIONS = -1;
local conferences = {};
local whitelist = module:get_option_set("muc_access_whitelist", {});

local log_level = "info";

local function count_keys(t)
    return it.count(it.keys(t));
end

-- check max user occupants
local function check_for_max_occupants(session, room, stanza)
    -- check max occupants
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
        local meetingId = room._data.meetingId;
		local slots = conferences[meetingId] and conferences[meetingId].max_occupants or MAX_OCCUPANTS;

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

module:hook("muc-occupant-pre-join", function(event)
	local origin, room, stanza = event.origin, event.room, event.stanza;
	log("debug", "pre join: %s %s", tostring(room), tostring(stanza));
	return check_for_max_occupants(origin, room, stanza);
end);

--- Handles request for updating conference info
-- @param event the http event, holds the request query
-- @return GET response, containing a json with response details
function handle_conference_event(event)
    local body = json.decode(event.request.body);

    log("debug", "%s: Update Conference Event Received: %s", event.request.method, tostring(body));

    local meetingId = body["meetingId"];

    if not meetingId then
        return { status_code = 400 };
    end

    if body["delete_yn"] then
        conferences[meetingId] = nil;
    else
        conferences[meetingId] = {
            max_occupants = body["max_occupants"] or MAX_OCCUPANTS,
            max_durations = body["max_durations"] or MAX_DURATIONS,
        };
    end

    return { status_code = 200; };
end

module:depends("http");
module:provides("http", {
    default_path = "/";
    name = "conferences";
    route = {
        ["POST /conferences/events"] = function (event) return async_handler_wrapper(event,handle_conference_event) end;
    };
});

-- module:hook_global('config-reloaded', load_config);
