import zlib
import struct
import math
import os

def save_png(filename, width, height, pixels):
    os.makedirs(os.path.dirname(os.path.abspath(filename)), exist_ok=True)
    raw_bytes = bytearray()
    for y in range(height):
        raw_bytes.append(0)
        for x in range(width):
            r, g, b, a = pixels[y][x]
            raw_bytes.extend([
                int(max(0, min(255, round(r)))),
                int(max(0, min(255, round(g)))),
                int(max(0, min(255, round(b)))),
                int(max(0, min(255, round(a))))
            ])

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

def blend_pixel(c, x, y, r, g, b, a):
    if x < 0 or x >= len(c[0]) or y < 0 or y >= len(c):
        return
    br, bg, bb, ba = c[y][x]
    alpha = a / 255.0
    out_a = alpha + (ba / 255.0) * (1.0 - alpha)
    if out_a <= 0: return
    out_r = (r * alpha + br * (ba / 255.0) * (1.0 - alpha)) / out_a
    out_g = (g * alpha + bg * (ba / 255.0) * (1.0 - alpha)) / out_a
    out_b = (b * alpha + bb * (ba / 255.0) * (1.0 - alpha)) / out_a
    c[y][x] = (out_r, out_g, out_b, out_a * 255.0)

def draw_circle(c, cx, cy, radius, col, fill=True):
    r, g, b, a = col
    rad_ceil = int(radius + 2)
    for y in range(int(cy - rad_ceil), int(cy + rad_ceil + 1)):
        for x in range(int(cx - rad_ceil), int(cx + rad_ceil + 1)):
            d = math.hypot(x - cx, y - cy)
            if fill:
                diff = d - radius
                if diff <= -0.5:
                    blend_pixel(c, x, y, r, g, b, a)
                elif diff < 0.5:
                    blend_pixel(c, x, y, r, g, b, a * (0.5 - diff))
            else:
                diff = abs(d - radius)
                if diff <= 0.5:
                    blend_pixel(c, x, y, r, g, b, a * (1.0 - diff * 2.0))

def draw_line(c, x0, y0, x1, y1, col, width=1.5):
    r, g, b, a = col
    dx = x1 - x0
    dy = y1 - y0
    length = math.hypot(dx, dy)
    if length == 0: return
    nx = -dy / length
    ny = dx / length
    steps = int(length * 2.5)
    for i in range(steps + 1):
        t = i / float(steps)
        px = x0 + dx * t
        py = y0 + dy * t
        w_steps = int(width * 2) + 1
        for w in range(-w_steps, w_steps + 1):
            offset = (w / float(w_steps)) * (width / 2.0)
            lx = int(round(px + nx * offset))
            ly = int(round(py + ny * offset))
            d = abs(offset) / (width / 2.0)
            alpha_f = max(0.0, 1.0 - d * d)
            blend_pixel(c, lx, ly, r, g, b, a * alpha_f)

def draw_round_rect(c, x, y, w, h, radius, col, fill=True):
    r, g, b, a = col
    for py in range(int(y), int(y + h)):
        for px in range(int(x), int(x + w)):
            # Distance from inner box
            dx = max(0, max(x + radius - px, px - (x + w - 1 - radius)))
            dy = max(0, max(y + radius - py, py - (y + h - 1 - radius)))
            d = math.hypot(dx, dy)
            if d <= radius - 0.5:
                blend_pixel(c, px, py, r, g, b, a)
            elif d < radius + 0.5:
                blend_pixel(c, px, py, r, g, b, a * (radius + 0.5 - d))

# ----------------- 2000s HORROR UI TEXTURES -----------------

def make_2000s_window_bg(path):
    # 128x128 9-slice: Brushed gunmetal tactical case
    w, h = 128, 128
    c = create_canvas(w, h, (14, 17, 21, 250))
    # Brushed metal subtle noise lines
    for y in range(h):
        for x in range(w):
            val = math.sin(x * 1.5 + y * 0.1) * 3.0 + math.sin(y * 0.8) * 2.0
            c[y][x] = (14 + val, 17 + val, 21 + val, 250)
    # Metallic bevel border
    for x in range(w):
        for thick in range(3):
            c[thick][x] = (65 - thick*10, 75 - thick*10, 90 - thick*10, 255)
            c[h - 1 - thick][x] = (8, 10, 12, 255)
    for y in range(h):
        for thick in range(3):
            c[y][thick] = (65 - thick*10, 75 - thick*10, 90 - thick*10, 255)
            c[y][w - 1 - thick] = (8, 10, 12, 255)
    # Heavy hex corner bolts (2000s survival case)
    for bx, by in [(9, 9), (w - 10, 9), (9, h - 10), (w - 10, h - 10)]:
        draw_circle(c, bx, by, 4.5, (10, 12, 14, 255))
        draw_circle(c, bx, by, 3.5, (50, 58, 68, 255))
        draw_circle(c, bx - 1, by - 1, 1.5, (140, 155, 175, 255))
    save_png(path, w, h, c)

def make_2000s_slot_default(path):
    # 64x64 Slot: Brushed steel chamfered frame with deep inner recessed shadow
    w, h = 64, 64
    c = create_canvas(w, h, (10, 12, 15, 240))
    # Outer dark shadow
    for y in range(h):
        for x in range(w):
            c[y][x] = (12, 14, 18, 240)
    # Beveled chamfer frame
    draw_round_rect(c, 2, 2, w - 4, h - 4, 4, (38, 44, 54, 255))
    draw_round_rect(c, 4, 4, w - 8, h - 8, 3, (16, 19, 24, 255))
    # Top-left highlight
    draw_line(c, 4, 4, w - 5, 4, (85, 98, 118, 200), 1.5)
    draw_line(c, 4, 4, 4, h - 5, (85, 98, 118, 200), 1.5)
    # Bottom-right shadow
    draw_line(c, 4, h - 5, w - 5, h - 5, (8, 9, 11, 240), 1.5)
    draw_line(c, w - 5, 4, w - 5, h - 5, (8, 9, 11, 240), 1.5)
    # Subtle matte carbon mesh in interior
    for y in range(8, h - 8):
        for x in range(8, w - 8):
            if (x + y) % 4 == 0:
                blend_pixel(c, x, y, 22, 26, 32, 70)
    save_png(path, w, h, c)

def make_2000s_slot_selected(path):
    # 64x64 Selected Slot: Smooth warm amber/golden rim glow with sleek corner brackets
    w, h = 64, 64
    c = create_canvas(w, h, (12, 14, 18, 240))
    draw_round_rect(c, 2, 2, w - 4, h - 4, 4, (38, 44, 54, 255))
    draw_round_rect(c, 4, 4, w - 8, h - 8, 3, (18, 22, 28, 255))
    # Golden amber glowing perimeter halo
    for y in range(h):
        for x in range(w):
            d = min(min(x, w - 1 - x), min(y, h - 1 - y))
            if 2 <= d <= 6:
                intensity = math.sin((d - 2) / 4.0 * math.pi)
                blend_pixel(c, x, y, 255, 184, 52, 140 * intensity)
    # Precision Machined Corner Brackets (Amber / Gold)
    b_len = 12
    # Top-Left
    draw_line(c, 4, 4, 4 + b_len, 4, (255, 215, 110, 255), 2.0)
    draw_line(c, 4, 4, 4, 4 + b_len, (255, 215, 110, 255), 2.0)
    # Top-Right
    draw_line(c, w - 5, 4, w - 5 - b_len, 4, (255, 215, 110, 255), 2.0)
    draw_line(c, w - 5, 4, w - 5, 4 + b_len, (255, 215, 110, 255), 2.0)
    # Bottom-Left
    draw_line(c, 4, h - 5, 4 + b_len, h - 5, (255, 215, 110, 255), 2.0)
    draw_line(c, 4, h - 5, 4, h - 5 - b_len, (255, 215, 110, 255), 2.0)
    # Bottom-Right
    draw_line(c, w - 5, h - 5, w - 5 - b_len, h - 5, (255, 215, 110, 255), 2.0)
    draw_line(c, w - 5, h - 5, w - 5, h - 5 - b_len, (255, 215, 110, 255), 2.0)
    save_png(path, w, h, c)

def make_2000s_slot_equipped(path):
    # 18x18 Sleek tactical phosphor-green diamond badge
    w, h = 18, 18
    c = create_canvas(w, h, (0,0,0,0))
    # Outer dark rim
    draw_line(c, 9, 2, 16, 9, (10, 20, 15, 255), 2.0)
    draw_line(c, 16, 9, 9, 16, (10, 20, 15, 255), 2.0)
    draw_line(c, 9, 16, 2, 9, (10, 20, 15, 255), 2.0)
    draw_line(c, 2, 9, 9, 2, (10, 20, 15, 255), 2.0)
    # Inner glowing emerald diamond
    draw_line(c, 9, 3, 15, 9, (60, 225, 140, 255), 1.5)
    draw_line(c, 15, 9, 9, 15, (60, 225, 140, 255), 1.5)
    draw_line(c, 9, 15, 3, 9, (60, 225, 140, 255), 1.5)
    draw_line(c, 3, 9, 9, 3, (60, 225, 140, 255), 1.5)
    # Center bright glint
    draw_circle(c, 9, 9, 2.5, (160, 255, 200, 255))
    save_png(path, w, h, c)

def make_2000s_button(path, icon_type):
    # 42x42 Sleek brushed metallic industrial push-button
    w, h = 42, 42
    c = create_canvas(w, h, (0,0,0,0))
    # Outer shadow
    draw_circle(c, 21, 22, 19.5, (8, 10, 12, 180))
    # Beveled rim
    draw_circle(c, 21, 21, 19.0, (48, 56, 68, 255))
    draw_circle(c, 21, 21, 17.5, (28, 33, 40, 255))
    # Specular ring
    draw_circle(c, 20, 20, 18.0, (110, 125, 148, 120), fill=False)
    cx, cy = 21, 21
    if icon_type == 'equip': # Tactical Crosshair in Emerald
        draw_circle(c, cx, cy, 8.0, (60, 225, 140, 240), fill=False)
        draw_line(c, cx - 12, cy, cx - 4, cy, (60, 225, 140, 240), 1.8)
        draw_line(c, cx + 4, cy, cx + 12, cy, (60, 225, 140, 240), 1.8)
        draw_line(c, cx, cy - 12, cx, cy - 4, (60, 225, 140, 240), 1.8)
        draw_line(c, cx, cy + 4, cx, cy + 12, (60, 225, 140, 240), 1.8)
        draw_circle(c, cx, cy, 1.8, (180, 255, 210, 255))
    elif icon_type == 'action': # Tactical Gear / Lightning in Amber
        coords = [(21, 10), (16, 21), (22, 21), (18, 32), (28, 19), (21, 19)]
        for i in range(len(coords)):
            p0 = coords[i]; p1 = coords[(i + 1) % len(coords)]
            draw_line(c, p0[0], p0[1], p1[0], p1[1], (255, 190, 60, 240), 2.0)
        draw_circle(c, cx, cy, 3.0, (255, 235, 150, 255))
    elif icon_type == 'close': # Hazard Crimson [X]
        draw_line(c, cx - 8, cy - 8, cx + 8, cy + 8, (240, 65, 80, 240), 2.5)
        draw_line(c, cx + 8, cy - 8, cx - 8, cy + 8, (240, 65, 80, 240), 2.5)
        draw_line(c, cx - 8, cy - 8, cx + 8, cy + 8, (255, 150, 160, 180), 1.2)
    save_png(path, w, h, c)

def make_2000s_turntable_frame(path):
    # 180x180 Sleek dark glass monitor with precision corner brackets
    w, h = 180, 180
    c = create_canvas(w, h, (10, 13, 17, 220))
    # Beveled frame
    draw_round_rect(c, 2, 2, w - 4, h - 4, 6, (40, 48, 58, 255))
    draw_round_rect(c, 4, 4, w - 8, h - 8, 4, (12, 15, 20, 240))
    # Subtle vignette gradient inside
    for y in range(4, h - 4):
        for x in range(4, w - 4):
            dx = (x - w / 2.0) / (w / 2.0)
            dy = (y - h / 2.0) / (h / 2.0)
            vig = 1.0 - math.sqrt(dx*dx + dy*dy) * 0.45
            vig = max(0.0, min(1.0, vig))
            c[y][x] = (12 * vig, 15 * vig, 20 * vig, 245)
    # Corner brackets (Brushed Steel)
    b_len = 16
    for bx, by, sx, sy in [(6, 6, 1, 1), (w - 7, 6, -1, 1), (6, h - 7, 1, -1), (w - 7, h - 7, -1, -1)]:
        draw_line(c, bx, by, bx + sx * b_len, by, (100, 118, 140, 240), 1.8)
        draw_line(c, bx, by, bx, by + sy * b_len, (100, 118, 140, 240), 1.8)
    save_png(path, w, h, c)

def make_2000s_hud_dock(path):
    # 76x76 HUD Dock: Smoked dark acrylic backing, slender metallic chamfers, recessed 64x64 slot
    w, h = 76, 76
    c = create_canvas(w, h, (10, 13, 18, 215))
    draw_round_rect(c, 2, 2, w - 4, h - 4, 6, (45, 54, 66, 255))
    draw_round_rect(c, 4, 4, w - 8, h - 8, 4, (14, 18, 24, 235))
    # Recessed inner slot 56x56
    draw_round_rect(c, 10, 8, 56, 52, 3, (10, 12, 16, 255))
    # Metallic edge highlight
    draw_line(c, 4, 4, w - 5, 4, (110, 128, 152, 180), 1.5)
    draw_line(c, 4, 4, 4, h - 5, (110, 128, 152, 180), 1.5)
    save_png(path, w, h, c)

def make_2000s_hud_pip(path, lit):
    w, h = 10, 5
    c = create_canvas(w, h, (0,0,0,0))
    if lit:
        # Glowing amber LED
        draw_round_rect(c, 0, 0, w, h, 2, (255, 175, 40, 255))
        draw_round_rect(c, 2, 1, w - 4, h - 2, 1, (255, 245, 190, 255))
    else:
        # Dark recessed LED
        draw_round_rect(c, 0, 0, w, h, 2, (20, 24, 30, 255))
        draw_round_rect(c, 1, 1, w - 2, h - 2, 1, (12, 15, 20, 255))
    save_png(path, w, h, c)

# ----------------- 64x64 SMOOTH 2000s HORROR ITEM ICONS -----------------

def make_2000s_icon_blaster(path):
    # Sleek 2000s Combat Handgun (Half-Life 2 / Doom 3 style)
    w, h = 64, 64
    c = create_canvas(w, h, (0,0,0,0))
    # Drop shadow
    draw_round_rect(c, 13, 24, 42, 13, 3, (0, 0, 0, 90))
    # Slide (machined steel)
    for y in range(21, 33):
        for x in range(12, 53):
            # Vertical gradient: highlight top, shadow bottom
            t = (y - 21) / 12.0
            val = int(85 - t * 45)
            blend_pixel(c, x, y, val, val + 5, val + 15, 255)
    # Specular slide top ridge
    draw_line(c, 14, 21, 51, 21, (180, 195, 220, 255), 1.5)
    draw_line(c, 14, 22, 51, 22, (120, 135, 160, 255), 1.0)
    # Muzzle tip
    draw_line(c, 52, 23, 52, 29, (40, 45, 55, 255), 2.0)
    draw_circle(c, 54, 26, 1.5, (255, 200, 80, 255)) # Energy pin
    # Slide serrations (rear grip slide grooves)
    for sx in [16, 19, 22, 25]:
        draw_line(c, sx, 23, sx, 30, (20, 22, 28, 255), 1.2)
    # Glowing internal power chamber (amber)
    draw_round_rect(c, 30, 25, 12, 5, 2, (255, 160, 30, 255))
    draw_round_rect(c, 32, 26, 8, 3, 1, (255, 230, 130, 255))
    # Ergonomic grip (dark tactical polymer)
    for gy in range(33, 52):
        gw = 11
        gx = int(17 + (gy - 33) * 0.45)
        for x in range(gx, gx + gw):
            # Checkered texture
            chk = 5 if (x + gy) % 2 == 0 else -5
            blend_pixel(c, x, gy, 32 + chk, 36 + chk, 42 + chk, 255)
    # Grip bevel highlight
    draw_line(c, 17, 33, 25, 51, (80, 90, 105, 220), 1.5)
    # Trigger guard & trigger
    draw_line(c, 29, 33, 34, 40, (50, 58, 70, 255), 1.8)
    draw_line(c, 34, 40, 28, 41, (50, 58, 70, 255), 1.8)
    draw_line(c, 28, 35, 30, 38, (160, 175, 195, 255), 1.8) # Silver trigger
    save_png(path, w, h, c)

def make_2000s_icon_grenade(path):
    # Heavy Fragmentation Grenade (Resident Evil 4 / F.E.A.R. style)
    w, h = 64, 64
    c = create_canvas(w, h, (0,0,0,0))
    # Drop shadow
    draw_circle(c, 32, 42, 17.0, (0, 0, 0, 90))
    # Segmented cast-iron grenade body (dark drab olive/steel)
    draw_circle(c, 32, 39, 15.0, (42, 52, 44, 255))
    # Radial Phong shading
    for y in range(24, 55):
        for x in range(17, 48):
            d = math.hypot(x - 27, y - 33) # light from top-left
            if d < 15.0:
                spec = max(0.0, 1.0 - d / 15.0)
                val = int(50 + spec * 70)
                blend_pixel(c, x, y, int(val * 0.8), val, int(val * 0.85), 255)
    # Segmentation grooves
    for y in [30, 36, 42, 48]:
        draw_line(c, 19, y, 45, y, (18, 22, 18, 220), 1.5)
    for x in [24, 32, 40]:
        draw_line(c, x, 26, x, 51, (18, 22, 18, 220), 1.5)
    # Fuse collar (brass/steel)
    draw_round_rect(c, 28, 17, 8, 8, 2, (120, 130, 145, 255))
    draw_line(c, 28, 17, 36, 17, (190, 205, 225, 255), 1.5)
    # Safety lever spoon (yellow zinc-chromate)
    draw_line(c, 34, 18, 44, 25, (220, 185, 45, 255), 2.5)
    draw_line(c, 44, 25, 44, 44, (200, 165, 40, 255), 2.2)
    # Arming pin pull-ring
    draw_circle(c, 24, 21, 5.0, (190, 205, 225, 255), fill=False)
    # Detonation status diode (red LED bloom)
    draw_circle(c, 32, 21, 2.5, (255, 60, 60, 255))
    draw_circle(c, 32, 21, 5.0, (255, 80, 80, 80), fill=False)
    save_png(path, w, h, c)

def make_2000s_icon_dosimeter(path):
    # Field Geiger Dosimeter (S.T.A.L.K.E.R. / Silent Hill style)
    w, h = 64, 64
    c = create_canvas(w, h, (0,0,0,0))
    # Drop shadow
    draw_round_rect(c, 18, 16, 28, 41, 4, (0, 0, 0, 90))
    # Rugged industrial hazard yellow/black body
    draw_round_rect(c, 16, 14, 28, 40, 4, (185, 145, 30, 255))
    draw_round_rect(c, 18, 16, 24, 36, 3, (215, 175, 40, 255))
    # Top-left metallic bevel
    draw_line(c, 16, 14, 44, 14, (255, 225, 100, 240), 1.5)
    draw_line(c, 16, 14, 16, 54, (255, 225, 100, 240), 1.5)
    # Analog meter window
    draw_round_rect(c, 20, 19, 20, 16, 3, (240, 245, 248, 255))
    # Meter scale & red hazard arc
    draw_circle(c, 30, 32, 9.0, (80, 90, 100, 180), fill=False)
    draw_line(c, 32, 22, 38, 24, (230, 50, 50, 255), 2.0)
    # Needle pointing towards red hazard zone
    draw_line(c, 30, 31, 35, 23, (20, 25, 30, 255), 1.5)
    # Chrome Sensor Probe Wand on right side
    draw_line(c, 47, 12, 47, 44, (180, 195, 215, 255), 2.5)
    draw_circle(c, 47, 10, 2.8, (220, 235, 255, 255))
    # Rotary knobs & switches
    draw_circle(c, 25, 43, 3.5, (40, 48, 58, 255))
    draw_circle(c, 35, 43, 3.5, (40, 48, 58, 255))
    # Glowing radiation LED (amber)
    draw_circle(c, 30, 49, 2.0, (255, 180, 40, 255))
    save_png(path, w, h, c)

def make_2000s_icon_torch(path):
    # Survival Magnesium Flare Torch (Silent Hill / Condemned style)
    w, h = 64, 64
    c = create_canvas(w, h, (0,0,0,0))
    # Drop shadow
    draw_line(c, 15, 54, 38, 31, (0, 0, 0, 80), 6.0)
    # Heavy pyrotechnic red cylinder
    draw_line(c, 13, 53, 35, 31, (185, 35, 45, 255), 6.0)
    draw_line(c, 12, 52, 34, 30, (240, 65, 75, 255), 2.5) # Specular highlight
    # Textured black grip tape on lower half
    draw_line(c, 13, 53, 24, 42, (30, 35, 42, 255), 6.5)
    for i in range(4):
        px = 14 + i * 2.5; py = 52 - i * 2.5
        draw_line(c, px - 2, py + 2, px + 2, py - 2, (60, 68, 80, 255), 1.2)
    # Metal flare nozzle collar
    draw_line(c, 34, 32, 38, 28, (170, 185, 205, 255), 7.0)
    # Glowing Flare Flame (Smooth anti-aliased gradient)
    for rad in range(16, 1, -1):
        t = rad / 16.0
        # Color transition: Core white -> Yellow -> Orange -> Deep Crimson
        if t < 0.25: col = (255, 255, 250, 255)
        elif t < 0.5: col = (255, 220, 90, 240)
        elif t < 0.75: col = (255, 130, 30, 180)
        else: col = (220, 40, 30, 80)
        fx = 43 + math.sin(rad * 0.5) * 1.5
        fy = 22 - (16 - rad) * 0.9
        draw_circle(c, fx, fy, rad * 0.9, col)
    # Embers
    draw_circle(c, 46, 7, 1.2, (255, 200, 80, 255))
    draw_circle(c, 52, 12, 1.5, (255, 140, 40, 240))
    save_png(path, w, h, c)

def make_2000s_icon_med_injector(path):
    # Pneumatic Stim Hypo Injector (Doom 3 / System Shock 2 style)
    w, h = 64, 64
    c = create_canvas(w, h, (0,0,0,0))
    # Drop shadow
    draw_line(c, 18, 48, 48, 18, (0, 0, 0, 80), 6.0)
    # Chrome Plunger & Handle (top-right)
    draw_line(c, 44, 22, 51, 15, (180, 195, 215, 255), 6.0)
    draw_line(c, 48, 14, 54, 20, (210, 225, 245, 255), 2.5)
    # Glass Ampoule Chamber (middle diagonal)
    draw_line(c, 28, 38, 43, 23, (40, 60, 50, 200), 7.5)
    # Glowing Emerald Bioluminescent Stim Fluid
    draw_line(c, 29, 37, 41, 25, (40, 225, 120, 255), 5.5)
    draw_line(c, 28, 36, 40, 24, (160, 255, 200, 255), 2.0) # Fluid reflection glint
    # Lower metal collar & stainless nozzle
    draw_line(c, 22, 44, 27, 39, (160, 175, 195, 255), 6.0)
    # Precision hypodermic needle tip
    draw_line(c, 14, 52, 21, 45, (230, 240, 255, 255), 1.8)
    draw_circle(c, 13, 53, 1.0, (255, 255, 255, 255))
    save_png(path, w, h, c)

def make_2000s_icon_ammo_cell(path):
    # High-Density Munitions Power Cell (Half-Life 2 / Dead Space style)
    w, h = 64, 64
    c = create_canvas(w, h, (0,0,0,0))
    # Drop shadow
    draw_round_rect(c, 18, 16, 28, 38, 4, (0, 0, 0, 90))
    # Dark composite ribbed casing
    draw_round_rect(c, 16, 14, 28, 38, 4, (28, 33, 42, 255))
    draw_line(c, 16, 14, 44, 14, (90, 105, 130, 255), 1.5)
    draw_line(c, 16, 14, 16, 52, (90, 105, 130, 255), 1.5)
    # 3 Glowing Cyan/Blue Capacitive Energy Bars
    for i in range(3):
        by = 22 + i * 8
        draw_round_rect(c, 21, by, 18, 5, 2, (15, 60, 95, 255))
        draw_round_rect(c, 22, by + 1, 16, 3, 1, (50, 200, 255, 255))
        draw_line(c, 23, by + 1, 37, by + 1, (190, 240, 255, 255), 1.0)
    # Copper terminal pins on bottom
    draw_line(c, 22, 52, 26, 52, (235, 160, 50, 255), 2.5)
    draw_line(c, 34, 52, 38, 52, (235, 160, 50, 255), 2.5)
    save_png(path, w, h, c)

def make_2000s_icon_basalt_shard(path):
    # Ancient Obsidian Shard Relic (S.T.A.L.K.E.R. / Silent Hill style)
    w, h = 64, 64
    c = create_canvas(w, h, (0,0,0,0))
    # Drop shadow
    draw_circle(c, 32, 42, 14.0, (0, 0, 0, 90))
    # Faceted obsidian mineral
    pts = [(32, 10), (44, 26), (40, 50), (28, 54), (18, 36), (22, 18)]
    # Left facet (dark violet/grey)
    for y in range(12, 54):
        for x in range(18, 44):
            dx = x - 32; dy = y - 32
            d = math.hypot(dx, dy)
            if d < 18:
                val = int(25 + (x - 18) * 1.5)
                c[y][x] = (val + 5, val, val + 15, 255)
    # Chiseled ridge highlights
    draw_line(c, 32, 10, 31, 52, (140, 135, 165, 255), 1.8)
    draw_line(c, 32, 10, 44, 26, (110, 105, 135, 255), 1.5)
    draw_line(c, 44, 26, 40, 50, (60, 55, 75, 255), 1.5)
    # Glowing Molten Amber Fracture Vein down center
    vein_pts = [(32, 14), (30, 20), (33, 26), (29, 34), (32, 42), (31, 48)]
    for i in range(len(vein_pts) - 1):
        p0 = vein_pts[i]; p1 = vein_pts[i+1]
        draw_line(c, p0[0], p0[1], p1[0], p1[1], (255, 175, 40, 255), 2.2)
        draw_line(c, p0[0], p0[1], p1[0], p1[1], (255, 240, 180, 255), 1.0)
    save_png(path, w, h, c)

if __name__ == '__main__':
    base = 'C:/Users/Isaac/kinetic-fps/textures/ui'
    icons = f'{base}/icons'

    print("Generating 2000s Horror UI Textures...")
    make_2000s_window_bg(f'{base}/case_window_bg.png')
    make_2000s_slot_default(f'{base}/slot_2000s_default.png')
    make_2000s_slot_selected(f'{base}/slot_2000s_selected.png')
    make_2000s_slot_equipped(f'{base}/slot_2000s_equipped.png')
    make_2000s_button(f'{base}/btn_2000s_equip.png', 'equip')
    make_2000s_button(f'{base}/btn_2000s_action.png', 'action')
    make_2000s_button(f'{base}/btn_2000s_close.png', 'close')
    make_2000s_turntable_frame(f'{base}/turntable_frame_2000s.png')
    make_2000s_hud_dock(f'{base}/hud_dock_2000s.png')
    make_2000s_hud_pip(f'{base}/hud_pip_lit.png', True)
    make_2000s_hud_pip(f'{base}/hud_pip_unlit.png', False)

    print("Generating 64x64 2000s Horror Item Icons...")
    make_2000s_icon_blaster(f'{icons}/icon_blaster.png')
    make_2000s_icon_grenade(f'{icons}/icon_grenade.png')
    make_2000s_icon_dosimeter(f'{icons}/icon_dosimeter.png')
    make_2000s_icon_torch(f'{icons}/icon_torch.png')
    make_2000s_icon_med_injector(f'{icons}/icon_med_injector.png')
    make_2000s_icon_ammo_cell(f'{icons}/icon_ammo_cell.png')
    make_2000s_icon_basalt_shard(f'{icons}/icon_basalt_shard.png')

    print("ALL 2000s HORROR ASSETS GENERATED SUCCESSFULLY!")
