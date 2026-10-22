"""
Generate Authentic Retro Pixel Art Assets for O.R.O.S.
- Pixel Art Logo O.R.O.S.
- Pixel Art Background (Cyberpunk Foundry Grid)
- Pixel Art UI Buttons (Normal, Hover, Pressed)
- Pixel Art Card Frame
- Pixel Art Heroes: Kael, Vex, Brutus
- Pixel Art Weapons: Revolver, Shotgun, SMG
- Pixel Art Enemies: Viper, Turret, Boss Colossus
- Pixel Art Pickup: Medkit
Author: Muhammad Rayhan Najib & Hermes Agent
"""

import math
from PIL import Image, ImageDraw, ImageFont, ImageEnhance
import numpy as np

SPRITE_DIR = "C:/Users/WA/Documents/OROS_MicroGame/assets/sprites"

def create_pixel_logo():
    # 240x60 pixel art logo for O.R.O.S.
    img = Image.new("RGBA", (240, 60), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Draw chunky pixel letter blocks
    # Colors: Outer border (0, 20, 40), Cyan fill (0, 230, 255), Highlights (200, 255, 255), Gold accents (255, 210, 40)
    
    # We will draw block letters for O . R . O . S .
    def draw_pixel_rect(x, y, w, h, fill, border=None):
        if border:
            draw.rectangle([x-1, y-1, x+w, y+h], fill=border)
        draw.rectangle([x, y, x+w-1, y+h-1], fill=fill)
        
    # Letter O (x=16)
    draw_pixel_rect(16, 10, 36, 36, (0, 210, 255), (10, 30, 60))
    draw_pixel_rect(24, 18, 20, 20, (6, 12, 22), (10, 30, 60))
    # Dot
    draw_pixel_rect(58, 38, 8, 8, (255, 210, 40), (40, 30, 0))
    
    # Letter R (x=72)
    draw_pixel_rect(72, 10, 36, 36, (0, 210, 255), (10, 30, 60))
    draw_pixel_rect(80, 18, 12, 10, (6, 12, 22), (10, 30, 60))
    draw_pixel_rect(80, 32, 14, 14, (6, 12, 22), (10, 30, 60))
    draw_pixel_rect(88, 24, 14, 22, (6, 12, 22), (10, 30, 60))
    # Dot
    draw_pixel_rect(114, 38, 8, 8, (255, 210, 40), (40, 30, 0))
    
    # Letter O (x=128)
    draw_pixel_rect(128, 10, 36, 36, (0, 210, 255), (10, 30, 60))
    draw_pixel_rect(136, 18, 20, 20, (6, 12, 22), (10, 30, 60))
    # Dot
    draw_pixel_rect(170, 38, 8, 8, (255, 210, 40), (40, 30, 0))
    
    # Letter S (x=184)
    draw_pixel_rect(184, 10, 36, 36, (0, 210, 255), (10, 30, 60))
    draw_pixel_rect(184, 18, 26, 6, (6, 12, 22), (10, 30, 60))
    draw_pixel_rect(194, 26, 26, 6, (6, 12, 22), (10, 30, 60))
    
    # Subtitle highlight line
    draw_pixel_rect(16, 52, 208, 4, (255, 210, 40), (50, 40, 0))
    
    img.save(f"{SPRITE_DIR}/pixel_logo_oros.png")
    print("Created pixel_logo_oros.png")

def create_pixel_menu_bg():
    # 640x360 retro pixel art background: Dark industrial foundry floor with perspective neon grid & vents
    w, h = 640, 360
    img = Image.new("RGBA", (w, h), (10, 14, 22, 255))
    draw = ImageDraw.Draw(img)
    
    # Subtle dark blue horizontal scanlines
    for y in range(0, h, 4):
        draw.line([0, y, w, y], fill=(14, 20, 32, 255))
        
    # Perspective grid lines receding towards center horizon (cy=120)
    cy = 110
    cx = w // 2
    for x in range(0, w + 1, 32):
        draw.line([x, h, cx + (x - cx) // 4, cy], fill=(24, 45, 75, 180), width=1)
        
    for y in range(cy, h, 18):
        draw.line([0, y, w, y], fill=(22, 40, 68, 160), width=1)
        
    # Industrial pipes and conduits in background (top)
    draw.rectangle([0, 0, w, 40], fill=(6, 8, 14, 255))
    draw.line([0, 40, w, 40], fill=(0, 180, 220, 200), width=2)
    # Steam vent grates
    for x in range(30, w, 70):
        draw.rectangle([x, 10, x + 40, 30], fill=(16, 22, 34, 255), outline=(0, 200, 240, 120))
        for vy in range(14, 28, 4):
            draw.line([x + 4, vy, x + 36, vy], fill=(30, 45, 65, 255))
            
    # Soft dark vignette overlay
    vignette = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    v_draw = ImageDraw.Draw(vignette)
    for r in range(min(w, h) // 2, 0, -10):
        alpha = int((1.0 - (r / (min(w, h) / 2.0))) * 180)
        v_draw.rectangle([cx - r * 1.8, h // 2 - r, cx + r * 1.8, h // 2 + r], fill=(4, 6, 12, alpha))
    img = Image.alpha_composite(img, vignette)
    
    img.save(f"{SPRITE_DIR}/pixel_menu_bg.png")
    print("Created pixel_menu_bg.png")

def create_pixel_buttons():
    # 3-slice / 9-slice pixel buttons (180x36)
    # 1. Normal: Slate border, dark cyan interior
    normal = Image.new("RGBA", (180, 36), (0, 0, 0, 0))
    d_norm = ImageDraw.Draw(normal)
    d_norm.rectangle([0, 0, 179, 35], fill=(12, 18, 28, 240), outline=(28, 64, 105, 255))
    d_norm.rectangle([2, 2, 177, 33], outline=(18, 38, 65, 255)) # Bevel inner
    # Corner rivets
    for cx, cy in [(4, 4), (175, 4), (4, 31), (175, 31)]:
        d_norm.point((cx, cy), fill=(0, 210, 255, 220))
    normal.save(f"{SPRITE_DIR}/pixel_btn_normal.png")
    
    # 2. Hover: Electric cyan border, glowing highlight
    hover = Image.new("RGBA", (180, 36), (0, 0, 0, 0))
    d_hov = ImageDraw.Draw(hover)
    d_hov.rectangle([0, 0, 179, 35], fill=(18, 32, 52, 250), outline=(0, 230, 255, 255))
    d_hov.rectangle([2, 2, 177, 33], outline=(40, 140, 210, 255))
    for cx, cy in [(4, 4), (175, 4), (4, 31), (175, 31)]:
        d_hov.point((cx, cy), fill=(255, 220, 60, 255))
    hover.save(f"{SPRITE_DIR}/pixel_btn_hover.png")
    
    # 3. Pressed: Sunken amber border
    pressed = Image.new("RGBA", (180, 36), (0, 0, 0, 0))
    d_prs = ImageDraw.Draw(pressed)
    d_prs.rectangle([0, 0, 179, 35], fill=(8, 12, 20, 255), outline=(255, 200, 40, 255))
    d_prs.rectangle([2, 2, 177, 33], outline=(140, 100, 10, 255))
    pressed.save(f"{SPRITE_DIR}/pixel_btn_pressed.png")
    print("Created pixel buttons (normal, hover, pressed)")

def create_pixel_heroes():
    # 3 Distinct Playable Heroes (48x48 x 4 frames)
    # 1. KAEL (CyberSmith) - Trenchcoat, cyan visor, dual plasma revolver
    # Already created or refined! Let's ensure it has proper cyan energy.
    
    # 2. VEX (Phase Assassin) - Sleek ninja silhouette, red scarf, speed runner
    vex_sheet = Image.new("RGBA", (48 * 4, 48), (0, 0, 0, 0))
    d_vex = ImageDraw.Draw(vex_sheet)
    for i in range(4):
        ox = i * 48
        bob = (1 if i % 2 == 0 else -2)
        # Head & Visor
        d_vex.rectangle([ox + 20, 8 + bob, ox + 28, 16 + bob], fill=(20, 24, 32), outline=(10, 12, 16))
        d_vex.line([ox + 22, 12 + bob, ox + 27, 12 + bob], fill=(255, 40, 60), width=2) # Red visor eye
        # Flowing red scarf
        scarf_flutter = (i * 2) % 6
        d_vex.polygon([(ox + 18, 14 + bob), (ox + 8 - scarf_flutter, 18 + bob + scarf_flutter), (ox + 16, 18 + bob)], fill=(255, 50, 70))
        # Sleek dark suit
        d_vex.rectangle([ox + 19, 17 + bob, ox + 29, 28 + bob], fill=(30, 36, 48), outline=(15, 18, 25))
        # Legs stride
        if i % 2 == 0:
            d_vex.line([ox + 20, 28 + bob, ox + 16, 42], fill=(20, 24, 32), width=3) # left leg
            d_vex.line([ox + 28, 28 + bob, ox + 32, 42], fill=(20, 24, 32), width=3) # right leg
        else:
            d_vex.line([ox + 21, 28 + bob, ox + 21, 40], fill=(20, 24, 32), width=3)
            d_vex.line([ox + 27, 28 + bob, ox + 27, 40], fill=(20, 24, 32), width=3)
        # Arm & Energy Dagger
        d_vex.line([ox + 28, 20 + bob, ox + 36, 22 + bob], fill=(40, 48, 64), width=2)
        d_vex.line([ox + 36, 22 + bob, ox + 42, 20 + bob], fill=(255, 60, 80), width=2) # Red laser dagger
    vex_sheet.save(f"{SPRITE_DIR}/player_vex_run.png")
    print("Created player_vex_run.png")
    
    # 3. BRUTUS (Juggernaut) - Heavy armored cyborg, orange reactor chest, heavy boots
    brutus_sheet = Image.new("RGBA", (48 * 4, 48), (0, 0, 0, 0))
    d_brut = ImageDraw.Draw(brutus_sheet)
    for i in range(4):
        ox = i * 48
        bob = (0 if i % 2 == 0 else -1)
        # Bulky Head & Helmet
        d_brut.rectangle([ox + 18, 6 + bob, ox + 30, 14 + bob], fill=(60, 65, 75), outline=(25, 28, 35))
        d_brut.rectangle([ox + 21, 9 + bob, ox + 27, 12 + bob], fill=(255, 160, 30)) # Orange visor
        # Heavy Pauldrons
        d_brut.rectangle([ox + 12, 12 + bob, ox + 18, 20 + bob], fill=(75, 80, 95), outline=(30, 35, 45))
        d_brut.rectangle([ox + 30, 12 + bob, ox + 36, 20 + bob], fill=(75, 80, 95), outline=(30, 35, 45))
        # Torso with Reactor Furnace
        d_brut.rectangle([ox + 16, 14 + bob, ox + 32, 28 + bob], fill=(45, 50, 60), outline=(20, 22, 28))
        d_brut.ellipse([ox + 20, 18 + bob, ox + 28, 25 + bob], fill=(255, 140, 20), outline=(255, 220, 60))
        # Heavy hydraulic legs
        leg_spread = 2 if i % 2 == 0 else 0
        d_brut.rectangle([ox + 16 - leg_spread, 28 + bob, ox + 22 - leg_spread, 42], fill=(50, 55, 65), outline=(20, 22, 28))
        d_brut.rectangle([ox + 26 + leg_spread, 28 + bob, ox + 32 + leg_spread, 42], fill=(50, 55, 65), outline=(20, 22, 28))
    brutus_sheet.save(f"{SPRITE_DIR}/player_brutus_run.png")
    print("Created player_brutus_run.png")

def create_pixel_weapons():
    # 1. Shotgun (30x12)
    shotgun = Image.new("RGBA", (30, 12), (0, 0, 0, 0))
    d_sg = ImageDraw.Draw(shotgun)
    d_sg.rectangle([2, 4, 10, 10], fill=(85, 50, 25)) # Wooden stock
    d_sg.rectangle([10, 3, 20, 9], fill=(65, 75, 85)) # Receiver
    d_sg.rectangle([20, 4, 28, 7], fill=(120, 130, 145)) # Twin barrel
    d_sg.rectangle([14, 8, 18, 11], fill=(40, 45, 50)) # Pump
    shotgun.save(f"{SPRITE_DIR}/spr_shotgun.png")
    
    # 2. Cyber SMG (22x14)
    smg = Image.new("RGBA", (22, 14), (0, 0, 0, 0))
    d_smg = ImageDraw.Draw(smg)
    d_smg.rectangle([2, 2, 16, 8], fill=(30, 35, 45), outline=(0, 210, 255))
    d_smg.rectangle([16, 4, 20, 6], fill=(0, 230, 255)) # Muzzle
    d_smg.rectangle([6, 8, 10, 13], fill=(20, 25, 30)) # Extended magazine
    smg.save(f"{SPRITE_DIR}/spr_smg.png")
    print("Created spr_shotgun.png and spr_smg.png")

def create_pixel_enemies():
    # 1. Cyber Viper / Stalker (48x48 x 4 frames) - Fast zig-zagging serpentine mech
    viper_sheet = Image.new("RGBA", (48 * 4, 48), (0, 0, 0, 0))
    d_v = ImageDraw.Draw(viper_sheet)
    for i in range(4):
        ox = i * 48
        wave = int(math.sin(i * (math.pi / 2.0)) * 4)
        # Serrated head
        d_v.polygon([(ox + 34, 24 + wave), (ox + 22, 18 + wave), (ox + 22, 30 + wave)], fill=(120, 25, 40), outline=(200, 30, 50))
        d_v.point((ox + 28, 22 + wave), fill=(255, 230, 60)) # Glowing yellow eye
        # Segmented body segments
        for s in range(3):
            sx = ox + 18 - s * 7
            sy = 24 - wave * (1 if s % 2 == 0 else -1)
            d_v.rectangle([sx, sy - 3, sx + 5, sy + 3], fill=(80, 20, 30), outline=(150, 40, 50))
    viper_sheet.save(f"{SPRITE_DIR}/spr_enemy_viper.png")
    print("Created spr_enemy_viper.png")
    
    # 2. Laser Sentinel Turret (48x48 x 4 frames) - Stationary/slow tripod turret with charging eye
    turret_sheet = Image.new("RGBA", (48 * 4, 48), (0, 0, 0, 0))
    d_t = ImageDraw.Draw(turret_sheet)
    for i in range(4):
        ox = i * 48
        # Tripod base
        d_t.polygon([(ox + 12, 38), (ox + 24, 28), (ox + 36, 38)], fill=(40, 48, 60), outline=(20, 25, 32))
        # Central eye chassis
        eye_rad = 7 + (1 if i % 2 == 0 else -1)
        d_t.ellipse([ox + 24 - eye_rad, 22 - eye_rad, ox + 24 + eye_rad, 22 + eye_rad], fill=(50, 58, 72), outline=(0, 200, 240))
        # Glowing aperture lens (pulsing red)
        glow_c = (255, 40, 60) if i < 2 else (255, 120, 140)
        d_t.ellipse([ox + 21, 19, ox + 27, 25], fill=glow_c)
    turret_sheet.save(f"{SPRITE_DIR}/spr_enemy_turret.png")
    print("Created spr_enemy_turret.png")
    
    # 3. BOSS: COLOSSUS-OMEGA (96x96 x 4 frames) - Massive bipedal war mech
    boss_sheet = Image.new("RGBA", (96 * 4, 96), (0, 0, 0, 0))
    d_b = ImageDraw.Draw(boss_sheet)
    for i in range(4):
        ox = i * 96
        bob = (0 if i % 2 == 0 else -2)
        # Giant Armored Torso (50x45)
        d_b.rectangle([ox + 23, 18 + bob, ox + 73, 58 + bob], fill=(45, 50, 62), outline=(15, 18, 25))
        # Glowing Core Reactor (24x24)
        d_b.ellipse([ox + 36, 28 + bob, ox + 60, 52 + bob], fill=(255, 50, 40), outline=(255, 210, 50))
        d_b.ellipse([ox + 42, 34 + bob, ox + 54, 46 + bob], fill=(255, 240, 180)) # White-hot center
        # Twin Missile Pods on Shoulders
        d_b.rectangle([ox + 14, 12 + bob, ox + 26, 32 + bob], fill=(65, 70, 85), outline=(20, 24, 30))
        d_b.rectangle([ox + 70, 12 + bob, ox + 82, 32 + bob], fill=(65, 70, 85), outline=(20, 24, 30))
        for my in range(16, 28, 4):
            d_b.point((ox + 18, my + bob), fill=(255, 180, 20))
            d_b.point((ox + 22, my + bob), fill=(255, 180, 20))
            d_b.point((ox + 74, my + bob), fill=(255, 180, 20))
            d_b.point((ox + 78, my + bob), fill=(255, 180, 20))
        # Giant Hydraulic Legs
        l_off = 3 if i % 2 == 0 else -3
        d_b.rectangle([ox + 26 + l_off, 58 + bob, ox + 38 + l_off, 88], fill=(35, 40, 50), outline=(15, 18, 22))
        d_b.rectangle([ox + 58 - l_off, 58 + bob, ox + 70 - l_off, 88], fill=(35, 40, 50), outline=(15, 18, 22))
        # Feet treads
        d_b.rectangle([ox + 22 + l_off, 86, ox + 42 + l_off, 92], fill=(20, 24, 30))
        d_b.rectangle([ox + 54 - l_off, 86, ox + 74 - l_off, 92], fill=(20, 24, 30))
    boss_sheet.save(f"{SPRITE_DIR}/spr_boss_colossus.png")
    print("Created spr_boss_colossus.png (384x96)")

def create_pixel_pickup():
    # Nano-Medkit Pickup (24x24) - Neon green cross crate
    medkit = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    d_m = ImageDraw.Draw(medkit)
    # Crate chassis
    d_m.rectangle([2, 2, 21, 21], fill=(16, 32, 24), outline=(30, 220, 90))
    d_m.rectangle([4, 4, 19, 19], outline=(20, 90, 45))
    # Green cross
    d_m.rectangle([10, 6, 13, 17], fill=(40, 255, 110))
    d_m.rectangle([6, 10, 17, 13], fill=(40, 255, 110))
    medkit.save(f"{SPRITE_DIR}/spr_pickup_medkit.png")
    print("Created spr_pickup_medkit.png")

if __name__ == "__main__":
    create_pixel_logo()
    create_pixel_menu_bg()
    create_pixel_buttons()
    create_pixel_heroes()
    create_pixel_weapons()
    create_pixel_enemies()
    create_pixel_pickup()
