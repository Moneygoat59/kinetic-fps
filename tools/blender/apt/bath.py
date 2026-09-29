"""Apartment kit: bathroom. Floor pieces: origin on the floor, back on y = 0, front -Y. Hanging pieces: origin = centre of the back
face (marker z = hang height).
toilet            lid down
vanity            0.8 sink cabinet at apt_dims.VANITY_H: oval basin sunk into the top, one soap bar, one toothbrush, child lock
medicine_cabinet  hanging: mirror door on pivot_leaf (shut; [E] opens it); three shelves of amber pharmacy bottles in rows by size, every label forward
vanity_light      hanging: three globes (marker_light_vanity)
bathtub           1.6 alcove tub, shower curtain drawn back to one end, perfectly pleated
towel_rack        hanging: two towels folded to the same length
bath_mat          0.8 x 0.5
"""
import apt_dims as D
import apt_forms as F
import ps1_lib as L
from apt_lib import AptKit


def toilet():
    k = AptKit("toilet")
    k.SOFT("tank", (0.48, 0.19, 0.36), (0, -0.115, 0.6), k.PORC, 0.03, step=0.07)
    k.SOFT("tank_lid", (0.5, 0.21, 0.035), (0, -0.115, 0.797), k.PORC, 0.012, step=0.07)
    k.B("lever", (0.06, 0.03, 0.015), (-0.17, -0.22, 0.72), k.CHROME, 0.004)
    for name, r1, r2, h, z in (("pedestal", 0.15, 0.12, 0.3, 0.15), ("bowl", 0.15, 0.2, 0.13, 0.335)):
        k.FRUSTUM(name, r1, r2, h, (0, -0.44, z), k.PORC, axis="z", v=28).scale = (1.0, 1.25, 1.0)
    k.SOFT("neck", (0.28, 0.24, 0.28), (0, -0.25, 0.3), k.PORC, 0.07, step=0.06)
    for name, r, t, z, mat in (("seat", 0.205, 0.028, 0.414, k.PORC), ("lid", 0.198, 0.022, 0.44, k.PLASTIC)):
        k.CYL(name, r, t, (0, -0.46, z), mat, v=32).scale = (1.0, 1.25, 1.0)
    k.TUBE("hinge", (-0.1, -0.24, 0.43), (0.1, -0.24, 0.43), 0.012, k.CHROME)
    k.COL((0.5, 0.72, 0.8), (0, -0.36, 0.4))
    k.finish(wall=True, subdiv=0.2, ao_dist=0.3)


def vanity():
    k = AptKit("vanity")
    w, d, h = 0.8, 0.5, D.VANITY_H
    k.B("plinth", (w - 0.04, d - 0.06, 0.08), (0, -d / 2 + 0.03, 0.04), k.BLACK)
    zc = h - 0.2                                                                          # solid carcass below the bowl,
    k.B("cabinet", (w, d - 0.02, zc - 0.08), (0, -(d - 0.02) / 2, 0.08 + (zc - 0.08) / 2), k.WHITE)   # open box round it
    for sx in (-1, 1):
        k.B(f"side{sx}", (0.02, d - 0.02, 0.16), (sx * (w / 2 - 0.01), -(d - 0.02) / 2, zc + 0.08), k.WHITE)
    for name, y in (("back", -0.01), ("rail", -(d - 0.02) + 0.01)):
        k.B(name, (w - 0.04, 0.02, 0.16), (0, y, zc + 0.08), k.WHITE)
    by, ra, rb = -0.25, 0.2, 0.16                                                        # oval basin under a cut-out
    k.parts.append(F.holed_slab("top", (-w / 2 - 0.01, -d - 0.01, w / 2 + 0.01, 0.0), h - 0.04, h, (0, by, ra, rb), k.PORC))
    bowl = [(0, h - 0.18), (0.11, h - 0.175), (0.165, h - 0.1), (0.172, h - 0.03), (0.172, h - 0.004), (0.16, h - 0.004),
            (0.158, h - 0.03), (0.148, h - 0.09), (0.11, h - 0.14), (0.045, h - 0.158), (0, h - 0.16)]
    k.parts.append(F.lathe("basin", bowl, k.PORC, (0, by, 0), segs=40))
    k.parts[-1].scale = (ra / rb, 1.0, 1.0)
    k.CYL("drain", 0.019, 0.004, (0, by, h - 0.158), k.CHROME, v=16)
    k.CYL("drain_hole", 0.012, 0.004, (0, by, h - 0.156), k.BLACK, v=16)
    k.B("overflow", (0.03, 0.004, 0.012), (0, by - rb + 0.012, h - 0.035), k.BLACK, 0.002, rot=(-15, 0, 0))
    k.CYL("tap_base", 0.026, 0.02, (0, -0.05, h + 0.01), k.CHROME, v=16)
    k.PIPE("tap", [(0, -0.05, h + 0.02), (0, -0.05, h + 0.15), (0, -0.09, h + 0.17), (0, -0.15, h + 0.15)], 0.011, k.CHROME,
           verts=10)
    k.B("tap_lever", (0.012, 0.06, 0.012), (0, -0.03, h + 0.13), k.CHROME, 0.004, rot=(-20, 0, 0))
    k.B("soap_dish", (0.1, 0.07, 0.012), (0.3, -0.08, h + 0.006), k.CHROME, 0.003)
    k.B("soap", (0.08, 0.05, 0.025), (0.3, -0.08, h + 0.024), k.LINEN, 0.008)
    k.CYL("cup", 0.03, 0.1, (-0.3, -0.08, h + 0.05), k.GLASS, v=10)
    k.TUBE("brush", (-0.3, -0.08, h + 0.02), (-0.295, -0.08, h + 0.19), 0.006, k.SOFA)
    for s in (-1, 1):
        k.B(f"door{s}", (w / 2 - 0.01, 0.02, h - 0.16), (s * w / 4, -d + 0.01, 0.08 + (h - 0.12) / 2), k.WHITE, 0.004)
        k.CYL(f"knob{s}", 0.011, 0.022, (s * 0.05, -d - 0.01, h - 0.14), k.CHROME, "y", 8)
    k.B("child_lock", (0.14, 0.01, 0.02), (0, -d - 0.02, h - 0.14), k.CAP)                  # strap across both knobs
    k.COL((w, d, h), (0, -d / 2, h / 2))
    k.finish(wall=True, subdiv=0.25, ao_dist=0.35)


def _rx_bottle(k, name, x, base, r, h, rx):
    k.CYL(f"bot{name}", r, h, (x, -0.075, base + h / 2), k.PILL, v=16)
    k.CYL(f"cap{name}", r * 1.08, 0.018, (x, -0.075, base + h + 0.009), k.CAP, v=16)
    k.WRAP_UV(f"lbl{name}", (x, -0.075), r + 0.0012, base + h * 0.2, base + h * 0.85, 205, 335, k.RX, D.row_uv(rx, len(D.RX)), segs=6)


def medicine_cabinet():
    k = AptKit("medicine_cabinet")
    w, d, h = 0.6, 0.14, 0.75
    k.B("back", (w, 0.01, h), (0, -0.005, 0), k.WHITE)
    for s in (-1, 1):
        k.B(f"side{s}", (0.02, d, h), (s * (w / 2 - 0.01), -d / 2, 0), k.WHITE)
        k.B(f"cap{s}", (w, d, 0.025), (0, -d / 2, s * (h / 2 - 0.0125)), k.WHITE)
    for row, z in enumerate((-0.23, 0.02, 0.26)):                              # thick enough that the vanity light cannot leak
        k.B(f"shelf{row}", (w - 0.03, d - 0.01, 0.02), (0, -d / 2 + 0.005, z - 0.006), k.WHITE)
    # seven bottles, not a pharmacy: four of the daily one in a row, the bedtime pair, one more; labels forward
    for x in (-0.18, -0.06, 0.06, 0.18):
        _rx_bottle(k, f"top{x}", x, 0.264, 0.021, 0.08, 0)
    for x in (0.08, 0.17):
        _rx_bottle(k, f"mid{x}", x, 0.024, 0.024, 0.11, 1)
    _rx_bottle(k, "low", 0.16, -0.226, 0.03, 0.075, 2)
    k.SOFT("toothpaste", (0.19, 0.045, 0.045), (-0.13, -0.075, 0.049), k.CAP, 0.008, step=0.05)
    k.B("toothpaste_band", (0.05, 0.047, 0.047), (-0.19, -0.075, 0.049), k.SOFA)
    k.CYL("cotton_jar", 0.04, 0.1, (-0.18, -0.075, -0.176), k.GLASS, v=16)
    k.SOFT("cotton", (0.07, 0.07, 0.07), (-0.18, -0.075, -0.185), k.LINEN, 0.03, step=0.03)
    k.CYL("cotton_lid", 0.042, 0.015, (-0.18, -0.075, -0.12), k.CHROME, v=16)
    k.B("bandages", (0.11, 0.06, 0.075), (-0.03, -0.075, -0.188), k.PAPER, 0.004)
    k.B("bandages_band", (0.112, 0.062, 0.018), (-0.03, -0.075, -0.17), k.RUSTF)
    door = k.PIVOT("pivot_leaf", (-w / 2, -d - 0.02, 0))                                  # mirror door, shut; AptDoor opens it
    k.B("door", (w, 0.02, h), (0, -d - 0.01, 0), k.WHITE, 0.004, into=door)
    door.append(L.quad("mirror", (0, -d - 0.021, 0), w - 0.04, h - 0.04, "-y", k.MIRROR))
    k.B("pull", (0.012, 0.012, 0.06), (w / 2 - 0.03, -d - 0.027, 0), k.CHROME, into=door)
    k.finish(wall=True, subdiv=0.15, ao_dist=0.15, ground=False)


def vanity_light():
    k = AptKit("vanity_light")
    k.B("bar", (0.62, 0.05, 0.06), (0, -0.04, 0), k.CHROME, 0.01)
    k.B("plate", (0.16, 0.02, 0.1), (0, -0.01, 0), k.CHROME, 0.005)
    for x in (-0.22, 0.0, 0.22):
        k.CYL(f"globe{x}", 0.055, 0.09, (x, -0.1, -0.01), k.BULB, v=10)
    k.LIGHT("marker_light_vanity", (0, -0.25, -0.05))
    k.finish(wall=True, subdiv=0.1, ao_dist=0.08, ground=False)


def bathtub():
    k = AptKit("bathtub")
    w, d, h = 1.6, 0.75, 0.55
    k.B("apron", (w, 0.06, h), (0, -d + 0.03, h / 2), k.PORC)
    for s in (-1, 1):
        k.B(f"end{s}", (0.08, d - 0.06, h), (s * (w / 2 - 0.04), -(d - 0.06) / 2, h / 2), k.PORC)
    k.B("back_wall", (w - 0.16, 0.08, h), (0, -0.04, h / 2), k.PORC)
    k.SOFT("basin", (w - 0.16, d - 0.14, 0.14), (0, -d / 2 + 0.01, 0.07), k.PORC, 0.05, step=0.1)          # rounded floor
    for name, size, loc in (("rim_f", (w, 0.075, 0.035), (0, -d + 0.0375, h + 0.0175)),
                            ("rim_b", (w, 0.095, 0.035), (0, -0.0475, h + 0.0175)),
                            ("rim_l", (0.095, d, 0.035), (-w / 2 + 0.0475, -d / 2, h + 0.0175)),
                            ("rim_r", (0.095, d, 0.035), (w / 2 - 0.0475, -d / 2, h + 0.0175))):
        k.SOFT(name, size, loc, k.PORC, 0.014, step=0.2)
    k.CYL("drain", 0.025, 0.004, (-w / 2 + 0.2, -d / 2, 0.142), k.CHROME, v=16)
    k.PIPE("spout", [(-w / 2 + 0.02, -d / 2, h + 0.2), (-w / 2 + 0.14, -d / 2, h + 0.2), (-w / 2 + 0.14, -d / 2, h + 0.12)],
           0.018, k.CHROME, verts=10)
    k.CYL("handle", 0.035, 0.03, (-w / 2 + 0.015, -d / 2, h + 0.35), k.CHROME, "x", 16)
    k.PIPE("riser", [(-w / 2 + 0.01, -0.06, h + 0.2), (-w / 2 + 0.01, -0.06, 1.85), (-w / 2 + 0.2, -0.06, 1.95)], 0.012, k.CHROME, verts=8)
    k.FRUSTUM("head", 0.02, 0.055, 0.04, (-w / 2 + 0.22, -0.1, 1.92), k.CHROME, axis="z", v=16)
    rod_y, rod_z = -d + 0.02, 2.0
    k.TUBE("rod", (-w / 2, rod_y, rod_z), (w / 2, rod_y, rod_z), 0.012, k.CHROME, verts=10)
    k.PLEATS("curtain", -w / 2 + 0.03, -w / 2 + 0.52, rod_y, 0.62, rod_z - 0.03, 0.02, 7, k.CURTAIN)   # drawn back to the tap end
    for i in range(24):
        x = -w / 2 + 0.035 + i * 0.07 if i >= 8 else -w / 2 + 0.035 + i * 0.07 * 0.9
        k.CYL(f"ring{i}", 0.018, 0.005, (min(x, w / 2 - 0.04), rod_y, rod_z), k.CHROME, "x", 12)
    k.COL((w, d, h + 0.035), (0, -d / 2, (h + 0.035) / 2))
    k.finish(wall=True, subdiv=0.3, ao_dist=0.4)


def towel_rack():
    k = AptKit("towel_rack")
    for s in (-1, 1):
        k.CYL(f"post{s}", 0.015, 0.07, (s * 0.31, -0.035, 0), k.CHROME, "y", 8)
    k.TUBE("bar", (-0.32, -0.07, 0), (0.32, -0.07, 0), 0.011, k.CHROME)
    for x in (-0.15, 0.15):                                                                  # two towels, same fold, same length
        k.CYL(f"fold{x}", 0.018, 0.26, (x, -0.07, 0.004), k.TOWEL, "x", 8)
        for dy in (-0.021, 0.021):
            k.SOFT(f"towel{x}{dy}", (0.26, 0.014, 0.44), (x, -0.07 + dy, -0.22), k.TOWEL, 0.006, step=0.06)
    k.finish(wall=True, subdiv=0.1, ao_dist=0.1, ground=False)


def bath_mat():
    k = AptKit("bath_mat")
    k.B("mat", (0.8, 0.5, 0.012), (0, 0, 0.006), k.TOWEL, 0.004)
    k.finish(subdiv=0.2, ao_dist=0.1)


PROPS = {f.__name__: f for f in (toilet, vanity, medicine_cabinet, vanity_light, bathtub, towel_rack, bath_mat)}
