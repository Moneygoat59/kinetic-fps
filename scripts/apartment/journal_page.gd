class_name JournalPage
extends Control
## The open spread of a journal, drawn for a SubViewport (AptJournal puts the viewport's texture on the kit piece's pages):
## ruled cream paper, a shadow down the gutter, and the handwritten lines. Lines fill the left page then the right; a full
## spread is turned (`spread` counts turns) and the next begins blank. Redraws only when told (queue_redraw on a change).
## Layout is in pixels of SIZE; uv_of() maps a point to the spread's UV (u 0..0.5 left page, 0.5..1 right; v 0 at the top).

const SIZE := Vector2i(1024, 726)
const FONT_FILE := "Caveat-Regular.ttf"
const FONT_SIZE := 50
const PAPER := Color(0.93, 0.9, 0.81)
const RULE := Color(0.55, 0.62, 0.72, 0.35)
const MARGIN_RULE := Color(0.75, 0.35, 0.35, 0.3)
const INK := Color(0.09, 0.11, 0.24)
const TOP := 104.0                   # first baseline
const PITCH := 58.0                  # ruled line spacing
const PER_PAGE := 10
const INSET := 62.0                  # text start (px from the page's left edge, just past the margin rule)
const GUTTER_SHADE := 70.0           # px of shadow either side of the fold

var lines := PackedStringArray()     # everything written, oldest first
var shown := -1                      # characters of the newest line shown (-1: all of it)
var font: Font


## A page drawn into its own SubViewport under `host` (renders only when refresh() asks). The viewport's texture is the page.
static func in_viewport(host: Node) -> JournalPage:
	var view := SubViewport.new()
	view.size = SIZE
	view.disable_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
	var p := JournalPage.new()
	view.add_child(p)
	host.add_child(view)
	return p


func texture() -> Texture2D:
	var view := get_parent() as SubViewport
	return view.get_texture() if view else null


## Redraw and re-render the viewport once (call after changing lines / shown).
func refresh() -> void:
	queue_redraw()
	var view := get_parent() as SubViewport
	if view:
		view.render_target_update_mode = SubViewport.UPDATE_ONCE


func _ready() -> void:
	size = Vector2(SIZE)
	font = FontLibrary.get_font(FONT_FILE)
	if font == null:
		font = ThemeDB.fallback_font


## Where line `i` (0-based, over the whole journal) starts: its baseline on this spread, or (-1, -1) on an earlier spread.
func line_origin(i: int) -> Vector2:
	var slot := i % (PER_PAGE * 2)
	if i / (PER_PAGE * 2) != spread():
		return Vector2(-1.0, -1.0)
	var page := slot / PER_PAGE
	var row := slot % PER_PAGE
	var j := jitter(i)
	return Vector2(page * SIZE.x * 0.5 + INSET + j.x, TOP + row * PITCH + j.y)


func spread() -> int:
	return maxi(lines.size() - 1, 0) / (PER_PAGE * 2)


func uv_of(p: Vector2) -> Vector2:
	return Vector2(p.x / SIZE.x, p.y / SIZE.y)


## Pixel advance of each prefix of `text` (entry k = width of the first k characters), for a pen that follows the ink.
func advances(text: String) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(text.length() + 1)
	for k in text.length() + 1:
		out[k] = font.get_string_size(text.left(k), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	return out


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(SIZE)), PAPER)
	var half := SIZE.x * 0.5
	for row in PER_PAGE + 1:
		var y := TOP + row * PITCH + 6.0
		draw_line(Vector2(24.0, y), Vector2(SIZE.x - 24.0, y), RULE, 1.5)
	for x in [INSET - 14.0, half + INSET - 14.0]:
		draw_line(Vector2(x, 30.0), Vector2(x, SIZE.y - 30.0), MARGIN_RULE, 1.5)
	for k in 8:                                                      # the fold: darker toward the gutter
		var w := GUTTER_SHADE * (1.0 - k / 8.0)
		draw_rect(Rect2(half - w, 0.0, w * 2.0, SIZE.y), Color(0.25, 0.2, 0.12, 0.035))
	var first := spread() * PER_PAGE * 2
	for i in range(first, lines.size()):
		var text := lines[i]
		if i == lines.size() - 1 and shown >= 0:
			text = text.left(shown)
		if text.is_empty():
			continue
		var o := line_origin(i)
		draw_set_transform(o, jitter(i).z)
		draw_string(font, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, INK)
	draw_set_transform(Vector2.ZERO)


## Per-line hand wobble, the same every time the line is drawn: x, y offset (px) and a slight slant (radians).
func jitter(i: int) -> Vector3:
	var h := hash(i * 7919 + 13)
	return Vector3(float(h % 13) - 6.0, float((h / 13) % 5) - 2.0, deg_to_rad(float((h / 65) % 17) / 10.0 - 0.8))
