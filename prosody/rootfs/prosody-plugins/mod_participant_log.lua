local participant_log_component
    = module:get_option_string(
        "participant_log_component", "participantlog"..module.host);

module:add_identity("component", "participant_log", participant_log_component);
