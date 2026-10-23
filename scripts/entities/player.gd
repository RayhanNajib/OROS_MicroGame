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

@onready var sfx_skill_dash: AudioStreamPlayer2D = $SFXSkillDash
@onready var sfx_skill_freeze: AudioStreamPlayer2D = $SFXSkillFreeze
@onready var sfx_skill_slam: AudioStreamPlayer2D = $SFXSkillSlam
@onready var sfx_weapon_swap: AudioStreamPlayer2D = $SFXWeaponSwap
@onready var sfx_pickup_core: AudioStreamPlayer2D = $SFXPickupCore

# Reload & Shooting state
var shoot_cooldown: float = 0.0
var is_reloading: bool = false
var reload_timer: float = 0.0

# Invulnerability & Dash state
var is_invulnerable: bool = false
var invuln_timer: float = 0.0
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_velocity: Vector2 = Vector2.ZERO

# Animation timer
var anim_timer: float = 0.0
var current_frame: int = 0

# Orbital saw instance
var saw_instance: Node2D = null

# VFX references
var muzzle_flash: Sprite2D = null
var shadow_sprite: Sprite2D = null

func _ready() -> void:
	add_to_group("player")
	if not bullet_scene:
		bullet_scene = load("res://scenes/entities/Bullet.tscn")
	if not orbital_saw_scene:
		orbital_saw_scene = load("res://scenes/entities/OrbitalSaw.tscn")
		
	if has_node("WeaponPivot/Muzzle/MuzzleFlash"):
		muzzle_flash = get_node("WeaponPivot/Muzzle/MuzzleFlash")
	if has_node("ShadowSprite"):
		shadow_sprite = get_node("ShadowSprite")
		
	GameState.weapon_swapped.connect(_on_weapon_swapped)
	update_hero_visuals()
	update_weapon_visuals()

	# Sync ammo & health with GameState
	GameState.ammo = GameState.max_ammo
	GameState.health = GameState.max_health
	emit_ammo_update()

func update_hero_visuals() -> void:
	match GameState.selected_hero:
		"vex":
			var skin = "res://assets/sprites/skins/player_vex_toxic.png" if SaveManager.equipped_hero_skin == "toxic" else "res://assets/sprites/player_vex_run.png"
			body_sprite.texture = load(skin)
		"brutus":
			var skin = "res://assets/sprites/skins/player_brutus_gold.png" if SaveManager.equipped_hero_skin == "gold" else "res://assets/sprites/player_brutus_run.png"
			body_sprite.texture = load(skin)
		_:
			var skin = "res://assets/sprites/skins/player_kael_crimson.png" if SaveManager.equipped_hero_skin == "crimson" else "res://assets/sprites/player_kael_run.png"
			body_sprite.texture = load(skin)

func update_weapon_visuals() -> void:
	match GameState.selected_weapon:
		"shotgun":
			var wep = "res://assets/sprites/skins/spr_shotgun_cyber.png" if SaveManager.equipped_weapon_skin == "cyber" else "res://assets/sprites/spr_shotgun.png"
			gun_sprite.texture = load(wep)
			gun_sprite.position = Vector2(14, 0)
			muzzle.position = Vector2(28, 0)
		"smg":
			var wep = "res://assets/sprites/skins/spr_smg_violet.png" if SaveManager.equipped_weapon_skin == "violet" else "res://assets/sprites/spr_smg.png"
			gun_sprite.texture = load(wep)
			gun_sprite.position = Vector2(10, 0)
			muzzle.position = Vector2(20, 0)
		_:
			var wep = "res://assets/sprites/skins/spr_revolver_gold.png" if SaveManager.equipped_weapon_skin == "gold" else "res://assets/sprites/spr_revolver.png"
			gun_sprite.texture = load(wep)
			gun_sprite.position = Vector2(10, 0)
			muzzle.position = Vector2(22, 0)

func _on_weapon_swapped(_wep_id: String, _slot_idx: int, _is_syn: bool) -> void:
	update_weapon_visuals()
	if sfx_weapon_swap:
		sfx_weapon_swap.play()
	is_reloading = false
	reload_timer = 0.0
	emit_ammo_update()

func _process(delta: float) -> void:
	# 1. Aim gun towards mouse
	var mouse_pos := get_global_mouse_position()
	weapon_pivot.look_at(mouse_pos)
	
	# Smoothly return gun pivot after recoil
	weapon_pivot.position = weapon_pivot.position.move_toward(Vector2(0, 3), 40.0 * delta)
	
	# Flip character & gun based on aim angle
	if mouse_pos.x < global_position.x:
		body_sprite.flip_h = true
		weapon_pivot.scale.y = -1.0
	else:
		body_sprite.flip_h = false
		weapon_pivot.scale.y = 1.0

	# 2. Orbital Saw Check
	if GameState.has_orbital_saw and not is_instance_valid(saw_instance):
		saw_instance = orbital_saw_scene.instantiate()
		get_parent().add_child(saw_instance)

	# 3. Reloading Cycle
	if is_reloading:
		reload_timer += delta
		var pct := clampf(reload_timer / GameState.reload_duration, 0.0, 1.0)
		GameState.update_ammo_state(GameState.ammo, GameState.max_ammo, true, pct)
		if reload_timer >= GameState.reload_duration:
			finish_reload()
	else:
		if Input.is_action_just_pressed("reload") and GameState.ammo < GameState.max_ammo:
			start_reload()

	# 4. Shooting
	if shoot_cooldown > 0.0:
		shoot_cooldown -= delta
		
	var is_trying_to_shoot := Input.is_action_pressed("primary_attack")
	if is_trying_to_shoot and not is_reloading and shoot_cooldown <= 0.0:
		if GameState.ammo > 0:
			fire_weapon()
		else:
			start_reload()

	# 5. In-Game Weapon Switch Shortcuts (Q cycle, or 1/2/3)
	if Input.is_physical_key_pressed(KEY_Q) and not is_reloading:
		if not get_tree().paused:
			GameState.cycle_weapon()

	# 6. Active Character Skill (SPACE / SHIFT / E)
	var wants_skill := Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_physical_key_pressed(KEY_E)
	if wants_skill and GameState.skill_cooldown_timer <= 0.0 and not is_dashing:
		trigger_active_skill()

	# 7. Invulnerability Flash
	if is_invulnerable:
		invuln_timer -= delta
		var is_flash := int(invuln_timer * 18.0) % 2 == 0
		modulate = Color(2.0, 0.4, 0.4, 0.6) if is_flash else Color(1.0, 1.0, 1.0, 0.9)
		if invuln_timer <= 0.0:
			is_invulnerable = false
			modulate = Color(1.0, 1.0, 1.0, 1.0)

	# 8. Dynamic Animation
	if velocity.length() > 8.0:
		anim_timer += delta * (velocity.length() / 14.0)
		current_frame = int(anim_timer) % 4
		body_sprite.frame = current_frame
		var bob: float = -absf(sin(anim_timer * PI)) * 3.0
		body_sprite.position.y = bob
		var target_tilt := (velocity.x / 180.0) * 0.16
		body_sprite.rotation = lerp_angle(body_sprite.rotation, target_tilt, delta * 18.0)
		body_sprite.scale = Vector2.ONE
	else:
		var breath := sin(Time.get_ticks_msec() * 0.005) * 0.04
		body_sprite.scale = Vector2(1.0 + breath, 1.0 - breath)
		body_sprite.position.y = breath * 2.0
		body_sprite.rotation = lerp_angle(body_sprite.rotation, 0.0, delta * 12.0)
		body_sprite.frame = 1

func _physics_process(delta: float) -> void:
	# Skill Cooldown Loop
	if GameState.skill_cooldown_timer > 0.0:
		GameState.skill_cooldown_timer -= delta
		GameState.skill_cooldown_updated.emit(GameState.skill_cooldown_timer, GameState.skill_cooldown_max)

	# Handle Dash Movement
	if is_dashing:
		dash_timer -= delta
		velocity = dash_velocity
		move_and_slide()
		if dash_timer <= 0.0:
			is_dashing = false
		return

	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_axis("move_left", "move_right")
	input_vector.y = Input.get_axis("move_up", "move_down")
	
	if input_vector == Vector2.ZERO:
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
			input_vector.x -= 1.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
			input_vector.x += 1.0
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
			input_vector.y -= 1.0
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
			input_vector.y += 1.0
			
	input_vector = input_vector.normalized()

	var is_firing := Input.is_action_pressed("primary_attack") and GameState.ammo > 0
	var speed_multiplier := GameState.move_speed_penalty if (is_firing or is_reloading) else 1.0
	var target_speed := GameState.base_speed * speed_multiplier

	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * target_speed, 1200.0 * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 1400.0 * delta)

	move_and_slide()

func trigger_active_skill() -> void:
	GameState.skill_cooldown_timer = GameState.skill_cooldown_max
	
	match GameState.selected_hero:
		"kael":
			# EMP Cryo Dash: Dashes forward + freeze shockwave
			is_dashing = true
			dash_timer = 0.16
			var aim_dir := (get_global_mouse_position() - global_position).normalized()
			dash_velocity = aim_dir * 580.0
			is_invulnerable = true
			invuln_timer = 0.35
			
			if sfx_skill_dash: sfx_skill_dash.play()
			if sfx_skill_freeze: sfx_skill_freeze.play()
			
			# Freeze enemies in area
			var enemies = get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if is_instance_valid(e) and global_position.distance_to(e.global_position) < (180.0 + GameState.skill_level * 15.0):
					if e.has_method("take_damage"):
						e.take_damage(30 + GameState.skill_level * 5, aim_dir * 120.0)
					if e.has_method("apply_freeze"):
						e.apply_freeze(0.4, 3.0)
						
		"vex":
			# Phase Blink: Instant teleport + Decoy bomb
			var aim_dir := (get_global_mouse_position() - global_position).normalized()
			var blink_dest = global_position + aim_dir * (260.0 + GameState.skill_level * 20.0)
			global_position = blink_dest
			is_invulnerable = true
			invuln_timer = 0.4
			if sfx_skill_dash: sfx_skill_dash.play()
			
			# Decoy shock blast
			var tw := create_tween()
			tw.tween_interval(0.2)
			tw.tween_callback(func():
				var enemies = get_tree().get_nodes_in_group("enemies")
				for e in enemies:
					if is_instance_valid(e) and global_position.distance_to(e.global_position) < 140.0:
						if e.has_method("take_damage"):
							e.take_damage(60 + GameState.skill_level * 10, Vector2.ZERO)
			)

		"brutus":
			# Titan Seismic Slam: High damage ring + massive knockback + 2.0s Kinetic Shield
			is_invulnerable = true
			invuln_timer = 2.0 # 2s shield!
			modulate = Color(2.5, 1.5, 0.4, 1.0) # Golden shield
			if sfx_skill_slam: sfx_skill_slam.play()
			
			var enemies = get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if is_instance_valid(e):
					var dist = global_position.distance_to(e.global_position)
					if dist < (220.0 + GameState.skill_level * 20.0):
						var to_e = (e.global_position - global_position).normalized()
						if e.has_method("take_damage"):
							e.take_damage(65 + GameState.skill_level * 8, to_e * 380.0)

func fire_weapon() -> void:
	shoot_cooldown = GameState.fire_rate
	GameState.ammo -= 1
	emit_ammo_update()
	
	if sfx_gunshot:
		sfx_gunshot.pitch_scale = randf_range(0.92, 1.08)
		sfx_gunshot.play()

	var base_angle := weapon_pivot.rotation
	weapon_pivot.position = Vector2(0, 3) - Vector2.RIGHT.rotated(base_angle) * 5.0
	
	if muzzle_flash:
		muzzle_flash.visible = true
		muzzle_flash.rotation = randf_range(0.0, TAU)
		var flash_tw := create_tween()
		flash_tw.tween_interval(0.06)
		flash_tw.tween_callback(func(): 
			if is_instance_valid(muzzle_flash): 
				muzzle_flash.visible = false
		)
		
	body_sprite.scale = Vector2(1.06, 0.94)

	var count := GameState.projectile_count
	var spread := GameState.projectile_spread
	
	for i in range(count):
		var angle := base_angle
		if count > 1:
			var t := float(i) / float(count - 1)
			angle = base_angle - (spread * 0.5) + (spread * t)
			
		spawn_bullet(angle)

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
	
	# Weapon-specific projectile balancing and skin colors
	match GameState.selected_weapon:
		"shotgun":
			b.bullet_tex = load("res://assets/sprites/spr_bullet_pellet.png")
			b.lifespan = 0.30 # Short range! Pellets evaporate after ~160px
		"smg":
			b.bullet_tex = load("res://assets/sprites/spr_bullet_violet.png")
			b.lifespan = 1.3
		_:
			var tex = "res://assets/sprites/spr_bullet_gold.png" if SaveManager.equipped_weapon_skin == "gold" else "res://assets/sprites/spr_bullet_cyan.png"
			b.bullet_tex = load(tex)
			b.lifespan = 1.8
			
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
	invuln_timer = 1.0
	
	GameState.take_damage(damage)
	body_sprite.scale = Vector2(1.15, 0.85)
	
	if sfx_player_hurt:
		sfx_player_hurt.play()