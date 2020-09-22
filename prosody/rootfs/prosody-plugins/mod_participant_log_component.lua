local st = require "util.stanza";
local socket = require "socket";
local json = require "util.json";
local ext_events = module:require "ext_events";
local it = require "util.iterators";
local jid_resource = require "util.jid".resource;
local is_healthcheck_room = module:require "util".is_healthcheck_room;

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

log("info", "Starting participant logger for %s", muc_component_host);

function occupant_joined(event)
    local room = event.room;
    local occupant = event.occupant;

    local nick = jid_resource(occupant.nick);

    local participant_count = it.count(room:each_occupant());


    if room.participant then
        local users_json = {};

        room.participant[nick] = {joinTime = os.date("*t"), leaveTime = nil, sessions = occupant.sessions[occupant.jid]};

        for k, v in pairs(room.participant) do
            users_json[k] = v;
        end

        local body_json = {};
        body_json.type = 'participant_log';
        body_json.log = users_json;

        for k, v in pairs(room._occupants) do
            local stanza = st.message({
                from = module.host;
                to = v.jid;
            })
            :tag("json-message", {xmlns='http://jitsi.org/jitmeet'})
            :text(json.encode(body_json)):up();

            room:route_stanza(stanza);
        end
    end
end

function occupant_leaving(event)
    local room = event.room;

    if is_healthcheck_room(room.jid) then
            return;
    end

    local occupant = event.occupant;
    local nick = jid_resource(occupant.nick);

    local logForOccupant = room.participant[nick];

    if logForOccupant then
        local users_json = {};

        room.participant[nick] = {joinTime = room.participant[nick].joinTime, leaveTime = os.date("*t"), sessions = room.participant[nick].sessions};

        for k, v in pairs(room.participant) do
            users_json[k] = v;
        end

        local body_json = {};
        body_json.type = 'participant_log';
        body_json.log = users_json;

        for k, v in pairs(room._occupants) do
            local stanza = st.message({
                from = module.host;
                to = v.jid;
            })
            :tag("json-message", {xmlns='http://jitsi.org/jitmeet'})
            :text(json.encode(body_json)):up();

            room:route_stanza(stanza);
        end
    end
end

function room_created(event)
    local room = event.room;
    room.participant = {};
end

-- executed on every host added internally in prosody, including components
function process_host(host)
    if host == muc_component_host then -- the conference muc component
        module:log("info", "Hook to muc events on %s", host);

       local muc_module = module:context(host)
       muc_module:hook("muc-room-created", room_created, -1);
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