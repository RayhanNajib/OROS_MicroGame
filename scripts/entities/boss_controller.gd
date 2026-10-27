extends CharacterBody2D

@export var boss_type: String = "colossus"
@export var boss_name: String = "COLOSSUS-OMEGA"
@export var max_hp: int = 2250
@export var base_speed: float = 125.0
@export var contact_damage: int = 2

# Compatibility alias for wave_spawner and mini-boss callers
var boss_max_hp: int:
	get: return max_hp
	set(v):
		max_hp = v
		current_hp = v
var boss_hp: int:
	get: return current_hp
	set(v): current_hp = v
var max_health: int:
	get: return max_hp
	set(v):
		max_hp = v
		current_hp = v
var health: int:
	get: return current_hp
	set(v): current_hp = v

var current_hp: int = 2250
var boss_alive_time: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_timer: Timer = $AnimTimer

var player: Node2D = null
var current_frame: int = 0
var knockback_velocity: Vector2 = Vector2.ZERO

var attack_timer: float = 0.0
var special_timer: float = 0.0
var is_special_active: bool = false
var contact_cooldown: float = 0.0

# Apex Boss Dash Skill Attributes
var dash_timer: float = 0.0
var is_dashing: bool = false
var is_dash_charging: bool = false
var dash_dir: Vector2 = Vector2.ZERO
var dash_time_remaining: float = 0.0
var dash_interval: float = 5.2

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
	# Find closest valid active player (exclude downed co-op players)
	var players = get_tree().get_nodes_in_group("player")
	var best_p: Node2D = null
	var min_d: float = 999999.0
	for p in players:
		if not is_instance_valid(p): continue
		if p.get("is_downed") == true: continue
		var d = global_position.distance_to(p.global_position)
		if d < min_d:
			min_d = d
			best_p = p
	player = best_p

	if not is_instance_valid(player):
		# If no active player, target tower or idle
		return

	if contact_cooldown > 0.0:
		contact_cooldown -= delta

	var to_player := (player.global_position - global_position)
	var dist := to_player.length()
	var dir := to_player.normalized()

	if sprite and not is_dashing:
		sprite.flip_h = (dir.x < 0)

	# Regular Attack Loop
	attack_timer += delta
	var atk_interval := 3.4
	if boss_type == "chrono": atk_interval = 2.0
	elif boss_type == "dreadnought": atk_interval = 2.6
	
	if attack_timer >= atk_interval and not is_dashing and not is_dash_charging:
		attack_timer = 0.0
		execute_regular_attack(dir)

	# Special Ability Loop
	special_timer += delta
	var sp_interval := 6.5
	if boss_type == "chrono": sp_interval = 4.5
	
	if special_timer >= sp_interval and not is_dashing and not is_dash_charging:
		special_timer = 0.0
		execute_special_ability(dir)

	# Apex Boss Dash Skill Loop
	dash_timer += delta
	if dash_timer >= dash_interval and not is_special_active and not is_dash_charging and not is_dashing:
		dash_timer = 0.0
		start_dash_sequence(dir)

	boss_alive_time += delta
	var speed_mult: float = 1.0
	if boss_alive_time > 60.0:
		speed_mult = minf(3.0, 1.0 + ((boss_alive_time - 60.0) / 60.0) * 2.0)

	# Velocity calculation
	if is_dashing:
		dash_time_remaining -= delta
		velocity = dash_dir * 560.0
		spawn_boss_ghost()
		if dash_time_remaining <= 0.0:
			is_dashing = false
			modulate = Color(1, 1, 1, 1)
			GameState.screen_shake_requested.emit(8.0, 0.2)
	elif is_dash_charging:
		velocity = Vector2.ZERO
	else:
		var move_speed := 0.0 if is_special_active else (base_speed * speed_mult)
		velocity = (dir * move_speed) + knockback_velocity

	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 300.0 * delta)
	move_and_slide()

	# ARENA ZONE ENFORCEMENT: Boss is strictly contained inside the arena circle!
	var max_zone_dist: float = 490.0
	var arena_ctrl = get_tree().get_first_node_in_group("arena_controller")
	if arena_ctrl and "zone_radius" in arena_ctrl:
		max_zone_dist = maxf(140.0, float(arena_ctrl.zone_radius) - 40.0)
	elif has_node("/root/GameArena"):
		var ga = get_node("/root/GameArena")
		if "zone_radius" in ga:
			max_zone_dist = maxf(140.0, float(ga.zone_radius) - 40.0)

	var current_center_dist: float = global_position.length()
	if current_center_dist > max_zone_dist:
		# Forced high-speed sprint leash back into the arena
		var inward_dir: Vector2 = -global_position.normalized()
		velocity = inward_dir * (base_speed * 3.2)
		global_position = global_position.normalized() * max_zone_dist

	# Contact damage with player
	var hit_bound := 48.0
	if is_dashing: hit_bound = 64.0
	if boss_type == "chrono": hit_bound = 60.0
	elif boss_type == "dreadnought": hit_bound = 55.0
	
	if dist < hit_bound and contact_cooldown <= 0.0:
		if is_instance_valid(player) and player.has_method("take_hit"):
			var dmg = contact_damage * 2 if is_dashing else contact_damage
			player.take_hit(dmg)
			contact_cooldown = 0.8
			if is_dashing and "apply_knockback" in player:
				player.apply_knockback(dash_dir * 420.0)

func start_dash_sequence(target_dir: Vector2) -> void:
	is_dash_charging = true
	dash_dir = target_dir
	# Telegraph windup with crimson glow and screen warning
	modulate = Color(3.0, 0.3, 0.3, 1.0)
	var tw := create_tween()
	tw.tween_interval(0.42)
	tw.tween_callback(func():
		is_dash_charging = false
		is_dashing = true
		dash_time_remaining = 0.38
		modulate = Color(2.5, 0.6, 0.6, 1.0)
		GameState.screen_shake_requested.emit(5.0, 0.15)
	)

func spawn_boss_ghost() -> void:
	if not sprite: return
	var ghost := Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.hframes = sprite.hframes
	ghost.vframes = sprite.vframes
	ghost.frame = sprite.frame
	ghost.flip_h = sprite.flip_h
	ghost.global_position = global_position
	ghost.scale = sprite.scale
	ghost.modulate = Color(2.0, 0.2, 0.2, 0.55)
	get_parent().add_child(ghost)
	var gtw := create_tween()
	gtw.tween_property(ghost, "modulate:a", 0.0, 0.22)
	gtw.tween_callback(ghost.queue_free)

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
	
	# Boss resists 90% knockback
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

	# Boss Loot: 1 Skill Core (hadiah langka setelah mengalahkan boss besar; mini-boss berpeluang kecil 25%)
	var core_scene = load("res://scenes/entities/SkillCorePickup.tscn")
	if core_scene:
		var should_drop: bool = true if not is_in_group("mini_boss") else (randf() < 0.25)
		if should_drop:
			var core = core_scene.instantiate()
			core.global_position = global_position + Vector2(randf_range(-16, 16), randf_range(-16, 16))
			get_parent().call_deferred("add_child", core)
			
	queue_free()
