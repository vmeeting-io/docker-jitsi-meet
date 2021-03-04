
module:hook("iq-set/bare/http://jabber.org/protocol/muc#admin:query",
function (event)
    module:log("info", "check_for_incoming_ban: %s", tostring(event.stanza));
end, 100);

-- local function add_blacklist(stanza, from)
--     local room_jid = room_jid_match_rewrite(jid_bare(from));
--     local room = get_room_from_jid(room_jid);
--     local occupant = room:get_occupant_by_real_jid(stanza.attr.to);
--     -- log("info", "add_blacklist:", room, dump(occupant), from);

--     if occupant == nil then
--         -- log("info", "occupant not found: %s", stanza.attr.to);
--         return;
--     end

--     local stats_id = get_stats_id(occupant);
--     if stats_id then
--         room.blacklist[stats_id] = from;
--     end
--     log("info", "Added blacklist %s = %s", stats_id, from);
-- end

-- local xmlns_muc_user = "http://jabber.org/protocol/muc#user";
-- local function check_for_incoming_ban(event)
--     local is_enabled = module:get_option_boolean("enable_incoming_ban");
--     if not is_enabled then
--         return;
--     end

--     local stanza = event.stanza;
-- 	local to_session = full_sessions[stanza.attr.to];
--     log(log_level, "check_for_incoming_ban: %s", tostring(stanza));
-- 	-- if to_session then
-- 	-- 	local directed = to_session.directed;
-- 	-- 	local from = stanza.attr.from;
-- 	-- 	if stanza.attr.type == "set" then
-- 	-- 		-- This is a stanza from somewhere we sent directed presence to (may be a MUC)
-- 	-- 		local x = stanza:get_child("x", xmlns_muc_user);
-- 	-- 		if x then
-- 	-- 			for status in x:childtags("status") do
-- 	-- 				if status.attr.code == '307' then
-- 	-- 					add_blacklist(stanza, from);
-- 	-- 				end
-- 	-- 			end
-- 	-- 		end
-- 	-- 	end
-- 	-- end
-- end

-- local function check_for_ban(event)
--     local is_enabled = module:get_option_boolean("enable_incoming_ban");
--     if not is_enabled then
--         return;
--     end

-- 	local origin, stanza = event.origin, event.stanza;
-- 	local to = room_jid_match_rewrite(jid_bare(stanza.attr.to));
--     local room = get_room_from_jid(to);
--     local stats_id = stanza:get_child_text('stats-id');

-- 	-- rewrite jid
-- 	if stats_id and room.blacklist[stats_id] then
-- 		log("info", "check_for_ban: %s is forbidden from %s", stats_id, to);
-- 		if stanza.attr.type ~= "error" then
-- 			origin.send(st.error_reply(stanza, "auth", "forbidden")
-- 				:tag("x", { xmlns = xmlns_muc_user })
-- 					:tag("status", { code = '301' }));
-- 		end
-- 		return true;
-- 	end
-- 	-- log("info", "check_for_ban: %s is accepted from %s", stats_id, to, room);
-- end

-- local domain_base = module:get_option_string("muc_mapper_domain_base");
-- local guest_prefix = "guest";

-- function process_host(host)
--     module:log("info", "Loading mod_participant_log_component for %s", host);
--     local muc_module = module:context(host);

--     if host == muc_component_host then -- the conference muc component
--         module:log("info", "Hook to muc events on %s", host);
--         muc_module:hook("muc-room-created", room_created, -1);
--         muc_module:hook("muc-room-destroyed", room_destroyed, -1);
--         muc_module:hook("muc-occupant-joined", occupant_joined, -1);
--         muc_module:hook("muc-occupant-pre-leave", occupant_leaving, -1);
--         muc_module:hook('muc-broadcast-presence', occupant_updated, -1);

--         whitelist = muc_module:get_option_set('muc_lobby_whitelist', {});
--         log("info", "whitelist for participant logger: %s", whitelist);
--     elseif host == guest_prefix..'.'..domain_base then
--         module:log("info", "Hook to guest events on %s", host);
-- 		muc_module:hook("pre-presence/full", check_for_ban, 100);
--     end
-- end

-- prosody.events.add_handler("host-activated", process_host);
-- for host in pairs(prosody.hosts) do
--     process_host(host);
-- end
