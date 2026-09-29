"""Shared dimensions for kit pieces whose geometry and textures must line up (pure Python: used by the Blender builders
and by tools/blender/kit_textures.py). Metres, Blender axes (Z up, front -Y).

Field dosimeter (handheld, origin at the base centre):"""
DOSI_W, DOSI_D, DOSI_H = 0.2, 0.09, 0.13         # body width (x), depth (y), height (z)
DOSI_GRIP_Z = 0.17                               # carry-handle grip centreline above the base
DOSI_GRIP_R = 0.011                              # grip sleeve radius (it rests on the rack hook)
DOSI_TOP = DOSI_GRIP_Z + DOSI_GRIP_R             # top of the handle
METER_C = (-0.035, 0.085)                        # meter face centre (x, z) on the front
METER_W, METER_H = 0.09, 0.056                   # meter face size (texture kit_meter_face.png is 128 x 80)
NEEDLE_PIVOT_Z = METER_C[1] - METER_H / 2 + 0.0014   # needle hub: 2 px above the face bottom (texture pivot 64, 78)
NEEDLE_LEN = 0.042                               # 60 px of the 128 px face
NEEDLE_SWING = 50.0                              # degrees either side of vertical (texture scale spans the same arc)

# Field-kit wall rack (wall prop: back on y = 0, origin on the floor). The painted shadow board (kit_decal_shadowboard.png,
# 268 x 192 px over 0.84 x 0.6 m, 320 px/m) draws a device outline behind every slot, so both use these numbers.
RACK_W, RACK_H = 0.84, 0.6
RACK_ZC = 1.15                                   # plate centre height
RACK_SLOTS = (-0.27, 0.0, 0.27)                  # slot centres (x); slot 3 (+x) still holds a dosimeter
RACK_HOOK_Z = RACK_ZC + 0.17                     # hook bar height
RACK_HOOK_R = 0.006
RACK_DEVICE_Y = -0.07                            # hung device centre (its back rests on the plate)
RACK_DEVICE_Z = RACK_HOOK_Z + RACK_HOOK_R - (DOSI_GRIP_Z - DOSI_GRIP_R)   # hung device base height
BOARD_W, BOARD_H, BOARD_PPM = 0.84, 0.6, 320     # shadow-board decal size (m, = plate face) and pixels per metre

# Walkway kit (tools/blender/kit/walkways.py): steel stairs, landings and catwalks that snap together on a 2 m grid. The silo
# tower (tools/blender/props/silo_tower.py) lays its markers out with the same numbers.
WALK_W = 2.0                                     # flight / catwalk width (x), landing depth (y)
LANDING_W = 2 * WALK_W                           # a switchback landing spans two flights side by side
FLIGHT_RISE, FLIGHT_RUN = 4.0, 8.0               # one flight: 20 risers of 0.2 over 20 goings of 0.4 (26.6 deg)
RISER, GOING = 0.2, 0.4
RAIL_H = 1.0                                     # handrail height above the walking line
DOOR_W, DOOR_H = 2.0, 2.4                        # blast door clear opening
DOOR_FRAME_W, DOOR_FRAME_H, DOOR_DEPTH = 4.4, 3.1, 0.5   # housing (leaves slide 1 m into it on each side)

# Vent ducts (tools/blender/kit/ducts.py): square sheet-steel ducts big enough to crawl through, on the same 2 m grid. The
# crawl (scripts/player_crawl.gd) and VentDuct (scripts/world/vent_duct.gd) are sized to them: keep O73Kit.DUCT_* equal.
DUCT_W, DUCT_H = 1.2, 1.0                        # clear inside: width (x), height (z); crawling surface at z 0
DUCT_T = 0.04                                    # sheet thickness
DUCT_MOUTH = 1.2                                 # duct_mouth: stub length behind the wall face (walls up to ~1.1 m thick)

# Server room (tools/blender/kit/servers.py, placed by tools/blender/props/silo_servers.py). The rack's equipment face is
# one emissive quad (kit_screen_rack_*.png, drawn by tools/blender/server_textures.py: SRV_UNITS units of SRV_UNIT_PX px).
SRV_W, SRV_D, SRV_H = 0.6, 1.0, 2.11             # server_rack footprint (x along the row, y depth) and height
SRV_FACE_W, SRV_FACE_H, SRV_FACE_Z = 0.5, 1.75, 0.22   # equipment face size and bottom edge
SRV_UNITS, SRV_UNIT_PX, SRV_FACE_PX = 14, 16, 64       # face texture: 14 units, 64 x 224 px
TRAY_W, TRAY_L = 0.5, 2.0                        # cable_tray: ladder width (x), one segment's length (y)
TRAY_HANG = 0.8                                  # cable_tray hanger rods reach this far above its origin: mount at ceiling - 0.8

# Rail tunnels (tools/blender/kit/tunnels.py + tunnel_lib.py): the company's underground line, single track, amber powered.
# Every piece runs along local +Y (Godot -Z) from its origin (the entry face, tunnel centre, invert level z 0) and carries
# marker_next at its exit (position + heading): the next piece's origin goes there (TunnelLine in Godot chains them).
# Walkway (cess) on the right (+X) heading +Y, the amber power rail and the main on the left (-X).
TUN_HW = 3.0                                     # inner half width at the walls
TUN_SPRING = 2.6                                 # walls vertical up to here, then a semicircular arch of radius TUN_HW
TUN_CROWN = TUN_SPRING + TUN_HW                  # 5.6 m clear at the crown
TUN_LINING = 0.35                                # lining thickness (the solid behind the inner face)
TUN_SLAB = 0.5                                   # invert slab under z 0
TUN_LEN = 8.0                                    # tunnel_straight / tunnel_refuge / tunnel_vent / tunnel_collapse length
TUN_RIB = 2.0                                    # segment rings every 2 m (a lining joint: a shallow proud band)
TUN_CURVE_DEG = 15.0                             # tunnel_curve_l / _r turn this much ...
TUN_CURVE_R = TUN_LEN / 0.25881904510252074      # ... on this radius (8 / sin 15 deg): each curve advances exactly TUN_LEN
                                                 # along its entry heading, so r,l,l,r (a wiggle) is 32 m on and 0 aside
TUN_BULK_LEN = 2.0                               # tunnel_bulkhead (a portal frame between sections)
TRACK_X = -0.6                                   # track centreline (left of the tunnel centre, leaving room for the cess)
GAUGE = 1.435                                    # rail centres
RAIL_TOP = 0.2                                   # rail head above the invert (sleepers sit in the slab, tops at 0.05)
WALK_X0 = 1.75                                   # cess walkway: from here to the right wall, top at WALK_Z
WALK_Z = 0.7
POWER_X = -2.05                                  # the amber conductor rail (covered), on insulators
MAIN_X, MAIN_Z, MAIN_R = -2.62, 1.55, 0.17       # the amber main on the left wall
REFUGE_W, REFUGE_D, REFUGE_H = 1.8, 1.1, 2.4     # tunnel_refuge: niche in the right wall at walkway level, centred on y = 4
VENT_Y, VENT_Z = 4.0, WALK_Z + 1.4               # tunnel_vent: duct opening in the right wall (centre y, duct floor height)
JUNC_R = 12.0                                    # tunnel_junction: centre to each mouth plane (a tunnel piece starts there)
JUNC_HALL_R = 10.5                               # the round hall's wall
JUNC_WALL_H, JUNC_DOME_H = 4.2, 5.2              # wall height, then an elliptic dome this much higher
JUNC_PIT_R, JUNC_PIT_D = 5.0, 0.35               # turntable pit

# Station (tools/blender/kit/station.py; props in station_props.py; textures tools/blender/station_textures.py). tunnel_station
# chains like tunnel_straight: bore, a headwall, the platform cavern, a headwall, bore. The cavern keeps the bore's left wall
# (track, conductor, drain and main run straight through) and widens to the right over a side platform at WALK_Z, so the
# walkway runs straight onto it.
STA_LEN = 24.0                                   # entry face to exit face
STA_Y0, STA_Y1 = 1.5, 22.5                       # the cavern (between the headwalls' inner faces)
STA_HEAD = 0.5                                   # headwall thickness (a bore stub of STA_Y0 - STA_HEAD in front of each)
STA_XR = 6.6                                     # the cavern's right (back) wall; left wall = -TUN_HW
STA_EDGE = 0.95                                  # platform edge (x): a nosing overhangs a recess under it
STA_RECESS = 0.3                                 # how far the recess runs in under the edge
STA_SPRING = 3.6                                 # walls vertical to here, then an elliptic vault ...
STA_RISE = 2.6                                   # ... this high: crown STA_SPRING + STA_RISE over the invert
STA_RIB = 3.0                                    # transverse ribs every 3 m from STA_Y0

# Records vault (tools/blender/kit/vault.py + vault_door.py; furniture in archive.py / drawings.py; textures
# tools/blender/archive_textures.py). tunnel_vault ends a line like tunnel_collapse (no marker_next): VAULT_APPROACH of
# tunnel, a loading dock at walkway height, the vault wall with a round door, then the hall. Hall floor = WALK_Z.
VAULT_APPROACH = 10.0                            # tunnel from the entry face to the vault wall's front face
VAULT_WALL = 1.2                                 # wall thickness (the round doorway runs through it)
VAULT_DOCK_Y = 6.2                               # the dock's front edge (full width, top at WALK_Z, up to the wall)
VAULT_HW = 9.0                                   # hall: interior half width ...
VAULT_Y0 = VAULT_APPROACH + VAULT_WALL           # ... from the wall's back face ...
VAULT_Y1 = VAULT_Y0 + 22.0                       # ... to the back wall (5 bays of VAULT_BAY)
VAULT_BAY = 4.4                                  # ceiling beams every bay; the last one carries the machine room's cage
VAULT_CLEAR = 5.6                                # floor to ceiling slab (beams hang 0.6 under it)
VAULT_COL_X = 2.3                                # the aisle's columns (+/-)
DOOR_R, DOOR_ZC = 1.45, WALK_Z + 1.2             # round doorway: radius, centre height (the floor runs through its foot)
DOOR_FLANGE = 1.7                                # the door leaf's front flange radius (the plug fits the doorway)
DOOR_HINGE = (-2.2, VAULT_APPROACH - 0.45)       # hinge pintle (x, y): the door hangs on the left, swung out to the dock
DOOR_OPEN = -100.0                               # degrees the leaf stands open (about the pintle, Z)

# Archive furniture (archive.py, drawings.py). Fronts face -Y, origin at the base centre.
STACK_W, STACK_L, STACK_H = 1.0, 5.6, 2.4        # archive_stack: a mobile shelving carriage, end panel (crank) at the front
STACK_BAY, STACK_END = 1.0, 0.3                  # five 1 m bays between two 0.3 m end panels
STACK_SHELVES = (0.2, 0.58, 0.96, 1.34, 1.72, 2.1)
FILE_W, FILE_D, FILE_H = 0.47, 0.71, 1.33        # file_cabinet (four drawers)
PLAN_W, PLAN_D, PLAN_H = 1.35, 0.95, 0.96        # plan_chest (two five-drawer units on a plinth)
TUBE_W, TUBE_D, TUBE_H = 1.2, 0.6, 1.9           # tube_rack (pigeonholes of rolled drawings)
CAT_W, CAT_D, CAT_H = 0.95, 0.5, 1.4             # card_catalog (drawers on a stand)
