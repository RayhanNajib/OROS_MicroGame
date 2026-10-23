"""
Asset Generator for O.R.O.S. 5-Stage Nightmare Progression & Cyber Armory Marketplace
Author: Muhammad Rayhan Najib & Hermes Agent
"""

import math
import os
from PIL import Image, ImageDraw, ImageEnhance

SPRITE_DIR = "C:/Users/WA/Documents/OROS_MicroGame/assets/sprites"
UI_DIR = f"{SPRITE_DIR}/ui"
SKIN_DIR = f"{SPRITE_DIR}/skins"
os.makedirs(UI_DIR, exist_ok=True)
os.makedirs(SKIN_DIR, exist_ok=True)

# ==============================================================================
# 1. ASYMMETRIC TECH-PANEL & BUTTON GENERATION
# ==============================================================================

def create_asymmetric_button(w, h, state="normal"):
    # Chamfered 45-deg top-left (cut=8) and bottom-right (cut=8)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cut = 8
    
    # Outer polygon points
    points = [
        (cut, 0),
        (w - 1, 0),
        (w - 1, h - 1 - cut),
        (w - 1 - cut, h - 1),
        (0, h - 1),
        (0, cut)
    ]
    
    if state == "normal":
        bg_col = (13, 20, 32, 245)
        border_col = (0, 184, 212, 255)
        accent_col = (0, 230, 255, 200)
    elif state == "hover":
        bg_col = (23, 37, 59, 255)
        border_col = (0, 240, 255, 255)
        accent_col = (255, 170, 0, 255)
    else: # pressed
        bg_col = (7, 10, 16, 255)
        border_col = (255, 210, 48, 255)
        accent_col = (255, 210, 48, 255)
        
    draw.polygon(points, fill=bg_col, outline=border_col)
    
    # Inner tech accent line along top-right & bottom-left
    draw.line([(cut + 4, 3), (w - 5, 3)], fill=accent_col, width=1)
    draw.line([(w - 4, 4), (w - 4, h - 1 - cut - 3)], fill=accent_col, width=1)
    
    # Tech notch / rivet node at chamfered corners
    draw.rectangle([cut - 2, 2, cut, 4], fill=accent_col)
    draw.rectangle([w - 1 - cut, h - 5, w - 1 - cut + 2, h - 3], fill=accent_col)
    
    return img

btn_norm = create_asymmetric_button(180, 44, "normal")
btn_norm.save(f"{UI_DIR}/btn_asym_normal.png")

btn_hov = create_asymmetric_button(180, 44, "hover")
btn_hov.save(f"{UI_DIR}/btn_asym_hover.png")

btn_prs = create_asymmetric_button(180, 44, "pressed")
btn_prs.save(f"{UI_DIR}/btn_asym_pressed.png")
print("Created asymmetric tech buttons (normal, hover, pressed)")

# ==============================================================================
# 2. MARKETPLACE SKINS (HEROES & WEAPONS)
# ==============================================================================

def create_recolored_hero(base_path, out_path, color_map):
    if not os.path.exists(base_path): return
    img = Image.open(base_path).convert("RGBA")
    data = img.getdata()
    new_data = []
    for item in data:
        # Check matching color ranges and replace
        r, g, b, a = item
        replaced = False
        for src_rgb, dst_rgb in color_map.items():
            if abs(r - src_rgb[0]) < 25 and abs(g - src_rgb[1]) < 25 and abs(b - src_rgb[2]) < 25:
                new_data.append((dst_rgb[0], dst_rgb[1], dst_rgb[2], a))
                replaced = True
                break
        if not replaced:
            new_data.append(item)
    img.putdata(new_data)
    img.save(out_path)
    print(f"Saved skin: {out_path}")

# Kael Crimson Anvil (Red/Gold theme)
create_recolored_hero(
    f"{SPRITE_DIR}/player_kael_run.png",
    f"{SKIN_DIR}/player_kael_crimson.png",
    {
        (0, 210, 255): (255, 45, 60),   # Cyan visor -> Crimson visor
        (30, 36, 48): (65, 20, 25),     # Dark coat -> Dark burgundy
        (255, 210, 40): (255, 215, 60)  # Gold trim
    }
)

# Vex Toxic Mantis (Neon Green theme)
create_recolored_hero(
    f"{SPRITE_DIR}/player_vex_run.png",
    f"{SKIN_DIR}/player_vex_toxic.png",
    {
        (255, 40, 60): (40, 255, 110),   # Red eye -> Neon Green
        (255, 50, 70): (30, 220, 90),    # Red scarf -> Poison Green
        (30, 36, 48): (20, 38, 28)       # Suit -> Bio Dark
    }
)

# Brutus Golden Fortress (Polished Brass theme)
create_recolored_hero(
    f"{SPRITE_DIR}/player_brutus_run.png",
    f"{SKIN_DIR}/player_brutus_gold.png",
    {
        (60, 65, 75): (160, 130, 50),   # Steel -> Burnished Gold
        (75, 80, 95): (200, 165, 65),   # Pauldrons -> Gold plate
        (255, 140, 20): (0, 230, 255)   # Reactor -> Cyan Core
    }
)

# ==============================================================================
# 3. WEAPON SKINS
# ==============================================================================

def create_weapon_skins():
    # 1. Gold Sovereign Revolver
    rev = Image.open(f"{SPRITE_DIR}/spr_revolver.png").convert("RGBA")
    data = rev.getdata()
    new_data = []
    for r, g, b, a in data:
        if a > 0 and (r > 40 or g > 40):
            new_data.append((255, 210, 45, a))
        else:
            new_data.append((r, g, b, a))
    rev.putdata(new_data)
    rev.save(f"{SKIN_DIR}/spr_revolver_gold.png")

    # 2. Cyber Blast Shotgun (Cyan neon rails)
    sg = Image.open(f"{SPRITE_DIR}/spr_shotgun.png").convert("RGBA")
    data = sg.getdata()
    new_data = []
    for r, g, b, a in data:
        if a > 0 and r > 70:
            new_data.append((0, 230, 255, a))
        else:
            new_data.append((r, g, b, a))
    sg.putdata(new_data)
    sg.save(f"{SKIN_DIR}/spr_shotgun_cyber.png")

    # 3. Hyper Violet SMG
    smg = Image.open(f"{SPRITE_DIR}/spr_smg.png").convert("RGBA")
    data = smg.getdata()
    new_data = []
    for r, g, b, a in data:
        if a > 0 and (r > 30 or b > 40):
            new_data.append((210, 40, 255, a))
        else:
            new_data.append((r, g, b, a))
    smg.putdata(new_data)
    smg.save(f"{SKIN_DIR}/spr_smg_violet.png")
    print("Created weapon skins (gold revolver, cyber shotgun, violet smg)")

create_weapon_skins()

# ==============================================================================
# 4. CUSTOM DROP LOOT GEMS (MARKETPLACE REWARD)
# ==============================================================================

def create_custom_loot():
    # 1. Battery Core (Yellow Hex Cell)
    bat = Image.new("RGBA", (18, 18), (0, 0, 0, 0))
    d_bat = ImageDraw.Draw(bat)
    d_bat.rectangle([4, 2, 13, 15], fill=(30, 35, 45), outline=(255, 210, 40))
    d_bat.rectangle([6, 0, 11, 2], fill=(255, 210, 40)) # Terminal cap
    d_bat.rectangle([6, 5, 11, 12], fill=(255, 220, 60)) # Glowing charge
    bat.save(f"{SKIN_DIR}/spr_gem_battery.png")

    # 2. Emerald Crystal Shard (Green Hex Crystal)
    eme = Image.new("RGBA", (18, 18), (0, 0, 0, 0))
    d_eme = ImageDraw.Draw(eme)
    d_eme.polygon([(9, 1), (16, 6), (16, 12), (9, 17), (2, 12), (2, 6)], fill=(30, 220, 90), outline=(150, 255, 180))
    d_eme.polygon([(9, 4), (13, 7), (13, 11), (9, 14), (5, 11), (5, 7)], fill=(60, 255, 130))
    eme.save(f"{SKIN_DIR}/spr_gem_emerald.png")
    print("Created custom drop loot skins (battery, emerald)")

create_custom_loot()

# ==============================================================================
# 5. NEW ENEMIES & STAGE BOSSES (FOR 5 STAGES)
# ==============================================================================

def create_stage_enemies_and_bosses():
    # A. Stage 2 Objective: Power Core Defense Tower (48x80)
    tower = Image.new("RGBA", (48, 80), (0, 0, 0, 0))
    d_tow = ImageDraw.Draw(tower)
    # Heavy base
    d_tow.rectangle([6, 60, 41, 78], fill=(35, 42, 55), outline=(15, 20, 28))
    d_tow.line([10, 72, 37, 72], fill=(255, 210, 30), width=3) # Hazard yellow band
    # Tower central spire
    d_tow.rectangle([14, 18, 33, 60], fill=(45, 54, 70), outline=(20, 25, 35))
    # Glowing plasma containment column (pulsing cyan)
    d_tow.rectangle([18, 22, 29, 56], fill=(0, 220, 255), outline=(180, 255, 255))
    # Top emitter sphere
    d_tow.ellipse([12, 4, 35, 22], fill=(25, 32, 45), outline=(0, 240, 255))
    d_tow.ellipse([18, 8, 29, 18], fill=(0, 255, 255))
    tower.save(f"{SPRITE_DIR}/spr_power_tower.png")

    # B. Stage 2 Enemy: Kamikaze Roller (32x32 x 4 frames)
    roller = Image.new("RGBA", (32 * 4, 32), (0, 0, 0, 0))
    d_rol = ImageDraw.Draw(roller)
    for i in range(4):
        ox = i * 32
        d_rol.ellipse([ox + 4, 4, ox + 27, 27], fill=(55, 20, 25), outline=(255, 45, 60))
        # Spikes / treads rotating
        ang = (i / 4.0) * math.pi
        d_rol.line([ox + 16 + math.cos(ang)*12, 16 + math.sin(ang)*12, ox + 16 - math.cos(ang)*12, 16 - math.sin(ang)*12], fill=(255, 180, 40), width=2)
        d_rol.ellipse([ox + 12, 12, ox + 19, 19], fill=(255, 60, 75)) # Red blinking fuse
    roller.save(f"{SPRITE_DIR}/spr_enemy_kamikaze.png")

    # C. Stage 2 Boss: ARACHNID-SOVEREIGN (112x112 x 4 frames) - Queen Mech
    queen = Image.new("RGBA", (112 * 4, 112), (0, 0, 0, 0))
    d_q = ImageDraw.Draw(queen)
    for i in range(4):
        ox = i * 112
        bob = 0 if i % 2 == 0 else -3
        # Abdomen Egg Pods (acid violet & neon green)
        d_q.ellipse([ox + 20, 40 + bob, ox + 92, 98 + bob], fill=(45, 25, 55), outline=(180, 40, 220))
        d_q.ellipse([ox + 36, 52 + bob, ox + 50, 66 + bob], fill=(80, 255, 120)) # Toxic egg sacs
        d_q.ellipse([ox + 62, 52 + bob, ox + 76, 66 + bob], fill=(80, 255, 120))
        # Armored Carapace & Head
        d_q.rectangle([ox + 38, 22 + bob, ox + 74, 48 + bob], fill=(60, 35, 75), outline=(20, 12, 28))
        # Multi-optic sensors (8 green eyes)
        for ex in [44, 50, 62, 68]:
            d_q.point((ox + ex, 30 + bob), fill=(80, 255, 120))
            d_q.point((ox + ex, 34 + bob), fill=(80, 255, 120))
        # Huge scythe mandibles
        d_q.line([ox + 42, 46 + bob, ox + 32, 62 + bob], fill=(200, 50, 70), width=3)
        d_q.line([ox + 70, 46 + bob, ox + 80, 62 + bob], fill=(200, 50, 70), width=3)
    queen.save(f"{SPRITE_DIR}/spr_boss_arachnid.png")

    # D. Stage 3 Boss: NEXUS-PRIME A.I. (96x96 x 4 frames) - Floating Hologram Drone Overlord
    nexus = Image.new("RGBA", (96 * 4, 96), (0, 0, 0, 0))
    d_nex = ImageDraw.Draw(nexus)
    for i in range(4):
        ox = i * 96
        float_y = int(math.sin(i * math.pi / 2.0) * 4)
        # Rotating outer holographic ring
        d_nex.ellipse([ox + 12, 12 + float_y, ox + 83, 83 + float_y], fill=(12, 18, 30, 200), outline=(0, 230, 255))
        d_nex.ellipse([ox + 24, 24 + float_y, ox + 71, 71 + float_y], outline=(255, 210, 40))
        # Core A.I. Monolith Eye
        d_nex.ellipse([ox + 38, 38 + float_y, ox + 57, 57 + float_y], fill=(255, 45, 60), outline=(255, 255, 255))
    nexus.save(f"{SPRITE_DIR}/spr_boss_nexus.png")

    # E. Stage 4 Boss: DREADNOUGHT-GOLIATH (128x128 x 4 frames) - Heavy Twin Railgun Walker
    dread = Image.new("RGBA", (128 * 4, 128), (0, 0, 0, 0))
    d_dr = ImageDraw.Draw(dread)
    for i in range(4):
        ox = i * 128
        bob = (1 if i % 2 == 0 else -2)
        # Giant chassis (70x50)
        d_dr.rectangle([ox + 29, 32 + bob, ox + 99, 82 + bob], fill=(40, 46, 58), outline=(18, 22, 28))
        # Dual heavy railgun barrels extending forward
        d_dr.rectangle([ox + 18, 24 + bob, ox + 28, 70 + bob], fill=(70, 78, 95), outline=(0, 210, 255))
        d_dr.rectangle([ox + 100, 24 + bob, ox + 110, 70 + bob], fill=(70, 78, 95), outline=(0, 210, 255))
        # Heavy hazard stripes
        d_dr.line([ox + 35, 78 + bob, ox + 93, 78 + bob], fill=(255, 210, 40), width=4)
        # Heavy quad legs
        leg_step = 4 if i % 2 == 0 else -4
        d_dr.rectangle([ox + 32 + leg_step, 82 + bob, ox + 46 + leg_step, 118], fill=(28, 32, 42))
        d_dr.rectangle([ox + 82 - leg_step, 82 + bob, ox + 96 - leg_step, 118], fill=(28, 32, 42))
    dread.save(f"{SPRITE_DIR}/spr_boss_dreadnought.png")

    # F. Stage 5 Apex Nightmare Boss: CHRONO-HARBINGER OMEGA (144x144 x 4 frames)
    chrono = Image.new("RGBA", (144 * 4, 144), (0, 0, 0, 0))
    d_ch = ImageDraw.Draw(chrono)
    for i in range(4):
        ox = i * 144
        # Pulsing spacetime rift wings
        wing_w = 48 + int(math.sin(i * math.pi / 2.0) * 8)
        d_ch.polygon([(ox + 72, 20), (ox + 72 - wing_w, 60), (ox + 72 - wing_w + 12, 100), (ox + 72, 85)], fill=(35, 15, 55, 220), outline=(210, 40, 255))
        d_ch.polygon([(ox + 72, 20), (ox + 72 + wing_w, 60), (ox + 72 + wing_w - 12, 100), (ox + 72, 85)], fill=(35, 15, 55, 220), outline=(210, 40, 255))
        # Singularity core in chest
        d_ch.ellipse([ox + 52, 45, ox + 91, 84], fill=(10, 5, 18), outline=(0, 230, 255))
        d_ch.ellipse([ox + 60, 53, ox + 83, 76], fill=(255, 50, 90), outline=(255, 255, 255))
        # Corona flares
        for f in range(8):
            ang = (f / 8.0) * 2 * math.pi + (i * 0.2)
            px = ox + 72 + math.cos(ang) * 32
            py = 64 + math.sin(ang) * 32
            d_ch.line([ox + 72, 64, px, py], fill=(160, 40, 255, 160), width=2)
    chrono.save(f"{SPRITE_DIR}/spr_boss_chrono.png")
    print("Created Stage Enemies & Bosses (Tower, Kamikaze, Arachnid, Nexus, Dreadnought, Chrono-Harbinger)")

create_stage_enemies_and_bosses()
