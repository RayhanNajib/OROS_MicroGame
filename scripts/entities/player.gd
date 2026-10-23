extends CharacterBody2D

@export var bullet_scene: PackedScene
@export var orbital_saw_scene: PackedScene

@onready var body_sprite: Sprite2D = $BodySprite
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var gun_sprite: Sprite2D = $WeaponPivot/GunSprite
@onready var muzzle: Marker2D = $WeaponPivot/Muzzle
@onready var slash_arc_sprite: Sprite2D = $WeaponPivot/SlashArcSprite

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

@onready var sfx_melee_slash: AudioStreamPlayer2D = $SFXMeleeSlash
@onready var sfx_melee_hit: AudioStreamPlayer2D = $SFXMeleeHit

@onready var reload_bar: ProgressBar = $ReloadBar
@onready var camera: Camera2D = $Camera2D

@onready var telegraph_line: Line2D = $SkillTelegraph/TelegraphLine

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
var is_holding_skill: bool = false

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
		
	GameState.weapon_slot_swapped.connect(_on_weapon_slot_swapped)
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
	if GameState.is_melee_active:
		# Secondary Cyber Blade
		gun_sprite.texture = load("res://assets/sprites/spr_melee_blade.png")
		gun_sprite.position = Vector2(12, 0)
		muzzle.position = Vector2(24, 0)
	else:
		# Primary Ranged Weapon
		match GameState.primary_weapon:
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

func _on_weapon_slot_swapped(_slot_idx: int, _wep_name: String, _is_melee: bool) -> void:
	update_weapon_visuals()
	if sfx_weapon_swap:
		sfx_weapon_swap.play()
	is_reloading = false
	reload_timer = 0.0
	shoot_cooldown = 0.15 # Brief readying delay
	emit_ammo_update()

func _process(delta: float) -> void:
	# Weapon swap timer tick
	if GameState.swap_cooldown_timer > 0.0:
		GameState.swap_cooldown_timer -= delta

	# 1. Aim gun towards mouse & Dynamic Cursor Look-Ahead Camera (100px max)
	var mouse_pos := get_global_mouse_position()
	weapon_pivot.look_at(mouse_pos)
	
	if camera:
		var look_offset = (mouse_pos - global_position) * 0.22
		look_offset = look_offset.limit_length(100.0)
		camera.offset = camera.offset.move_toward(look_offset, 280.0 * delta)
	
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

	# 3. Reloading Cycle & Above-Head Progress Bar
	if is_reloading:
		reload_timer += delta
		var pct := clampf(reload_timer / GameState.reload_duration, 0.0, 1.0)
		GameState.update_ammo_state(GameState.ammo, GameState.max_ammo, true, pct)
		
		if reload_bar:
			reload_bar.visible = true
			reload_bar.value = pct * 100.0
			
		if reload_timer >= GameState.reload_duration:
			finish_reload()
	else:
		if reload_bar:
			reload_bar.visible = false
		if not GameState.is_melee_active and Input.is_action_just_pressed("reload") and GameState.ammo < GameState.max_ammo:
			start_reload()

	# 4. Shooting / Melee Slashing
	if shoot_cooldown > 0.0:
		shoot_cooldown -= delta
		
	var is_trying_to_attack := Input.is_action_pressed("primary_attack")
	if is_trying_to_attack and not is_reloading and shoot_cooldown <= 0.0:
		if GameState.is_melee_active:
			perform_melee_slash()
		else:
			if GameState.ammo > 0:
				fire_ranged_weapon()
			else:
				start_reload()

	# 5. Weapon Swap Inputs: [Q], [1], [2], [Numpad 1], [Numpad 2]
	if not get_tree().paused and GameState.swap_cooldown_timer <= 0.0:
		if Input.is_physical_key_pressed(KEY_1) or Input.is_physical_key_pressed(KEY_KP_1):
			if GameState.equipped_slot != 1:
				GameState.equip_slot(1)
		elif Input.is_physical_key_pressed(KEY_2) or Input.is_physical_key_pressed(KEY_KP_2):
			if GameState.equipped_slot != 2:
				GameState.equip_slot(2)
		elif Input.is_physical_key_pressed(KEY_Q):
			GameState.toggle_slot()

	# 6. Active Character Skill: Hold [E / Space / Shift] to aim, release to trigger!
	var skill_key_pressed := Input.is_physical_key_pressed(KEY_E) or Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_SHIFT)
	if skill_key_pressed and GameState.skill_cooldown_timer <= 0.0 and not is_dashing:
		is_holding_skill = true
	elif is_holding_skill and not skill_key_pressed:
		is_holding_skill = false
		trigger_active_skill()

	# 7. Update Skill Telegraphing Projection Indicator (Only visible while holding!)
	update_skill_telegraph(mouse_pos)

	# 8. Invulnerability Flash
	if is_invulnerable:
		invuln_timer -= delta
		var is_flash := int(invuln_timer * 18.0) % 2 == 0
		modulate = Color(2.5, 2.0, 0.4, 0.6) if is_flash else Color(1.0, 1.0, 1.0, 0.9)
		if invuln_timer <= 0.0:
			is_invulnerable = false
			modulate = Color(1.0, 1.0, 1.0, 1.0)

	# 9. Dynamic Animation Stride
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

func update_skill_telegraph(mouse_pos: Vector2) -> void:
	if not telegraph_line: return
	
	if not is_holding_skill or GameState.skill_cooldown_timer > 0.0:
		telegraph_line.visible = false
		return
		
	telegraph_line.visible = true
	telegraph_line.clear_points()
	
	var to_mouse = (mouse_pos - global_position)
	var dir = to_mouse.normalized()
	
	match GameState.selected_hero:
		"kael":
			# Cyan dashed laser arrow to mouse (260px)
			telegraph_line.default_color = Color(0.0, 0.94, 1.0, 0.8)
			telegraph_line.add_point(Vector2.ZERO)
			telegraph_line.add_point(dir * 260.0)
		"vex":
			# Emerald green target point (320px)
			telegraph_line.default_color = Color(0.13, 0.95, 0.4, 0.8)
			telegraph_line.add_point(Vector2.ZERO)
			telegraph_line.add_point(dir * 320.0)
		"brutus":
			# High-voltage yellow circular ring (220px)
			telegraph_line.default_color = Color(1.0, 0.9, 0.1, 0.7)
			var pts := 24
			for i in range(pts + 1):
				var ang = (float(i) / float(pts)) * TAU
				telegraph_line.add_point(Vector2(cos(ang), sin(ang)) * 220.0)

func _physics_process(delta: float) -> void:
	if GameState.skill_cooldown_timer > 0.0:
		GameState.skill_cooldown_timer -= delta
		GameState.update_skill_cooldown(GameState.skill_cooldown_timer, GameState.skill_cooldown_max)

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

	var is_attacking := Input.is_action_pressed("primary_attack")
	var speed_multiplier := GameState.move_speed_penalty if (is_attacking or is_reloading) else 1.0
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
			is_dashing = true
			dash_timer = 0.18
			var aim_dir := (get_global_mouse_position() - global_position).normalized()
			dash_velocity = aim_dir * 620.0
			is_invulnerable = true
			invuln_timer = 0.40
			
			if sfx_skill_dash: sfx_skill_dash.play()
			if sfx_skill_freeze: sfx_skill_freeze.play()
			
			# Pure Mobility Dash + Frost Slow (ZERO screen wipe damage!)
			var enemies = get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if is_instance_valid(e) and global_position.distance_to(e.global_position) < 140.0:
					if e.has_method("apply_freeze"):
						e.apply_freeze(0.4, 3.0)
					if e.has_method("take_damage"):
						e.take_damage(5, aim_dir * 80.0, false) # Minimal 5 DMG, enemies survive!
						
		"vex":
			var aim_dir := (get_global_mouse_position() - global_position).normalized()
			var blink_dest = global_position + aim_dir * (280.0 + GameState.skill_level * 20.0)
			global_position = blink_dest
			is_invulnerable = true
			invuln_timer = 0.4
			if sfx_skill_dash: sfx_skill_dash.play()
			
			var tw := create_tween()
			tw.tween_interval(0.2)
			tw.tween_callback(func():
				var enemies = get_tree().get_nodes_in_group("enemies")
				for e in enemies:
					if is_instance_valid(e) and global_position.distance_to(e.global_position) < 140.0:
						if e.has_method("take_damage"):
							e.take_damage(60 + GameState.skill_level * 10, Vector2.ZERO, false)
			)

		"brutus":
			is_invulnerable = true
			invuln_timer = 2.0
			modulate = Color(2.5, 2.2, 0.4, 1.0) # Yellow Kinetic Shield
			if sfx_skill_slam: sfx_skill_slam.play()
			
			var enemies = get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if is_instance_valid(e):
					var dist = global_position.distance_to(e.global_position)
					if dist < (220.0 + GameState.skill_level * 20.0):
						var to_e = (e.global_position - global_position).normalized()
						if e.has_method("take_damage"):
							e.take_damage(65 + GameState.skill_level * 8, to_e * 380.0, false)

func perform_melee_slash() -> void:
	shoot_cooldown = GameState.fire_rate
	
	if sfx_melee_slash:
		sfx_melee_slash.pitch_scale = randf_range(0.95, 1.1)
		sfx_melee_slash.play()
		
	# Slash visual arc
	if slash_arc_sprite:
		slash_arc_sprite.visible = true
		slash_arc_sprite.rotation = randf_range(-0.3, 0.3)
		slash_arc_sprite.scale = Vector2(1.2, 1.2)
		var tw := create_tween()
		tw.tween_property(slash_arc_sprite, "scale", Vector2(1.4, 1.4), 0.1)
		tw.tween_callback(func(): slash_arc_sprite.visible = false)

	# Melee Cleave: 110px radius in frontal 120 degree arc
	var aim_dir := (get_global_mouse_position() - global_position).normalized()
	var enemies = get_tree().get_nodes_in_group("enemies")
	var hit_any := false
	
	for e in enemies:
		if is_instance_valid(e):
			var to_e = (e.global_position - global_position)
			var dist = to_e.length()
			if dist <= 110.0:
				var angle_diff = absf(aim_dir.angle_to(to_e.normalized()))
				if angle_diff <= deg_to_rad(65.0): # Within frontal arc
					hit_any = true
					if e.has_method("take_damage"):
						# CRUCIAL: from_melee = true triggers 100% Medkit Drop upon kill!
						e.take_damage(GameState.bullet_damage, aim_dir * GameState.bullet_knockback, true)
						
	if hit_any and sfx_melee_hit:
		sfx_melee_hit.play()

func fire_ranged_weapon() -> void:
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
	
	match GameState.primary_weapon:
		"shotgun":
			b.bullet_tex = load("res://assets/sprites/spr_bullet_pellet.png")
			b.lifespan = 0.28 # Point-blank range (< 110px)
		"smg":
			b.bullet_tex = load("res://assets/sprites/spr_bullet_cyan.png")
			b.lifespan = 1.2
		_:
			b.bullet_tex = load("res://assets/sprites/spr_bullet_gold.png") if SaveManager.equipped_weapon_skin == "gold" else load("res://assets/sprites/spr_bullet_cyan.png")
			b.lifespan = 1.6
			
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