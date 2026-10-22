"""
Craft Smooth, Fluid 4-Frame Walking & Idle Spritesheets for O.R.O.S.
Author: Muhammad Rayhan Najib & Hermes Agent
"""

import os
import math
from PIL import Image, ImageEnhance, ImageChops, ImageFilter
import numpy as np

SPRITE_DIR = "C:/Users/WA/Documents/OROS_MicroGame/assets/sprites"

def isolate_clean_rgba(img_path, threshold=24):
    img = Image.open(img_path).convert("RGBA")
    data = np.array(img)
    # Check if r, g, b are all below threshold
    r, g, b, a = data[:, :, 0], data[:, :, 1], data[:, :, 2], data[:, :, 3]
    mask = (r < threshold) & (g < threshold) & (b < threshold)
    data[:, :, 3][mask] = 0
    clean = Image.fromarray(data)
    bbox = clean.getbbox()
    if bbox:
        return clean.crop(bbox)
    return clean

def build_smooth_kael_sheet():
    # Crop the base Kael from top-left of raw_nano_player
    raw = Image.open(f"{SPRITE_DIR}/raw_nano_player.png").convert("RGBA")
    tl = raw.crop((0, 0, 512, 512))
    data = np.array(tl)
    mask = (data[:, :, 0] < 26) & (data[:, :, 1] < 26) & (data[:, :, 2] < 26)
    data[:, :, 3][mask] = 0
    clean = Image.fromarray(data)
    bbox = clean.getbbox()
    base = clean.crop(bbox)
    
    # Target frame size: 48x48. Character height ~40px.
    base_resized = base.resize((32, 40), Image.Resampling.LANCZOS)
    bw, bh = base_resized.size
    
    # Split into Torso (top 24px) and Legs (bottom 16px)
    torso = base_resized.crop((0, 0, bw, 24))
    legs = base_resized.crop((0, 24, bw, bh))
    
    frames = []
    
    # Frame 0: Contact Step A (Right foot forward, left foot back)
    f0 = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    # Paste legs with stride spread (shear/stretch)
    legs0 = legs.resize((int(bw * 1.15), 16), Image.Resampling.LANCZOS)
    f0.paste(legs0, ((48 - legs0.width) // 2 + 1, 32), legs0)
    # Paste torso with slight forward dip
    f0.paste(torso, ((48 - bw) // 2, 8), torso)
    frames.append(f0)
    
    # Frame 1: Passing Step A (Body rises 2px, legs centered)
    f1 = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    legs1 = legs.resize((int(bw * 0.9), 16), Image.Resampling.LANCZOS)
    f1.paste(legs1, ((48 - legs1.width) // 2, 30), legs1)
    f1.paste(torso, ((48 - bw) // 2, 6), torso) # 2px higher bob
    frames.append(f1)
    
    # Frame 2: Contact Step B (Left foot forward, right foot back, coat sway)
    f2 = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    legs2 = legs.resize((int(bw * 1.15), 16), Image.Resampling.LANCZOS)
    # Mirror legs slightly for opposite stride
    legs2_flip = legs2.transpose(Image.FLIP_LEFT_RIGHT)
    f2.paste(legs2_flip, ((48 - legs2_flip.width) // 2 - 1, 32), legs2_flip)
    f2.paste(torso, ((48 - bw) // 2, 8), torso)
    frames.append(f2)
    
    # Frame 3: Passing Step B (Body rises 2px, return stride)
    f3 = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    legs3 = legs.resize((int(bw * 0.92), 16), Image.Resampling.LANCZOS)
    f3.paste(legs3, ((48 - legs3.width) // 2, 30), legs3)
    f3.paste(torso, ((48 - bw) // 2, 6), torso)
    frames.append(f3)
    
    # Assemble sheet
    sheet = Image.new("RGBA", (48 * 4, 48), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        sheet.paste(frame, (i * 48, 0), frame)
    sheet.save(f"{SPRITE_DIR}/player_kael_run.png")
    print(f"Generated Smooth Kael Sheet: {SPRITE_DIR}/player_kael_run.png (192x48)")

def build_smooth_spider_sheet():
    raw = Image.open(f"{SPRITE_DIR}/raw_nano_spider.png").convert("RGBA")
    tl = raw.crop((0, 0, 512, 512))
    data = np.array(tl)
    mask = (data[:, :, 0] < 28) & (data[:, :, 1] < 28) & (data[:, :, 2] < 28)
    data[:, :, 3][mask] = 0
    clean = Image.fromarray(data)
    bbox = clean.getbbox()
    base = clean.crop(bbox).resize((40, 32), Image.Resampling.LANCZOS)
    bw, bh = base.size
    
    frames = []
    # 4 scuttle gait frames with alternating leg splay
    for i in range(4):
        f = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
        # Tripod gait stretch/compression
        s_w = 1.0 + (0.1 if i % 2 == 0 else -0.08)
        s_h = 1.0 - (0.08 if i % 2 == 0 else -0.06)
        scaled = base.resize((int(bw * s_w), int(bh * s_h)), Image.Resampling.LANCZOS)
        # Glow pulse on red eyes
        if i == 1 or i == 3:
            enh = ImageEnhance.Color(scaled)
            scaled = enh.enhance(1.3)
        ox = (48 - scaled.width) // 2
        oy = (48 - scaled.height) // 2 + (1 if i % 2 == 0 else -1)
        f.paste(scaled, (ox, oy), scaled)
        frames.append(f)
        
    sheet = Image.new("RGBA", (48 * 4, 48), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        sheet.paste(frame, (i * 48, 0), frame)
    sheet.save(f"{SPRITE_DIR}/spr_enemy_spider.png")
    print(f"Generated Smooth Spider Sheet: {SPRITE_DIR}/spr_enemy_spider.png (192x48)")

def build_smooth_drone_sheet():
    base = isolate_clean_rgba(f"{SPRITE_DIR}/raw_nano_drone.png", 26).resize((38, 34), Image.Resampling.LANCZOS)
    bw, bh = base.size
    
    frames = []
    # 4 hover frames: vertical sine float + thruster exhaust flare
    for i in range(4):
        f = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
        float_y = int(math.sin(i * (math.pi / 2.0)) * 3.0)
        drone_copy = base.copy()
        if i == 1: # Peak thrust
            enh = ImageEnhance.Brightness(drone_copy)
            drone_copy = enh.enhance(1.15)
        ox = (48 - bw) // 2
        oy = (48 - bh) // 2 + float_y
        f.paste(drone_copy, (ox, oy), drone_copy)
        frames.append(f)
        
    sheet = Image.new("RGBA", (48 * 4, 48), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        sheet.paste(frame, (i * 48, 0), frame)
    sheet.save(f"{SPRITE_DIR}/spr_enemy_drone.png")
    print(f"Generated Smooth Drone Sheet: {SPRITE_DIR}/spr_enemy_drone.png (192x48)")

def build_smooth_golem_sheet():
    base = isolate_clean_rgba(f"{SPRITE_DIR}/raw_nano_golem.png", 26).resize((46, 52), Image.Resampling.LANCZOS)
    bw, bh = base.size
    
    frames = []
    # 4 heavy stomp frames: heavy ground impact compression & recoil
    for i in range(4):
        f = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
        if i == 0:
            # Stomp left
            scaled = base.resize((int(bw * 1.08), int(bh * 0.94)), Image.Resampling.LANCZOS)
            oy = 64 - scaled.height - 2
        elif i == 1:
            # Rise recoil
            scaled = base.resize((int(bw * 0.96), int(bh * 1.02)), Image.Resampling.LANCZOS)
            oy = 64 - scaled.height - 5
        elif i == 2:
            # Stomp right
            scaled = base.resize((int(bw * 1.08), int(bh * 0.94)), Image.Resampling.LANCZOS)
            oy = 64 - scaled.height - 2
        else:
            # Rise recoil
            scaled = base.resize((int(bw * 0.96), int(bh * 1.02)), Image.Resampling.LANCZOS)
            oy = 64 - scaled.height - 5
            
        ox = (64 - scaled.width) // 2
        f.paste(scaled, (ox, oy), scaled)
        frames.append(f)
        
    sheet = Image.new("RGBA", (64 * 4, 64), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        sheet.paste(frame, (i * 64, 0), frame)
    sheet.save(f"{SPRITE_DIR}/spr_enemy_golem.png")
    print(f"Generated Smooth Golem Sheet: {SPRITE_DIR}/spr_enemy_golem.png (256x64)")

if __name__ == "__main__":
    build_smooth_kael_sheet()
    build_smooth_spider_sheet()
    build_smooth_drone_sheet()
    build_smooth_golem_sheet()
