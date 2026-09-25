shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float pulse : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 center = vec2(0.5, 0.5);
	vec2 dir = uv - center;
	float dist = length(dir);

	// Wave disorientation wobble
	float wobble = sin(TIME * 4.5 + dist * 10.0) * intensity * (0.006 + pulse * 0.005);
	vec2 warped_uv = uv + normalize(dir + vec2(0.0001)) * wobble;

	// Chromatic aberration expanding radially
	float split = (intensity * 0.014 + pulse * 0.010) * dist;
	float r = texture(SCREEN_TEXTURE, warped_uv + dir * split).r;
	float g = texture(SCREEN_TEXTURE, warped_uv).g;
	float b = texture(SCREEN_TEXTURE, warped_uv - dir * split).b;
	vec3 col = vec3(r, g, b);

	// Amber / toxic chemical color surge
	vec3 amber_tint = vec3(1.22, 0.78, 0.16);
	col = mix(col, col * amber_tint, intensity * 0.50);

	// Tunnel vision / pulsing dark vignette
	float vig = uv.x * (1.0 - uv.x) * uv.y * (1.0 - uv.y) * 16.0;
	float vig_power = (intensity * 0.85 + pulse * 0.40);
	vig = clamp(pow(vig, vig_power * 0.5), 0.0, 1.0);
	col = mix(texture(SCREEN_TEXTURE, uv).rgb, col * vig, intensity);

	COLOR = vec4(col, 1.0);
}
