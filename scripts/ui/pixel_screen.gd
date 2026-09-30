class_name PixelScreen
extends SubViewport
## Low-res 2D display rendered into a texture and shown on a model's screen surface (kit_scr_* quads): real pixels with
## scanlines instead of floating 3D text. Reusable by any device or terminal that needs a live readout:
##   var scr := PixelScreen.make(Vector2i(160, 80)); owner.add_child(scr); scr.attach(mesh, "kit_scr_dosi")
##   var line := scr.label(Vector2(4, 2), 16, Color.ORANGE)   # then set line.text as values change

const SCANLINE_ALPHA := 0.35

var canvas: Control


static func make(px_size: Vector2i, bg: Color = Color(0.016, 0.012, 0.004)) -> PixelScreen:
	var scr := PixelScreen.new()
	scr.size = px_size
	scr.disable_3d = true
	scr.transparent_bg = false
	scr.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	scr.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	var back := ColorRect.new()
	back.color = bg
	back.size = Vector2(px_size)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scr.add_child(back)
	scr.canvas = Control.new()
	scr.canvas.size = Vector2(px_size)
	scr.canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scr.add_child(scr.canvas)
	scr.add_child(_scanlines(px_size))
	return scr


static func _scanlines(px_size: Vector2i) -> TextureRect:
	var img := Image.create(1, 2, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color(0, 0, 0, 0))
	img.set_pixel(0, 1, Color(0, 0, 0, SCANLINE_ALPHA))
	var lines := TextureRect.new()
	lines.texture = ImageTexture.create_from_image(img)
	lines.stretch_mode = TextureRect.STRETCH_TILE
	lines.size = Vector2(px_size)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE    # an interactive screen (TerminalDesktop) is clicked through it
	return lines


## Shows this screen on the surface of `mesh` whose material is `material_name` (a per-instance copy). False if absent.
func attach(mesh: MeshInstance3D, material_name: String, energy: float = 1.3) -> bool:
	if mesh == null or mesh.mesh == null:
		return false
	for i in mesh.mesh.get_surface_count():
		var mat := mesh.mesh.surface_get_material(i) as BaseMaterial3D
		if mat == null or mat.resource_name != material_name:
			continue
		var own := mat.duplicate() as BaseMaterial3D
		own.emission_enabled = true
		own.emission_texture = get_texture()
		own.emission = Color.WHITE
		own.emission_energy_multiplier = energy
		own.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mesh.set_surface_override_material(i, own)
		return true
	return false


## A text line on the display (VT323 terminal font by default).
func label(pos: Vector2, font_size: int, color: Color, font: Font = null) -> Label:
	var line := Label.new()
	line.position = pos
	line.add_theme_font_override("font", font if font else FontLibrary.terminal_font())
	line.add_theme_font_size_override("font_size", font_size)
	line.add_theme_color_override("font_color", color)
	canvas.add_child(line)
	return line


## A solid block (bar-graph segment, divider) on the display.
func block(rect: Rect2, color: Color) -> ColorRect:
	var box := ColorRect.new()
	box.position = rect.position
	box.size = rect.size
	box.color = color
	canvas.add_child(box)
	return box
