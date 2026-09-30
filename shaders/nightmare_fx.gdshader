shader_type canvas_item;
// Full-screen nightmare filter over the finale of night 2 (scripts/world/wraith/nightmare_fx.gd drives every uniform per
// frame). Reads the rendered frame and tears it up:
//   warp        radial bulge / pinch (the heartbeat, the in-breath, the scream's vibration)
//   tear        horizontal bands of the image jumping sideways, and scanlines (a signal failing)
//   blur        zoom blur toward the centre (being wrenched round)
//   aberration  red / blue split outward from the centre
//   desat       colour drains away, except reds (its eyes, the blood) which stay and burn
//   red         blood-red creeping in from the edges
//   grain       film noise;  vignette  the edges closing in (tunnel vision)
//   flash       the whole frame washed to flash_color;  invert  a negative frame

uniform sampler2D screen : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float warp = 0.0;
uniform float tear = 0.0;
uniform float blur = 0.0;
uniform float aberration = 0.0;
uniform float desat = 0.0;
uniform float red = 0.0;
uniform float grain = 0.0;
uniform float vignette = 0.0;
uniform float flash = 0.0;
uniform vec3 flash_color : source_color = vec3(1.0);
uniform float invert = 0.0;
uniform float seed = 0.0;               // changes every frame the effect wants new randomness

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec3 sample_split(vec2 uv, vec2 dir) {
	return vec3(texture(screen, uv + dir * aberration).r, texture(screen, uv).g, texture(screen, uv - dir * aberration).b);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 c = uv - 0.5;
	float r = length(c);
	uv += c * warp * (0.4 + r * r * 3.0);
	float band = floor(uv.y * 36.0);
	float hit = step(1.0 - tear * 0.4, hash(vec2(band, seed)));
	uv.x += (hash(vec2(band * 1.7, seed + 3.1)) - 0.5) * 0.14 * tear * hit;
	vec3 col = vec3(0.0);
	if (blur > 0.001) {
		for (int i = 0; i < 8; i++) {
			col += sample_split(uv - c * blur * float(i) / 7.0, c);
		}
		col /= 8.0;
	} else {
		col = sample_split(uv, c);
	}
	col *= 1.0 - tear * 0.25 * step(0.5, fract(SCREEN_UV.y * 270.0));                 // scanlines
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	float redness = clamp((col.r - max(col.g, col.b)) * 4.0, 0.0, 1.0);
	col = mix(col, vec3(lum), desat * (1.0 - redness));
	col = mix(col, col * vec3(1.5, 0.3, 0.25) + vec3(0.08, 0.0, 0.0), red * smoothstep(0.15, 0.75, r));
	col += (hash(SCREEN_UV * vec2(1931.0, 1087.0) + seed * 17.0) - 0.5) * grain;
	col *= 1.0 - vignette * smoothstep(0.2, 0.75, r * 1.25);
	col = mix(col, flash_color, clamp(flash, 0.0, 1.0));
	col = mix(col, vec3(1.0) - col, invert);
	COLOR = vec4(col, 1.0);
}
