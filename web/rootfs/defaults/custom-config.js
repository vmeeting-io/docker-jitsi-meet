
if (!config.hasOwnProperty('p2p')) config.p2p = {};
config.p2p.enabled = {{ not (.Env.ENABLE_INDIVIDUAL_REC | default "false" | toBool) }};
