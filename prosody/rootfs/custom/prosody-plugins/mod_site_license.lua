local http = require "net.http";
local log = module._log;
local is_admin = require "core.usermanager".is_admin;
local it = require "util.iterators";
local split_jid = require "util.jid".split;
local json = require "util.json";
local st = require "util.stanza";
local timer = require "util.timer"

local async_handler_wrapper = module:require "util".async_handler_wrapper;
local get_room_from_jid = module:require "util".get_room_from_jid;
local room_jid_match_rewrite = module:require "util".room_jid_match_rewrite;
local encodeURI = module:require "util".encodeURI;

local MAX_OCCUPANTS = 50;
local MAX_DURATIONS = -1;
local conferences = {};
local whitelist = module:get_option_set("muc_access_whitelist", {});
local muc_domain_prefix = module:get_option_string("muc_mapper_domain_prefix", "conference");
local muc_domain_base = module:get_option_string("muc_mapper_domain_base", module.host);
local muc_domain = module:get_option_string("muc_mapper_domain", muc_domain_prefix.."."..muc_domain_base);
local vmeeting_api_token = module:get_option_string("vmeeting_api_token", "");

local log_level = "info";

local function count_keys(t)
    return it.count(it.keys(t));
end

-- check max user occupants
local function check_for_max_occupants(session, room, stanza)
    -- check max occupants
    local user_jid = stanza.attr.from;
	local user, domain, res = split_jid(user_jid);
	local roomData = room._data;

    --no user object means no way to check for max occupants
	if user == nil or is_admin(user_jid) then
		log(log_level, "nil or admin user not required to check max occupants: %s", user_jid);
		return;
    end

	-- If we're a whitelisted user joining the room, don't bother checking the max
	-- occupants.
    log(log_level, "user = %s, domain = %s, res = %s", user, domain, roomData.max_occupants or MAX_OCCUPANTS);
	if whitelist and whitelist:contains(domain) or whitelist:contains(user..'@'..domain) then
		return;
	end

	if room and not room._jid_nick[user_jid] then
        local count = count_keys(room._occupants);
		local slots = roomData and roomData.max_occupants or MAX_OCCUPANTS;

		if slots < 0 then
			log(log_level, "It is not required to check max occupants: %s", slots);
			return;
		end

		-- If there is no whitelist, just check the count.
		if not whitelist and count > slots then
			log("info", "Attempt to enter a maxed out MUC");
			session.send(st.error_reply(stanza, "cancel", "service-unavailable"));
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
			log("info", "Attempt to enter a maxed out MUC");
			session.send(st.error_reply(stanza, "cancel", "service-unavailable"));
			return true;
		end
    end
end

local function destroy_meeting(now, id, room)
	if is_healthcheck_room(room.jid) then
		return;
	end

	for _, p in room:each_occupant() do
		if not is_admin(p.jid) then
			room:set_affiliation(true, p.jid, "outcast");
			log(log_level, "kick the occupant, %s", p.jid);
		end
	end

	log(log_level, "conference terminated: %s", room.jid);
end

local function start_time_restrict_task(room)
	if is_healthcheck_room(room.jid) or not room._data then
		log(log_level, "skip time restriction");
		return;
	end

	if room._data.task_id then
		timer.stop(room._data.task_id);
		room._data.task_id = nil;
		log(log_level, "%s task is stopped", room._data.task_id);
	end

	if not room._data.tstart then
		room._data.tstart = os.time();
		log(log_level, "conference started at %s: %s", os.date());
	end

	if not room._data.max_durations or room._data.max_durations <= 0 then
		log(log_level, "It has unlimited duration: %s", room._data.max_durations);
		return;
	end

	local time_elapsed = os.difftime(os.time(), room._data.tstart);
	local time_remained = room._data.max_durations - time_elapsed;
	if time_remained <= 0 then
		log(log_level, "No time is remained: %s", time_remained);
		destroy_meeting(os.time(), room._data.task_id, room);
		return;
	end

	room._data.task_id = timer.add_task(time_remained, destroy_meeting, room);
	log(log_level, "It will terminate after %s seconds", time_remained);
end

module:hook("muc-room-created", function(event)
	local room = event.room;

	if is_healthcheck_room(room.jid) or not room._data then
		log(log_level, "skip restriction");
		return;
	end

	local max_durations = room._data.max_durations;
	if not max_durations or max_durations < 0 then
		log(log_level, "skip restriction: %s", max_durations);
		return;
	end

	start_time_restrict_task(room);
end);

module:hook("muc-occupant-pre-join", function(event)
	local origin, room, stanza = event.origin, event.room, event.stanza;
	log(log_level, "pre join: %s %s", tostring(room), tostring(stanza));
	return check_for_max_occupants(origin, room, stanza);
end);

local function get_authorization_token(request)
	local authorization = request.headers.authorization;
	if authorization then
		local token = authorization:match("Bearer ([^ ]+)");
		return token;
	end
end

--- Handles request for updating conference info
-- @param event the http event, holds the request query
-- @return GET response, containing a json with response details
function handle_conference_event(event)
	local token = get_authorization_token(event.request);
	if not token or token ~= vmeeting_api_token then
		log("info", "Forbidden: Authorization token is needed.");
		return { status_code = 403 };
	end

    local body = json.decode(event.request.body);

    log(log_level, "%s: Update Conference Event Received: %s", event.request.method, tostring(body));

	local roomName = encodeURI(body["room_name"]);
    if not roomName then
		log(log_level, "Not Found, %s", roomName);
        return { status_code = 400 };
    end

	local roomAddress = roomName.."@"..muc_domain;
	local room_jid = room_jid_match_rewrite(roomAddress);
	local room = get_room_from_jid(room_jid);
	if not room or not room._data then
		log(log_level, "Not Found %s %s", roomAddress, room_jid);
		return { status_code = 400 };
	end

	local max_durations;
	if body["max_durations"] ~= json.null then
		max_durations = body["max_durations"];
	else
		max_durations = -1;
	end
	if body["delete_yn"] then
		log(log_level, "Conference Removed: %s", room._data.meetingId);
		room._data.max_occupants = 0;
		room._data.max_durations = 0;
		start_time_restrict_task(room);
    else
		room._data.max_occupants = body["max_occupants"] or MAX_OCCUPANTS;
		room._data.max_durations = max_durations;
		start_time_restrict_task(room);
		log(log_level, "Conference Updated: %s %s %s", room._data.meetingId, room._data.max_occupants, room._data.max_durations);
    end

    return { status_code = 200; };
end

function module.load()
	module:depends("http");
	module:provides("http", {
		default_path = "/";
		name = "conferences";
		route = {
			["POST /conferences/events"] = function (event) return async_handler_wrapper(event,handle_conference_event) end;
		};
	});
end

-- module:hook_global('config-reloaded', load_config);
