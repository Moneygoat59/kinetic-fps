"""Relay Hub 00 interior. Called by relay_hub.py as build(c) (`c` = namespace of its helpers, materials and dimensions).
Hall 11.2 x 8.0 m, ceiling 3.35 m above the floor. Door at the front (-Y); the ROUTING WALL is the back wall (+Y):
  four route risers (73, 02, 03 rise from buried wells; 00 drops to the silo) with gate valves, handwheels (valve_<key>),
  sight glasses (hub_flow_<key>), route plates and status lamps (hub_glow_lamp_<key>), all tied into one header that runs
  from the surge tank (rear-left) to the silo drop (rear-right, a grated glowing basin).
The router console (kit terminal_router) stands in the middle facing the door. Left = operations (map, notes, desk, tapes,
lockers); right = stores (radar console, shelves, amber cells, drums, crates). Two columns carry the ceiling beams.
"""
import math

import ps1_lib as L

RY, HZ = 3.5, 2.95                                   # route pipes: centre plane y, header height
RX = {"73": -3.6, "02": -1.2, "03": 1.2, "00": 3.6}   # riser x per route (left to right)
TX, TY = -4.75, 3.2                                  # surge tank
SX, SY = 3.6, 3.45                                   # silo drop basin


def build(c):
    lining(c)
    routing_wall(c)
    silo_drop(c)
    surge_tank(c)
    structure(c)
    walls(c)
    decals(c)
    kit(c)
    markers(c)


def lining(c):
    z0, z1 = c.FZ, c.CZ
    c.B("lin_l", (0.05, 2 * c.CY, z1 - z0), (-c.CX + 0.025, 0, (z0 + z1) / 2), c.M_PLATE)
    c.B("lin_r", (0.05, 2 * c.CY, z1 - z0), (c.CX - 0.025, 0, (z0 + z1) / 2), c.M_PLATE)
    c.B("lin_b", (2 * c.CX, 0.05, z1 - z0), (0, c.CY - 0.025, (z0 + z1) / 2), c.M_PLATE)
    w = c.CX - c.DW - 0.4
    for s in (-1, 1):
        c.B(f"lin_f{s}", (w, 0.05, z1 - z0), (s * (c.CX - w / 2), -c.CY + 0.025, (z0 + z1) / 2), c.M_PLATE)


def _riser(c, key, r, valve_z, wheel_r, glass_z):
    x = RX[key]
    c.PIPE(f"riser_{key}", [(x, RY, c.FZ + 0.2), (x, RY, HZ)], r, clamps=0.9)
    c.B(f"valve_body_{key}", (0.36 + r, 0.36 + r, 0.44), (x, RY, valve_z), c.M_RUST, 0.04)
    c.CYL(f"valve_bonnet_{key}", 0.1, 0.26, (x, RY - 0.3, valve_z), c.M_MET_D, "y", 8)
    c.TUBE(f"valve_stem_{key}", (x, RY - 0.4, valve_z), (x, RY - 0.56, valve_z), 0.025, c.M_MET)
    c.WHEEL(f"wheel_{key}", (x, RY - 0.58, valve_z), wheel_r, c.M_HAZ, c.MOVER(f"valve_{key}", (x, RY - 0.58, valve_z)))
    c.LIQ_CYL(f"glass_{key}", r + 0.03, 0.4, (x, RY, glass_z), "z", 10, c.LQ_ROUTE[key])
    for dz in (-0.22, 0.22):
        c.CYL(f"glass_fl_{key}{dz}", r + 0.08, 0.05, (x, RY, glass_z + dz), c.M_MET, v=10)
    for i in range(4):
        a = math.radians(45 + 90 * i)
        px, py = x + (r + 0.06) * math.cos(a), RY + (r + 0.06) * math.sin(a)
        c.TUBE(f"glass_bar_{key}{i}", (px, py, glass_z - 0.2), (px, py, glass_z + 0.2), 0.012, c.M_MET_D, 4)
    c.CYL(f"gauge_{key}", 0.07, 0.04, (x + r + 0.12, RY - 0.1, valve_z + 0.45), c.M_MET, "y", 10)
    c.TUBE(f"gauge_tap_{key}", (x + r, RY, valve_z + 0.45), (x + r + 0.12, RY - 0.08, valve_z + 0.45), 0.015, c.M_MET)
    px = x + 0.75
    c.DECAL(f"plate_{key}", (px, c.CY - 0.012, 1.8), 0.5, 0.5, "-y", c.D_PLATE[key])
    c.B(f"lamp_{key}", (0.18, 0.05, 0.1), (px, c.CY - 0.03, 2.25), c.M_LAMP[key])
    c.B(f"lamp_hood_{key}", (0.26, 0.12, 0.03), (px, c.CY - 0.06, 2.32), c.M_MET_D)
    L.empty(f"marker_route_light_{key}", (x, RY - 0.75, glass_z))


def routing_wall(c):
    for key in ("73", "02", "03"):
        x = RX[key]
        c.CYL(f"collar_{key}", 0.32, 0.2, (x, RY, c.FZ + 0.1), c.M_MET_D, v=10)
        c.CYL(f"collar_fl_{key}", 0.36, 0.05, (x, RY, c.FZ + 0.2), c.M_MET, v=10)
        c.COL(f"collar_{key}_c", (0.72, 0.72, 0.3), (x, RY, c.FZ + 0.15))
        _riser(c, key, 0.15, 1.3, 0.24, 2.1)
        c.COL(f"riser_{key}_c", (0.5, 0.5, HZ - c.FZ), (x, RY, (HZ + c.FZ) / 2))
    # header: surge tank -> across the wall -> down into the silo drop
    c.PIPE("header", [(TX + 0.5, RY, HZ), (RX["00"], RY, HZ), (RX["00"], RY, c.FZ + 0.12)], 0.2, clamps=1.2)
    for x in (-3.0, -0.6, 1.8):
        c.TUBE(f"hanger{x}", (x, RY, c.CZ), (x, RY, HZ + 0.2), 0.03)
        c.TUBE(f"hanger_clamp{x}", (x - 0.05, RY, HZ), (x + 0.05, RY, HZ), 0.25, c.M_MET, 8)
    for x in (-2.4, 0.0, 2.4):
        c.LIQ_CYL(f"hdr_glass{x}", 0.23, 0.4, (x, RY, HZ), "x", 12)
        for dx in (-0.22, 0.22):
            c.CYL(f"hdr_fl{x}{dx}", 0.28, 0.05, (x + dx, RY, HZ), c.M_MET, "x", 10)
    c.B("valve_body_00", (0.56, 0.56, 0.5), (RX["00"], RY, 1.7), c.M_RUST, 0.05)
    c.CYL("valve_bonnet_00", 0.12, 0.3, (RX["00"], RY - 0.4, 1.7), c.M_MET_D, "y", 8)
    c.TUBE("valve_stem_00", (RX["00"], RY - 0.5, 1.7), (RX["00"], RY - 0.66, 1.7), 0.03, c.M_MET)
    c.WHEEL("wheel_00", (RX["00"], RY - 0.68, 1.7), 0.32, c.M_HAZ, c.MOVER("valve_00", (RX["00"], RY - 0.68, 1.7)))
    c.LIQ_CYL("glass_00", 0.24, 0.42, (RX["00"], RY, 2.45), "z", 12, c.LQ_ROUTE["00"])
    for dz in (-0.23, 0.23):
        c.CYL(f"glass_fl_00{dz}", 0.29, 0.05, (RX["00"], RY, 2.45 + dz), c.M_MET, v=12)
    px = RX["00"] + 0.9
    c.DECAL("plate_00", (px, c.CY - 0.012, 1.8), 0.5, 0.5, "-y", c.D_PLATE["00"])
    c.B("lamp_00", (0.18, 0.05, 0.1), (px, c.CY - 0.03, 2.25), c.M_LAMP["00"])
    c.B("lamp_hood_00", (0.26, 0.12, 0.03), (px, c.CY - 0.06, 2.32), c.M_MET_D)
    L.empty("marker_route_light_00", (RX["00"], RY - 0.85, 1.0))
    c.COL("riser_00_c", (0.7, 0.7, HZ - c.FZ), (RX["00"], RY, (HZ + c.FZ) / 2))


def silo_drop(c):
    """Grated basin the silo main dives into: glowing once the silo route runs (hub_flow_00)."""
    for s in (-1, 1):
        c.B(f"drop_wall_x{s}", (0.15, 1.1, 0.4), (SX + s * 0.575, SY, c.FZ + 0.2), c.M_CON_T, 0.03)
        c.B(f"drop_wall_y{s}", (1.3, 0.15, 0.4), (SX, SY + s * 0.475, c.FZ + 0.2), c.M_CON_T, 0.03)
    c.liquids.append(L.quad("drop_liquid", (SX, SY, c.FZ + 0.06), 1.0, 0.8, "+z", c.LQ_ROUTE["00"], up=(0, 1, 0)))
    for i, x in enumerate((-0.36, -0.18, 0.18, 0.36)):
        c.B(f"drop_bar{i}", (0.04, 0.95, 0.04), (SX + x, SY, c.FZ + 0.42), c.M_MET)
    c.COL("drop_c", (1.3, 1.1, 0.45), (SX, SY, c.FZ + 0.225))
    c.DECAL("haz_drop", (SX, SY - 0.75, c.FZ + 0.021), 1.3, 0.2, "+z", c.D_HAZARD, up=(0, 1, 0))
    c.DECAL("crust_drop", (SX, SY - 0.2, c.FZ + 0.015), 2.0, 1.6, "+z", c.D_CRUST, up=(0, 1, 0))


def surge_tank(c):
    z0 = c.FZ
    c.CYL("tank_plinth", 0.78, 0.12, (TX, TY, z0 + 0.06), c.M_CON_T, v=14)
    c.CYL("tank", 0.7, 3.0, (TX, TY, z0 + 1.5), c.M_MET_D, v=14)
    c.parts.append(L.cone("tank_top", 0.7, 0.25, 0.22, (TX, TY, z0 + 3.11), c.M_MET_D, 14))
    for z in (0.7, 1.7, 2.7):
        c.CYL(f"tank_band{z}", 0.72, 0.06, (TX, TY, z0 + z), c.M_MET, v=14)
    a = math.radians(-45)
    gx, gy = TX + 0.78 * math.cos(a), TY + 0.78 * math.sin(a)
    c.LIQ_CYL("tank_level", 0.05, 2.2, (gx, gy, z0 + 1.45), "z", 6)
    for z in (0.3, 2.6):
        c.CYL(f"tank_level_cap{z}", 0.07, 0.08, (gx, gy, z0 + z), c.M_MET, v=6)
        c.TUBE(f"tank_level_arm{z}", (TX + 0.68 * math.cos(a), TY + 0.68 * math.sin(a), z0 + z), (gx, gy, z0 + z), 0.02, c.M_MET)
    c.CYL("tank_gauge", 0.09, 0.04, (TX + 0.3, TY - 0.7, z0 + 1.2), c.M_MET, "y", 10)
    c.COL("tank_c", (1.5, 1.5, 3.2), (TX, TY, z0 + 1.6))
    c.DECAL("tank_drips", (TX + 0.2, TY - 0.72, z0 + 0.6), 0.5, 0.9, "-y", c.D_DRIPS)


def structure(c):
    for s in (-1, 1):
        x = s * 2.4
        c.B(f"col{s}", (0.55, 0.55, c.CZ - c.FZ), (x, -0.4, (c.FZ + c.CZ) / 2), c.M_CON, 0.06)
        c.B(f"col_cap{s}", (0.8, 0.8, 0.2), (x, -0.4, c.CZ - 0.1), c.M_CON_T, 0.04)
        c.B(f"col_base{s}", (0.7, 0.7, 0.12), (x, -0.4, c.FZ + 0.06), c.M_CON_T, 0.03)
        c.COL(f"col{s}_c", (0.7, 0.7, c.CZ - c.FZ), (x, -0.4, (c.FZ + c.CZ) / 2))
        c.B(f"beam{s}", (0.4, 2 * c.CY, 0.3), (x, 0, c.CZ - 0.15), c.M_CON_T, 0.03)
    c.B("beam_x", (2 * c.CX, 0.35, 0.25), (0, -0.4, c.CZ - 0.125), c.M_CON_T, 0.03)
    for i, (x, y) in enumerate(((0, -2.0), (-4.0, -1.2), (4.0, -1.2))):
        c.B(f"light_housing{i}", (1.3, 0.5, 0.1), (x, y, c.CZ - 0.05), c.M_MET_D, 0.02)
        c.B(f"light_lens{i}", (1.1, 0.3, 0.04), (x, y, c.CZ - 0.12), c.M_AMBER)
    c.PIPE("ceil_cable_a", [(-c.CX + 0.1, -3.0, 3.5), (-3.0, -2.6, 3.3), (-1.5, -3.1, 3.52), (0.2, -2.7, 3.28), (1.8, -3.2, 3.5)],
           0.035, mat=c.M_CABLE, verts=5)
    c.PIPE("ceil_cable_b", [(c.CX - 0.1, 0.6, 3.52), (4.2, 1.0, 3.3), (3.0, 0.5, 3.5)], 0.03, mat=c.M_CABLE, verts=5)
    c.TUBE("hang_cable", (1.0, -1.5, 3.6), (1.05, -1.5, 2.7), 0.02, c.M_CABLE, 5)
    c.PIPE("router_feed", [(0.5, 1.9, c.CZ), (0.5, 1.9, 2.6), (0.5, 1.95, 2.1)], 0.05, clamps=0.5)   # cable duct into the console


def walls(c):
    x = -c.CX
    c.B("map_frame", (0.06, 1.8, 1.25), (x + 0.075, -1.0, 2.15), c.M_MET_D, 0.02)
    c.SCREEN("scr_map", (x + 0.108, -1.0, 2.15), 1.66, 1.14, "+x", c.S_MAP)
    c.B("notes_board", (0.05, 1.35, 0.72), (x + 0.075, 1.1, 2.8), c.M_MET_D)
    c.DECAL("notes", (x + 0.106, 1.1, 2.8), 1.25, 0.62, "+x", c.D_NOTES)
    c.PIPE("wall_conduit_l", [(x + 0.08, -2.2, 3.5), (x + 0.08, -2.2, 0.3)], 0.04, clamps=0.8)
    c.PIPE("wall_conduit_r", [(-x - 0.08, -2.4, 3.5), (-x - 0.08, -2.4, 0.3)], 0.04, clamps=0.8)
    c.DECAL("sign_front", (2.4, -c.CY + 0.058, 2.0), 0.42, 0.56, "+y", c.D_WARN)
    c.DECAL("sign_drop", (RX["00"] - 0.9, c.CY - 0.058, 1.6), 0.42, 0.56, "-y", c.D_WARN)


def decals(c):
    f = c.FZ
    D = c.DECAL
    D("haz_door", (0, -c.CY + 0.35, f + 0.022), 2.0, 0.25, "+z", c.D_HAZARD, up=(0, 1, 0))
    D("lane", (0, -2.2, f + 0.02), 0.5, 2.6, "+z", c.D_ARROWS, up=(0, 1, 0))
    D("crust_73", (RX["73"], RY - 0.2, f + 0.016), 1.6, 1.4, "+z", c.D_CRUST, up=(0, 1, 0))
    c.POOL("spill_73", (RX["73"] + 0.3, RY - 0.5, f + 0.03), 1.1, 0.9)
    for i, (x, y, s) in enumerate(((-1.5, -1.5, 1.6), (2.8, 0.8, 1.4), (-3.4, 1.4, 1.2), (1.2, -3.2, 1.0), (4.2, -1.8, 1.3))):
        D(f"stain{i}", (x, y, f + 0.012 + 0.001 * i), s, s, "+z", c.D_STAIN, up=(0, 1, 0))
    for i, (x, y, s) in enumerate(((-3.0, -2.6, 2.6), (3.2, -0.2, 2.2), (0.8, 2.6, 2.0), (-1.2, 0.4, 1.8))):
        D(f"dust{i}", (x, y, f + 0.006 + 0.001 * i), s, s, "+z", c.D_DUST, up=(0, 1, 0))
    D("papers", (-3.9, -0.6, f + 0.028), 1.0, 1.0, "+z", c.D_PAPERS, up=(0, 1, 0))
    D("papers2", (1.4, 0.4, f + 0.029), 0.8, 0.8, "+z", c.D_PAPERS, up=(0, 1, 0))
    D("drips_02", (RX["02"] + 0.3, c.CY - 0.055, 0.95), 0.7, 1.1, "-y", c.D_DRIPS)
    D("streak_b", (-2.4, c.CY - 0.056, 1.3), 1.0, 2.0, "-y", c.D_STREAK)
    D("streak_b2", (2.4, c.CY - 0.056, 1.3), 0.8, 1.8, "-y", c.D_STREAK)
    D("crack_l", (-c.CX + 0.056, 2.4, 2.6), 0.4, 1.2, "+x", c.D_CRACK)


# (prop, x, y, z above the floor, yaw deg, AO proxy (size, local centre) or None). Kit fronts face local -Y at yaw 0.
KIT = [
    ("terminal_router", 0.0, 1.45, 0.0, 0, ((2.1, 0.9, 1.8), (0, 0, 0.9))),
    ("table_steel", -5.1, -1.0, 0.0, 90, ((1.6, 0.9, 0.78), (0, 0, 0.39))),
    ("terminal_crt", -5.12, -1.0, 0.78, 90, None),
    ("chair_steel", -4.25, -1.15, 0.0, -70, None),
    ("terminal_mainframe", -5.18, 0.4, 0.0, 90, ((0.94, 0.74, 1.98), (0, 0, 0.99))),
    ("terminal_mainframe", -5.18, 1.36, 0.0, 90, ((0.94, 0.74, 1.98), (0, 0, 0.99))),
    ("locker", -5.35, -3.35, 0.0, 90, ((0.8, 0.5, 1.92), (0, 0, 0.96))),
    ("locker", -5.35, -2.5, 0.0, 90, ((0.8, 0.5, 1.92), (0, 0, 0.96))),
    ("terminal_wall", -2.3, -4.0 + 0.05, 0.0, 180, ((0.6, 0.3, 0.8), (0, -0.15, 1.47))),
    ("terminal_console", 5.19, -1.0, 0.0, -90, ((1.04, 0.77, 1.6), (0, -0.035, 0.8))),
    ("shelf_rack", 5.325, 0.8, 0.0, -90, ((1.2, 0.45, 1.9), (0, 0, 0.95))),
    ("shelf_rack", 5.325, 2.05, 0.0, -90, ((1.2, 0.45, 1.9), (0, 0, 0.95))),
    ("drum_amber", 4.65, 3.6, 0.0, 0, ((0.58, 0.58, 0.89), (0, 0, 0.445))),
    ("drum_amber", 5.25, 3.55, 0.0, 70, ((0.58, 0.58, 0.89), (0, 0, 0.445))),
    ("table_steel", 5.1, -2.9, 0.0, -90, ((1.6, 0.9, 0.78), (0, 0, 0.39))),
    ("amber_cell", 5.1, -3.3, 0.78, 0, None),
    ("amber_cell", 5.05, -2.6, 0.78, 40, None),
    ("crate_large", 3.3, -3.4, 0.0, 10, ((0.9, 0.65, 0.6), (0, 0, 0.3))),
    ("crate_small", 3.3, -3.4, 0.6, 35, None),
]


def kit(c):
    for i, (prop, kx, ky, kz, yaw, proxy) in enumerate(KIT):
        L.empty(f"marker_kit_{prop}__{i}", (kx, ky, c.KZ + kz)).rotation_euler = (0, 0, math.radians(yaw))
        if proxy:
            (size, (lx, ly, lz)), ca, sa = proxy, math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
            c.proxies.append(L.box(f"kit_proxy{i}", size, (kx + lx * ca - ly * sa, ky + lx * sa + ly * ca, c.KZ + kz + lz), None,
                                   (0, 0, yaw)))


def markers(c):
    m = {"marker_door_center": (0, c.YF + 0.25, c.FZ), "marker_spawn_inside": (0, -2.5, c.FZ),
         "marker_light_ceiling_c": (0, -2.0, 3.35), "marker_light_ceiling_l": (-4.0, -1.2, 3.35),
         "marker_light_ceiling_r": (4.0, -1.2, 3.35), "marker_light_wall": (0, 2.6, 2.7), "marker_light_tank": (-4.0, 2.3, 1.7)}
    for n, p in m.items():
        L.empty(n, p)
