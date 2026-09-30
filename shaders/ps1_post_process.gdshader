shader_type canvas_item;

uniform float pixel_size : hint_range(1.0, 8.0) = 1.0;
uniform float color_depth : hint_range(8.0, 128.0) = 64.0;
uniform float dither_amount : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

// 4x4 Bayer matrix
float get_bayer(vec2 uv, vec2 screen_size) {
	vec2 p = floor(mod(uv * screen_size / max(pixel_size, 1.0), 4.0));
	int x = int(p.x);
	int y = int(p.y);
	int index = y * 4 + x;
	float bayer[16] = float[16](
		0.0 / 16.0,  8.0 / 16.0,  2.0 / 16.0, 10.0 / 16.0,
		12.0 / 16.0, 4.0 / 16.0, 14.0 / 16.0,  6.0 / 16.0,
		3.0 / 16.0, 11.0 / 16.0,  1.0 / 16.0,  9.0 / 16.0,
		15.0 / 16.0, 7.0 / 16.0, 13.0 / 16.0,  5.0 / 16.0
	);
	return bayer[index] - 0.5;
}

void fragment() {
	vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 coord = floor(SCREEN_UV * screen_size / max(pixel_size, 1.0)) * max(pixel_size, 1.0) / screen_size;
	
	vec3 col = texture(screen_texture, coord).rgb;
	
	// Bayer dither
	float d = get_bayer(SCREEN_UV, screen_size) * dither_amount;
	col += d;
	
	// PS1 color quantization
	col = floor(col * color_depth + 0.5) / color_depth;
	
	// Gritty retro contrast curve
	col = pow(col, vec3(1.10));
	col *= vec3(0.96, 0.98, 0.94);
	
	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
