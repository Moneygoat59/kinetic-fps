shader_type spatial;
// Overlay (GeometryInstance3D.material_overlay) that soils a clean apartment piece left out in the dead forest: mud climbing
// from the ground line, ash settled on what faces up, a patchy film over the rest. World-space noise, so no UVs needed and no
// two pieces match. Remnant.grime() sets it; ground_y is per instance.
render_mode blend_mix, depth_draw_never, cull_back, specular_disabled;

uniform vec3 mud : source_color = vec3(0.06, 0.05, 0.042);
uniform vec3 ash : source_color = vec3(0.2, 0.19, 0.18);
uniform vec3 film : source_color = vec3(0.11, 0.095, 0.08);
uniform float mud_band = 0.9;        // m above the ground the mud reaches
uniform float film_amount = 0.74;    // how much of the clean colour the film takes away
uniform float noise_scale = 2.6;
instance uniform float ground_y = 0.0;

varying vec3 w_pos;
varying vec3 w_nrm;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x), mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x), mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void vertex() {
	w_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	w_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 p = w_pos * noise_scale;
	float n = noise(p) * 0.6 + noise(p * 2.7) * 0.3 + noise(p * 7.1) * 0.1;
	float rise = clamp(1.0 - (w_pos.y - ground_y) / mud_band, 0.0, 1.0);
	float mud_a = smoothstep(0.35, 0.7, rise + (n - 0.5) * 0.6);
	float ash_a = smoothstep(0.45, 0.85, clamp(w_nrm.y, 0.0, 1.0) * 0.8 + (n - 0.5) * 0.9) * 0.85;
	float streak = noise(vec3(w_pos.x * 9.0, w_pos.y * 0.8, w_pos.z * 9.0));
	float film_a = film_amount * (0.7 + 0.3 * n) + smoothstep(0.6, 0.9, streak) * 0.2;
	vec3 col = mix(film, ash, ash_a);
	col = mix(col, mud, mud_a);
	ALBEDO = col;
	ROUGHNESS = 1.0;
	ALPHA = clamp(max(film_a, max(ash_a, mud_a)), 0.0, 0.96);
}
