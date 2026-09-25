import zlib
import struct
import os

def save_png(filename, width, height, pixels):
    os.makedirs(os.path.dirname(os.path.abspath(filename)), exist_ok=True)
    raw_bytes = bytearray()
    for y in range(height):
        raw_bytes.append(0)
        for x in range(width):
            r, g, b, a = pixels[y][x]
            raw_bytes.extend([r, g, b, a])

    def make_chunk(tag, data):
        chunk = tag + data
        crc = zlib.crc32(chunk)
        return struct.pack('>I', len(data)) + chunk + struct.pack('>I', crc)

    header = b'\x89PNG\r\n\x1a\n'
    ihdr = make_chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))
    idat = make_chunk(b'IDAT', zlib.compress(bytes(raw_bytes), level=9))
    iend = make_chunk(b'IEND', b'')

    with open(filename, 'wb') as f:
        f.write(header + ihdr + idat + iend)

def create_canvas(w, h, fill=(0,0,0,0)):
    return [[fill for _ in range(w)] for _ in range(h)]

# --- Color Constants ---
O = (12, 14, 18, 255)       # Outline
_ = (0, 0, 0, 0)            # Transparent
G0 = (18, 20, 25, 255)      # Gunmetal dark
G1 = (35, 39, 46, 255)      # Gunmetal mid-dark
G2 = (60, 68, 82, 255)      # Gunmetal mid
G3 = (92, 104, 125, 255)    # Gunmetal light
G4 = (155, 168, 189, 255)   # Gunmetal highlight
GW = (214, 226, 240, 255)   # Gunmetal white spec

A0 = (42, 26, 8, 255)       # Amber dark
A1 = (94, 50, 15, 255)      # Amber mid-dark
A2 = (181, 107, 24, 255)    # Amber mid
A3 = (240, 158, 43, 255)    # Amber bright
A4 = (255, 210, 105, 255)   # Amber glow
AW = (255, 244, 212, 255)   # Amber white

E0 = (6, 28, 18, 255)       # Emerald dark
E1 = (15, 61, 38, 255)      # Emerald mid-dark
E2 = (31, 122, 77, 255)     # Emerald mid
E3 = (61, 217, 139, 255)    # Emerald bright
E4 = (133, 245, 188, 255)   # Emerald glow

R0 = (36, 8, 10, 255)       # Red dark
R1 = (82, 19, 24, 255)      # Red mid-dark
R2 = (158, 35, 46, 255)     # Red mid
R3 = (230, 59, 73, 255)     # Red bright
R4 = (255, 138, 148, 255)   # Red glow

C0 = (14, 45, 65, 255)      # Cyan dark
C1 = (24, 100, 145, 255)    # Cyan mid
C2 = (56, 189, 248, 255)    # Cyan bright
C3 = (186, 230, 253, 255)   # Cyan glow

B0 = (10, 9, 16, 255)       # Basalt dark
B1 = (26, 22, 34, 255)      # Basalt mid
B2 = (46, 41, 58, 255)      # Basalt light
B3 = (75, 67, 94, 255)      # Basalt highlight
B4 = (122, 112, 148, 255)   # Basalt spec

# ---------------- UI FRAMES & TEXTURES ----------------

def make_window_bg(path):
    w, h = 48, 48
    c = create_canvas(w, h, (17, 19, 23, 248))
    # Outer 1px frame
    for x in range(w):
        c[0][x] = O; c[h-1][x] = O
    for y in range(h):
        c[y][0] = O; c[y][w-1] = O
    # Bevel highlight top/left, shadow bottom/right
    for x in range(1, w-1):
        c[1][x] = G3; c[2][x] = G2
        c[h-2][x] = G0; c[h-3][x] = G0
    for y in range(1, h-1):
        c[y][1] = G3; c[y][2] = G2
        c[y][w-2] = G0; c[y][w-3] = G0
    # Corner rivets
    for rx, ry in [(4, 4), (w-6, 4), (4, h-6), (w-6, h-6)]:
        c[ry][rx] = G4; c[ry][rx+1] = GW
        c[ry+1][rx] = G1; c[ry+1][rx+1] = G2
    # Subtle interior carbon cross pattern
    for y in range(4, h-4):
        for x in range(4, w-4):
            if (x % 4 == 0) and (y % 4 == 0):
                c[y][x] = (22, 25, 30, 248)
    save_png(path, w, h, c)

def make_slot_default(path):
    w, h = 48, 48
    c = create_canvas(w, h, (18, 21, 26, 255))
    # Border
    for x in range(w):
        c[0][x] = O; c[h-1][x] = O
        c[1][x] = G1; c[h-2][x] = G0
    for y in range(h):
        c[y][0] = O; c[y][w-1] = O
        c[y][1] = G1; c[y][w-2] = G0
    # Inset shadow
    for x in range(2, w-2):
        c[2][x] = (12, 14, 18, 255)
    for y in range(2, h-2):
        c[y][2] = (12, 14, 18, 255)
    # Subtle inner corner ticks
    for cx, cy in [(4, 4), (w-5, 4), (4, h-5), (w-5, h-5)]:
        c[cy][cx] = G1
    save_png(path, w, h, c)

def make_slot_selected(path):
    w, h = 48, 48
    c = create_canvas(w, h, (20, 24, 30, 255))
    # Outer slot frame
    for x in range(w):
        c[0][x] = O; c[h-1][x] = O
        c[1][x] = G2; c[h-2][x] = G0
    for y in range(h):
        c[y][0] = O; c[y][w-1] = O
        c[y][1] = G2; c[y][w-2] = G0
    # Glowing Amber Corner Brackets (7px wide, 2px thick)
    bracket_len = 8
    for i in range(bracket_len):
        # Top-Left
        c[2][2+i] = A4; c[3][2+i] = A3
        c[2+i][2] = A4; c[2+i][3] = A3
        # Top-Right
        c[2][w-3-i] = A4; c[3][w-3-i] = A3
        c[2+i][w-3] = A4; c[2+i][w-4] = A3
        # Bottom-Left
        c[h-3][2+i] = A4; c[h-4][2+i] = A3
        c[h-3-i][2] = A4; c[h-3-i][3] = A3
        # Bottom-Right
        c[h-3][w-3-i] = A4; c[h-4][w-3-i] = A3
        c[h-3-i][w-3] = A4; c[h-3-i][w-4] = A3
    save_png(path, w, h, c)

def make_slot_equipped_badge(path):
    w, h = 14, 14
    c = create_canvas(w, h, _)
    # Draw glowing emerald reticle diamond
    for i in range(5):
        # Diamond shape
        c[2+i][6-i] = E3; c[2+i][7+i] = E3
        c[11-i][6-i] = E3; c[11-i][7+i] = E3
    # Center glow
    c[6][6] = E4; c[6][7] = E4; c[7][6] = E4; c[7][7] = E4
    # Outer outline
    for i in range(5):
        c[1+i][6-i] = O; c[1+i][7+i] = O
        c[12-i][6-i] = O; c[12-i][7+i] = O
    save_png(path, w, h, c)

def make_button_frame(w, h, fill=G1):
    c = create_canvas(w, h, fill)
    for x in range(w):
        c[0][x] = O; c[h-1][x] = O
        c[1][x] = G3; c[h-2][x] = G0
    for y in range(h):
        c[y][0] = O; c[y][w-1] = O
        c[y][1] = G3; c[y][w-2] = G0
    return c

def make_btn_equip(path):
    # 36x36 Button with a glowing crosshair / reticle icon in emerald
    w, h = 36, 36
    c = make_button_frame(w, h, (25, 30, 38, 255))
    cx, cy = 18, 18
    # Crosshair circle
    for r in range(5, 8):
        c[cy - r][cx] = E3; c[cy + r][cx] = E3
        c[cy][cx - r] = E3; c[cy][cx + r] = E3
    for dx, dy in [(-5, -5), (5, -5), (-5, 5), (5, 5), (-4, -6), (4, -6), (-6, -4), (6, -4), (-4, 6), (4, 6), (-6, 4), (6, 4)]:
        c[cy + dy][cx + dx] = E2
    # Center dot
    c[cy][cx] = E4
    save_png(path, w, h, c)

def make_btn_action(path):
    # 36x36 Button with a lightning spark / use action icon in amber
    w, h = 36, 36
    c = make_button_frame(w, h, (25, 30, 38, 255))
    # Lightning bolt icon
    coords = [
        (19, 9), (18, 10), (19, 10), (17, 11), (18, 11), (19, 11),
        (16, 12), (17, 12), (18, 12), (15, 13), (16, 13), (17, 13), (18, 13), (19, 13), (20, 13),
        (16, 14), (17, 14), (18, 14), (19, 14), (15, 15), (16, 15), (17, 15), (18, 15),
        (17, 16), (18, 16), (19, 16), (18, 17), (19, 17), (20, 17), (21, 17),
        (19, 18), (20, 18), (19, 19), (20, 19), (18, 20), (19, 20), (18, 21), (19, 21),
        (17, 22), (18, 22), (17, 23), (18, 23), (17, 24), (16, 25), (16, 26)
    ]
    for x, y in coords:
        c[y][x] = A4
        c[y-1][x] = A3
    save_png(path, w, h, c)

def make_btn_close(path):
    # 36x36 Button with a bold [X] cancel icon in crimson
    w, h = 36, 36
    c = make_button_frame(w, h, (30, 22, 24, 255))
    for i in range(-6, 7):
        cx, cy = 18, 18
        c[cy + i][cx + i] = R3
        c[cy + i][cx + i + 1] = R4
        c[cy + i][cx - i] = R3
        c[cy + i][cx - i - 1] = R4
    save_png(path, w, h, c)

def make_turntable_frame(path):
    # 140x140 Sci-fi framed viewing window
    w, h = 140, 140
    c = create_canvas(w, h, (10, 12, 15, 235))
    for x in range(w):
        c[0][x] = O; c[h-1][x] = O
        c[1][x] = G2; c[h-2][x] = G0
    for y in range(h):
        c[y][0] = O; c[y][w-1] = O
        c[y][1] = G2; c[y][w-2] = G0
    # Corner ticks
    for i in range(12):
        c[3][3+i] = G4; c[3+i][3] = G4
        c[3][w-4-i] = G4; c[3+i][w-4] = G4
        c[h-4][3+i] = G4; c[h-4-i][3] = G4
        c[h-4][w-4-i] = G4; c[h-4-i][w-4] = G4
    # Center axis marks
    mid = 70
    for i in range(-4, 5):
        c[4][mid+i] = G3; c[h-5][mid+i] = G3
        c[mid+i][4] = G3; c[mid+i][w-5] = G3
    save_png(path, w, h, c)

def make_hud_dock(path):
    # 54x54 HUD dock with slot inset and 4 pips at bottom
    w, h = 54, 54
    c = create_canvas(w, h, (14, 16, 20, 240))
    for x in range(w):
        c[0][x] = O; c[h-1][x] = O
        c[1][x] = G3; c[h-2][x] = G0
    for y in range(h):
        c[y][0] = O; c[y][w-1] = O
        c[y][1] = G3; c[y][w-2] = G0
    # Inner slot border 36x36 at (9, 6)
    for x in range(9, 45):
        c[6][x] = G0; c[41][x] = G1
    for y in range(6, 42):
        c[y][9] = G0; c[y][44] = G1
    save_png(path, w, h, c)

def make_hud_pip_active(path):
    w, h = 6, 6
    c = create_canvas(w, h, A4)
    for x in range(w):
        c[0][x] = A2; c[h-1][x] = A1
    for y in range(h):
        c[y][0] = A2; c[y][w-1] = A1
    c[2][2] = AW; c[2][3] = AW
    save_png(path, w, h, c)

def make_hud_pip_inactive(path):
    w, h = 6, 6
    c = create_canvas(w, h, G0)
    for x in range(w):
        c[0][x] = O; c[h-1][x] = O
    for y in range(h):
        c[y][0] = O; c[y][w-1] = O
    c[2][2] = G1; c[2][3] = G1
    save_png(path, w, h, c)

# ---------------- 32x32 AUTHENTIC PIXEL ART ICONS ----------------

def make_icon_blaster(path):
    # Futuristic Combat Pistol
    w, h = 32, 32
    c = create_canvas(w, h, _)
    # Slide (top body)
    for y in range(10, 16):
        for x in range(6, 27):
            c[y][x] = G2
    # Slide top highlights
    for x in range(7, 26):
        c[10][x] = G4; c[11][x] = G3
    # Cooling vents
    for x in [10, 13, 16, 19]:
        c[11][x] = G0; c[12][x] = G0
    # Glowing energy chamber
    for x in range(12, 17):
        c[13][x] = A4; c[14][x] = A3
    # Muzzle tip
    c[12][26] = G4; c[13][26] = G3; c[13][27] = A4
    # Grip (angled handle)
    grip = [
        (16, 8), (16, 9), (16, 10), (16, 11), (16, 12),
        (17, 9), (17, 10), (17, 11), (17, 12),
        (18, 10), (18, 11), (18, 12), (18, 13),
        (19, 10), (19, 11), (19, 12), (19, 13),
        (20, 11), (20, 12), (20, 13), (20, 14),
        (21, 11), (21, 12), (21, 13), (21, 14),
        (22, 12), (22, 13), (22, 14), (22, 15),
        (23, 12), (23, 13), (23, 14), (23, 15)
    ]
    for gy, gx in grip:
        c[gy][gx] = G1
        if gx in [9, 10, 11]: c[gy][gx] = G2
    # Trigger guard
    c[16][14] = G1; c[17][15] = G1; c[18][14] = G1
    c[16][12] = G4  # Trigger
    # Outline pass
    for y in range(1, h-1):
        for x in range(1, w-1):
            if c[y][x] != _:
                for dy, dx in [(-1,0), (1,0), (0,-1), (0,1)]:
                    if c[y+dy][x+dx] == _:
                        c[y+dy][x+dx] = O
    save_png(path, w, h, c)

def make_icon_grenade(path):
    # Fragmentation Grenade
    w, h = 32, 32
    c = create_canvas(w, h, _)
    # Pineapple segments
    for y in range(12, 26):
        for x in range(10, 22):
            c[y][x] = G2
    # Grid segmentation grooves
    for y in [15, 18, 21]:
        for x in range(10, 22):
            c[y][x] = G0
    for x in [13, 16, 19]:
        for y in range(12, 26):
            c[y][x] = G0
    # Metallic highlights
    for y in range(13, 25):
        if c[y][11] == G2: c[y][11] = G4
        if c[y][12] == G2: c[y][12] = G3
    # Top neck collar & fuse
    for x in range(14, 18):
        c[9][x] = G3; c[10][x] = G3; c[11][x] = G1
    # Yellow arming pin ring
    c[7][13] = A4; c[7][14] = A4; c[8][13] = A3; c[8][15] = A3; c[9][14] = A3
    # Glowing detonation diode
    c[10][15] = R3; c[10][16] = R4
    # Outline pass
    for y in range(1, h-1):
        for x in range(1, w-1):
            if c[y][x] != _:
                for dy, dx in [(-1,0), (1,0), (0,-1), (0,1)]:
                    if c[y+dy][x+dx] == _:
                        c[y+dy][x+dx] = O
    save_png(path, w, h, c)

def make_icon_dosimeter(path):
    # Field Radiation Dosimeter
    w, h = 32, 32
    c = create_canvas(w, h, _)
    # Rugged yellow/dark body
    for y in range(9, 27):
        for x in range(9, 23):
            c[y][x] = A1
    # Bevel highlight
    for y in range(10, 26):
        c[y][10] = A3
    for x in range(10, 22):
        c[10][x] = A3
    # Analog meter window
    for y in range(12, 19):
        for x in range(12, 20):
            c[y][x] = (220, 225, 230, 255)
    # Curved red danger zone on meter
    c[13][17] = R3; c[13][18] = R3; c[14][18] = R3
    # Meter needle pointing to danger
    c[17][13] = O; c[16][14] = O; c[15][15] = O; c[14][16] = R4; c[13][17] = R4
    # Sensor wand / antenna on right side
    for y in range(5, 17):
        c[y][24] = G3; c[y][25] = G1
    c[4][24] = G4; c[4][25] = G4
    # Front toggle switches
    c[22][13] = G4; c[23][13] = G1
    c[22][17] = G4; c[23][17] = G1
    # Glowing radiation LED
    c[22][20] = A4; c[23][20] = A3
    # Outline pass
    for y in range(1, h-1):
        for x in range(1, w-1):
            if c[y][x] != _:
                for dy, dx in [(-1,0), (1,0), (0,-1), (0,1)]:
                    if c[y+dy][x+dx] == _:
                        c[y+dy][x+dx] = O
    save_png(path, w, h, c)

def make_icon_torch(path):
    # Survival Flare Torch
    w, h = 32, 32
    c = create_canvas(w, h, _)
    # Diagonal torch body (bottom-left to center)
    for i in range(10):
        # Cylinder slice
        c[26-i][8+i] = R2; c[25-i][9+i] = R3; c[24-i][10+i] = R1
        if i < 6: # Taped handle grip
            c[26-i][8+i] = G1; c[25-i][9+i] = G2; c[24-i][10+i] = G0
    # Metal flare collar
    c[16][18] = G4; c[15][19] = G3; c[14][20] = G2
    # Blazing Flare Flame (white -> yellow -> orange -> red)
    flame = [
        (13, 21, AW), (12, 22, AW), (12, 21, A4), (13, 22, A4),
        (11, 22, A4), (11, 23, A4), (12, 23, A3), (10, 23, A3),
        (9, 23, A3), (9, 24, A3), (8, 24, A2), (7, 24, A2),
        (6, 25, A1), (5, 25, R3), (4, 25, R2),
        # Sparks & side flames
        (10, 21, A3), (9, 21, A2), (8, 22, R3),
        (11, 24, A3), (10, 25, A2), (8, 26, R3), (6, 27, R4)
    ]
    for fy, fx, col in flame:
        c[fy][fx] = col
    # Outline pass
    for y in range(1, h-1):
        for x in range(1, w-1):
            if c[y][x] != _:
                for dy, dx in [(-1,0), (1,0), (0,-1), (0,1)]:
                    if c[y+dy][x+dx] == _:
                        c[y+dy][x+dx] = O
    save_png(path, w, h, c)

def make_icon_med_injector(path):
    # Pneumatic Stim Injector
    w, h = 32, 32
    c = create_canvas(w, h, _)
    # Diagonal presentation
    # Plunger cap (top right)
    for i in range(3):
        c[6+i][24-i] = G4; c[7+i][25-i] = G3
    # Chrome casing
    for i in range(4):
        c[9+i][21-i] = G3; c[10+i][22-i] = G4; c[11+i][23-i] = G1
    # Glass ampoule chamber with glowing emerald liquid
    for i in range(8):
        c[13+i][17-i] = E4; c[14+i][18-i] = E3; c[15+i][19-i] = E2
    # Glass reflection highlight
    c[13][17] = (220, 255, 240, 255); c[14][16] = (220, 255, 240, 255)
    # Lower metal nozzle
    for i in range(3):
        c[21+i][9-i] = G3; c[22+i][10-i] = G1
    # Steel needle tip
    c[24][7] = GW; c[25][6] = GW; c[26][5] = GW
    # Outline pass
    for y in range(1, h-1):
        for x in range(1, w-1):
            if c[y][x] != _:
                for dy, dx in [(-1,0), (1,0), (0,-1), (0,1)]:
                    if c[y+dy][x+dx] == _:
                        c[y+dy][x+dx] = O
    save_png(path, w, h, c)

def make_icon_ammo_cell(path):
    # High-Density Kinetic Power Cell
    w, h = 32, 32
    c = create_canvas(w, h, _)
    # Dark rugged battery casing
    for y in range(9, 25):
        for x in range(10, 22):
            c[y][x] = G1
    # Bevel highlights
    for x in range(11, 21):
        c[9][x] = G3; c[10][x] = G2
    for y in range(10, 24):
        c[y][10] = G3
    # 3 Vertical Glowing Power Level Bars
    for x_bar in [12, 15, 18]:
        for y_bar in range(13, 21):
            c[y_bar][x_bar] = C2
            c[y_bar][x_bar+1] = C3
    # Copper terminal pins on bottom
    for x in [12, 13, 18, 19]:
        c[25][x] = A3; c[26][x] = A4
    # Top connector socket
    c[7][15] = G3; c[7][16] = G3; c[8][15] = G4; c[8][16] = G4
    # Outline pass
    for y in range(1, h-1):
        for x in range(1, w-1):
            if c[y][x] != _:
                for dy, dx in [(-1,0), (1,0), (0,-1), (0,1)]:
                    if c[y+dy][x+dx] == _:
                        c[y+dy][x+dx] = O
    save_png(path, w, h, c)

def make_icon_basalt_shard(path):
    # Ancient Basalt Monolith Shard
    w, h = 32, 32
    c = create_canvas(w, h, _)
    # Angular crystalline jagged shard
    # Upper pinnacle
    c[5][16] = B4
    c[6][15] = B3; c[6][16] = B4; c[6][17] = B2
    c[7][15] = B3; c[7][16] = B3; c[7][17] = B1
    for y in range(8, 25):
        # Facets
        width_y = int(4.5 + 4.0 * (1.0 - abs(y - 16) / 10.0))
        for x in range(16 - width_y, 16 + width_y):
            if x < 16:
                c[y][x] = B3 if x == 16 - width_y else B2
            else:
                c[y][x] = B1 if x == 16 + width_y - 1 else B0
    # Specular ridge line
    for y in range(8, 24):
        c[y][15] = B4
    # Glowing Molten Amber Fracture Veins
    vein = [
        (10, 16, A3), (11, 16, A4), (12, 17, A4), (13, 17, A3),
        (14, 16, A4), (15, 16, AW), (16, 15, A4), (17, 15, A3),
        (18, 16, A4), (19, 17, A4), (20, 17, A3), (21, 16, A2)
    ]
    for vy, vx, col in vein:
        c[vy][vx] = col
    # Outline pass
    for y in range(1, h-1):
        for x in range(1, w-1):
            if c[y][x] != _:
                for dy, dx in [(-1,0), (1,0), (0,-1), (0,1)]:
                    if c[y+dy][x+dx] == _:
                        c[y+dy][x+dx] = O
    save_png(path, w, h, c)

if __name__ == '__main__':
    base = 'C:/Users/Isaac/kinetic-fps/textures/ui'
    icons = f'{base}/icons'

    print("Generating UI Textures...")
    make_window_bg(f'{base}/pixel_window_bg.png')
    make_slot_default(f'{base}/pixel_slot_default.png')
    make_slot_selected(f'{base}/pixel_slot_selected.png')
    make_slot_equipped_badge(f'{base}/pixel_slot_equipped_badge.png')
    make_btn_equip(f'{base}/btn_equip.png')
    make_btn_action(f'{base}/btn_action.png')
    make_btn_close(f'{base}/btn_close.png')
    make_turntable_frame(f'{base}/pixel_turntable_frame.png')
    make_hud_dock(f'{base}/pixel_hud_dock.png')
    make_hud_pip_active(f'{base}/hud_pip_active.png')
    make_hud_pip_inactive(f'{base}/hud_pip_inactive.png')

    print("Generating 32x32 Pixel Art Item Icons...")
    make_icon_blaster(f'{icons}/icon_blaster.png')
    make_icon_grenade(f'{icons}/icon_grenade.png')
    make_icon_dosimeter(f'{icons}/icon_dosimeter.png')
    make_icon_torch(f'{icons}/icon_torch.png')
    make_icon_med_injector(f'{icons}/icon_med_injector.png')
    make_icon_ammo_cell(f'{icons}/icon_ammo_cell.png')
    make_icon_basalt_shard(f'{icons}/icon_basalt_shard.png')

    print("ALL PIXEL ART ASSETS GENERATED SUCCESSFULLY!")
