local get_room_from_jid = module:require "util".get_room_from_jid;
local room_jid_match_for_recorder = module:require "util".room_jid_match_for_recorder;
local st = require "util.stanza";
local json = require "cjson";

-- detect new jibri start recording action and add recorder_identity info to metadata
module:hook("pre-iq/full", function(event)
    local stanza = event.stanza;

    if stanza.name == "iq" then
        for k, v in pairs(event) do
            log('info', "%s: %s", k, v);
        end
        local jibri = stanza:get_child('jibri', 'http://jitsi.org/protocol/jibri');

        if jibri and jibri.attr.action == 'start' and jibri.attr.recording_mode == 'file' then
            -- log('info', "Start: ", stanza.attr.to);   
            local room1 = room_jid_match_for_recorder(stanza.attr.to);
            local room2 = get_room_from_jid(room_jid_match_for_recorder(stanza.attr.to));
            -- log('info', "Room1: ", room1);      
            -- log('info', "Room2: ", room2);        

            local recorder_identity = event.origin.jitsi_meet_context_user;
            if recorder_identity then
                log('info', "new recording session by: " .. recorder_identity.email);
                -- inject recorder_identity info field to file recording metadata
                local app_data = json.decode(jibri.attr.app_data);
                app_data.file_recording_metadata.recorder_identity = recorder_identity;
                local room = get_room_from_jid(room_jid_match_for_recorder(stanza.attr.to));
                if room and room._data then
                    app_data.file_recording_metadata.meetingId = room._data.meetingId;
                end
                jibri.attr.app_data = json.encode(app_data);
            else
                log('warning', "new recording without recorder_identity info");
            end
        end
    end
end);
