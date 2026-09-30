shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled;

uniform sampler2D albedo_texture : source_color, filter_nearest;
uniform float jitter_resolution : hint_range(0.0, 640.0, 1.0) = 180.0;
uniform float metallic : hint_range(0.0, 1.0) = 0.15;
uniform float roughness : hint_range(0.0, 1.0) = 0.85;
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec3 emissive_color : source_color = vec3(0.0);
uniform float emissive_intensity : hint_range(0.0, 10.0) = 0.0;

varying vec2 v_uv;

void vertex() {
	v_uv = UV;
	
	// Authentic PS1 screen-space vertex snapping
	if (jitter_resolution > 0.0) {
		vec4 snapped = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
		if (snapped.w != 0.0) {
			snapped.xyz /= snapped.w;
			snapped.xy = floor(snapped.xy * jitter_resolution) / jitter_resolution;
			snapped.xyz *= snapped.w;
			POSITION = snapped;
		}
	}
}

void fragment() {
	vec4 col = texture(albedo_texture, v_uv) * tint_color;
	ALBEDO = col.rgb;
	ALPHA = col.a;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	
	if (emissive_intensity > 0.0) {
		EMISSION = emissive_color * emissive_intensity;
	}
}
