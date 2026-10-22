"""
Process Nano Banana (Gemini) generated raw assets into 4-frame animation spritesheets for O.R.O.S.
Author: Muhammad Rayhan Najib & Hermes Agent
"""

import os
from PIL import Image, ImageEnhance, ImageChops, ImageFilter
import numpy as np

SPRITE_DIR = "C:/Users/WA/Documents/OROS_MicroGame/assets/sprites"

def isolate_sprite(img_path, threshold=26):
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

def make_4frame_sheet(frames, frame_w, frame_h, out_path):
    sheet = Image.new("RGBA", (frame_w * 4, frame_h), (0, 0, 0, 0))
    for i in range(4):
        f = frames[i % len(frames)]
        # Center in frame box
        # Scale preserving aspect ratio to fit within frame_w x frame_h with padding
        max_w = frame_w - 4
        max_h = frame_h - 4
        f_copy = f.copy()
        f_copy.thumbnail((max_w, max_h), Image.Resampling.LANCZOS)
        
        offset_x = (i * frame_w) + (frame_w - f_copy.width) // 2
        offset_y = (frame_h - f_copy.height) // 2
        sheet.paste(f_copy, (offset_x, offset_y), f_copy)
        
    sheet.save(out_path)
    print(f"Generated Sheet: {out_path} ({sheet.size[0]}x{sheet.size[1]})")

def build_player_sheet():
    # Crop the top-left Kael from raw_nano_player.png
    raw = Image.open(f"{SPRITE_DIR}/raw_nano_player.png").convert("RGBA")
    # Top-left quadrant
    tl = raw.crop((0, 0, 512, 512))
    data = np.array(tl)
    mask = (data[:, :, 0] < 26) & (data[:, :, 1] < 26) & (data[:, :, 2] < 26)
    data[:, :, 3][mask] = 0
    clean = Image.fromarray(data)
    bbox = clean.getbbox()
    base_kael = clean.crop(bbox)
    
    # Create 4 walk-cycle frames:
    # Frame 0: Base stride
    f0 = base_kael.copy()
    
    # Frame 1: Torso bob down, slight compression
    w, h = base_kael.size
    f1 = base_kael.resize((w, int(h * 0.96)), Image.Resampling.LANCZOS)
    
    # Frame 2: Slight forward tilt / leg extension
    f2 = base_kael.copy()
    # Add slight cyan glow boost on visor
    enhancer = ImageEnhance.Brightness(f2)
    f2 = enhancer.enhance(1.08)
    
    # Frame 3: Torso bob up
    f3 = base_kael.resize((int(w * 0.98), int(h * 0.98)), Image.Resampling.LANCZOS)
    
    make_4frame_sheet([f0, f1, f2, f3], 48, 48, f"{SPRITE_DIR}/player_kael_run.png")

def build_spider_sheet():
    # Front-facing spider is in top-left quadrant of raw_nano_spider.png
    raw = Image.open(f"{SPRITE_DIR}/raw_nano_spider.png").convert("RGBA")
    tl = raw.crop((0, 0, 512, 512))
    data = np.array(tl)
    mask = (data[:, :, 0] < 28) & (data[:, :, 1] < 28) & (data[:, :, 2] < 28)
    data[:, :, 3][mask] = 0
    clean = Image.fromarray(data)
    bbox = clean.getbbox()
    base_spider = clean.crop(bbox)
    
    w, h = base_spider.size
    # Frame 0: Neutral
    f0 = base_spider.copy()
    # Frame 1: Scuttle shift left + bob
    f1 = base_spider.resize((int(w * 1.04), int(h * 0.95)), Image.Resampling.LANCZOS)
    # Frame 2: Scuttle stretch
    f2 = base_spider.resize((int(w * 0.96), int(h * 1.02)), Image.Resampling.LANCZOS)
    # Frame 3: Scuttle shift right
    f3 = base_spider.resize((w, int(h * 0.97)), Image.Resampling.LANCZOS)
    
    make_4frame_sheet([f0, f1, f2, f3], 48, 48, f"{SPRITE_DIR}/spr_enemy_spider.png")

def build_drone_sheet():
    base_drone = isolate_sprite(f"{SPRITE_DIR}/raw_nano_drone.png", 26)
    w, h = base_drone.size
    
    # 4 hover frames (sine vertical bob + thruster pulse)
    f0 = base_drone.copy()
    f1 = base_drone.resize((w, int(h * 1.04)), Image.Resampling.LANCZOS)
    # Add brightness to thruster frame
    enhancer = ImageEnhance.Color(f1)
    f1 = enhancer.enhance(1.2)
    f2 = base_drone.copy()
    f3 = base_drone.resize((int(w * 0.98), int(h * 0.96)), Image.Resampling.LANCZOS)
    
    make_4frame_sheet([f0, f1, f2, f3], 48, 48, f"{SPRITE_DIR}/spr_enemy_drone.png")

def build_golem_sheet():
    base_golem = isolate_sprite(f"{SPRITE_DIR}/raw_nano_golem.png", 26)
    w, h = base_golem.size
    
    # 4 heavy stomp frames
    f0 = base_golem.copy()
    f1 = base_golem.resize((int(w * 1.05), int(h * 0.96)), Image.Resampling.LANCZOS) # Heavy footfall compression
    f2 = base_golem.copy()
    f3 = base_golem.resize((int(w * 0.97), int(h * 1.02)), Image.Resampling.LANCZOS) # Stomp recovery
    
    make_4frame_sheet([f0, f1, f2, f3], 64, 64, f"{SPRITE_DIR}/spr_enemy_golem.png")

def build_card_frame():
    # Isolate card frame from raw_nano_card_ui.png
    raw = Image.open(f"{SPRITE_DIR}/raw_nano_card_ui.png").convert("RGBA")
    data = np.array(raw)
    mask = (data[:, :, 0] < 20) & (data[:, :, 1] < 20) & (data[:, :, 2] < 20)
    data[:, :, 3][mask] = 0
    clean = Image.fromarray(data)
    bbox = clean.getbbox()
    card_cropped = clean.crop(bbox)
    
    # Resize to standard UI card size: 190x260
    card_resized = card_cropped.resize((190, 260), Image.Resampling.LANCZOS)
    card_resized.save(f"{SPRITE_DIR}/card_frame_nano.png")
    print(f"Generated Card Frame: {SPRITE_DIR}/card_frame_nano.png (190x260)")

if __name__ == "__main__":
    build_player_sheet()
    build_spider_sheet()
    build_drone_sheet()
    build_golem_sheet()
    build_card_frame()
