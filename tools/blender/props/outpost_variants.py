"""Outpost bunker variants. Every amber well on the relay network is the same Outpost 73 build (outpost73_bunker.py: shell,
blast door, kit furniture, pump yard, art rules); a variant only changes what 200 years did to it and where things stand.
Build one with  tools\\blender.ps1 tools/blender/props/outpost73_bunker.py 02   (no argument = 73).

  73  the first well. Front-right cornice broke off, lower ladder rotted away, dish sagged on its mount. Still pumping.
  02  NO CARRIER: a dead tree came down over the rear-left corner, crushed it and swept the comm dish off the roof (it lies
      by the front-right corner). Interior mirrored (well riser rear-right, desk + map on the left). Ladder intact, on the left.
  03  SEIZED: the pump jack stalled mid-shift and the well overflowed. Amber crystal has grown through the yard, the pump
      skid and the floor; two storage tanks on the right side took the overflow and weep. Front-left cornice broke off.

Keys (read by outpost73_bunker.py and o73_exterior.py):
  out        output .glb name              tag      texture suffix ("" for 73: decal_stencil.png, "_02": decal_stencil_02.png)
  mirror     interior mirrored in X        brk      (sx, sy) mirror of 73's front-right roof break
  ladder     wall side of the ladder (+1 right, -1 left; the hatch goes on the other wall)
  lad_fall   lower ladder section rotted off and lying on the ground
  dish       "roof" (sagged on its mount) or "fallen" (torn off, lying on the ground)
  beacon     (x, y) of the roof beacon       branch   side of the dead branch on the roof (0 = none)
  log        log leaning on the rear-left corner          extras   extra builders in outpost_extras.py
  pickup     "dosimeter" (field-kit rack) or "route_key" (key case on the desk, see ROUTE_KEY)
"""

VARIANTS = {
    "73": dict(out="outpost73_bunker.glb", tag="", mirror=False, brk=(1, 1), ladder=1, lad_fall=True, dish="roof",
               beacon=(-2.7, 2.6), branch=-1, log=True, extras=(), pickup="dosimeter"),
    "02": dict(out="outpost02_bunker.glb", tag="_02", mirror=True, brk=(-1, -1), ladder=-1, lad_fall=False, dish="fallen",
               beacon=(2.7, 2.6), branch=0, log=False, extras=("tree", "fallen_dish"), pickup="route_key"),
    "03": dict(out="outpost03_bunker.glb", tag="_03", mirror=False, brk=(-1, 1), ladder=-1, lad_fall=True, dish="roof",
               beacon=(-2.7, 2.6), branch=1, log=True, extras=("tanks", "overgrowth", "flood"), pickup="route_key"),
}

# route key case on the desk, beside the relay CRT: (x, y, yaw) in 73's (unmirrored) layout, standing on the tabletop
ROUTE_KEY = (1.66, -1.5, -90)


def pick(argv):
    """Variant from the command line (any argument that names one; contact_check passes the generator path first)."""
    key = next((a for a in argv if a in VARIANTS), "73")
    return key, VARIANTS[key]


def kit(v, rows, cx):
    """The variant's furniture: the field-kit rack (73 only) becomes a crate stack by the grille; mirrored for 02.
    rows are 73's KIT rows (prop, x, y, z, yaw, proxy)."""
    if v["pickup"] == "dosimeter":
        return rows
    out = [r for r in rows if r[0] != "dosimeter_rack"]
    out += [("crate_large", -cx + 0.35, 0.02, 0.0, 90, ((0.9, 0.65, 0.6), (0, 0, 0.3))),
            ("crate_small", -cx + 0.36, 0.08, 0.6, 75, None)]
    if "flood" in v["extras"]:                                       # 03: the surge shoved the chair to the back of the room
        out = [r if r[0] != "chair_steel" else ("chair_steel", -0.05, 0.9, 0.0, 160, None) for r in out]
    return [mirror_row(r) for r in out] if v["mirror"] else out


def mirror_row(r):
    """Mirror a KIT row in X: position, yaw and the AO proxy's local x offset (the props themselves are not mirrored)."""
    prop, x, y, z, yaw, proxy = r
    if proxy:
        size, (lx, ly, lz) = proxy
        proxy = (size, (-lx, ly, lz))
    return (prop, -x, y, z, -yaw, proxy)
