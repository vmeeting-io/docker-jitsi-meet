local conference_db_component
    = module:get_option_string(
        "conference_db_component", "conferencedb"..module.host);

module:add_identity("component", "conference_db", conference_db_component);
