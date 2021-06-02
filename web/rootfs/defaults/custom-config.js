{{ if (.Env.ENABLE_INDIVIDUAL_REC | default "false" | toBool) }}
config.sendMinHeight = {{ .Env.REC_RESOLUTION | default 180 }}

if (!config.hasOwnProperty('p2p')) config.p2p = {};
config.p2p.enabled = false;
{{ end }}
