shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, specular_disabled, shadows_disabled;

#include "res://shaders/abyss_fog.gdshaderinc"

void fragment() {
	vec4 base = abyss_base(UV, COLOR);
	float deep = abyss_deep();
	ALBEDO = base.rgb;
	ALPHA = base.a;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	AO = mix(1.0, ambient_floor, deep);
	AO_LIGHT_AFFECT = 0.0;
	EMISSION = abyss_emission(UV);
	FOG = abyss_fog(CAMERA_POSITION_WORLD, deep);
}
