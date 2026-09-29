class_name JournalPen
extends RefCounted
## The journal_open kit piece's pen (node `pen`, origin at the nib) and where it goes to write: at(chars) is its local pose
## with the nib `chars` characters into the newest line of `page` (fractional = between letters), following the line's
## slant and the page's curve out of the gutter. Page geometry mirrors tools/blender/apt/writing.py (PW, PH, page_z).

const PAGE_W := 0.12
const PAGE_H := 0.17
const PAGE_BASE := 0.0105
const LIFT_OFF := 0.001               # nib just above the paper
const WRITE_TILT := Vector3(-48.0, 32.0, 0.0)   # degrees: held up and to the right of the nib
const WOBBLE := 3.0                   # px of up-and-down as the letters loop

var node: Node3D
var rest: Transform3D
var page: JournalPage
var _adv := PackedFloat32Array()
var _basis: Basis


func _init(pen: Node3D, journal_page: JournalPage) -> void:
	node = pen
	page = journal_page
	rest = pen.transform if pen else Transform3D.IDENTITY
	_basis = Basis.from_euler(WRITE_TILT * (PI / 180.0))


## Call when a new line starts (measures its letters once).
func start_line(text: String) -> void:
	_adv = page.advances(text)


func at(chars: float) -> Transform3D:
	if _adv.is_empty() or page.lines.is_empty():
		return rest
	var i := page.lines.size() - 1
	var k := clampi(int(chars), 0, _adv.size() - 1)
	var x := lerpf(_adv[k], _adv[mini(k + 1, _adv.size() - 1)], chars - float(k))
	var px := page.line_origin(i) + Vector2(x, 0.0).rotated(page.jitter(i).z) + Vector2(0.0, sin(chars * 9.0) * WOBBLE)
	var uv := page.uv_of(px)
	var lx := (uv.x - 0.5) * 2.0 * PAGE_W
	return Transform3D(_basis, Vector3(lx, surface(absf(lx) / PAGE_W) + LIFT_OFF, (uv.y - 0.5) * PAGE_H))


## Page surface height at t = 0 (gutter) .. 1 (outer edge).
static func surface(t: float) -> float:
	return PAGE_BASE - 0.003 + 0.006 * (1.0 - pow(1.0 - t, 2.5)) - 0.001 * t
