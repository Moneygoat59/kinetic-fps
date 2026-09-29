"""Apartment kit: small tabletop pieces (placed many times through marker_kit_* rows; origin at the base centre, front -Y).
pill_bottle / _tall / _wide / _small  amber pharmacy bottles, child-proof caps, wrap labels (apt_dims.RX 0..3), label forward
pill_organizer   7-day box S M T W T F S, lids shut except today's
blister_pack     foil card lying flat, two pills pushed out
water_glass      tumbler, half full
alarm_clock      LED clock (kit_scr_alarm blinks 6:59)
cleaning_row     spray, bleach, gloves box, sponge: squared up in a row
soap_stack       four wrapped bars, unopened
tp_pyramid       six toilet rolls in a pyramid
"""
import apt_dims as D
from apt_lib import AptKit


def _bottle(name, r, h, rx):
    k = AptKit(name)
    k.CYL("body", r, h, (0, 0, h / 2), k.PILL, v=12)
    k.CYL("shoulder", r * 0.86, 0.006, (0, 0, h + 0.003), k.PILL, v=12)
    k.CYL("cap", r * 1.08, 0.02, (0, 0, h + 0.016), k.CAP, v=12)
    k.CYL("cap_ring", r * 1.1, 0.004, (0, 0, h + 0.007), k.CAP, v=12)
    k.WRAP_UV("label", (0, 0), r + 0.0012, h * 0.18, h * 0.86, 195, 345, k.RX, D.row_uv(rx, len(D.RX)), segs=6)
    k.COL_CYL(r, h + 0.026, (0, 0, (h + 0.026) / 2))
    k.finish(subdiv=0.05, ao_dist=0.08)


def pill_bottle():
    _bottle("pill_bottle", 0.021, 0.08, 0)


def pill_bottle_tall():
    _bottle("pill_bottle_tall", 0.024, 0.11, 1)


def pill_bottle_wide():
    _bottle("pill_bottle_wide", 0.03, 0.075, 2)


def pill_bottle_small():
    _bottle("pill_bottle_small", 0.018, 0.06, 3)


def pill_organizer():
    k = AptKit("pill_organizer")
    w, cell = 0.245, 0.035
    k.B("tray", (w, 0.05, 0.022), (0, 0, 0.011), k.PLASTIC, 0.003)
    for i in range(7):
        x = -w / 2 + 0.0035 + cell * (i + 0.5)
        if i == 4:                                                                    # today's lid is open, empty
            k.B("lid_open", (cell - 0.003, 0.004, 0.046), (x, 0.027, 0.045), k.PLASTIC, into=k.PIVOT("flip_lid", (x, 0.027, 0.0222)))
            k.B("well", (cell - 0.008, 0.042, 0.002), (x, 0, 0.0215), k.CAP)
            continue
        k.QUAD_UV(f"lid{i}", (x, 0, 0.0232), cell - 0.004, 0.046, "+z", k.ORG, (i / 7, 0, (i + 1) / 7, 1), up=(0, 1, 0), into=k.panels)
    k.COL((w, 0.05, 0.025), (0, 0, 0.0125))
    k.USE("pills", (0, 0, 0.03))
    k.finish(subdiv=0.05, ao_dist=0.05)


def blister_pack():
    k = AptKit("blister_pack")
    k.B("card", (0.1, 0.052, 0.002), (0, 0, 0.001), k.CHROME)
    for i in range(10):
        x, y = -0.036 + (i % 5) * 0.018, -0.012 + (i // 5) * 0.024
        if i in (0, 1):
            k.B(f"torn{i}", (0.011, 0.011, 0.0005), (x, y, 0.0022), k.PAPER)          # two taken, foil torn
            continue
        k.CYL(f"bubble{i}", 0.006, 0.004, (x, y, 0.004), k.GLASS, v=8)
        k.CYL(f"pill{i}", 0.0045, 0.003, (x, y, 0.0035), k.CAP, v=8)
    k.COL((0.1, 0.052, 0.006), (0, 0, 0.003))
    k.finish(subdiv=0.05, ao_dist=0.03)


def water_glass():
    k = AptKit("water_glass")
    k.CYL("coaster", 0.045, 0.004, (0, 0, 0.002), k.WOOD_L, v=12)
    k.glass_parts.append(k.CYL("tumbler", 0.034, 0.11, (0, 0, 0.059), k.GLASS, v=12, into=[]))
    k.glass_parts.append(k.CYL("water", 0.031, 0.05, (0, 0, 0.03), k.WATER, v=12, into=[]))
    k.COL_CYL(0.035, 0.115, (0, 0, 0.0575))
    k.finish(subdiv=0.05, ao_dist=0.05)


def alarm_clock():
    k = AptKit("alarm_clock")
    k.B("case", (0.13, 0.06, 0.065), (0, 0, 0.0325), k.BLACK, 0.006, rot=(-8, 0, 0))
    k.SCREEN("face", (0, -0.0325, 0.036), 0.1, 0.045, k.ALARM, tilt=8)
    k.B("button", (0.05, 0.02, 0.006), (0, 0.005, 0.068), k.CHROME)
    k.PIPE("cord", [(0.03, 0.03, 0.01), (0.05, 0.08, 0.004), (0.12, 0.1, 0.004)], 0.003, k.CORD, verts=4)
    k.COL((0.13, 0.07, 0.07), (0, 0, 0.035))
    k.finish(subdiv=0.05, ao_dist=0.05)


def cleaning_row():
    k = AptKit("cleaning_row")
    k.B("spray", (0.07, 0.045, 0.19), (-0.15, 0, 0.095), k.PLASTIC, 0.01)                       # spray bottle
    k.B("trigger", (0.035, 0.07, 0.04), (-0.15, -0.01, 0.21), k.CAP)
    k.B("bleach", (0.1, 0.07, 0.24), (-0.04, 0, 0.12), k.CAP, 0.015)                             # bleach jug
    k.CYL("bleach_cap", 0.018, 0.03, (-0.02, 0, 0.255), k.SOFA, v=8)
    k.B("gloves", (0.12, 0.08, 0.1), (0.1, 0, 0.05), k.PAPER)                                     # box of gloves
    k.B("gloves_slot", (0.06, 0.03, 0.002), (0.1, 0, 0.101), k.DUVET)
    k.B("sponge", (0.09, 0.06, 0.03), (0.22, 0, 0.015), k.CHAIR)
    k.COL((0.52, 0.08, 0.26), (0.03, 0, 0.13))
    k.finish(subdiv=0.08, ao_dist=0.1)


def soap_stack():
    k = AptKit("soap_stack")
    for i in range(4):
        k.B(f"bar{i}", (0.09, 0.06, 0.03), (0, 0, 0.015 + i * 0.03), k.PAPER if i % 2 else k.LINEN, 0.004)
    k.COL((0.09, 0.06, 0.12), (0, 0, 0.06))
    k.finish(subdiv=0.05, ao_dist=0.05)


def tp_pyramid():
    k = AptKit("tp_pyramid")
    r, h = 0.055, 0.1
    for row, n in enumerate((3, 2, 1)):
        for i in range(n):
            x = (i - (n - 1) / 2) * 2 * r
            k.CYL(f"roll{row}{i}", r, h, (x, 0, h / 2 + row * h), k.LINEN, v=10)
            k.CYL(f"core{row}{i}", r * 0.35, h + 0.002, (x, 0, h / 2 + row * h), k.CARD, v=8)
    k.COL((6 * r, 2 * r, 3 * h), (0, 0, 1.5 * h))
    k.finish(subdiv=0.08, ao_dist=0.1)


PROPS = {f.__name__: f for f in (pill_bottle, pill_bottle_tall, pill_bottle_wide, pill_bottle_small, pill_organizer, blister_pack,
                                 water_glass, alarm_clock, cleaning_row, soap_stack, tp_pyramid)}
