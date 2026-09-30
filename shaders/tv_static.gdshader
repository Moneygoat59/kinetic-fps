shader_type spatial;
// A screen with no signal: coarse per-cell snow re-rolled 30 times a second, scanlines, a brighter band rolling down,
// darker at the edges like an old panel. Unshaded (the screen is the light). Used by AptTvStatic.
render_mode unshaded, shadows_disabled, cull_back;

uniform vec2 cells = vec2(220.0, 124.0);
uniform float energy = 1.5;
uniform vec3 tint : source_color = vec3(0.8, 0.86, 1.0);
uniform float roll_speed = 0.18;

float hash(vec2 p) {
	p = fract(p * vec2(0.1031, 0.1030));
	p += dot(p, p.yx + 33.33);
	return fract((p.x + p.y) * p.x);
}

void fragment() {
	float frame = mod(floor(TIME * 30.0), 257.0);
	vec2 cell = floor(UV * cells);
	float snow = hash(cell + vec2(frame * 13.0, frame * 7.0));
	snow = snow * snow * 1.4;
	float scan = 0.8 + 0.2 * sin(UV.y * cells.y * 3.14159);
	float band = smoothstep(0.12, 0.0, abs(fract(UV.y + TIME * roll_speed) - 0.5));
	vec2 e = UV * (1.0 - UV);
	float edge = clamp(pow(e.x * e.y * 18.0, 0.35), 0.0, 1.0);
	ALBEDO = tint * snow * scan * (0.75 + 0.45 * band) * edge * energy;
}
