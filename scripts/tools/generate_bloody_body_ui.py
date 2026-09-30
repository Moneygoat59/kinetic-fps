import zlib
import struct
import math
import random
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

def add_blood_splatter(c, cx, cy, radius, num_droplets=22, seed=42):
    rng = random.Random(seed)
    # Core coagulated dark pool
    for _ in range(int(radius * 16)):
        ang = rng.uniform(0, math.pi * 2)
        dist = (rng.uniform(0, 1.0) ** 0.6) * radius
        bx = cx + math.cos(ang) * dist
        by = cy + math.sin(ang) * dist
        cr = rng.uniform(1.0, 3.2)
        # Wet crimson into dark liver
        blend_pixel(c, int(bx), int(by), rng.uniform(90, 140), rng.uniform(8, 18), rng.uniform(12, 25), rng.uniform(180, 245))
    # Dried coagulated perimeter ring
    for _ in range(int(radius * 12)):
        ang = rng.uniform(0, math.pi * 2)
        dist = rng.uniform(radius * 0.8, radius * 1.4)
        bx = cx + math.cos(ang) * dist
        by = cy + math.sin(ang) * dist
        cr = rng.uniform(0.8, 2.0)
        draw_circle(c, bx, by, cr, (40, 5, 8, rng.uniform(150, 220)))
    # Satellite droplets and trailing drips
    for _ in range(num_droplets):
        ang = rng.uniform(0, math.pi * 2)
        dist = rng.uniform(radius * 1.2, radius * 3.2)
        dx = cx + math.cos(ang) * dist
        dy = cy + math.sin(ang) * dist
        dr = rng.uniform(0.8, 2.4)
        draw_circle(c, dx, dy, dr, (125, 14, 20, rng.uniform(190, 255)))
        # Downward gravity drip trail
        if rng.random() > 0.35:
            tail_len = rng.uniform(3, 10)
            draw_line(c, dx, dy, dx, dy + tail_len, (65, 7, 11, 200), 1.0)

# ----------------- GROSS BLOODY TEXTURES -----------------

def make_bloody_autopsy_bg(path):
    # 540x270 Distressed, blood-soaked autopsy table / morgue slab
    w, h = 540, 270
    c = create_canvas(w, h, (18, 14, 16, 252))
    rng = random.Random(1337)

    # Grungy metal / oxidized bone texture with directional scratches
    for y in range(h):
        for x in range(w):
            val = math.sin(x * 0.15 + y * 0.08) * 4.0 + math.sin((x - y) * 0.2) * 3.0
            noise = rng.uniform(-4, 4)
            c[y][x] = (22 + val + noise, 18 + val * 0.8 + noise, 19 + val * 0.7 + noise, 252)

    # Dark clotted pools and splatters across the slab
    splatters = [
        (90, 75, 34, 28, 101),
        (230, 160, 48, 36, 202),
        (380, 80, 40, 30, 303),
        (470, 200, 32, 24, 404),
        (150, 220, 28, 20, 505),
        (310, 45, 22, 16, 606)
    ]
    for sx, sy, srad, sdrop, sseed in splatters:
        add_blood_splatter(c, sx, sy, srad, sdrop, sseed)

    # Bloody handprint smear on right side (classic 2000s horror trope!)
    # Palm
    draw_circle(c, 440, 110, 16, (85, 10, 15, 160))
    # 5 Smudged bloody fingers dragging downwards
    fingers = [(428, 88), (435, 82), (442, 80), (449, 83), (456, 92)]
    for fx, fy in fingers:
        draw_line(c, fx, fy + 14, fx, fy, (95, 12, 18, 180), 4.5)
        draw_line(c, fx, fy + 14, fx + rng.uniform(-2, 2), fy + 32, (60, 8, 12, 120), 3.0)

    # Dark oxidized beveled frame with grime
    for x in range(w):
        for t in range(4):
            c[t][x] = (45 - t*8, 32 - t*6, 30 - t*6, 255)
            c[h - 1 - t][x] = (10, 6, 8, 255)
    for y in range(h):
        for t in range(4):
            c[y][t] = (45 - t*8, 32 - t*6, 30 - t*6, 255)
            c[y][w - 1 - t] = (10, 6, 8, 255)

    save_png(path, w, h, c)

def make_body_silhouette(path):
    # 180x230 Anatomical Human Body Outline with Outstretched Hands
    w, h = 180, 230
    c = create_canvas(w, h, (0, 0, 0, 0))
    bone_col = (195, 180, 165, 210)  # Eerie surgical bone white
    vein_col = (140, 25, 35, 140)    # Visceral dark red vein
    target_col = (255, 60, 75, 240)  # Glowing arterial red socket

    cx = 90
    # Head & Cranium
    draw_circle(c, cx, 24, 11, bone_col, fill=False)
    draw_circle(c, cx, 24, 10, (40, 10, 14, 120), fill=True) # Faint skull shadow
    # Neck
    draw_line(c, cx - 4, 35, cx - 4, 43, bone_col, 1.8)
    draw_line(c, cx + 4, 35, cx + 4, 43, bone_col, 1.8)

    # Torso & Ribcage outline
    draw_line(c, cx - 4, 43, cx - 22, 52, bone_col, 2.0) # Shoulders
    draw_line(c, cx + 4, 43, cx + 22, 52, bone_col, 2.0)
    # Spine (vertebrae ticks)
    for sp in range(45, 125, 8):
        draw_line(c, cx - 3, sp, cx + 3, sp, bone_col, 1.2)
    # Ribcage arcs
    for ry in [58, 68, 78, 88]:
        rw = 18 - (ry - 58) * 0.15
        draw_line(c, cx - rw, ry, cx, ry - 3, bone_col, 1.4)
        draw_line(c, cx + rw, ry, cx, ry - 3, bone_col, 1.4)
    # Torso side contours
    draw_line(c, cx - 22, 52, cx - 16, 95, bone_col, 1.8)
    draw_line(c, cx + 22, 52, cx + 16, 95, bone_col, 1.8)
    # Pelvis & Waist
    draw_line(c, cx - 16, 95, cx - 20, 122, bone_col, 2.0)
    draw_line(c, cx + 16, 95, cx + 20, 122, bone_col, 2.0)
    draw_line(c, cx - 20, 122, cx, 130, bone_col, 2.0)
    draw_line(c, cx + 20, 122, cx, 130, bone_col, 2.0)

    # Right Arm & Outstretched Hand (Viewer's Left)
    draw_line(c, cx - 22, 52, cx - 36, 85, bone_col, 2.2)  # Upper Arm
    draw_line(c, cx - 36, 85, cx - 48, 125, bone_col, 2.0) # Forearm
    # Hand palm & open fingers
    draw_circle(c, cx - 52, 134, 4.5, bone_col, fill=False)
    for f in range(-2, 3):
        draw_line(c, cx - 52, 134, cx - 52 + f * 3, 145, bone_col, 1.4)

    # Left Arm & Outstretched Hand (Viewer's Right)
    draw_line(c, cx + 22, 52, cx + 36, 85, bone_col, 2.2)
    draw_line(c, cx + 36, 85, cx + 48, 125, bone_col, 2.0)
    draw_circle(c, cx + 52, 134, 4.5, bone_col, fill=False)
    for f in range(-2, 3):
        draw_line(c, cx + 52, 134, cx + 52 + f * 3, 145, bone_col, 1.4)

    # Legs
    # Right Leg
    draw_line(c, cx - 15, 126, cx - 18, 172, bone_col, 2.2) # Thigh
    draw_line(c, cx - 18, 172, cx - 17, 218, bone_col, 2.0) # Shin
    draw_line(c, cx - 17, 218, cx - 23, 224, bone_col, 2.0) # Foot
    # Left Leg
    draw_line(c, cx + 15, 126, cx + 18, 172, bone_col, 2.2)
    draw_line(c, cx + 18, 172, cx + 17, 218, bone_col, 2.0)
    draw_line(c, cx + 17, 218, cx + 23, 224, bone_col, 2.0)

    # Bloodied anatomical grab target sockets with pulse crosshairs!
    # Sockets:
    # 0: Right Hand (Weapon Slot 0) at (cx - 52, 138)
    # 1: Left Hand (Torch Slot 1) at (cx + 52, 138)
    # 2: Torso / Chest (Grenade Slot 2) at (cx, 72)
    # 3: Waist / Holster (Dosimeter Slot 3) at (cx, 112)
    # 4: Right Thigh (Med Injector Slot 4) at (cx - 18, 160)
    # 5: Left Thigh (Ammo Cell Slot 5) at (cx + 18, 160)
    # 6: Head / Cranium (Basalt Relic Slot 6) at (cx, 24)
    sockets = [
        (cx - 52, 138), (cx + 52, 138), (cx, 72),
        (cx, 112), (cx - 18, 160), (cx + 18, 160), (cx, 24)
    ]
    for sx, sy in sockets:
        draw_circle(c, sx, sy, 7.5, (160, 20, 30, 90), fill=True)
        draw_circle(c, sx, sy, 6.5, target_col, fill=False)
        draw_circle(c, sx, sy, 2.0, (255, 160, 170, 255), fill=True)

    save_png(path, w, h, c)

def make_bloody_slot_default(path):
    # 54x54 Distressed oxidized dark iron frame with dried blood encrusted corners
    w, h = 54, 54
    c = create_canvas(w, h, (14, 12, 14, 240))
    # Beveled iron frame
    for y in range(h):
        for x in range(w):
            c[y][x] = (16, 13, 15, 240)
    draw_line(c, 2, 2, w - 3, 2, (50, 42, 45, 255), 2.0)
    draw_line(c, 2, 2, 2, h - 3, (50, 42, 45, 255), 2.0)
    draw_line(c, 2, h - 3, w - 3, h - 3, (8, 6, 8, 255), 2.0)
    draw_line(c, w - 3, 2, w - 3, h - 3, (8, 6, 8, 255), 2.0)
    # Dried blood encrusted corners
    add_blood_splatter(c, 7, 7, 7.0, 5, 11)
    add_blood_splatter(c, w - 8, h - 8, 6.0, 4, 22)
    save_png(path, w, h, c)

def make_bloody_slot_selected(path):
    # 54x54 Pulsating arterial crimson border with wet blood splatters
    w, h = 54, 54
    c = create_canvas(w, h, (20, 10, 12, 245))
    # Glowing blood red frame
    draw_line(c, 2, 2, w - 3, 2, (225, 35, 50, 255), 2.5)
    draw_line(c, 2, 2, 2, h - 3, (225, 35, 50, 255), 2.5)
    draw_line(c, 2, h - 3, w - 3, h - 3, (180, 20, 35, 255), 2.5)
    draw_line(c, w - 3, 2, w - 3, h - 3, (180, 20, 35, 255), 2.5)
    # Corner brackets (arterial crimson / bone highlight)
    b_len = 10
    draw_line(c, 4, 4, 4 + b_len, 4, (255, 110, 125, 255), 2.0)
    draw_line(c, 4, 4, 4, 4 + b_len, (255, 110, 125, 255), 2.0)
    draw_line(c, w - 5, 4, w - 5 - b_len, 4, (255, 110, 125, 255), 2.0)
    draw_line(c, w - 5, 4, w - 5, 4 + b_len, (255, 110, 125, 255), 2.0)
    draw_line(c, 4, h - 5, 4 + b_len, h - 5, (255, 110, 125, 255), 2.0)
    draw_line(c, 4, h - 5, 4, h - 5 - b_len, (255, 110, 125, 255), 2.0)
    draw_line(c, w - 5, h - 5, w - 5 - b_len, h - 5, (255, 110, 125, 255), 2.0)
    draw_line(c, w - 5, h - 5, w - 5, h - 5 - b_len, (255, 110, 125, 255), 2.0)
    add_blood_splatter(c, w / 2.0, h / 2.0, 10.0, 8, 33)
    save_png(path, w, h, c)

def make_bloody_slot_equipped(path):
    # 18x18 Visceral blood/bone anatomical gripper icon
    w, h = 18, 18
    c = create_canvas(w, h, (0,0,0,0))
    # Blood pool
    draw_circle(c, 9, 9, 7.5, (140, 18, 28, 220))
    draw_circle(c, 9, 9, 5.0, (230, 45, 60, 255))
    draw_circle(c, 9, 9, 2.2, (255, 210, 220, 255))
    save_png(path, w, h, c)

def make_bloody_button(path, btn_type):
    # 40x40 Blood-stained surgical push-button
    w, h = 40, 40
    c = create_canvas(w, h, (0,0,0,0))
    draw_circle(c, 20, 20, 18.0, (30, 15, 18, 240))
    draw_circle(c, 20, 20, 16.5, (18, 10, 12, 255))
    draw_circle(c, 20, 20, 16.5, (95, 20, 28, 200), fill=False)
    add_blood_splatter(c, 14, 14, 6.0, 4, 77)
    cx, cy = 20, 20
    if btn_type == 'equip': # Anatomical Hand Gripper Symbol
        draw_circle(c, cx, cy, 6.5, (240, 45, 60, 240), fill=False)
        draw_line(c, cx - 9, cy, cx + 9, cy, (240, 45, 60, 240), 1.8)
        draw_line(c, cx, cy - 9, cx, cy + 9, (240, 45, 60, 240), 1.8)
        draw_circle(c, cx, cy, 2.0, (255, 200, 210, 255))
    elif btn_type == 'action': # Visceral Slash / Suture Symbol
        draw_line(c, cx - 8, cy + 8, cx + 8, cy - 8, (255, 180, 50, 240), 2.2)
        draw_line(c, cx - 4, cy - 2, cx + 2, cy + 4, (255, 180, 50, 240), 2.0)
    elif btn_type == 'close': # Carved Bone [X] with blood
        draw_line(c, cx - 7, cy - 7, cx + 7, cy + 7, (235, 40, 55, 240), 2.4)
        draw_line(c, cx + 7, cy - 7, cx - 7, cy + 7, (235, 40, 55, 240), 2.4)
    save_png(path, w, h, c)

def make_bloody_turntable_frame(path):
    # 180x180 Autopsy glass examination frame with blood streaks
    w, h = 180, 180
    c = create_canvas(w, h, (14, 10, 12, 220))
    # Beveled iron rim
    draw_line(c, 2, 2, w - 3, 2, (45, 30, 35, 255), 2.0)
    draw_line(c, 2, 2, 2, h - 3, (45, 30, 35, 255), 2.0)
    draw_line(c, 2, h - 3, w - 3, h - 3, (10, 6, 8, 255), 2.0)
    draw_line(c, w - 3, 2, w - 3, h - 3, (10, 6, 8, 255), 2.0)
    # Blood streaks dripping down from the top edge
    add_blood_splatter(c, 40, 10, 12.0, 10, 88)
    add_blood_splatter(c, 140, 8, 14.0, 12, 99)
    draw_line(c, 40, 10, 40, 48, (80, 10, 15, 160), 2.0)
    draw_line(c, 140, 8, 140, 65, (80, 10, 15, 160), 2.5)
    save_png(path, w, h, c)

def make_bloody_hud_dock(path):
    # 80x80 HUD Dock: Blood-stained dark vignette backing with anatomical hand grips
    w, h = 80, 80
    c = create_canvas(w, h, (14, 8, 10, 215))
    # Blood splatter on edge
    add_blood_splatter(c, 20, 20, 16.0, 12, 101)
    add_blood_splatter(c, 62, 62, 14.0, 10, 202)
    # Slender dark red iron border
    draw_line(c, 2, 2, w - 3, 2, (80, 18, 25, 255), 1.8)
    draw_line(c, 2, 2, 2, h - 3, (80, 18, 25, 255), 1.8)
    draw_line(c, 2, h - 3, w - 3, h - 3, (30, 6, 10, 255), 1.8)
    draw_line(c, w - 3, 2, w - 3, h - 3, (30, 6, 10, 255), 1.8)
    # Subtle inner recessed item cradle
    draw_circle(c, 40, 36, 26.0, (10, 6, 8, 240))
    save_png(path, w, h, c)

def make_bloody_pip(path, lit):
    # Blood droplet pip (lit: arterial crimson drop; unlit: dark scab drop)
    w, h = 10, 8
    c = create_canvas(w, h, (0,0,0,0))
    if lit:
        draw_circle(c, 5, 5, 3.8, (240, 35, 50, 255))
        draw_circle(c, 4, 4, 1.5, (255, 180, 190, 255)) # Wet glint
        draw_line(c, 5, 1, 5, 5, (220, 25, 40, 255), 1.5)
    else:
        draw_circle(c, 5, 5, 3.2, (35, 8, 12, 230))
        draw_line(c, 5, 2, 5, 5, (25, 6, 8, 200), 1.2)
    save_png(path, w, h, c)

if __name__ == '__main__':
    base = 'C:/Users/Isaac/kinetic-fps/textures/ui'
    print("Generating Gross Bloody Horror UI & Body Outline Assets...")
    make_bloody_autopsy_bg(f'{base}/bloody_autopsy_bg.png')
    make_body_silhouette(f'{base}/body_silhouette.png')
    make_bloody_slot_default(f'{base}/bloody_slot_default.png')
    make_bloody_slot_selected(f'{base}/bloody_slot_selected.png')
    make_bloody_slot_equipped(f'{base}/bloody_slot_equipped.png')
    make_bloody_button(f'{base}/bloody_btn_equip.png', 'equip')
    make_bloody_button(f'{base}/bloody_btn_action.png', 'action')
    make_bloody_button(f'{base}/bloody_btn_close.png', 'close')
    make_bloody_turntable_frame(f'{base}/bloody_turntable_frame.png')
    make_bloody_hud_dock(f'{base}/bloody_hud_dock.png')
    make_bloody_pip(f'{base}/bloody_pip_lit.png', True)
    make_bloody_pip(f'{base}/bloody_pip_unlit.png', False)
    print("ALL GROSS BLOODY ASSETS GENERATED SUCCESSFULLY!")
