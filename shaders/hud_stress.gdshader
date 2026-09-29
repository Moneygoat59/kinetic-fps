// Field HUD stress overlay (FieldHud): the edges close in, colour drains toward grey (in a world where
// colour only comes from light, stress takes the light away), and a faint lens split creeps in at the high end.
// No red flashes (art bible). Full-screen ColorRect on the HUD layer, drawn before the HUD's own elements.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float stress : hint_range(0.0, 1.0) = 0.0;
uniform float hurt : hint_range(0.0, 1.0) = 0.0;   // 1 when hit, decays
uniform float aspect = 1.7778;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 c = uv - 0.5;
	float split = stress * stress * 0.0035 + hurt * 0.006;
	vec3 col = vec3(texture(screen_tex, uv + c * split).r, texture(screen_tex, uv).g, texture(screen_tex, uv - c * split).b);
	float grey = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(grey), clamp(stress * 0.7 + hurt * 0.35, 0.0, 0.88));
	float r = length(c * vec2(aspect, 1.0)) / aspect * 1.6;
	float inner = 0.62 - 0.22 * stress - 0.1 * hurt;
	float vig = smoothstep(inner, inner + 0.55, r);
	col *= 1.0 - vig * clamp(0.2 + 0.74 * stress + 0.45 * hurt, 0.0, 0.95);
	COLOR = vec4(col, 1.0);
}
