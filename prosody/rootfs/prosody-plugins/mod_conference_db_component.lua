local st = require "util.stanza";
local socket = require "socket";
local json = require "util.json";
local ext_events = module:require "ext_events";
local it = require "util.iterators";
local jid = require "util.jid";
local is_healthcheck_room = module:require "util".is_healthcheck_room;
local http = require "net.http";

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

log("info", "Starting conference db module for %s", muc_component_host);

function room_created(event)
    local room = event.room;

    log("info", "Room is %s", room);
end

function room_destroyed(event)
    local room = event.room;

    if is_healthcheck_room(room.jid) then
        return;
    end

    local node, host, resource = jid.split(room.jid);

    local url = "http://vmapi:5000/conference/set-end-time";
    local reqbody = { name = node };
    local reqbody_string = http.formencode(reqbody);
    log("info", "node is %s", node);

    http.request(url, { body=reqbody_string, method="POST" },
        function(resp_body, response_code, response)
            log("info", "HTTP POST Request to room %s with meetingId %s received code %s", node, room._data.meetingId, response_code);
        end);
end

-- executed on every host added internally in prosody, including components
function process_host(host)
    if host == muc_component_host then -- the conference muc component
        module:log("info", "Hook to muc events on %s", host);

       local muc_module = module:context(host)
       muc_module:hook("muc-room-created", room_created, -1);
       muc_module:hook("muc-room-destroyed", room_destroyed, -1);
    end
end

if prosody.hosts[muc_component_host] == nil then
    module:log("info", "No muc component found, will listen for it: %s", muc_component_host);

    -- when a host or component is added
    prosody.events.add_handler("host-activated", process_host);
else
    process_host(muc_component_host);
end