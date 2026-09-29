// AbyssFog (scripts/world/abyss_fog.gd): an imported StandardMaterial3D rebuilt as a shader whose fog turns from the
// level's pale depth fog at the rim into black with depth below it, so a pit reads bottomless. Albedo texture x colour x
// vertex colour (baked AO), dead matte, optional emission. Ambient light fades with depth too (AO), lamps still light.
uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_enable;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform bool use_tex = false;
uniform bool use_vcol = false;
uniform sampler2D emission_tex : source_color, filter_nearest, repeat_enable;
uniform vec3 emission_color : source_color = vec3(0.0);
uniform float emission_energy = 0.0;
uniform bool use_emission_tex = false;
uniform vec2 uv_offset = vec2(0.0);
uniform vec3 surface_fog : source_color = vec3(0.70, 0.73, 0.76);
uniform vec3 abyss_color : source_color = vec3(0.0);
uniform float fog_begin = 8.0;
uniform float fog_end = 45.0;
uniform float fog_curve = 1.1;
uniform float rim_y = 0.0;          // world height where the pit starts
uniform float abyss_depth = 28.0;   // metres below rim_y where the fog is fully black
uniform float abyss_end = 70.0;     // view distance at which the deep fog is total
uniform float ambient_floor = 0.2;  // ambient light left at full depth
uniform float reach = 1.0;          // < 1: fog takes this surface slower (glowing lines stay visible deeper)

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

vec4 abyss_base(vec2 uv, vec4 vcol) {
	vec4 base = albedo_color;
	if (use_tex) {
		base *= texture(albedo_tex, uv + uv_offset);
	}
	if (use_vcol) {
		base.rgb *= vcol.rgb;
	}
	return base;
}

vec3 abyss_emission(vec2 uv) {
	vec3 em = emission_color * emission_energy;
	if (use_emission_tex) {
		em *= texture(emission_tex, uv + uv_offset).rgb;
	}
	return em;
}

float abyss_deep() {
	return clamp((rim_y - world_pos.y) / abyss_depth, 0.0, 1.0);
}

vec4 abyss_fog(vec3 cam, float deep) {
	float end = mix(fog_end, abyss_end, deep);
	float amount = pow(smoothstep(fog_begin, end, length(world_pos - cam)), fog_curve);
	return vec4(mix(surface_fog, abyss_color, deep), clamp(amount * reach, 0.0, 1.0));
}
