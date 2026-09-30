"""Records vault: where the furniture stands. vault.py turns every row into a kit marker marker_kit_<prop>__v<n>[flags]
(BunkerKit.furnish spawns the live piece there). Row = (prop, x, y, facing[, height over the floor][, marker flags]);
facing = the way the piece's front looks ('+x' toward the right wall, '-x' the left, '+y' deeper in, '-y' back to the
door). Blender frame of tunnel_vault: y from the entry face, the hall floor at WALK_Z.
Zones: the aisle down the middle from the door to the tape cage; paper files on the left (mobile stacks packed on their
rails, one aisle open, one ajar; card index and filing cabinets by the door); drawings on the right (plan chests under
the pinned drawings, drafting tables, the layout tables, tube racks, filing cabinets); the digital records behind the
wire cage at the far end (tape cabinets, the operator console, racks, cooling).
"""
from kit_dims import CAT_D, FILE_D, PLAN_D, STACK_L, TRAY_HANG, TUBE_D, VAULT_BAY, VAULT_HW, VAULT_Y0, VAULT_Y1

FACE = {"-y": 0.0, "+x": 90.0, "+y": 180.0, "-x": -90.0}      # kit fronts face -Y: yaw that turns them
HW, Y0, Y1 = VAULT_HW, VAULT_Y0, VAULT_Y1
STACK_X = -3.0 - STACK_L / 2                   # stack ends (cranks) line the aisle at x -3
STACKS = (13.7, 14.7, 15.7, 17.9, 18.9, 19.9, 20.9, 22.3, 23.3, 24.3, 25.3, 26.3, 27.3)   # 16.2..17.4 open, 21.4..21.8 ajar
CAGE_Y = Y0 + 4 * VAULT_BAY                    # the tape cage's mesh wall, under the last beam
CAGE_H = 3.2                                   # its ceiling over the floor
TABLE_TOP = 0.78

KIT = [("archive_stack", STACK_X, y, "+x") for y in STACKS]
KIT += [("card_catalog", x, Y0 + CAT_D / 2 + 0.05, "+y") for x in (-3.9, -4.9)]
KIT += [("file_cabinet_open" if i == 2 else "file_cabinet", -5.9 - 0.49 * i, Y0 + FILE_D / 2 + 0.05, "+y") for i in range(6)]
KIT += [("table_steel", 4.2, Y0 + 0.53, "+y"), ("terminal_crt", 4.2, Y0 + 0.53, "+y", TABLE_TOP),
        ("chair_steel", 4.2, Y0 + 1.45, "-y"), ("shelf_rack", 6.3, Y0 + 0.28, "+y")]
KIT += [("plan_chest_open" if i == 3 else "plan_chest", HW - PLAN_D / 2 - 0.03, 12.6 + 1.4 * i, "-x") for i in range(6)]
KIT += [("drafting_table", 5.2, 14.3, "-x"), ("chair_steel", 4.35, 14.3, "+x"),
        ("drafting_table", 5.2, 17.7, "-x"), ("chair_steel", 4.3, 17.4, "+x")]
KIT += [("table_steel", 5.6, 21.6, "-x"), ("table_steel", 5.6, 23.2, "-x"), ("chair_steel", 4.75, 22.5, "+x")]
KIT += [("tube_rack", HW - TUBE_D / 2 - 0.03, y, "-x") for y in (21.8, 23.1)]
KIT += [("file_cabinet_open" if i == 5 else "file_cabinet", HW - FILE_D / 2 - 0.03, 24.7 + 0.49 * i, "-x") for i in range(8)]
# the tape cage; the console is the vault's usable terminal (res://content/terminals/vault_records.tres)
KIT += [("terminal_mainframe", -8.3 + i, Y1 - 0.42, "-y") for i in range(4)]
KIT += [("terminal_server", -1.8, Y1 - 0.5, "-y", 0.0, "__drive_vault_records"), ("chair_steel", -1.8, Y1 - 1.35, "+y")]
KIT += [("server_rack_open" if i == 3 else "server_rack", 0.9 + 0.6 * i, Y1 - 0.55, "-y") for i in range(9)]
KIT += [("cable_tray", 1.2 + 2.0 * i, Y1 - 0.55, "+x", CAGE_H - TRAY_HANG) for i in range(3)]
KIT += [("crac_unit", 7.7, Y1 - 0.45, "-y"), ("shelf_rack", -HW + 0.28, 30.4, "+x"), ("shelf_rack", -HW + 0.28, 31.7, "+x"),
        ("crate_small", 6.9, 30.2, "-y")]
