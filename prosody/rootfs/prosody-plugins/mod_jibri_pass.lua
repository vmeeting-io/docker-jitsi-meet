local MUC_NS = "http://jabber.org/protocol/muc";
local jid = require "util.jid";
local os = require "os";

-- allow jibri to join room with password
module:hook("muc-occupant-pre-join", function (event)
    local room, stanza = event.room, event.stanza;
    local user, domain, res = jid.split(event.stanza.attr.from);

    if user==os.getenv("JIBRI_RECORDER_USER") and domain==os.getenv("XMPP_RECORDER_DOMAIN") then
        local join = stanza:get_child("x", MUC_NS);
        join:tag("password", { xmlns = MUC_NS }):text(room:get_password());
    end;
end);
