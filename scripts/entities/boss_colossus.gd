extends CharacterBody2D

@export var max_hp: int = 750
var current_hp: int = 750
var base_speed: float = 46.0
var contact_damage: int = 2

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_timer: Timer = $AnimTimer

var player: Node2D = null
var current_frame: int = 0
var knockback_velocity: Vector2 = Vector2.ZERO

var attack_timer: float = 0.0
var slam_timer: float = 0.0
var is_slamming: bool = false
var contact_cooldown: float = 0.0

var enemy_bullet_scene: PackedScene
var xp_gem_scene: PackedScene
var medkit_scene: PackedScene

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	current_hp = max_hp
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		
	enemy_bullet_scene = load("res://scenes/entities/EnemyBullet.tscn")
	xp_gem_scene = load("res://scenes/entities/XPGem.tscn")
	medkit_scene = load("res://scenes/entities/MedkitPickup.tscn")
	
	if anim_timer:
		anim_timer.timeout.connect(_on_anim_tick)
		anim_timer.start(0.18)
		
	# Announce boss to GameState
	GameState.trigger_boss_spawn("COLOSSUS-OMEGA", max_hp)

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

	if contact_cooldown > 0.0:
		contact_cooldown -= delta

	var to_player := (player.global_position - global_position)
	var dist := to_player.length()
	var dir := to_player.normalized()

	if sprite:
		sprite.flip_h = (dir.x < 0)

	# 1. Radial Bullet Barrage
	attack_timer += delta
	if attack_timer >= 3.6:
		attack_timer = 0.0
		fire_radial_barrage()

	# 2. Ground Slam Charge
	slam_timer += delta
	if slam_timer >= 6.0:
		slam_timer = 0.0
		execute_ground_slam()

	# Move toward player if not slamming
	var move_speed := 0.0 if is_slamming else base_speed
	velocity = (dir * move_speed) + knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 300.0 * delta)
	move_and_slide()

	# Contact damage with player
	if dist < 42.0 and contact_cooldown <= 0.0:
		if is_instance_valid(player) and player.has_method("take_hit"):
			player.take_hit(contact_damage)
			contact_cooldown = 1.0

func fire_radial_barrage() -> void:
	if not enemy_bullet_scene: return
	var count := 8
	for i in range(count):
		var angle := (float(i) / float(count)) * TAU
		var b = enemy_bullet_scene.instantiate()
		b.global_position = global_position
		b.direction = Vector2.RIGHT.rotated(angle)
		b.speed = 210.0
		get_parent().add_child(b)

func execute_ground_slam() -> void:
	is_slamming = true
	# Telegraph charge: flash orange/white
	modulate = Color(2.5, 1.5, 0.4, 1.0)
	var tw := create_tween()
	tw.tween_interval(0.8)
	tw.tween_callback(func():
		is_slamming = false
		modulate = Color(1, 1, 1, 1)
		# Shockwave slam: fire dense 12-way burst
		if not enemy_bullet_scene: return
		for i in range(12):
			var angle := (float(i) / 12.0) * TAU
			var b = enemy_bullet_scene.instantiate()
			b.global_position = global_position
			b.direction = Vector2.RIGHT.rotated(angle)
			b.speed = 280.0
			get_parent().add_child(b)
	)

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	current_hp -= amount
	GameState.update_boss_hp(current_hp)
	
	# Spawn Floating Damage Popup
	var popup_scene = load("res://scenes/entities/DamagePopup.tscn")
	if popup_scene:
		var popup = popup_scene.instantiate()
		popup.global_position = global_position + Vector2(randf_range(-18, 18), -34)
		popup.setup(amount, true)
		get_parent().add_child(popup)
	
	# Heavy boss resists 90% knockback
	knockback_velocity = knockback * 0.1
	
	# Damage flash
	modulate = Color(2.0, 0.5, 0.5, 1.0)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.1)

	if player and player.has_node("SFXEnemyHit"):
		player.get_node("SFXEnemyHit").play()

	if current_hp <= 0:
		die()

func die() -> void:
	GameState.register_kill()
	GameState.update_boss_hp(0)
	
	if player and player.has_node("SFXEnemyDeath"):
		player.get_node("SFXEnemyDeath").play()
		
	# Guaranteed Boss Loot: 4x Gold XP Gems + 2x Medkits
	if xp_gem_scene:
		for i in range(4):
			var gem = xp_gem_scene.instantiate()
			gem.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
			gem.xp_value = 50
			gem.is_gold = true
			get_parent().call_deferred("add_child", gem)
			
	if medkit_scene:
		for i in range(2):
			var med = medkit_scene.instantiate()
			med.global_position = global_position + Vector2(randf_range(-25, 25), randf_range(-25, 25))
			get_parent().call_deferred("add_child", med)
			
	queue_free()
