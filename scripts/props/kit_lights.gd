extends RefCounted
## Light presets for Outpost 73 kit props (build-time only; KitProp animates what `make` returns).
## marker_light_<kind>[_n] -> OmniLight3D from LIGHTS; marker_spot[_n] -> shadowed SpotLight3D aimed out of the prop's front.

enum Anim { STEADY, PULSE, FLICKER }

## kind -> [colour, energy, range, Anim, casts shadow (optional)]. lamp..fridge: the apartment kit's warm practicals;
## vault*: the records vault's hanging lamps (tunnel_vault), still burning; indicator: tunnel_station's platform indicator.
const LIGHTS := {
	"screen": [Color(1.0, 0.62, 0.22), 0.45, 2.2, Anim.STEADY],
	"green": [Color(0.45, 1.0, 0.55), 0.4, 2.2, Anim.STEADY],
	"amber": [Color(1.0, 0.52, 0.10), 0.9, 3.0, Anim.PULSE],
	"lamp": [Color(1.0, 0.7, 0.42), 1.5, 5.5, Anim.STEADY, true],
	"bulb": [Color(1.0, 0.78, 0.55), 1.6, 6.0, Anim.STEADY, true],
	"vanity": [Color(1.0, 0.86, 0.7), 1.1, 3.5, Anim.STEADY, true],
	"strip": [Color(1.0, 0.8, 0.58), 0.55, 1.6, Anim.STEADY],
	"fridge": [Color(0.85, 0.92, 1.0), 0.3, 1.4, Anim.STEADY],
	"vault": [Color(1.0, 0.6, 0.3), 1.4, 9.5, Anim.STEADY],
	"vaultshadow": [Color(1.0, 0.6, 0.3), 1.6, 11.0, Anim.STEADY, true],
	"vaultfail": [Color(1.0, 0.6, 0.3), 1.1, 8.5, Anim.FLICKER],
	"indicator": [Color(1.0, 0.45, 0.1), 0.6, 6.0, Anim.STEADY],
}
const BULB_SIZE := 0.05                     # metres; shadowed omni practicals only
const SPOT_COLOR := Color(1.0, 0.74, 0.4)
const SPOT_ENERGY := 9.0
const SPOT_RANGE := 16.0
const SPOT_ANGLE := 38.0
const SPOT_AIM := Vector3(-18.0, 180.0, 0.0)  # degrees: out of the prop's front (+Z), tilted down like the lamp head


static func is_marker(node_name: String) -> bool:
	return node_name.begins_with("marker_light_") or node_name.begins_with("marker_spot")


const FADE_BEGIN := 55.0                    # kit lights fade out beyond this (props are scattered across the forest)
const FADE_LENGTH := 15.0


## Adds the light for `anchor` under it. Returns [light, Anim], or [] for an unknown marker.
static func make(anchor: Node3D) -> Array:
	if anchor == null:
		return []
	var marker_name := String(anchor.name)
	if marker_name.begins_with("marker_spot"):
		var spot := SpotLight3D.new()
		spot.light_color = SPOT_COLOR
		spot.light_energy = SPOT_ENERGY
		spot.spot_range = SPOT_RANGE
		spot.spot_angle = SPOT_ANGLE
		spot.shadow_enabled = true
		spot.rotation_degrees = SPOT_AIM
		fade(spot)
		anchor.add_child(spot)
		return [spot, Anim.FLICKER]
	var kind := marker_name.trim_prefix("marker_light_").get_slice("_", 0)
	if not LIGHTS.has(kind):
		push_warning("KitLights: unknown light kind '%s' (%s)" % [kind, marker_name])
		return []
	var spec: Array = LIGHTS[kind]
	var omni := OmniLight3D.new()
	omni.light_color = spec[0]
	omni.light_energy = spec[1]
	omni.omni_range = spec[2]
	omni.shadow_enabled = spec.size() > 4 and spec[4]
	omni.shadow_bias = 0.03                    # indoor practicals shadow small things (shelves, bottles): keep it tight
	if omni.shadow_enabled:
		omni.light_size = BULB_SIZE            # a real bulb has size: soft-edged shadows (PCSS), no hard stair steps
	fade(omni)
	anchor.add_child(omni)
	return [omni, spec[3]]


## Past FADE_BEGIN (beyond the forest fog wall) a light and, from half that, its shadow stop costing anything.
## Any runtime light in the open world should take this.
static func fade(light: Light3D) -> void:
	light.distance_fade_enabled = true
	light.distance_fade_begin = FADE_BEGIN
	light.distance_fade_length = FADE_LENGTH
	light.distance_fade_shadow = FADE_BEGIN * 0.5
