extends Node

# Selected Stage, Roster & Arsenal
var current_stage: int = 1
var selected_hero: String = "kael" # "kael", "vex", "brutus"
var selected_weapon: String = "revolver" # "revolver", "shotgun", "smg"

# 5-Stage Nightmare Progression Matrix
var stage_configs: Dictionary = {
	1: {
		"title": "SEKTOR 01: PABRIK SUBTERRANEAN",
		"difficulty": "NORMAL",
		"target_time": 180.0, # 3 Menit
		"objective": "Bertahan dari serbuan robot & kalahkan Colossus-Omega",
		"boss_name": "COLOSSUS-OMEGA",
		"boss_hp": 750,
		"has_tower": false
	},
	2: {
		"title": "SEKTOR 02: RERUNTUHAN SIBER",
		"difficulty": "HARD",
		"target_time": 210.0, # 3.5 Menit
		"objective": "Pertahankan Power Core Tower dari serangan Kamikaze Roller",
		"boss_name": "ARACHNID-SOVEREIGN",
		"boss_hp": 1100,
		"has_tower": true
	},
	3: {
		"title": "SEKTOR 03: REAKTOR OVERCLOCK",
		"difficulty": "VERY HARD",
		"target_time": 240.0, # 4 Menit
		"objective": "Hindari radiasi lantai reaktor & tundukkan Nexus-Prime A.I.",
		"boss_name": "NEXUS-PRIME A.I.",
		"boss_hp": 1500,
		"has_tower": false
	},
	4: {
		"title": "SEKTOR 04: GURUN PLASMA EMP",
		"difficulty": "EXPERT",
		"target_time": 270.0, # 4.5 Menit
		"objective": "Tembus badai EMP & taklukkan Dreadnought-Goliath",
		"boss_name": "DREADNOUGHT-GOLIATH",
		"boss_hp": 2100,
		"has_tower": false
	},
	5: {
		"title": "SEKTOR 05: APEX SINGULARITY",
		"difficulty": "NIGHTMARE",
		"target_time": 300.0, # 5 Menit
		"objective": "Singularity Meltdown total! Hancurkan Chrono-Harbinger Omega!",
		"boss_name": "CHRONO-HARBINGER OMEGA",
		"boss_hp": 3000,
		"has_tower": false
	}
}

# Player Runtime Stats
var max_health: int = 4
var health: int = 4

var base_speed: float = 160.0
var move_speed_penalty: float = 0.75 # 25% speed penalty (balanced kiting)

var max_ammo: int = 6
var ammo: int = 6
var fire_rate: float = 0.22 # Seconds between shots
var reload_duration: float = 1.0 # Seconds to reload

var bullet_damage: int = 22
var bullet_speed: float = 580.0
var projectile_count: int = 1
var projectile_spread: float = 0.12 # Radians spread
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
	is_boss_active = false
	has_freeze = false
	has_lightning = false
	has_orbital_saw = false
	has_vampire_chip = false
	has_explosive_rounds = false
	bullet_pierce = 0
	pickup_radius = 70.0
	ammo_changed.emit(ammo, max_ammo, false, 0.0)

func apply_selection() -> void:
	# 1. Apply Hero Archetype
	match selected_hero:
		"kael":
			max_health = 4
			base_speed = 160.0
		"vex":
			max_health = 3
			base_speed = 205.0 # High speed assassin
		"brutus":
			max_health = 6 # Heavy tank
			base_speed = 130.0
		_:
			max_health = 4
			base_speed = 160.0
	health = max_health

	# 2. Apply Weapon Arsenal
	match selected_weapon:
		"revolver":
			max_ammo = 6
			fire_rate = 0.22
			reload_duration = 1.0
			bullet_damage = 22
			bullet_speed = 580.0
			projectile_count = 1
			projectile_spread = 0.12
			bullet_knockback = 90.0
		"shotgun":
			max_ammo = 4
			fire_rate = 0.45
			reload_duration = 1.2
			bullet_damage = 9
			bullet_speed = 520.0
			projectile_count = 5 # 5 pellets per blast
			projectile_spread = 0.28
			bullet_knockback = 150.0
		"smg":
			max_ammo = 24
			fire_rate = 0.08 # Rapid fire
			reload_duration = 0.85
			bullet_damage = 8
			bullet_speed = 620.0
			projectile_count = 1
			projectile_spread = 0.08
			bullet_knockback = 50.0
		_:
			max_ammo = 6
			fire_rate = 0.22
			reload_duration = 1.0
			bullet_damage = 22
			bullet_speed = 580.0
			projectile_count = 1
			projectile_spread = 0.12
			bullet_knockback = 90.0
			
	ammo = max_ammo

func update_ammo_state(current: int, max_cap: int, is_reloading: bool = false, reload_pct: float = 0.0) -> void:
	ammo = current
	max_ammo = max_cap
	ammo_changed.emit(current, max_cap, is_reloading, reload_pct)

func add_xp(amount: int) -> void:
	current_xp += amount
	while current_xp >= xp_to_next:
		current_xp -= xp_to_next
		level += 1
		xp_to_next = roundi(12.0 * pow(level, 1.35))
		level_up_triggered.emit()
	xp_changed.emit(current_xp, xp_to_next, level)

func register_kill() -> void:
	total_kills += 1
	session_credits += 1 # 1 kill = 1 Nano-Credit
	
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
		session_credits += 150 # Boss Kill Bonus NC
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