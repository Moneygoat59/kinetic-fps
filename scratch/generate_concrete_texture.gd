extends SceneTree

func _init() -> void:
	print("Generating distressed dark concrete textures...")
	var sz = 512
	var img = Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var norm_img = Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var panel_img = Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	
	var n_base = FastNoiseLite.new()
	n_base.seed = 808
	n_base.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n_base.frequency = 0.015
	n_base.fractal_octaves = 4
	
	var n_grit = FastNoiseLite.new()
	n_grit.seed = 999
	n_grit.noise_type = FastNoiseLite.TYPE_PERLIN
	n_grit.frequency = 0.12
	n_grit.fractal_octaves = 3
	
	var n_pores = FastNoiseLite.new()
	n_pores.seed = 444
	n_pores.noise_type = FastNoiseLite.TYPE_CELLULAR
	n_pores.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	n_pores.cellular_return_type = FastNoiseLite.RETURN_DISTANCE
	n_pores.frequency = 0.08
	
	# Heightmap buffer for normal calculation
	var hmap: Array[float] = []
	hmap.resize(sz * sz)
	
	# Concrete base colors: dark distressed brutalist concrete
	var c_dark = Color(0.13, 0.14, 0.15)
	var c_mid = Color(0.22, 0.23, 0.24)
	var c_light = Color(0.32, 0.33, 0.35)
	var c_wear = Color(0.40, 0.42, 0.44) # lighter worn edge chalk/aggregate
	
	for y in range(sz):
		for x in range(sz):
			var b = (n_base.get_noise_2d(x, y) + 1.0) * 0.5
			var g = (n_grit.get_noise_2d(x, y) + 1.0) * 0.5
			var p = n_pores.get_noise_2d(x, y)
			
			var h = clampf(b * 0.6 + g * 0.35 - (0.15 if p < -0.4 else 0.0), 0.0, 1.0)
			hmap[y * sz + x] = h
			
			# Color blending
			var col = c_dark.lerp(c_mid, b)
			col = col.lerp(c_light, g * 0.5)
			if p < -0.38: # pitted pore
				col = col.lerp(Color(0.08, 0.08, 0.09), 0.6)
			elif g > 0.72: # micro aggregate spec
				col = col.lerp(c_wear, 0.35)
			
			img.set_pixel(x, y, col)
			
			# Panel texture with edge wear and corner distress
			# Distance to nearest border [0..1]
			var border_dist_x = minf(x, sz - 1 - x) / float(sz * 0.5)
			var border_dist_y = minf(y, sz - 1 - y) / float(sz * 0.5)
			var min_border = minf(border_dist_x, border_dist_y) * (sz * 0.5)
			
			var p_col = col
			if min_border < 4.0: # deep groove seam
				p_col = Color(0.06, 0.06, 0.07)
			elif min_border < 14.0: # beveled edge with chipped wear
				var edge_noise = (n_grit.get_noise_2d(x * 2.0, y * 2.0) + 1.0) * 0.5
				var wear_t = (1.0 - (min_border - 4.0) / 10.0) * (0.6 + edge_noise * 0.4)
				p_col = p_col.lerp(c_wear, wear_t * 0.75)
			# Corner distress (near corners min_border is in both x and y)
			var corner_dist = sqrt(pow(minf(x, sz - 1 - x), 2) + pow(minf(y, sz - 1 - y), 2))
			if corner_dist < 28.0 and corner_dist >= 4.0:
				var c_noise = (n_grit.get_noise_2d(x * 3.0, y * 3.0) + 1.0) * 0.5
				if c_noise > 0.45:
					p_col = p_col.lerp(c_wear, 0.4)
			
			# Tie-rod bolt holes near 4 corners
			for bx in [sz * 0.12, sz * 0.88]:
				for by in [sz * 0.12, sz * 0.88]:
					var bd = sqrt(pow(x - bx, 2) + pow(y - by, 2))
					if bd < 6.0:
						p_col = Color(0.05, 0.05, 0.06)
					elif bd < 9.0:
						p_col = p_col.lerp(c_wear, 0.5)
			
			panel_img.set_pixel(x, y, p_col)
	
	# Generate Sobel normal map
	for y in range(sz):
		for x in range(sz):
			var x_prev = (x - 1 + sz) % sz
			var x_next = (x + 1) % sz
			var y_prev = (y - 1 + sz) % sz
			var y_next = (y + 1) % sz
			
			var dx = (hmap[y * sz + x_next] - hmap[y * sz + x_prev]) * 2.5
			var dy = (hmap[y_next * sz + x] - hmap[y_prev * sz + x]) * 2.5
			var n = Vector3(-dx, -dy, 1.0).normalized()
			
			norm_img.set_pixel(x, y, Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5, 1.0))
	
	img.save_png("textures/distressed_dark_concrete.png")
	norm_img.save_png("textures/distressed_dark_concrete_normal.png")
	panel_img.save_png("textures/distressed_concrete_panel.png")
	print("Textures successfully saved to textures/")
	quit()
