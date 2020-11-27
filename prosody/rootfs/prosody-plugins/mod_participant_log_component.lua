local st = require "util.stanza";
local socket = require "socket";
local json = require "util.json";
local ext_events = module:require "ext_events";
local it = require "util.iterators";
local jid = require "jtil.jid";
local jid_resource = require "util.jid".resource;
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

log("info", "Starting participant logger for %s", muc_component_host);

function occupant_joined(event)
    local room = event.room;
    local occupant = event.occupant;

    local nick = jid_resource(occupant.nick);

    local participant_count = it.count(room:each_occupant());


    if room.participant then
        local node, host, resource = jid.split(room.jid);

        local url = "http://vmapi:5000/plog/participant-join";

        local body = {};
        body.room = node;
        body.stats = {};

        room.participant[nick] = {
            joinTime = os.date("*t"),
            leaveTime = nil,
            name = occupant.sessions[occupant.jid]:get_child_text('nick', 'http://jabber.org/protocol/nick'),
            email = occupant.sessions[occupant.jid]:get_child_text('email'),
            id = occupant.sessions[occupant.jid]:get_child_text('id'),
            jid = occupant.jid
        };

        for k, v in pairs(room.participant) do
            local stat = {};
        
            stat.joinTime = os.time(v.joinTime);
            stat.leaveTime = os.time(v.leaveTime);
            stat.name = v.name);
            stat.email = v.email;
            stat.id = id;
            stat.jid = jid;
            body.stats[k] = stat;
        end

        local encoded_body = json.encode(body);

        -- https://prosody.im/doc/developers/net/http
        http.request(url, { body=encoded_body, method="POST", headers = { ["Content-Type"] = "application/json" } },
        function(resp_body, response_code, response)
            print(resp_body, response_code, response);
        end);
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
        local node, host, resource = jid.split(room.jid);

        local url = "http://vmapi:5000/plog/participant-leave";

        local body = {};
        body.room = node;
        body.stats = {};

        room.participant[nick] = {
            joinTime = room.participant[nick].joinTime,
            leaveTime = os.date("*t"),
            name = room.participant[nick].name,
            email = room.participant[nick].email,
            id = room.participant[nick].id,
            jid = room.participant[nick].jid
        };

        for k, v in pairs(room.participant) do
            local stat = {};
        
            stat.joinTime = os.time(v.joinTime);
            stat.leaveTime = os.time(v.leaveTime);
            stat.name = v.name);
            stat.email = v.email;
            stat.id = id;
            stat.jid = jid;
            body.stats[k] = stat;
        end

        local encoded_body = json.encode(body);

        -- https://prosody.im/doc/developers/net/http
        http.request(url, { body=encoded_body, method="POST", headers = { ["Content-Type"] = "application/json" } },
        function(resp_body, response_code, response)
            print(resp_body, response_code, response);
        end);
    end
end

function room_created(event)
    local room = event.room;
    room.participant = {};
end

function room_destroyed(event)
    local room = event.room;

    if is_healthcheck_room(room.jid) then
        return;
    end

    local node, host, resource = jid.split(room.jid);

    local url = "http://vmapi:5000/plog/room-destoryed";

    local body = {};
    body.room = node;
    body.stats = {};

    for k, v in pairs(room.participant) do
        local stat = {};
    
        stat.joinTime = os.time(v.joinTime);
        stat.leaveTime = os.time(v.leaveTime);
        stat.name = v.name);
        stat.email = v.email;
        stat.id = id;
        stat.jid = jid;
        body.stats[k] = stat;
    end

    local encoded_body = json.encode(body);

    -- https://prosody.im/doc/developers/net/http
    http.request(url, { body=encoded_body, method="POST", headers = { ["Content-Type"] = "application/json" } },
    function(resp_body, response_code, response)
        print(resp_body, response_code, response);
    end);
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