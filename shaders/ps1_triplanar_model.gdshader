shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled;

uniform sampler2D albedo_texture : source_color, filter_nearest;
uniform vec3 uv_scale = vec3(8.0, 8.0, 8.0);
uniform float jitter_resolution : hint_range(0.0, 640.0, 1.0) = 160.0;
uniform float metallic : hint_range(0.0, 1.0) = 0.2;
uniform float roughness : hint_range(0.0, 1.0) = 0.85;
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec3 emissive_color : source_color = vec3(0.0);
uniform float emissive_intensity : hint_range(0.0, 10.0) = 0.0;

varying vec3 v_local_pos;
varying vec3 v_local_norm;

void vertex() {
	v_local_pos = VERTEX;
	v_local_norm = abs(NORMAL);
	
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
	// Triplanar local projection
	vec3 weights = v_local_norm / max(v_local_norm.x + v_local_norm.y + v_local_norm.z, 0.0001);
	
	vec3 col_x = texture(albedo_texture, v_local_pos.zy * uv_scale.x).rgb;
	vec3 col_y = texture(albedo_texture, v_local_pos.xz * uv_scale.y).rgb;
	vec3 col_z = texture(albedo_texture, v_local_pos.xy * uv_scale.z).rgb;
	
	vec3 tex_col = col_x * weights.x + col_y * weights.y + col_z * weights.z;
	
	ALBEDO = tex_col * tint_color.rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	
	if (emissive_intensity > 0.0) {
		EMISSION = emissive_color * emissive_intensity;
	}
}
