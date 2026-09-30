extends RefCounted
## Sample builders for WraithSfx (which caches them as AudioStreamWAV). Mono, RATE Hz, any scale (normalised on the way out).

const RATE := 22050


static func drone() -> PackedFloat32Array:
	var n := RATE * 6                                    # every partial completes whole cycles in 6 s: the loop is seamless
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / RATE
		var swell := 0.75 + 0.25 * sin(TAU * t / 3.0)
		var v := 0.36 * sin(TAU * 41.0 * t) + 0.3 * sin(TAU * 43.5 * t) + 0.16 * sin(TAU * 82.5 * t + 0.4 * sin(TAU * t / 6.0))
		v += 0.035 * sin(TAU * 660.0 * t) + 0.03 * sin(TAU * 698.5 * t)
		s[i] = v * swell
	return s


static func heartbeat() -> PackedFloat32Array:
	var n := int(RATE * 0.9)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		for beat in [[0.0, 1.0], [0.26, 0.7]]:
			var dt: float = t - beat[0]
			if dt >= 0.0:
				v += beat[1] * (sin(TAU * 46.0 * dt) * exp(-dt * 16.0) + 0.35 * sin(TAU * 92.0 * dt) * exp(-dt * 34.0))
		s[i] = v
	return s


static func sting() -> PackedFloat32Array:
	var n := int(RATE * 2.8)
	var s := PackedFloat32Array()
	s.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 72
	for i in n:
		var t := float(i) / RATE
		var bend := 1.0 - 0.035 * t
		var env := minf(t / 0.03, 1.0) * exp(-t * 1.2)
		var v := 0.0
		for f in [196.0, 207.65, 233.08, 277.18, 415.3]:
			var ph: float = TAU * f * bend * t
			v += sin(ph) + 0.3 * sin(2.0 * ph) + 0.15 * sin(3.0 * ph)
		v = v * 0.14 * env
		v += sin(TAU * 36.0 * t) * exp(-t * 2.5) * 0.9                       # boom
		v += rng.randf_range(-1.0, 1.0) * exp(-t * 14.0) * 0.6                 # hit
		s[i] = v
	return s


static func vanish() -> PackedFloat32Array:
	var n := int(RATE * 1.1)
	var s := PackedFloat32Array()
	s.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 73
	var low := 0.0
	var band := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := t / 1.1
		var f := 2.0 * sin(PI * (300.0 + 2600.0 * k * k) / RATE)
		var high := rng.randf_range(-1.0, 1.0) - low - 0.5 * band
		band += f * high
		low += f * band
		s[i] = (band + 0.4 * low) * k * k * k * (1.0 - smoothstep(0.97, 1.0, k))
	return s
