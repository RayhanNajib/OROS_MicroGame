extends Node

# Matriks Progresi 5-Stage Nightmare
var current_stage: int = 1

var stage_configs: Dictionary = {
	1: {
		"title": "PABRIK SUBTERRANEAN",
		"difficulty": "NORMAL",
		"target_time": 180.0,
		"objective": "Bertahan hidup dari drone pengintai dan hancurkan Colossus-Omega!",
		"boss_name": "COLOSSUS-OMEGA",
		"boss_hp": 750,
		"has_tower": false
	},
	2: {
		"title": "RERUNTUHAN SIBER",
		"difficulty": "HARD",
		"target_time": 210.0,
		"objective": "Pertahankan Power Core Tower dari Kamikaze Rollers & Spider Queen!",
		"boss_name": "ARACHNID-SOVEREIGN",
		"boss_hp": 1100,
		"has_tower": true
	},
	3: {
		"title": "REAKTOR OVERCLOCK",
		"difficulty": "VERY HARD",
		"target_time": 240.0,
		"objective": "Waspada radiasi thermal lantai & eliminasi Nexus-Prime A.I.!",
		"boss_name": "NEXUS-PRIME A.I.",
		"boss_hp": 1500,
		"has_tower": false
	},
	4: {
		"title": "GURUN PLASMA EMP",
		"difficulty": "EXPERT",
		"target_time": 270.0,
		"objective": "Badai EMP melipatgandakan kecepatan gerak musuh. Kalahkan Goliath!",
		"boss_name": "DREADNOUGHT-GOLIATH",
		"boss_hp": 2100,
		"has_tower": false
	},
	5: {
		"title": "APEX SINGULARITY",
		"difficulty": "NIGHTMARE",
		"target_time": 300.0,
		"objective": "Singularity Meltdown total! Hancurkan Chrono-Harbinger Omega!",
		"boss_name": "CHRONO-HARBINGER OMEGA",
		"boss_hp": 3000,
		"has_tower": false
	}
}

# 2-Weapons Loadout System (Primary Ranged + Secondary Melee)
var primary_weapon: String = "revolver" # Selected in Wizard: revolver / shotgun / smg
var secondary_weapon: String = "melee"   # Always Cyber Katana / Nano Blade
var selected_hero: String = "kael"
var selected_weapon: String = "revolver" # Active weapon ID

var equipped_slot: int = 1 # 1 = Primary, 2 = Secondary
var is_melee_active: bool = false
var swap_cooldown_timer: float = 0.0
const SWAP_COOLDOWN_MAX: float = 0.35

var is_native_synergy_active: bool = false

# Character Active Skill
var skill_level: int = 1
var skill_cooldown_max: float = 6.0
var skill_cooldown_timer: float = 0.0

# Player Runtime Stats
var max_health: int = 4
var health: int = 4

var base_speed: float = 160.0
var move_speed_penalty: float = 0.75

var max_ammo: int = 6
var ammo: int = 6
var fire_rate: float = 0.22
var reload_duration: float = 1.0

var bullet_damage: int = 18
var bullet_speed: float = 580.0
var projectile_count: int = 1
var projectile_spread: float = 0.12
var bullet_pierce: int = 0
var bullet_knockback: float = 90.0

var pickup_radius: float = 70.0

# Special Synergies
var has_freeze: bool = false
var has_lightning: bool = false
var has_orbital_saw: bool = false
var has_vampire_chip: bool = false
var has_explosive_rounds: bool = false

# Progression Stats
var level: int = 1
var current_xp: int = 0
var xp_to_next: int = 12
var total_kills: int = 0
var survival_time: float = 0.0
var session_credits: int = 0

# Tower Defense Event (Stage 2)
var tower_max_hp: int = 500
var tower_hp: int = 500
var has_tower_event: bool = false

# Boss State
var is_boss_active: bool = false
var boss_name: String = "COLOSSUS-OMEGA"
var boss_max_hp: int = 800
var boss_current_hp: int = 800

# Signals
signal health_changed(current: int, max_hp: int)
signal ammo_changed(current: int, max_cap: int, is_reloading: bool, reload_pct: float)
signal xp_changed(current: int, needed: int, lvl: int)
signal level_up_triggered()
signal game_over_triggered(time_survived: float, kills: int, lvl: int)
signal mission_victory_triggered(time_survived: float, kills: int, lvl: int)

signal boss_spawned(b_name: String, max_hp: int)
signal boss_hp_changed(cur_hp: int, max_hp: int)
signal boss_defeated()

signal tower_hp_changed(cur: int, max_hp: int)

signal weapon_slot_swapped(slot_idx: int, wep_name: String, is_melee: bool)
signal skill_cooldown_updated(current: float, max_cd: float)
signal skill_upgraded(new_level: int)

func trigger_mission_victory(time_survived: float, kills: int, lvl: int) -> void:
	mission_victory_triggered.emit(time_survived, kills, lvl)

func reset_run() -> void:
	apply_selection()
	var cfg = stage_configs.get(current_stage, stage_configs[1])
	has_tower_event = cfg.get("has_tower", false)
	tower_max_hp = 500
	tower_hp = 500
	
	level = 1
	current_xp = 0
	xp_to_next = 12
	total_kills = 0
	survival_time = 0.0
	session_credits = 0
	skill_level = 1
	skill_cooldown_timer = 0.0
	swap_cooldown_timer = 0.0
	
	is_boss_active = false
	has_freeze = false
	has_lightning = false
	has_orbital_saw = false
	has_vampire_chip = false
	has_explosive_rounds = false
	bullet_pierce = 0
	pickup_radius = 70.0

	equip_slot(1) # Start with Primary Ranged

func apply_selection() -> void:
	# 1. Apply Hero Archetype & Rune Upgrades
	var r_hp = SaveManager.runes.get("titan_alloy", 0)
	var r_spd = SaveManager.runes.get("ion_stride", 0) * 0.04
	var r_cd = SaveManager.runes.get("overclock_core", 0) * 0.10

	match selected_hero:
		"kael":
			max_health = 4 + r_hp
			base_speed = 160.0 * (1.0 + r_spd)
		"vex":
			max_health = 3 + r_hp
			base_speed = 205.0 * (1.0 + r_spd)
		"brutus":
			max_health = 6 + r_hp
			base_speed = 130.0 * (1.0 + r_spd)
		_:
			max_health = 4 + r_hp
			base_speed = 160.0 * (1.0 + r_spd)
	health = max_health
	skill_cooldown_max = maxf(2.0, 6.0 * (1.0 - r_cd))

	apply_active_slot_stats()

func equip_slot(slot_idx: int) -> bool:
	if swap_cooldown_timer > 0.0: return false
	equipped_slot = slot_idx
	swap_cooldown_timer = SWAP_COOLDOWN_MAX
	
	if equipped_slot == 1:
		selected_weapon = primary_weapon
		is_melee_active = false
	else:
		selected_weapon = "melee"
		is_melee_active = true
		
	apply_active_slot_stats()
	check_native_synergy()
	weapon_slot_swapped.emit(equipped_slot, selected_weapon, is_melee_active)
	update_ammo_state(ammo, max_ammo, false, 0.0)
	return true

func toggle_slot() -> bool:
	var next_slot = 2 if equipped_slot == 1 else 1
	return equip_slot(next_slot)

func apply_active_slot_stats() -> void:
	var r_dmg = 1.0 + (SaveManager.runes.get("cyber_caliber", 0) * 0.05)
	var r_rel = 1.0 - (SaveManager.runes.get("rapid_vent", 0) * 0.05)
	var r_kb = 1.0 + (SaveManager.runes.get("heavy_impulse", 0) * 0.15)
	var r_prc = SaveManager.runes.get("plasma_pierce", 0)

	if is_melee_active:
		# Secondary Cyber Blade
		max_ammo = 1
		fire_rate = 0.32
		reload_duration = 0.1
		bullet_damage = int(45 * r_dmg)
		bullet_speed = 0.0 # Melee arc
		projectile_count = 1
		projectile_spread = 0.0
		bullet_knockback = 240.0 * r_kb
		bullet_pierce = 999
	else:
		# Primary Ranged Weapon (Rebalanced)
		match primary_weapon:
			"revolver":
				max_ammo = 6
				fire_rate = 0.22
				reload_duration = 0.95 * r_rel
				bullet_damage = int(18 * r_dmg) # Won't 1-shot (takes 2 hits)
				bullet_speed = 620.0
				projectile_count = 1
				projectile_spread = 0.08
				bullet_knockback = 90.0 * r_kb
				bullet_pierce = r_prc
			"shotgun":
				# Point-blank only one-shots (8 pellets x 10 DMG = 80 DMG)
				max_ammo = 4
				fire_rate = 0.48
				reload_duration = 1.25 * r_rel
				bullet_damage = int(10 * r_dmg)
				bullet_speed = 520.0
				projectile_count = 8
				projectile_spread = 0.32
				bullet_knockback = 180.0 * r_kb
				bullet_pierce = r_prc
			"smg":
				max_ammo = 28
				fire_rate = 0.08
				reload_duration = 0.80 * r_rel
				bullet_damage = int(6 * r_dmg)
				bullet_speed = 640.0
				projectile_count = 1
				projectile_spread = 0.12
				bullet_knockback = 45.0 * r_kb
				bullet_pierce = r_prc
	ammo = max_ammo

func check_native_synergy() -> void:
	is_native_synergy_active = false
	if not is_melee_active:
		if selected_hero == "kael" and primary_weapon == "revolver":
			is_native_synergy_active = true
			bullet_damage = int(bullet_damage * 1.25)
		elif selected_hero == "vex" and primary_weapon == "smg":
			is_native_synergy_active = true
			fire_rate *= 0.75
		elif selected_hero == "brutus" and primary_weapon == "shotgun":
			is_native_synergy_active = true
			projectile_count += 2
			bullet_knockback *= 1.25

func upgrade_skill() -> void:
	skill_level += 1
	skill_cooldown_max = maxf(2.0, skill_cooldown_max * 0.85)
	skill_upgraded.emit(skill_level)

func update_ammo_state(current: int, max_cap: int, is_reloading: bool, reload_pct: float) -> void:
	ammo = current
	max_ammo = max_cap
	ammo_changed.emit(ammo, max_ammo, is_reloading, reload_pct)

func add_xp(amount: int) -> void:
	current_xp += amount
	while current_xp >= xp_to_next:
		current_xp -= xp_to_next
		level += 1
		xp_to_next = int(xp_to_next * 1.35) + 6
		level_up_triggered.emit()
	xp_changed.emit(current_xp, xp_to_next, level)

func register_kill() -> void:
	total_kills += 1
	session_credits += 1
	if selected_hero == "brutus" and total_kills % 50 == 0:
		heal(1)
	if has_vampire_chip and randf() < 0.05:
		heal(1)

func damage_tower(amount: int) -> void:
	if not has_tower_event: return
	tower_hp = max(0, tower_hp - amount)
	tower_hp_changed.emit(tower_hp, tower_max_hp)
	if tower_hp <= 0:
		game_over_triggered.emit(survival_time, total_kills, level)

func take_damage(amount: int) -> void:
	if selected_hero == "vex" and randf() < 0.15:
		return
		
	var final_dmg := amount
	if selected_hero == "brutus" and amount > 1:
		final_dmg = amount - 1
		
	health = max(0, health - final_dmg)
	health_changed.emit(health, max_health)
	if health <= 0:
		game_over_triggered.emit(survival_time, total_kills, level)

func heal(amount: int) -> void:
	health = min(max_health, health + amount)
	health_changed.emit(health, max_health)

func trigger_boss_spawn(b_title: String, m_hp: int) -> void:
	is_boss_active = true
	boss_name = b_title
	boss_max_hp = m_hp
	boss_current_hp = m_hp
	boss_spawned.emit(boss_name, boss_max_hp)

func update_boss_hp(c_hp: int) -> void:
	boss_current_hp = max(0, c_hp)
	boss_hp_changed.emit(boss_current_hp, boss_max_hp)
	if boss_current_hp <= 0 and is_boss_active:
		is_boss_active = false
		session_credits += 150
		boss_defeated.emit()

func calculate_mission_rank() -> Dictionary:
	var cfg = stage_configs.get(current_stage, stage_configs[1])
	var target: float = cfg.get("target_time", 180.0)
	var time_ratio := survival_time / target
	
	var rank := "C"
	var bonus_nc := 25
	
	if time_ratio >= 1.0 and (health >= max_health - 1 or total_kills >= 80):
		rank = "S"
		bonus_nc = 350
	elif time_ratio >= 0.85 or total_kills >= 60:
		rank = "A"
		bonus_nc = 200
	elif time_ratio >= 0.65 or total_kills >= 35:
		rank = "B"
		bonus_nc = 100
	else:
		rank = "C"
		bonus_nc = 40
		
	var total_earned := session_credits + bonus_nc
	SaveManager.add_credits(total_earned)
	SaveManager.record_stage_result(current_stage, survival_time, rank)
	
	return {
		"rank": rank,
		"bonus_nc": bonus_nc,
		"total_nc": total_earned,
		"cleared": time_ratio >= 1.0
	}