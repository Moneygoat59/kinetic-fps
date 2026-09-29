// Shared body of the wraith shaders (wraith.gdshader: skin, teeth, eyes, back faces culled; wraith_hair.gdshader: the hair
// cards, both sides, alpha cut). See wraith.gdshader for what it does.

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_disable;
uniform bool use_texture = true;
uniform bool use_normal = false;
uniform vec4 tint : source_color = vec4(1.0);
uniform float roughness = 0.5;
uniform float specular = 0.35;
uniform float alpha_cut = 0.0;           // hair cards: texels thinner than this are holes
uniform vec3 rim_color : source_color = vec3(0.52, 0.6, 0.78);
uniform float rim_strength = 0.12;       // a cold edge so it reads against the dark
uniform float presence : hint_range(0.0, 1.0) = 1.0;
uniform float base_y = 0.0;              // world y of its feet
uniform float hem_top = 0.5;             // below this (metres above base_y) it thins into mist
uniform float flicker : hint_range(0.0, 1.0) = 0.0;
uniform vec3 edge_color : source_color = vec3(0.55, 0.68, 0.95);

varying vec3 wpos;

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
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 t = use_texture ? texture(albedo_tex, UV) * tint : tint;
	float n = noise(wpos * 4.0 + vec3(0.0, -TIME * 0.7, TIME * 0.2)) * 0.7 + noise(wpos * 11.0 + vec3(TIME * 0.3, -TIME * 1.3, 0.0)) * 0.3;
	float hem = smoothstep(0.0, hem_top, wpos.y - base_y + (n - 0.5) * 0.35);
	float cut = 1.0 - presence * hem;
	cut = max(cut, flicker * 0.55 * step(0.72, noise(vec3(TIME * 11.0, wpos.y * 0.5, 0.0))));
#ifdef HAIR_CARDS
	if (n < cut) {
		discard;
	}
	ALPHA = t.a;                                   // alpha to coverage (MSAA): soft, fine strands, no sorting
	ALPHA_SCISSOR_THRESHOLD = alpha_cut;
	ALPHA_ANTIALIASING_EDGE = 0.3;
	ALPHA_TEXTURE_COORDINATE = UV * vec2(256.0, 1024.0);
#else
	if (n < cut || t.a < alpha_cut) {
		discard;
	}
#endif
	float burn = (1.0 - smoothstep(cut, cut + 0.09, n)) * step(0.001, cut);
	ALBEDO = t.rgb;
	if (use_normal) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
	}
	ROUGHNESS = roughness;
	SPECULAR = specular;
	float fres = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 3.0);
	EMISSION = rim_color * fres * rim_strength + edge_color * burn * 1.6;
}
