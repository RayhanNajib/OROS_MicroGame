extends Node

# Matriks Progresi 5-Stage Nightmare
var current_stage: int = 1

var stage_configs: Dictionary = {
	1: {
		"title": "PABRIK SUBTERRANEAN",
		"difficulty": "NORMAL",
		"target_time": 300.0,
		"objective": "Bertahan 5 Menit dari serbuan siber & hancurkan Colossus-Omega!",
		"boss_name": "COLOSSUS-OMEGA",
		"boss_hp": 2400,
		"has_tower": false
	},
	2: {
		"title": "RERUNTUHAN SIBER",
		"difficulty": "HARD",
		"target_time": 600.0,
		"objective": "Pertahankan Power Core Tower 10 Menit & eliminasi Arachnid-Sovereign!",
		"boss_name": "ARACHNID-SOVEREIGN",
		"boss_hp": 3600,
		"has_tower": true
	},
	3: {
		"title": "REAKTOR OVERCLOCK",
		"difficulty": "VERY HARD",
		"target_time": 900.0,
		"objective": "Waspada radiasi thermal 15 Menit & musnahkan Nexus-Prime A.I.!",
		"boss_name": "NEXUS-PRIME A.I.",
		"boss_hp": 4800,
		"has_tower": false
	},
	4: {
		"title": "GURUN PLASMA EMP",
		"difficulty": "EXPERT",
		"target_time": 1200.0,
		"objective": "Badai EMP melipatgandakan kecepatan musuh. Bertahan 20 Menit & kalahkan Goliath!",
		"boss_name": "DREADNOUGHT-GOLIATH",
		"boss_hp": 6400,
		"has_tower": false
	},
	5: {
		"title": "APEX SINGULARITY",
		"difficulty": "NIGHTMARE",
		"target_time": 1500.0,
		"objective": "Singularity Meltdown total! Bertahan 25 Menit paling susah & hancurkan Chrono-Harbinger Omega!",
		"boss_name": "CHRONO-HARBINGER OMEGA",
		"boss_hp": 9000,
		"has_tower": false
	}
}

# 2-Weapons Loadout System (Primary Ranged + Secondary Melee)
var primary_weapon: String = "revolver" # Selected in Wizard: revolver / shotgun / smg
var secondary_weapon: String = "melee"   # Always Cyber Katana / Nano Blade
var selected_hero: String = "kael"
var selected_weapon: String = "revolver" # Active weapon ID
var is_coop_mode: bool = false:
	set(val):
		is_coop_mode = val
		var im = get_node_or_null("/root/InputManager")
		if im and im.has_method("refresh_device_assignments"):
			im.refresh_device_assignments()
var coop_p2_hero: String = "nyx"
var coop_p2_weapon: String = "railgun"

# Co-op Dual Player Stats
var p1_max_health: int = 4
var p1_health: int = 4
var p2_max_health: int = 4
var p2_health: int = 4

var p1_max_ammo: int = 6
var p1_ammo: int = 6
var p1_is_reloading: bool = false
var p1_reload_pct: float = 0.0

var p2_max_ammo: int = 6
var p2_ammo: int = 4
var p2_is_reloading: bool = false
var p2_reload_pct: float = 0.0

var equipped_slot: int = 1 # 1 = Primary, 2 = Secondary
var is_melee_active: bool = false
var swap_cooldown_timer: float = 0.0
const SWAP_COOLDOWN_MAX: float = 0.35

var p2_equipped_slot: int = 1
var p2_is_melee_active: bool = false
var p2_swap_cooldown_timer: float = 0.0

var is_native_synergy_active: bool = false

# Character Active Skill
var skill_level: int = 1
var skill_cooldown_max: float = 6.0
var skill_cooldown_timer: float = 0.0

var p2_skill_level: int = 1
var p2_skill_cooldown_max: float = 6.0
var p2_skill_cooldown_timer: float = 0.0

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

var pickup_radius: float = 140.0
var has_magnetic_vacuum: bool = false

# Special Synergies & Legendary Cards
var has_freeze: bool = false
var has_lightning: bool = false
var has_orbital_saw: bool = false
var has_vampire_chip: bool = false
var has_explosive_rounds: bool = false

var has_recharge: bool = false
var has_excitement: bool = false
var excitement_timer: float = 0.0
var has_fresh_clip: bool = false
var fresh_clip_timer: float = 0.0
var has_assassin: bool = false
var has_fan_fire: bool = false
var has_holy_shield: bool = false
var holy_shield_active: bool = false
var holy_shield_timer: float = 0.0
var has_run_and_gun: bool = false
var has_anger_point: bool = false
var anger_point_timer: float = 0.0
var has_frostbite: bool = false
var has_pyro_mage: bool = false

var has_phoenix_reboot: bool = false
var phoenix_used: bool = false
var has_chrono_matrix: bool = false
var has_omni_burst: bool = false
var has_reactive_armor: bool = false

# New Skills, Weapon Evolution & 20MTD Synergies
var has_random_lightning: bool = false
var has_ghost_pet: bool = false
var is_weapon_evolved: bool = false
var evolved_weapon_name: String = ""
var synergy_frost_fire: bool = false
var synergy_overload: bool = false
var synergy_ghost_pact: bool = false
signal weapon_evolved(weapon_name: String)
signal synergy_unlocked(synergy_name: String, desc: String)

# 20MTD Cyber Tomes State
var player_scale_mult: float = 1.0
var has_tome_glass: bool = false
var has_tome_electro: bool = false
var has_tome_stillness: bool = false
var has_tome_wind: bool = false
var active_tomes: Array[String] = []

# Progression Stats
const MAX_LEVEL: int = 15
var level: int = 1
var current_xp: int = 0
var xp_to_next: int = 35
var total_kills: int = 0
var survival_time: float = 0.0
var session_credits: int = 0

# Tower Defense Event (Stage 2)
var tower_max_hp: int = 1500
var tower_hp: int = 1500
var has_tower_event: bool = false

# Boss State
var is_boss_active: bool = false
var boss_name: String = "COLOSSUS-OMEGA"
var boss_max_hp: int = 800
var boss_current_hp: int = 800

# Signals
signal health_changed(current: int, max_hp: int)
signal ammo_changed(current: int, max_cap: int, is_reloading: bool, reload_pct: float)
signal p1_health_changed(current: int, max_hp: int)
signal p2_health_changed(current: int, max_hp: int)
signal p1_ammo_changed(current: int, max_cap: int, is_reloading: bool, reload_pct: float)
signal p2_ammo_changed(current: int, max_cap: int, is_reloading: bool, reload_pct: float)
signal xp_changed(current: int, needed: int, lvl: int)
signal level_up_triggered()
signal tome_modal_triggered()
signal game_over_triggered(time_survived: float, kills: int, lvl: int)
signal mission_victory_triggered(time_survived: float, kills: int, lvl: int)

func open_tome_modal() -> void:
	tome_modal_triggered.emit()

signal boss_spawned(b_name: String, max_hp: int)
signal boss_hp_changed(cur_hp: int, max_hp: int)
signal boss_defeated()

signal tower_hp_changed(cur: int, max_hp: int)
@warning_ignore("unused_signal")
signal screen_shake_requested(intensity: float, duration: float)
signal stacked_level_up(count: int)

func request_screen_shake(intensity: float, duration: float) -> void:
	screen_shake_requested.emit(intensity, duration)

signal weapon_slot_swapped(slot_idx: int, wep_name: String, is_melee: bool)
signal p1_weapon_slot_swapped(slot_idx: int, wep_name: String, is_melee: bool)
signal p2_weapon_slot_swapped(slot_idx: int, wep_name: String, is_melee: bool)
signal skill_cooldown_updated(current: float, max_cd: float)
signal p1_skill_cooldown_updated(current: float, max_cd: float)
signal p2_skill_cooldown_updated(current: float, max_cd: float)
signal skill_upgraded(new_level: int)

func trigger_mission_victory(time_survived: float, kills: int, lvl: int) -> void:
	mission_victory_triggered.emit(time_survived, kills, lvl)

func update_skill_cooldown(cur_cd: float, max_cd: float) -> void:
	skill_cooldown_timer = cur_cd
	skill_cooldown_max = max_cd
	skill_cooldown_updated.emit(cur_cd, max_cd)
	p1_skill_cooldown_updated.emit(cur_cd, max_cd)

func update_p2_skill_cooldown(cur_cd: float, max_cd: float) -> void:
	p2_skill_cooldown_timer = cur_cd
	p2_skill_cooldown_max = max_cd
	p2_skill_cooldown_updated.emit(cur_cd, max_cd)

func reset_run() -> void:
	apply_selection()
	var cfg = stage_configs.get(current_stage, stage_configs[1])
	has_tower_event = cfg.get("has_tower", false)
	tower_max_hp = 1500
	tower_hp = 1500
	
	level = 1
	current_xp = 0
	xp_to_next = 35
	total_kills = 0
	survival_time = 0.0
	session_credits = 0
	skill_level = 1
	skill_cooldown_timer = 0.0
	swap_cooldown_timer = 0.0
	p2_equipped_slot = 1
	p2_is_melee_active = false
	p2_swap_cooldown_timer = 0.0
	p2_skill_level = 1
	p2_skill_cooldown_timer = 0.0
	
	is_boss_active = false
	has_freeze = false
	has_lightning = false
	has_orbital_saw = false
	has_vampire_chip = false
	has_explosive_rounds = false
	has_recharge = false
	has_excitement = false
	excitement_timer = 0.0
	has_fresh_clip = false
	fresh_clip_timer = 0.0
	has_assassin = false
	has_fan_fire = false
	has_holy_shield = false
	holy_shield_active = false
	holy_shield_timer = 0.0
	has_run_and_gun = false
	has_anger_point = false
	anger_point_timer = 0.0
	has_frostbite = false
	has_pyro_mage = false
	has_phoenix_reboot = false
	phoenix_used = false
	has_chrono_matrix = false
	has_omni_burst = false
	has_random_lightning = false
	has_ghost_pet = false
	is_weapon_evolved = false
	evolved_weapon_name = ""
	synergy_frost_fire = false
	synergy_overload = false
	synergy_ghost_pact = false
	player_scale_mult = 1.0
	has_tome_glass = false
	has_tome_electro = false
	has_tome_stillness = false
	has_tome_wind = false
	active_tomes.clear()
	bullet_pierce = 0
	pickup_radius = 140.0
	has_magnetic_vacuum = false
	has_reactive_armor = false

	equip_slot(1) # Start with Primary Ranged

func apply_selection() -> void:
	# 1. Apply Hero Archetype & Rune Upgrades
	var r_hp = SaveManager.runes.get("titan_alloy", 0)
	var r_spd = SaveManager.runes.get("ion_stride", 0) * 0.04
	var r_cd = SaveManager.runes.get("overclock_core", 0) * 0.10

	match selected_hero:
		"kael":
			max_health = 4 + r_hp
			base_speed = 165.0 * (1.0 + r_spd)
		"vex":
			max_health = 3 + r_hp
			base_speed = 195.0 * (1.0 + r_spd)
		"brutus":
			max_health = 4 + r_hp
			base_speed = 145.0 * (1.0 + r_spd)
		"nyx":
			max_health = 3 + r_hp
			base_speed = 170.0 * (1.0 + r_spd)
		_:
			max_health = 4 + r_hp
			base_speed = 165.0 * (1.0 + r_spd)
	health = max_health
	p1_max_health = max_health
	p1_health = health
	p1_max_ammo = max_ammo
	p1_ammo = ammo

	# Initialize Player 2 Stats for Co-op
	match coop_p2_hero:
		"kael": p2_max_health = 4
		"vex": p2_max_health = 3
		"brutus": p2_max_health = 4
		"nyx": p2_max_health = 3
		_: p2_max_health = 4
	p2_health = p2_max_health
	
	match coop_p2_weapon:
		"revolver": p2_max_ammo = 6
		"shotgun": p2_max_ammo = 4
		"smg": p2_max_ammo = 15
		"railgun": p2_max_ammo = 2
		_: p2_max_ammo = 6
	p2_ammo = p2_max_ammo

	skill_cooldown_max = maxf(2.0, 6.0 * (1.0 - r_cd))
	p2_skill_cooldown_max = skill_cooldown_max

	apply_active_slot_stats()

func equip_slot(slot_idx: int) -> bool:
	return equip_slot_p(1, slot_idx)

func toggle_slot() -> bool:
	return toggle_slot_p(1)

func equip_p2_slot(slot_idx: int) -> bool:
	return equip_slot_p(2, slot_idx)

func toggle_p2_slot() -> bool:
	return toggle_slot_p(2)

func equip_slot_p(p_idx: int, slot_idx: int) -> bool:
	if p_idx == 1:
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
		p1_weapon_slot_swapped.emit(equipped_slot, selected_weapon, is_melee_active)
		update_ammo_state(ammo, max_ammo, false, 0.0)
		return true
	else:
		if p2_swap_cooldown_timer > 0.0: return false
		p2_equipped_slot = slot_idx
		p2_swap_cooldown_timer = SWAP_COOLDOWN_MAX
		if p2_equipped_slot == 1:
			p2_is_melee_active = false
		else:
			p2_is_melee_active = true
		p2_weapon_slot_swapped.emit(p2_equipped_slot, coop_p2_weapon if not p2_is_melee_active else "melee", p2_is_melee_active)
		update_ammo_state_p(2, p2_ammo, p2_max_ammo, false, 0.0)
		return true

func toggle_slot_p(p_idx: int) -> bool:
	if p_idx == 1:
		var next_slot = 2 if equipped_slot == 1 else 1
		return equip_slot_p(1, next_slot)
	else:
		var next_slot = 2 if p2_equipped_slot == 1 else 1
		return equip_slot_p(2, next_slot)

func apply_active_slot_stats() -> void:
	var r_dmg = 1.0 + (SaveManager.runes.get("cyber_caliber", 0) * 0.05)
	var r_rel = 1.0 - (SaveManager.runes.get("rapid_vent", 0) * 0.05)
	var r_kb = 1.0 + (SaveManager.runes.get("heavy_impulse", 0) * 0.15)
	var r_prc = SaveManager.runes.get("plasma_pierce", 0)

	if is_melee_active:
		# Secondary Cyber Blade (+1.5x damage boost: 11 -> 26 DMG)
		max_ammo = 1
		fire_rate = 0.38
		reload_duration = 0.15
		bullet_damage = int(26 * r_dmg)
		bullet_speed = 0.0 # Melee arc
		projectile_count = 1
		projectile_spread = 0.0
		bullet_knockback = 280.0 * r_kb
		bullet_pierce = 999
	else:
		# Primary Ranged Weapon (+40% base + tailored shots-to-kill balance)
		match primary_weapon:
			"revolver":
				# 2-shot kill on standard mobs (base HP ~54)
				max_ammo = 6
				fire_rate = 0.22
				reload_duration = 1.30 * r_rel
				bullet_damage = int(28 * r_dmg)
				bullet_speed = 660.0
				projectile_count = 1
				projectile_spread = 0.06
				bullet_knockback = 120.0 * r_kb
				bullet_pierce = r_prc
			"shotgun":
				# Exactly 3 pellets default, high impact punch
				max_ammo = 4
				fire_rate = 0.44
				reload_duration = 1.60 * r_rel
				bullet_damage = int(22 * r_dmg)
				bullet_speed = 550.0
				projectile_count = 3
				projectile_spread = 0.18
				bullet_knockback = 200.0 * r_kb
				bullet_pierce = r_prc
			"smg":
				# High fire rate, exactly 5 bullets to kill regular mob (11 * 5 = 55 dmg)
				max_ammo = 15
				fire_rate = 0.08
				reload_duration = 1.25 * r_rel
				bullet_damage = int(11 * r_dmg)
				bullet_speed = 680.0
				projectile_count = 1
				projectile_spread = 0.10
				bullet_knockback = 50.0 * r_kb
				bullet_pierce = r_prc
			"railgun":
				# Laser / Railgun: Very few ammo (2), massive piercing destructive damage
				max_ammo = 2
				fire_rate = 0.60
				reload_duration = 1.90 * r_rel
				bullet_damage = int(65 * r_dmg)
				bullet_speed = 1000.0
				projectile_count = 1
				projectile_spread = 0.02
				bullet_knockback = 220.0 * r_kb
				bullet_pierce = 4 + r_prc
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

func evolve_active_weapon() -> void:
	if is_weapon_evolved: return
	is_weapon_evolved = true
	match primary_weapon:
		"revolver":
			evolved_weapon_name = "⚡ MJOLNIR REVOLVER"
			bullet_damage = int(bullet_damage * 1.6)
			has_lightning = true
			projectile_count += 1
		"shotgun":
			evolved_weapon_name = "❄️ GLACIAL FROST CANNON"
			bullet_damage = int(bullet_damage * 1.4)
			has_freeze = true
			projectile_count += 3
			bullet_pierce += 2
		"smg":
			evolved_weapon_name = "💥 MICRO-MISSILE VULCAN"
			has_explosive_rounds = true
			fire_rate = maxf(0.04, fire_rate * 0.70)
			max_ammo += 15
			ammo = max_ammo
		"railgun":
			evolved_weapon_name = "🌀 TACHYON ANOMALY LANCE"
			bullet_damage = int(bullet_damage * 2.0)
			has_omni_burst = true
			bullet_pierce = 99
	weapon_evolved.emit(evolved_weapon_name)

func check_synergies() -> void:
	# 1. Frost Fire (Freeze + Explosive)
	if has_freeze and has_explosive_rounds and not synergy_frost_fire:
		synergy_frost_fire = true
		bullet_damage = int(bullet_damage * 1.35)
		synergy_unlocked.emit("FROST FIRE", "Musuh beku meledak menyemburkan api saat hancur!")
		
	# 2. Overload (Lightning/Storm + Vacuum Magnet)
	if (has_lightning or has_random_lightning) and has_magnetic_vacuum and not synergy_overload:
		synergy_overload = true
		pickup_radius = 450.0
		synergy_unlocked.emit("HIGH OVERLOAD", "Medan magnet menyalurkan muatan listrik ke musuh sekitar!")
		
	# 3. Ghost Pact (Ghost Companion + Assassin)
	if has_ghost_pet and has_assassin and not synergy_ghost_pact:
		synergy_ghost_pact = true
		synergy_unlocked.emit("GHOST PACT", "Ghost companion otomatis mengeksekusi musuh HP <35%!")

const MAX_SKILL_LEVEL: int = 15

func upgrade_skill(player_idx: int = 1) -> bool:
	if player_idx == 2:
		if p2_skill_level >= MAX_SKILL_LEVEL:
			return false
		p2_skill_level = mini(MAX_SKILL_LEVEL, p2_skill_level + 1)
		skill_upgraded.emit(p2_skill_level)
		return true
	else:
		if skill_level >= MAX_SKILL_LEVEL:
			return false
		skill_level = mini(MAX_SKILL_LEVEL, skill_level + 1)
		skill_cooldown_max = maxf(2.0, skill_cooldown_max * 0.85)
		skill_upgraded.emit(skill_level)
		return true

func update_ammo_state(current: int, max_cap: int, is_reloading: bool, reload_pct: float) -> void:
	ammo = current
	max_ammo = max_cap
	ammo_changed.emit(ammo, max_ammo, is_reloading, reload_pct)
	p1_ammo = current
	p1_max_ammo = max_cap
	p1_is_reloading = is_reloading
	p1_reload_pct = reload_pct
	p1_ammo_changed.emit(current, max_cap, is_reloading, reload_pct)

func update_ammo_state_p(player_idx: int, current: int, max_cap: int, is_rel: bool, reload_pct: float) -> void:
	if player_idx == 1:
		update_ammo_state(current, max_cap, is_rel, reload_pct)
	else:
		p2_ammo = current
		p2_max_ammo = max_cap
		p2_is_reloading = is_rel
		p2_reload_pct = reload_pct
		p2_ammo_changed.emit(current, max_cap, is_rel, reload_pct)

func update_p2_ammo_state(current: int, max_cap: int, is_rel: bool = false, reload_pct: float = 0.0) -> void:
	update_ammo_state_p(2, current, max_cap, is_rel, reload_pct)

func add_xp(amount: int) -> void:
	if level >= MAX_LEVEL:
		current_xp = xp_to_next
		xp_changed.emit(xp_to_next, xp_to_next, MAX_LEVEL)
		return

	# Dynamic XP scaling across a 25-minute survival duration (1500 seconds):
	# Early game (levels 1-5): Fast progression so builds get running quickly
	# Late game (10-25 mins): Progressive steepening balanced with dense enemy hordes
	var time_ratio: float = clampf(survival_time / 1500.0, 0.0, 1.0)
	var early_boost: float = 1.75 if level <= 3 else (1.35 if level <= 6 else 1.0)
	var late_factor: float = 1.0 - (time_ratio * 0.35)
	var exp_boost: float = 1.20 if has_magnetic_vacuum else 1.0
	var boosted_amount: int = maxi(1, int(round(float(amount) * early_boost * late_factor * exp_boost)))
	if is_coop_mode:
		boosted_amount = maxi(1, int(round(float(boosted_amount) * 0.5)))
	current_xp += boosted_amount
	var gained_levels: int = 0
	while current_xp >= xp_to_next and level < MAX_LEVEL:
		current_xp -= xp_to_next
		level += 1
		gained_levels += 1
		# Dynamic curve scaling towards 25 minutes:
		var growth: float = 1.38 + float(level) * 0.02
		xp_to_next = int(float(xp_to_next) * growth) + 20 + int((survival_time / 60.0) * 5)
		level_up_triggered.emit()
		if level >= MAX_LEVEL:
			current_xp = 0
			break
	if gained_levels > 0:
		stacked_level_up.emit(gained_levels)
	xp_changed.emit(current_xp, xp_to_next, level)

# Alias pelindung agar panggilan add_exp dari manapun tidak crash
func add_exp(amount: int) -> void:
	add_xp(amount)

func register_kill() -> void:
	total_kills += 1
	# Nerfed credit gain: 1 credit every 8 kills
	if total_kills % 8 == 0:
		session_credits += 1
	if selected_hero == "brutus" and total_kills % 50 == 0:
		heal(1, 1)
	if has_vampire_chip and randf() < 0.05:
		heal(1, 1)

func damage_tower(amount: int) -> void:
	if not has_tower_event: return
	tower_hp = max(0, tower_hp - amount)
	tower_hp_changed.emit(tower_hp, tower_max_hp)
	if tower_hp <= 0:
		game_over_triggered.emit(survival_time, total_kills, level)

func heal_tower(amount: int) -> void:
	if not has_tower_event or tower_hp <= 0: return
	tower_hp = mini(tower_max_hp, tower_hp + amount)
	tower_hp_changed.emit(tower_hp, tower_max_hp)
	var tower = get_tree().get_first_node_in_group("defense_tower")
	if is_instance_valid(tower) and tower.has_method("heal"):
		tower.heal(amount)

func take_damage(amount: int, player_idx: int = 1) -> void:
	if is_coop_mode:
		var hero = selected_hero if player_idx == 1 else coop_p2_hero
		if hero == "vex" and randf() < 0.15:
			return
			
		var final_dmg := amount
		if hero == "brutus" and amount > 1:
			final_dmg = amount - 1
			
		if player_idx == 1:
			p1_health = max(0, p1_health - final_dmg)
			health = p1_health
			p1_health_changed.emit(p1_health, p1_max_health)
			health_changed.emit(p1_health, p1_max_health)
		else:
			p2_health = max(0, p2_health - final_dmg)
			p2_health_changed.emit(p2_health, p2_max_health)
			
		# In co-op, game over only triggers when BOTH players are downed!
		if p1_health <= 0 and p2_health <= 0:
			game_over_triggered.emit(survival_time, total_kills, level)
	else:
		if selected_hero == "vex" and randf() < 0.15:
			return
			
		var final_dmg := amount
		if selected_hero == "brutus" and amount > 1:
			final_dmg = amount - 1
			
		health = max(0, health - final_dmg)
		p1_health = health
		health_changed.emit(health, max_health)
		p1_health_changed.emit(health, max_health)
		if health <= 0:
			game_over_triggered.emit(survival_time, total_kills, level)

func heal(amount: int, player_idx: int = 1) -> void:
	if is_coop_mode:
		if player_idx == 1:
			p1_health = min(p1_max_health, p1_health + amount)
			health = p1_health
			p1_health_changed.emit(p1_health, p1_max_health)
			health_changed.emit(p1_health, p1_max_health)
		else:
			p2_health = min(p2_max_health, p2_health + amount)
			p2_health_changed.emit(p2_health, p2_max_health)
	else:
		health = min(max_health, health + amount)
		p1_health = health
		health_changed.emit(health, max_health)
		p1_health_changed.emit(health, max_health)

func heal_p2(amount: int) -> void:
	heal(amount, 2)

func update_health_bar(player_idx: int, cur_hp: int, max_hp: int) -> void:
	if player_idx == 1:
		p1_health = clamp(cur_hp, 0, max_hp)
		p1_max_health = max_hp
		health = p1_health
		max_health = p1_max_health
		health_changed.emit(p1_health, p1_max_health)
		p1_health_changed.emit(p1_health, p1_max_health)
	else:
		p2_health = clamp(cur_hp, 0, max_hp)
		p2_max_health = max_hp
		p2_health_changed.emit(p2_health, p2_max_health)

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
		session_credits += 12 # Nerfed boss kill bonus
		boss_defeated.emit()

func calculate_mission_rank() -> Dictionary:
	var cfg = stage_configs.get(current_stage, stage_configs[1])
	var target: float = cfg.get("target_time", 180.0)
	var time_ratio := survival_time / target
	
	var rank := "C"
	var bonus_nc := 5
	
	if time_ratio >= 1.0 and (health >= max_health - 1 or total_kills >= 80):
		rank = "S"
		bonus_nc = 18
	elif time_ratio >= 0.85 or total_kills >= 60:
		rank = "A"
		bonus_nc = 14
	elif time_ratio >= 0.65 or total_kills >= 35:
		rank = "B"
		bonus_nc = 9
	else:
		rank = "C"
		bonus_nc = 5
		
	var total_earned := session_credits + bonus_nc
	SaveManager.add_credits(total_earned)
	SaveManager.record_stage_result(current_stage, survival_time, rank)
	
	return {
		"rank": rank,
		"bonus_nc": bonus_nc,
		"total_nc": total_earned,
		"cleared": time_ratio >= 1.0
	}
