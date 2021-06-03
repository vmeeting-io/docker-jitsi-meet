{{ if (.Env.ENABLE_INDIVIDUAL_REC | default "false" | toBool) }}
config.p2p.enabled = false;
{{ end }}

// with selective on viewport forwarding, participant will stop sending video if its out of the viewport in all
// other viewports. This delay and possibly cause unstable video transmission when the participant appear in one
// of the viewports again. We set to always send minSendFrameHeight to fix that. minSendFrameHeight also needed
// for Individual recording to work
config.minSendFrameHeight = Math.max({{ .Env.REC_RESOLUTION | default 0 }}, config.constraints.video.height.min)
