local st = require "util.stanza";
local json = require "cjson";

-- detect new jibri start recording action and add recorder_identity info to metadata
module:hook("pre-iq/full", function(event)
    local stanza = event.stanza;
    if stanza.name == "iq" then
        local jibri = stanza:get_child('jibri', 'http://jitsi.org/protocol/jibri');
        if jibri and jibri.attr.action == 'start' and jibri.attr.recording_mode == 'file' then
            local recorder_identity = event.origin.jitsi_meet_context_user;
            if recorder_identity then
                log('info', "new recording session by: " .. recorder_identity.email);
                -- inject recorder_identity info field to file recording metadata
                local app_data = json.decode(jibri.attr.app_data);
                app_data.file_recording_metadata.recorder_identity = recorder_identity;
                jibri.attr.app_data = json.encode(app_data);
            else
                log('warning', "new recording without recorder_identity info");
            end
        end
    end
end);
