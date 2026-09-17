shader_type spatial;
render_mode diffuse_lambert_wrap, cull_back;

uniform sampler2D albedo_texture : source_color, filter_nearest;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform vec3 uv_scale = vec3(0.4, 0.4, 0.4);

void fragment() {
	vec3 flat_norm = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	NORMAL = flat_norm;

	vec3 abs_n = abs(flat_norm);
	abs_n /= (abs_n.x + abs_n.y + abs_n.z);

	vec3 world_p = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz * uv_scale;
	vec4 col_x = texture(albedo_texture, world_p.yz);
	vec4 col_y = texture(albedo_texture, world_p.xz);
	vec4 col_z = texture(albedo_texture, world_p.xy);
	vec4 tex = col_x * abs_n.x + col_y * abs_n.y + col_z * abs_n.z;

	ALBEDO = tex.rgb * albedo_color.rgb;
	ROUGHNESS = 0.95;
	SPECULAR = 0.0;
}
