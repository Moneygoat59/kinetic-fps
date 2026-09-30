shader_type spatial;
render_mode cull_disabled, specular_disabled;

#include "res://shaders/abyss_fog.gdshaderinc"

void fragment() {
	vec4 base = abyss_base(UV, COLOR);
	float deep = abyss_deep();
	ALBEDO = base.rgb;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	AO = mix(1.0, ambient_floor, deep);
	AO_LIGHT_AFFECT = 0.0;
	EMISSION = abyss_emission(UV);
	FOG = abyss_fog(CAMERA_POSITION_WORLD, deep);
}
