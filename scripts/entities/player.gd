extends CharacterBody2D

@export var bullet_scene: PackedScene
@export var orbital_saw_scene: PackedScene

@onready var body_sprite: Sprite2D = $BodySprite
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var gun_sprite: Sprite2D = $WeaponPivot/GunSprite
@onready var muzzle: Marker2D = $WeaponPivot/Muzzle

# SFX Nodes
@onready var sfx_gunshot: AudioStreamPlayer2D = $SFXGunshot
@onready var sfx_reload_start: AudioStreamPlayer2D = $SFXReloadStart
@onready var sfx_reload_finish: AudioStreamPlayer2D = $SFXReloadFinish
@onready var sfx_player_hurt: AudioStreamPlayer2D = $SFXPlayerHurt
@onready var sfx_enemy_hit: AudioStreamPlayer2D = $SFXEnemyHit
@onready var sfx_enemy_death: AudioStreamPlayer2D = $SFXEnemyDeath
@onready var sfx_xp_pickup: AudioStreamPlayer2D = $SFXXPPickup

# Reload & Shooting state
var shoot_cooldown: float = 0.0
var is_reloading: bool = false
var reload_timer: float = 0.0

# Invulnerability state
var is_invulnerable: bool = false
var invuln_timer: float = 0.0

# Animation timer
var anim_timer: float = 0.0
var current_frame: int = 0

# Orbital saw instance
var saw_instance: Node2D = null

func _ready() -> void:
	add_to_group("player")
	if not bullet_scene:
		bullet_scene = load("res://scenes/entities/Bullet.tscn")
	if not orbital_saw_scene:
		orbital_saw_scene = load("res://scenes/entities/OrbitalSaw.tscn")
		
	# Sync ammo & health with GameState
	GameState.ammo = GameState.max_ammo
	GameState.health = GameState.max_health
	
	emit_ammo_update()

func _process(delta: float) -> void:
	# 1. Aim gun towards mouse
	var mouse_pos := get_global_mouse_position()
	weapon_pivot.look_at(mouse_pos)
	
	# Flip character & gun based on aim angle
	if mouse_pos.x < global_position.x:
		body_sprite.flip_h = true
		weapon_pivot.scale.y = -1.0
	else:
		body_sprite.flip_h = false
		weapon_pivot.scale.y = 1.0

	# 2. Handle Orbital Saw check
	if GameState.has_orbital_saw and not is_instance_valid(saw_instance):
		saw_instance = orbital_saw_scene.instantiate()
		get_parent().add_child(saw_instance)

	# 3. Handle Reloading Cycle
	if is_reloading:
		reload_timer += delta
		var pct := clampf(reload_timer / GameState.reload_duration, 0.0, 1.0)
		GameState.update_ammo_state(GameState.ammo, GameState.max_ammo, true, pct)
		
		if reload_timer >= GameState.reload_duration:
			finish_reload()
	else:
		# Manual reload trigger with [R]
		if Input.is_action_just_pressed("reload") and GameState.ammo < GameState.max_ammo:
			start_reload()

	# 4. Handle Shooting
	if shoot_cooldown > 0.0:
		shoot_cooldown -= delta
		
	var is_trying_to_shoot := Input.is_action_pressed("primary_attack")
	if is_trying_to_shoot and not is_reloading and shoot_cooldown <= 0.0:
		if GameState.ammo > 0:
			fire_weapon()
		else:
			start_reload()

	# 5. Handle Invulnerability Flash
	if is_invulnerable:
		invuln_timer -= delta
		modulate.a = 0.3 if int(invuln_timer * 15.0) % 2 == 0 else 1.0
		if invuln_timer <= 0.0:
			is_invulnerable = false
			modulate.a = 1.0

	# 6. Animation frames
	if velocity.length() > 10.0:
		anim_timer += delta * 10.0
		current_frame = int(anim_timer) % 4
		body_sprite.frame = current_frame
	else:
		body_sprite.frame = 0
		anim_timer = 0.0

func _physics_process(delta: float) -> void:
	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_axis("move_left", "move_right")
	input_vector.y = Input.get_axis("move_up", "move_down")
	
	# Explicit fallback for direct WASD & Arrow Key events
	if input_vector == Vector2.ZERO:
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			input_vector.x -= 1.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			input_vector.x += 1.0
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			input_vector.y -= 1.0
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			input_vector.y += 1.0
			
	input_vector = input_vector.normalized()

	# 20MTD Movement Speed Penalty: 50% speed while firing or reloading!
	var is_firing := Input.is_action_pressed("primary_attack") and GameState.ammo > 0
	var speed_multiplier := GameState.move_speed_penalty if (is_firing or is_reloading) else 1.0
	var target_speed := GameState.base_speed * speed_multiplier

	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * target_speed, 1200.0 * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 1400.0 * delta)

	move_and_slide()

func fire_weapon() -> void:
	shoot_cooldown = GameState.fire_rate
	GameState.ammo -= 1
	emit_ammo_update()
	
	if sfx_gunshot:
		sfx_gunshot.pitch_scale = randf_range(0.92, 1.08)
		sfx_gunshot.play()

	# Multi-shot projectile fan spread calculation
	var base_angle := weapon_pivot.rotation
	var count := GameState.projectile_count
	var spread := GameState.projectile_spread
	
	for i in range(count):
		var angle := base_angle
		if count > 1:
			var t := float(i) / float(count - 1) # 0.0 to 1.0
			angle = base_angle - (spread * 0.5) + (spread * t)
			
		spawn_bullet(angle)

	# Auto reload when magazine empty
	if GameState.ammo <= 0:
		start_reload()

func spawn_bullet(angle: float) -> void:
	if not bullet_scene: return
	var b = bullet_scene.instantiate()
	b.global_position = muzzle.global_position
	b.direction = Vector2.RIGHT.rotated(angle)
	b.rotation = angle
	b.speed = GameState.bullet_speed
	b.damage = GameState.bullet_damage
	b.pierce = GameState.bullet_pierce
	b.knockback = GameState.bullet_knockback
	b.has_freeze = GameState.has_freeze
	b.has_lightning = GameState.has_lightning
	get_parent().add_child(b)

func start_reload() -> void:
	if is_reloading or GameState.ammo == GameState.max_ammo:
		return
	is_reloading = true
	reload_timer = 0.0
	if sfx_reload_start:
		sfx_reload_start.play()
	emit_ammo_update()

func finish_reload() -> void:
	is_reloading = false
	reload_timer = 0.0
	GameState.ammo = GameState.max_ammo
	if sfx_reload_finish:
		sfx_reload_finish.play()
	emit_ammo_update()

func emit_ammo_update() -> void:
	GameState.update_ammo_state(GameState.ammo, GameState.max_ammo, is_reloading, 0.0)

func take_hit(damage: int) -> void:
	if is_invulnerable:
		return
	is_invulnerable = true
	invuln_timer = 0.8 # 0.8s invulnerability
	
	GameState.take_damage(damage)
	
	if sfx_player_hurt:
		sfx_player_hurt.play()
