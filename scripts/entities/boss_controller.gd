extends CharacterBody2D

@export var boss_type: String = "colossus"
@export var boss_name: String = "COLOSSUS-OMEGA"
@export var max_hp: int = 750
@export var base_speed: float = 46.0
@export var contact_damage: int = 2

var current_hp: int = 750

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_timer: Timer = $AnimTimer

var player: Node2D = null
var current_frame: int = 0
var knockback_velocity: Vector2 = Vector2.ZERO

var attack_timer: float = 0.0
var special_timer: float = 0.0
var is_special_active: bool = false
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
	GameState.trigger_boss_spawn(boss_name, max_hp)

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

	# Regular Attack Loop
	attack_timer += delta
	var atk_interval := 3.4
	if boss_type == "chrono": atk_interval = 2.0
	elif boss_type == "dreadnought": atk_interval = 2.6
	
	if attack_timer >= atk_interval:
		attack_timer = 0.0
		execute_regular_attack(dir)

	# Special Ability Loop
	special_timer += delta
	var sp_interval := 6.5
	if boss_type == "chrono": sp_interval = 4.5
	
	if special_timer >= sp_interval:
		special_timer = 0.0
		execute_special_ability(dir)

	# Move toward player
	var move_speed := 0.0 if is_special_active else base_speed
	velocity = (dir * move_speed) + knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 300.0 * delta)
	move_and_slide()

	# Contact damage with player
	var hit_bound := 45.0
	if boss_type == "chrono": hit_bound = 60.0
	elif boss_type == "dreadnought": hit_bound = 55.0
	
	if dist < hit_bound and contact_cooldown <= 0.0:
		if is_instance_valid(player) and player.has_method("take_hit"):
			player.take_hit(contact_damage)
			contact_cooldown = 1.0

func execute_regular_attack(dir: Vector2) -> void:
	if not enemy_bullet_scene: return
	
	match boss_type:
		"colossus":
			# 8-way radial ring
			for i in range(8):
				var angle := (float(i) / 8.0) * TAU
				spawn_bullet(angle, 210.0)
		"arachnid":
			# 5-way acid spray towards player
			var base_ang := dir.angle()
			for i in range(5):
				var spread_ang = base_ang - 0.35 + (i * 0.175)
				spawn_bullet(spread_ang, 240.0)
		"nexus":
			# 4-beam cross rotating barrage
			for i in range(4):
				var angle := (float(i) / 4.0) * TAU + randf_range(0, 0.4)
				spawn_bullet(angle, 280.0)
		"dreadnought":
			# Twin heavy railgun blasts
			var base_ang := dir.angle()
			spawn_bullet(base_ang - 0.05, 380.0)
			spawn_bullet(base_ang + 0.05, 380.0)
		"chrono":
			# Spiral bullet hell
			for i in range(12):
				var angle := (float(i) / 12.0) * TAU + (Time.get_ticks_msec() * 0.003)
				spawn_bullet(angle, 260.0)

func execute_special_ability(dir: Vector2) -> void:
	is_special_active = true
	modulate = Color(2.5, 1.2, 0.4, 1.0) # Flash charge
	var tw := create_tween()
	tw.tween_interval(0.8)
	tw.tween_callback(func():
		is_special_active = false
		modulate = Color(1, 1, 1, 1)
		
		match boss_type:
			"colossus":
				# 12-way shockwave
				for i in range(12):
					spawn_bullet((float(i) / 12.0) * TAU, 300.0)
			"arachnid":
				# Spawn 4 rust spiders from pods
				var sp_scene = load("res://scenes/entities/EnemySpider.tscn")
				if sp_scene:
					for i in range(4):
						var spider = sp_scene.instantiate()
						spider.global_position = global_position + Vector2(randf_range(-35, 35), randf_range(-35, 35))
						get_parent().add_child(spider)
			"nexus":
				# Teleport behind player + 8-way blast
				if is_instance_valid(player):
					global_position = player.global_position - dir * 180.0
					for i in range(8):
						spawn_bullet((float(i) / 8.0) * TAU, 260.0)
			"dreadnought":
				# 16-missile barrage
				for i in range(16):
					spawn_bullet((float(i) / 16.0) * TAU, 240.0)
			"chrono":
				# Double singularity vortex: 20 bullets in opposing spirals
				for i in range(20):
					spawn_bullet((float(i) / 20.0) * TAU, 320.0)
	)

func spawn_bullet(angle: float, speed: float) -> void:
	if not enemy_bullet_scene: return
	var b = enemy_bullet_scene.instantiate()
	b.global_position = global_position
	b.direction = Vector2.RIGHT.rotated(angle)
	b.speed = speed
	get_parent().add_child(b)

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
	
	# Boss resists 90% knockback
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
		
	# Guaranteed Boss Loot: XP Gems + Medkits
	if xp_gem_scene:
		var gem_count := 4 if boss_type != "chrono" else 8
		for i in range(gem_count):
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

	# Guaranteed Boss Loot: Skill Cores
	var core_scene = load("res://scenes/entities/SkillCorePickup.tscn")
	if core_scene:
		for i in range(2):
			var core = core_scene.instantiate()
			core.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
			get_parent().call_deferred("add_child", core)
			
	queue_free()
