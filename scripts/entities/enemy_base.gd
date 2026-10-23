extends CharacterBody2D

@export var enemy_type: String = "spider" # "spider", "drone", "golem"
@export var max_hp: int = 18
@export var current_hp: int = 18
@export var base_speed: float = 110.0
@export var contact_damage: int = 1
@export var exp_reward: int = 5

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

var shoot_timer: float = 0.0
var shoot_interval: float = 2.4
var attack_cooldown: float = 0.0

var medkit_scene: PackedScene

func _ready() -> void:
	add_to_group("enemies")
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
	if not is_instance_valid(player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
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

	var effective_speed := base_speed * (freeze_slow_factor if is_frozen else 1.0)
	var to_player := (player.global_position - global_position)
	var dist_to_player := to_player.length()
	var dir := to_player.normalized()

	# Flip sprite facing player
	if sprite:
		sprite.flip_h = (dir.x < 0)

	# Movement logic by type
	var move_dir := dir
	if enemy_type == "kamikaze" and GameState.has_tower_event:
		var towers = get_tree().get_nodes_in_group("defense_tower")
		if towers.size() > 0 and is_instance_valid(towers[0]):
			var to_tower = (towers[0].global_position - global_position)
			move_dir = to_tower.normalized()
			if to_tower.length() < 30.0 and attack_cooldown <= 0.0:
				towers[0].take_damage(25) # Kamikaze detonation against tower
				attack_cooldown = 1.0
				die()
				return
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
		if is_instance_valid(player) and player.has_method("take_hit"):
			player.take_hit(contact_damage)
			attack_cooldown = 1.0 # 1.0s attack cooldown
			knockback_velocity = -dir * 280.0 # Recoil backward!

	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider and collider.is_in_group("player") and collider.has_method("take_hit"):
			if attack_cooldown <= 0.0:
				collider.take_hit(contact_damage)
				attack_cooldown = 1.0
				knockback_velocity = -dir * 280.0

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	current_hp -= amount
	
	# Spawn Floating Damage Number Popup
	var popup_scene = load("res://scenes/entities/DamagePopup.tscn")
	if popup_scene:
		var popup = popup_scene.instantiate()
		popup.global_position = global_position + Vector2(0, -14)
		popup.setup(amount, amount >= 30)
		get_parent().add_child(popup)
	
	# Apply knockback (golem resists knockback)
	if enemy_type == "golem":
		knockback_velocity = knockback * 0.3
	else:
		knockback_velocity = knockback
		
	# Damage flash
	modulate = Color(2.5, 0.4, 0.4, 1.0) # Flash bright red
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
	var b = enemy_bullet_scene.instantiate()
	b.global_position = global_position
	b.direction = (player.global_position - global_position).normalized()
	get_parent().add_child(b)

func die() -> void:
	GameState.register_kill()
	
	# Play enemy death sound
	if player and player.has_node("SFXEnemyDeath"):
		player.get_node("SFXEnemyDeath").play()
		
	# Spawn XP Gem
	if xp_gem_scene:
		var gem = xp_gem_scene.instantiate()
		gem.global_position = global_position
		gem.xp_value = exp_reward
		gem.is_gold = (exp_reward >= 20)
		get_parent().call_deferred("add_child", gem)
		
	# Chance to drop Nano-Medkit (12% normal, 100% on big enemies)
	if medkit_scene and (randf() < 0.12 or exp_reward >= 50):
		var med = medkit_scene.instantiate()
		med.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		get_parent().call_deferred("add_child", med)

	# Chance to drop Skill Core (Elites / Golems / 8% general drop)
	if (randf() < 0.08 or exp_reward >= 40):
		var core_scene = load("res://scenes/entities/SkillCorePickup.tscn")
		if core_scene:
			var core = core_scene.instantiate()
			core.global_position = global_position + Vector2(randf_range(-14, 14), randf_range(-14, 14))
			get_parent().call_deferred("add_child", core)
		
	queue_free()
