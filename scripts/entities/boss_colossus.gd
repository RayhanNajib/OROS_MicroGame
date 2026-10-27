extends CharacterBody2D

@export var max_hp: int = 2250
var current_hp: int = 2250
var base_speed: float = 46.0
var contact_damage: int = 4

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_timer: Timer = $AnimTimer

var player: Node2D = null
var current_frame: int = 0
var knockback_velocity: Vector2 = Vector2.ZERO

var attack_timer: float = 0.0
var slam_timer: float = 0.0
var is_slamming: bool = false
var contact_cooldown: float = 0.0

# 3x Speed Ramp & 2-Second Telegraph Laser
var boss_alive_time: float = 0.0
var laser_timer: float = 0.0
var is_charging_laser: bool = false
var laser_aim_dir: Vector2 = Vector2.ZERO
var laser_line: Line2D = null

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
			velocity = velocity.move_toward(Vector2.ZERO, 100.0 * delta)
			move_and_slide()
			return

	if contact_cooldown > 0.0:
		contact_cooldown -= delta

	var to_player := (player.global_position - global_position)
	var dist := to_player.length()
	var dir := to_player.normalized()

	if sprite:
		sprite.flip_h = (dir.x < 0)

	boss_alive_time += delta
	var speed_mult: float = 1.0
	if boss_alive_time > 60.0:
		# Ramp up to 3.0x speed after 1 minute
		speed_mult = minf(3.0, 1.0 + ((boss_alive_time - 60.0) / 60.0) * 2.0)

	# 1. Radial Bullet Barrage
	attack_timer += delta
	if attack_timer >= 3.6:
		attack_timer = 0.0
		fire_radial_barrage()

	# 2. Ground Slam Charge
	slam_timer += delta
	if slam_timer >= 6.0 and not is_charging_laser:
		slam_timer = 0.0
		execute_ground_slam()

	# 3. Lethal Long-Range Laser with 2.0s Telegraph Indicator
	laser_timer += delta
	if laser_timer >= 8.5 and not is_slamming and not is_charging_laser:
		laser_timer = 0.0
		start_laser_telegraph(dir)

	# Move toward player if not slamming or charging laser
	var move_speed := 0.0 if (is_slamming or is_charging_laser) else (base_speed * speed_mult)
	velocity = (dir * move_speed) + knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 300.0 * delta)
	move_and_slide()

	# Contact damage with player
	if dist < 42.0 and contact_cooldown <= 0.0:
		if is_instance_valid(player) and player.has_method("take_hit"):
			player.take_hit(contact_damage)
			contact_cooldown = 1.0

func start_laser_telegraph(target_dir: Vector2) -> void:
	is_charging_laser = true
	laser_aim_dir = target_dir
	
	if not laser_line:
		laser_line = Line2D.new()
		laser_line.z_index = 25
		add_child(laser_line)
	
	laser_line.visible = true
	laser_line.clear_points()
	laser_line.add_point(Vector2.ZERO)
	laser_line.add_point(laser_aim_dir * 900.0)
	laser_line.width = 2.0
	laser_line.default_color = Color(1.0, 0.15, 0.15, 0.5)

	# 2.0 seconds indicator before laser fires
	var tw := create_tween()
	tw.tween_method(func(val: float):
		if is_instance_valid(laser_line):
			laser_line.width = lerp(2.0, 8.0, val)
			laser_line.default_color = Color(1.0, 0.1, 0.1, lerp(0.5, 0.95, val))
	, 0.0, 1.0, 2.0)
	
	tw.tween_callback(func():
		if not is_instance_valid(self): return
		fire_heavy_laser()
	)

func fire_heavy_laser() -> void:
	if not is_instance_valid(self): return
	if is_instance_valid(laser_line):
		laser_line.width = 28.0
		laser_line.default_color = Color(3.5, 0.4, 0.4, 1.0)
	
	GameState.screen_shake_requested.emit(12.0, 0.35)
	
	# High damage piercing laser beam projectiles
	if enemy_bullet_scene:
		for i in range(12):
			var b = enemy_bullet_scene.instantiate()
			b.global_position = global_position + (laser_aim_dir * (i * 65.0 + 30.0))
			b.direction = laser_aim_dir
			b.speed = 650.0
			b.damage = 3
			get_parent().add_child(b)
	
	var fade_tw := create_tween()
	fade_tw.tween_interval(0.3)
	fade_tw.tween_callback(func():
		if is_instance_valid(laser_line):
			laser_line.visible = false
		is_charging_laser = false
	)

func fire_radial_barrage() -> void:
	if not enemy_bullet_scene: return
	var count := 8
	for i in range(count):
		var angle := (float(i) / float(count)) * TAU
		var b = enemy_bullet_scene.instantiate()
		b.global_position = global_position
		b.direction = Vector2.RIGHT.rotated(angle)
		b.speed = 210.0
		b.damage = 2
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
			b.damage = 2
			get_parent().add_child(b)
	)

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO, from_melee: bool = false) -> void:
	current_hp -= amount
	GameState.update_boss_hp(current_hp)
	
	# Spawn Floating Damage Popup
	var popup_scene = load("res://scenes/entities/DamagePopup.tscn")
	if popup_scene:
		var popup = popup_scene.instantiate()
		popup.global_position = global_position + Vector2(randf_range(-18, 18), -34)
		popup.setup(amount, from_melee or true)
		get_parent().add_child(popup)
	
	# Heavy boss resists 90% knockback
	knockback_velocity = knockback * 0.1
	
	# Damage flash in Yellow (NO RED)
	modulate = Color(2.5, 2.2, 0.4, 1.0)
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
