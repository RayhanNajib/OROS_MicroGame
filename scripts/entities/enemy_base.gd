extends CharacterBody2D

@export var enemy_type: String = "spider" # "spider", "drone", "golem"
@export var max_hp: int = 52 # Base HP balanced: 2-shot Revolver (56 dmg), 5-shot SMG (55 dmg)
@export var current_hp: int = 52
@export var base_speed: float = 110.0
@export var contact_damage: int = 1
@export var exp_reward: int = 1 # Nerfed minion base XP to 1

@export var enemy_bullet_scene: PackedScene
@export var xp_gem_scene: PackedScene

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_timer: Timer = $AnimTimer

var player: Node2D = null
var current_frame: int = 0
var knockback_velocity: Vector2 = Vector2.ZERO

var is_frozen: bool = false
var freeze_timer: float = 0.0
var freeze_slow_factor: float = 0.5
var was_killed_by_melee: bool = false

var shoot_timer: float = 0.0
var shoot_interval: float = 2.4
var attack_cooldown: float = 0.0

var medkit_scene: PackedScene

func _ready() -> void:
	add_to_group("enemies")
	# Dynamic HP scaling requested: +0.2x per player level, and +0.2x per minute elapsed
	var lvl_bonus: float = 0.2 * float(maxi(0, int(GameState.level) - 1))
	var time_minutes: float = floorf(float(GameState.survival_time) / 60.0)
	var time_bonus: float = 0.2 * time_minutes
	var total_scale: float = 1.0 + lvl_bonus + time_bonus
	max_hp = int(float(max_hp) * total_scale)
	current_hp = max_hp
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		
	if not enemy_bullet_scene:
		enemy_bullet_scene = load("res://scenes/entities/EnemyBullet.tscn")
	if not xp_gem_scene:
		xp_gem_scene = load("res://scenes/entities/XPGem.tscn")
	if not medkit_scene:
		medkit_scene = load("res://scenes/entities/MedkitPickup.tscn")
		
	# Balanced Drone laser timing (telegraph & fair interval)
	if enemy_type == "drone":
		shoot_timer = randf_range(1.8, 2.8) # Windup delay on spawn
		shoot_interval = 3.8 # Fair delay between laser shots
	elif enemy_type == "turret":
		shoot_timer = randf_range(1.5, 2.2)
		shoot_interval = 3.0
		
	# Setup sprite frames & animation
	if anim_timer:
		anim_timer.timeout.connect(_on_anim_tick)
		anim_timer.start(0.12)
		
	# Randomize shoot timer offset
	shoot_timer = randf_range(0.5, shoot_interval)

func _on_anim_tick() -> void:
	current_frame = (current_frame + 1) % 4
	if sprite:
		sprite.frame = current_frame

func _physics_process(delta: float) -> void:
	# Retarget to the closest active, non-downed player
	if not is_instance_valid(player) or player.get("is_downed") == true:
		player = null
		var players = get_tree().get_nodes_in_group("player")
		var closest_dist := 999999.0
		for p in players:
			if is_instance_valid(p) and not p.get("is_downed"):
				var d = global_position.distance_to(p.global_position)
				if d < closest_dist:
					closest_dist = d
					player = p
		if not is_instance_valid(player):
			# If all players are downed or dead, do not swarm corpses: hold position / decelerate
			velocity = velocity.move_toward(Vector2.ZERO, base_speed * delta)
			move_and_slide()
			return

	# Handle attack cooldown
	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	# Handle Freeze
	if is_frozen:
		freeze_timer -= delta
		if freeze_timer <= 0.0:
			is_frozen = false
			modulate = Color(1, 1, 1, 1)

	var chrono_slow := 0.75 if GameState.has_chrono_matrix else 1.0
	var effective_speed := base_speed * chrono_slow * (freeze_slow_factor if is_frozen else 1.0)
	
	# Target Priority: Decoy > Player
	var target_pos := player.global_position
	var decoys = get_tree().get_nodes_in_group("decoy")
	if decoys.size() > 0 and is_instance_valid(decoys[0]):
		if global_position.distance_to(decoys[0].global_position) < 260.0:
			target_pos = decoys[0].global_position
			
	var to_player := (target_pos - global_position)
	var dist_to_player := to_player.length()
	var dir := to_player.normalized()

	# Flip sprite facing player
	if sprite:
		sprite.flip_h = (dir.x < 0)

	# Movement logic by type
	var move_dir := dir
	if GameState.has_tower_event:
		var towers = get_tree().get_nodes_in_group("defense_tower")
		if towers.size() > 0 and is_instance_valid(towers[0]):
			var to_tower = (towers[0].global_position - global_position)
			var dist_tower = to_tower.length()
			
			if enemy_type == "kamikaze":
				move_dir = to_tower.normalized()
				if dist_tower < 70.0:
					towers[0].take_damage(40) # Kamikaze detonation against tower
					die()
					return
			elif dist_tower < 65.0 and attack_cooldown <= 0.0:
				towers[0].take_damage(contact_damage)
				attack_cooldown = 1.0
			elif dist_tower < dist_to_player * 0.8:
				# Siege the tower if closer to it
				move_dir = to_tower.normalized()
	elif enemy_type == "drone":
		# Maintain standoff distance of 160px
		if dist_to_player < 150.0:
			move_dir = -dir * 0.7 # Back off
		elif dist_to_player < 180.0:
			move_dir = Vector2.ZERO # Hold position
		
		# Handle shooting
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			shoot_timer = shoot_interval
			fire_drone_bullet()
	elif enemy_type == "turret":
		# Stationary turret with long-range shooting
		move_dir = dir * 0.2 if dist_to_player > 220.0 else Vector2.ZERO
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			shoot_timer = 2.0
			fire_drone_bullet()
	elif enemy_type == "viper":
		# Fast serpentine zig-zag
		var perp := Vector2(-dir.y, dir.x)
		var wave := sin(Time.get_ticks_msec() * 0.008) * 0.75
		move_dir = (dir + perp * wave).normalized()
	else:
		# Melee chaser
		move_dir = dir

	# Flocking separation: smooth boids repulsion
	var separation := Vector2.ZERO
	var neighbors := get_tree().get_nodes_in_group("enemies")
	for n in neighbors:
		if n != self and is_instance_valid(n):
			var d: float = global_position.distance_to(n.global_position)
			if d < 32.0 and d > 0.1:
				var rep: Vector2 = (global_position - n.global_position).normalized()
				separation += rep * (1.0 - (d / 32.0)) * 260.0

	velocity = (move_dir * effective_speed) + separation + knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 450.0 * delta)
	
	move_and_slide()

	# Proximity & Slide contact check against player with cooldown & recoil
	var hit_radius := 22.0
	if enemy_type == "golem":
		hit_radius = 32.0
	elif enemy_type == "drone":
		hit_radius = 16.0

	if dist_to_player <= hit_radius and attack_cooldown <= 0.0:
		if is_instance_valid(player) and not player.get("is_downed") and player.has_method("take_hit"):
			player.take_hit(contact_damage)
			attack_cooldown = 1.0 # 1.0s attack cooldown
			knockback_velocity = -dir * 280.0 # Recoil backward!

	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider and collider.is_in_group("player") and not collider.get("is_downed") and collider.has_method("take_hit"):
			if attack_cooldown <= 0.0:
				collider.take_hit(contact_damage)
				attack_cooldown = 1.0
				knockback_velocity = -dir * 280.0

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO, from_melee: bool = false) -> void:
	current_hp -= amount
	was_killed_by_melee = from_melee
	
	# Spawn Floating Damage Number Popup
	var popup_scene = load("res://scenes/entities/DamagePopup.tscn")
	if popup_scene:
		var popup = popup_scene.instantiate()
		popup.global_position = global_position + Vector2(0, -14)
		popup.setup(amount, from_melee or amount >= 30)
		get_parent().add_child(popup)
	
	# Apply knockback (golem resists knockback)
	if enemy_type == "golem":
		knockback_velocity = knockback * 0.3
	else:
		knockback_velocity = knockback
		
	# Damage flash in High-Voltage Yellow (NO RED)
	modulate = Color(2.5, 2.2, 0.4, 1.0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0.6, 0.9, 1.2, 1.0) if is_frozen else Color(1, 1, 1, 1), 0.12)
	
	# Play sound on player's audio bus or scene
	if player and player.has_node("SFXEnemyHit"):
		player.get_node("SFXEnemyHit").play()

	if current_hp <= 0:
		die()

func apply_freeze(slow_factor: float, duration: float) -> void:
	is_frozen = true
	freeze_timer = duration
	freeze_slow_factor = slow_factor
	modulate = Color(0.5, 0.85, 1.3, 1.0) # Cyan tint

func fire_drone_bullet() -> void:
	if not enemy_bullet_scene or not is_instance_valid(player):
		return
	modulate = Color(2.4, 0.3, 0.3, 1.0)
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.28)
	var b = enemy_bullet_scene.instantiate()
	b.global_position = global_position
	b.direction = (player.global_position - global_position).normalized()
	get_parent().add_child(b)

func die() -> void:
	GameState.register_kill()
	
	# Nanite Siphon Core Repair (Tower Defense Stage Mode):
	if GameState.has_tower_event and GameState.tower_hp > 0:
		var s_heal: int = int(clamp(round(float(max_hp) * 0.10), 2.0, 25.0))
		if is_in_group("boss"):
			s_heal = 120
		GameState.heal_tower(s_heal)
	
	# Play enemy death sound
	if player and player.has_node("SFXEnemyDeath"):
		player.get_node("SFXEnemyDeath").play()
		
	# Spawn XP Gem: Dynamic drop rate & scaled early game XP
	if xp_gem_scene:
		var is_elite_or_boss: bool = is_in_group("boss") or exp_reward >= 15
		var is_early_game: bool = float(GameState.survival_time) < 120.0
		var dynamic_drop_rate: float = 1.0 if is_early_game else clampf(0.75 + (float(GameState.survival_time) / 1500.0) * 0.20, 0.75, 0.95)
		var should_drop_xp: bool = is_elite_or_boss or (randf() < dynamic_drop_rate)
		if should_drop_xp:
			var gem = xp_gem_scene.instantiate()
			gem.global_position = global_position
			var rewarded_xp: int = exp_reward
			if is_in_group("boss"):
				rewarded_xp = 180
			elif exp_reward >= 15:
				rewarded_xp = exp_reward # Elite drops full value
			elif float(GameState.survival_time) < 60.0:
				rewarded_xp = 3 # Early game minute 1 boosted XP for smooth progression
			elif float(GameState.survival_time) < 120.0:
				rewarded_xp = 2 # Minute 2 paced XP
			else:
				rewarded_xp = 1 # Minute 2+ horde density gives 1 XP per minion
			gem.xp_value = rewarded_xp
			gem.is_gold = (rewarded_xp >= 15)
			get_parent().call_deferred("add_child", gem)
		
	# MELEE HEALING DROP RULE (Balanced Risk-Reward):
	# Base 35% chance to drop medkit upon melee kill (+ rune bonus if unlocked)
	# Primary Ranged kills drop 0% medkits!
	if was_killed_by_melee and medkit_scene:
		if randf() < 0.35 or exp_reward >= 50:
			var med = medkit_scene.instantiate()
			med.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
			get_parent().call_deferred("add_child", med)

	# Skill Core: Hanya drop saat mengalahkan elite enemy berdarah tebal (Golem / max_hp >= 100), dengan peluang kecil (10%)
	# Musuh kroco biasa (spider, viper, drone, turret, kamikaze) tidak pernah drop Skill Core
	var is_elite_heavy: bool = (enemy_type == "golem" or max_hp >= 100 or is_in_group("elite"))
	if is_elite_heavy and randf() < 0.10:
		var core_scene = load("res://scenes/entities/SkillCorePickup.tscn")
		if core_scene:
			var core = core_scene.instantiate()
			core.global_position = global_position + Vector2(randf_range(-14, 14), randf_range(-14, 14))
			get_parent().call_deferred("add_child", core)

	# Boss or High Elite Drops Ancient Cyber Tome!
	if is_in_group("boss") or exp_reward >= 120:
		var tome_scene = load("res://scenes/entities/TomePickup.tscn")
		if tome_scene:
			var tome = tome_scene.instantiate()
			tome.global_position = global_position
			get_parent().call_deferred("add_child", tome)
		
	queue_free()
