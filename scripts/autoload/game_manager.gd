extends Node

# Player Runtime Stats
var max_health: int = 4
var health: int = 4

var base_speed: float = 160.0
var move_speed_penalty: float = 0.5 # 50% speed while firing or reloading (20MTD signature kite)

var max_ammo: int = 6
var ammo: int = 6
var fire_rate: float = 0.22 # Seconds between shots
var reload_duration: float = 1.2 # Seconds to reload

var bullet_damage: int = 20
var bullet_speed: float = 580.0
var projectile_count: int = 1
var projectile_spread: float = 0.14 # Radians spread
var bullet_pierce: int = 0
var bullet_knockback: float = 90.0

var pickup_radius: float = 65.0

# Special Synergies
var has_freeze: bool = false
var has_lightning: bool = false
var has_orbital_saw: bool = false

# Progression Stats
var level: int = 1
var current_xp: int = 0
var xp_to_next: int = 12
var total_kills: int = 0
var survival_time: float = 0.0

# Signals
signal health_changed(current: int, max_hp: int)
signal ammo_changed(current: int, max_cap: int, is_reloading: bool, reload_pct: float)
signal xp_changed(current: int, needed: int, lvl: int)
signal level_up_triggered()
signal game_over_triggered(time_survived: float, kills: int, lvl: int)

func reset_run() -> void:
	max_health = 4
	health = 4
	base_speed = 160.0
	max_ammo = 6
	ammo = 6
	fire_rate = 0.22
	reload_duration = 1.2
	bullet_damage = 20
	bullet_speed = 580.0
	projectile_count = 1
	projectile_spread = 0.14
	bullet_pierce = 0
	bullet_knockback = 90.0
	pickup_radius = 65.0
	has_freeze = false
	has_lightning = false
	has_orbital_saw = false
	level = 1
	current_xp = 0
	xp_to_next = 12
	total_kills = 0
	survival_time = 0.0

func add_xp(amount: int) -> void:
	current_xp += amount
	while current_xp >= xp_to_next:
		current_xp -= xp_to_next
		level += 1
		xp_to_next = roundi(12.0 * pow(level, 1.35))
		emit_signal("level_up_triggered")
	emit_signal("xp_changed", current_xp, xp_to_next, level)

func register_kill() -> void:
	total_kills += 1

func take_damage(amount: int) -> void:
	health = max(0, health - amount)
	emit_signal("health_changed", health, max_health)
	if health <= 0:
		emit_signal("game_over_triggered", survival_time, total_kills, level)

func heal(amount: int) -> void:
	health = min(max_health, health + amount)
	emit_signal("health_changed", health, max_health)
