shader_type canvas_item;

uniform float scanline_count : hint_range(100.0, 500.0) = 240.0;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.18;
uniform float vignette_intensity : hint_range(0.0, 2.0) = 0.45;
uniform float aberration_amount : hint_range(0.0, 0.02) = 0.0018;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 uv = SCREEN_UV;

	// Slight barrel curvature
	vec2 crt_uv = uv * 2.0 - 1.0;
	vec2 offset = crt_uv.yx / vec2(60.0, 40.0);
	crt_uv += crt_uv * offset * offset;
	vec2 final_uv = crt_uv * 0.5 + 0.5;

	// Chromatic Aberration
	float r = texture(SCREEN_TEXTURE, final_uv + vec2(aberration_amount, 0.0)).r;
	float g = texture(SCREEN_TEXTURE, final_uv).g;
	float b = texture(SCREEN_TEXTURE, final_uv - vec2(aberration_amount, 0.0)).b;
	vec3 col = vec3(r, g, b);

	// Scanlines
	float scanline = sin(final_uv.y * scanline_count * 3.14159);
	col -= scanline * scanline_intensity * 0.5;

	// Vignette (dark edges)
	float vig = uv.x * (1.0 - uv.x) * uv.y * (1.0 - uv.y) * 16.0;
	vig = clamp(pow(vig, vignette_intensity * 0.5), 0.0, 1.0);
	col *= vig;

	COLOR = vec4(col, 1.0);
}
