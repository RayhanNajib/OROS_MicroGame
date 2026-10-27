extends CharacterBody2D

@export var player_index: int = 1 # 1 = Player 1 (WASD+Mouse), 2 = Player 2 (Arrows+Keypad)
var local_ammo: int = 6
var local_max_ammo: int = 6
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
var dash_trail_timer: float = 0.0
var is_holding_skill: bool = false
var is_melee_swinging: bool = false
var prev_joy_l2: bool = false
var _prev_swap_pressed: bool = false
var _prev_slot1_pressed: bool = false
var _prev_slot2_pressed: bool = false
var lightning_storm_timer: float = 0.0
var ghost_pet_timer: float = 0.0
var ghost_companion_node: Node2D = null
var current_aim_target: Vector2 = Vector2.ZERO
var current_aim_dir: Vector2 = Vector2.RIGHT

# Animation timer
var anim_timer: float = 0.0
var current_frame: int = 0

# Orbital saw instance
var saw_instance: Node2D = null

# VFX references
var muzzle_flash: Sprite2D = null
var shadow_sprite: Sprite2D = null

var ui_lockout_timer: float = 0.0

# 3-Second Position History Buffer (for Chrono Assassin Time Rewind)
var position_history: Array = []
var history_sample_timer: float = 0.0

# Downed & Revive State (Co-op 2P)
var is_downed: bool = false
var revive_progress: float = 0.0
var revive_max_time: float = 1.2
var downed_pulse_timer: float = 0.0
var vo_player: AudioStreamPlayer2D = null
var footstep_player: AudioStreamPlayer2D = null
var footstep_distance: float = 0.0
var footstep_interval: float = 48.0
var footstep_stream: AudioStream = null

var level_up_aura_timer: float = 0.0
var level_up_text_timer: float = 0.0
var level_up_count: int = 1

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

	vo_player = AudioStreamPlayer2D.new()
	vo_player.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
	add_child(vo_player)
	
	footstep_player = AudioStreamPlayer2D.new()
	footstep_player.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
	footstep_player.volume_db = -18.0
	add_child(footstep_player)
	
	var hero_name = (GameState.selected_hero if player_index == 1 else GameState.coop_p2_hero).to_lower()
	var step_path := "res://assets/audio/sfx_step_cyber.wav"
	if hero_name == "brutus":
		step_path = "res://assets/audio/sfx_step_heavy.wav"
	elif hero_name == "vex":
		step_path = "res://assets/audio/sfx_step_scout.wav"
	if ResourceLoader.exists(step_path):
		footstep_stream = load(step_path)
		footstep_player.stream = footstep_stream
		
	GameState.stacked_level_up.connect(_on_stacked_level_up)
		
	if player_index == 2:
		GameState.p2_weapon_slot_swapped.connect(_on_p2_weapon_slot_swapped)
	else:
		GameState.weapon_slot_swapped.connect(_on_weapon_slot_swapped)
		GameState.p1_weapon_slot_swapped.connect(_on_weapon_slot_swapped)
	GameState.screen_shake_requested.connect(_on_screen_shake_requested)
	
	if player_index == 2:
		if camera:
			camera.enabled = false
		modulate = Color(1.15, 0.95, 1.3, 1.0) # Player 2 distinguished neon aura!
		local_max_ammo = GameState.p2_max_ammo
		local_ammo = local_max_ammo
		GameState.p2_ammo = local_ammo
	else:
		local_max_ammo = GameState.p1_max_ammo
		local_ammo = local_max_ammo
		GameState.ammo = local_ammo
		GameState.health = GameState.max_health
		
	update_hero_visuals()
	update_weapon_visuals()
	emit_ammo_update()

func update_hero_visuals() -> void:
	var hero_id = GameState.selected_hero if player_index == 1 else GameState.coop_p2_hero
	var skin_variant: String = SaveManager.get_hero_skin(hero_id) if SaveManager.has_method("get_hero_skin") else SaveManager.equipped_hero_skin
	match hero_id:
		"vex":
			var skin = "res://assets/sprites/skins/player_vex_toxic.png" if skin_variant == "toxic" else "res://assets/sprites/player_vex_run.png"
			body_sprite.texture = load(skin)
		"brutus":
			var skin = "res://assets/sprites/skins/player_brutus_gold.png" if skin_variant == "gold" else "res://assets/sprites/player_brutus_run.png"
			body_sprite.texture = load(skin)
		"nyx":
			var skin = "res://assets/sprites/skins/player_nyx_void.png" if skin_variant == "void" else "res://assets/sprites/player_nyx_run.png"
			body_sprite.texture = load(skin)
		_:
			var skin = "res://assets/sprites/player_kael_run.png"
			if skin_variant == "cobalt":
				skin = "res://assets/sprites/skins/player_kael_cobalt.png"
			elif skin_variant == "crimson":
				skin = "res://assets/sprites/skins/player_kael_crimson.png"
			body_sprite.texture = load(skin)

func update_weapon_visuals() -> void:
	var hero_id = GameState.selected_hero if player_index == 1 else GameState.coop_p2_hero
	var wep_id = GameState.primary_weapon if player_index == 1 else GameState.coop_p2_weapon
	var is_melee: bool = GameState.is_melee_active if player_index == 1 else GameState.p2_is_melee_active
	if is_melee:
		# Character-Specific Melee Weapon
		match hero_id:
			"vex":
				gun_sprite.texture = load("res://assets/sprites/spr_melee_vex.png")
				gun_sprite.position = Vector2(12, 0)
			"brutus":
				gun_sprite.texture = load("res://assets/sprites/spr_melee_brutus.png")
				gun_sprite.position = Vector2(14, 0)
			"nyx":
				gun_sprite.texture = load("res://assets/sprites/spr_melee_nyx.png")
				gun_sprite.position = Vector2(12, 0)
			_:
				gun_sprite.texture = load("res://assets/sprites/spr_melee_kael.png")
				gun_sprite.position = Vector2(12, 0)
		muzzle.position = Vector2(24, 0)
	else:
		# Primary Ranged Weapon
		var wep_skin: String = SaveManager.get_weapon_skin(wep_id) if SaveManager.has_method("get_weapon_skin") else SaveManager.equipped_weapon_skin
		match wep_id:
			"shotgun":
				var wep = "res://assets/sprites/skins/spr_shotgun_cyber.png" if wep_skin == "cyber" else "res://assets/sprites/spr_shotgun.png"
				gun_sprite.texture = load(wep)
				gun_sprite.position = Vector2(14, 0)
				muzzle.position = Vector2(28, 0)
			"smg":
				var wep = "res://assets/sprites/skins/spr_smg_violet.png" if wep_skin == "violet" else "res://assets/sprites/spr_smg.png"
				gun_sprite.texture = load(wep)
				gun_sprite.position = Vector2(10, 0)
				muzzle.position = Vector2(20, 0)
			"railgun":
				var wep = "res://assets/sprites/skins/spr_railgun_cryo.png" if wep_skin == "cryo" else "res://assets/sprites/spr_railgun.png"
				gun_sprite.texture = load(wep)
				gun_sprite.position = Vector2(14, 0)
				muzzle.position = Vector2(32, 0)
			_:
				var wep = "res://assets/sprites/skins/spr_revolver_gold.png" if wep_skin == "gold" else "res://assets/sprites/spr_revolver.png"
				gun_sprite.texture = load(wep)
				gun_sprite.position = Vector2(10, 0)
				muzzle.position = Vector2(20, 0)

func play_hero_vo(event_type: String) -> void:
	var hero = GameState.selected_hero if player_index == 1 else GameState.coop_p2_hero
	var path = "res://assets/audio/vo_%s_%s.wav" % [hero, event_type]
	if ResourceLoader.exists(path):
		var st = load(path)
		if st and vo_player:
			vo_player.stream = st
			vo_player.play()

func _on_p2_weapon_slot_swapped(_slot_idx: int, wep_name: String, is_melee: bool) -> void:
	if player_index != 2: return
	update_weapon_visuals()
	var hero = GameState.coop_p2_hero
	var sound_path = ""
	if is_melee:
		match hero:
			"vex": sound_path = "res://assets/audio/sfx_equip_kunai.wav"
			"brutus": sound_path = "res://assets/audio/sfx_equip_hammer.wav"
			"nyx": sound_path = "res://assets/audio/sfx_equip_scythe.wav"
			"kael": sound_path = "res://assets/audio/sfx_equip_wrench.wav"
			_: sound_path = "res://assets/audio/sfx_equip_wrench.wav"
	else:
		var w = wep_name.to_lower()
		if w.is_empty():
			w = GameState.coop_p2_weapon
		sound_path = "res://assets/audio/sfx_equip_%s.wav" % w

	if ResourceLoader.exists(sound_path):
		var st = load(sound_path)
		if st and sfx_weapon_swap:
			sfx_weapon_swap.stream = st
			sfx_weapon_swap.play()
	elif sfx_weapon_swap:
		sfx_weapon_swap.play()

	is_reloading = false
	reload_timer = 0.0
	shoot_cooldown = 0.15 # Brief readying delay
	emit_ammo_update()

func _on_weapon_slot_swapped(_slot_idx: int, wep_name: String, is_melee: bool) -> void:
	if player_index != 1: return
	update_weapon_visuals()
	var hero = GameState.selected_hero
	var sound_path = ""
	if is_melee:
		match hero:
			"vex": sound_path = "res://assets/audio/sfx_equip_kunai.wav"
			"brutus": sound_path = "res://assets/audio/sfx_equip_hammer.wav"
			"nyx": sound_path = "res://assets/audio/sfx_equip_scythe.wav"
			"kael": sound_path = "res://assets/audio/sfx_equip_wrench.wav"
			_: sound_path = "res://assets/audio/sfx_equip_wrench.wav"
	else:
		var w = wep_name.to_lower()
		if w.is_empty():
			w = GameState.primary_weapon if player_index == 1 else GameState.coop_p2_weapon
		sound_path = "res://assets/audio/sfx_equip_%s.wav" % w

	if ResourceLoader.exists(sound_path):
		var st = load(sound_path)
		if st and sfx_weapon_swap:
			sfx_weapon_swap.stream = st
			sfx_weapon_swap.play()
	elif sfx_weapon_swap:
		sfx_weapon_swap.play()

	is_reloading = false
	reload_timer = 0.0
	shoot_cooldown = 0.15 # Brief readying delay
	emit_ammo_update()

func _on_screen_shake_requested(intensity: float, duration: float) -> void:
	if not camera or not camera.enabled: return
	var mult: float = 1.0
	if has_node("/root/SaveManager"):
		mult = get_node("/root/SaveManager").screen_shake_strength
	if mult <= 0.01: return
	var tw := create_tween()
	var act_intensity = intensity * mult
	tw.tween_property(camera, "offset", Vector2(randf_range(-act_intensity, act_intensity), randf_range(-act_intensity, act_intensity)), duration * 0.5)
	tw.tween_property(camera, "offset", Vector2.ZERO, duration * 0.5)

func _process(delta: float) -> void:
	if is_downed:
		velocity = Vector2.ZERO
		downed_pulse_timer += delta * 4.5
		# Check if the other player is within reviving range
		var other_p: Node2D = null
		for p in get_tree().get_nodes_in_group("player"):
			if p != self and is_instance_valid(p) and not p.get("is_downed"):
				other_p = p
				break
		if other_p and global_position.distance_to(other_p.global_position) <= 85.0:
			revive_progress += delta
			if revive_progress >= revive_max_time:
				revive_from_downed()
		else:
			revive_progress = maxf(0.0, revive_progress - delta * 1.5)
		
		queue_redraw()
		return

	# Weapon swap timer tick
	if player_index == 1:
		if GameState.swap_cooldown_timer > 0.0:
			GameState.swap_cooldown_timer -= delta
	else:
		if GameState.p2_swap_cooldown_timer > 0.0:
			GameState.p2_swap_cooldown_timer -= delta

	# 1. Aim gun towards target & Dynamic Cursor Look-Ahead Camera (100px max)
	var is_gamepad: bool = false
	var dev_id: int = -1
	if has_node("/root/InputManager"):
		var im = get_node("/root/InputManager")
		dev_id = im.p1_device_id if player_index == 1 else im.p2_device_id
		is_gamepad = (im.p1_scheme != "keyboard" if player_index == 1 else im.p2_scheme != "keyboard")
		
	var rjoy_x := Input.get_joy_axis(dev_id, JOY_AXIS_RIGHT_X) if dev_id >= 0 else 0.0
	var rjoy_y := Input.get_joy_axis(dev_id, JOY_AXIS_RIGHT_Y) if dev_id >= 0 else 0.0
	var rjoy_vec := Vector2(rjoy_x, rjoy_y)

	var ljoy_x := Input.get_joy_axis(dev_id, JOY_AXIS_LEFT_X) if dev_id >= 0 else 0.0
	var ljoy_y := Input.get_joy_axis(dev_id, JOY_AXIS_LEFT_Y) if dev_id >= 0 else 0.0
	var ljoy_vec := Vector2(ljoy_x, ljoy_y)

	if is_gamepad:
		if rjoy_vec.length() > 0.22:
			current_aim_dir = rjoy_vec.normalized()
			current_aim_target = global_position + current_aim_dir * 220.0
		elif ljoy_vec.length() > 0.20:
			current_aim_dir = ljoy_vec.normalized()
			current_aim_target = global_position + current_aim_dir * 220.0
		elif velocity.length() > 8.0:
			current_aim_dir = velocity.normalized()
			current_aim_target = global_position + current_aim_dir * 220.0
		else:
			current_aim_target = global_position + current_aim_dir * 220.0
	elif player_index == 1:
		var cam_ctrl = get_tree().get_first_node_in_group("coop_camera")
		if cam_ctrl and cam_ctrl.get("is_split") and cam_ctrl.has_method("get_p1_mouse_world_pos"):
			current_aim_target = cam_ctrl.get_p1_mouse_world_pos()
		else:
			current_aim_target = get_global_mouse_position()
		current_aim_dir = (current_aim_target - global_position).normalized()
	else:
		# Auto-aim nearest enemy or move direction for Player 2
		var nearest_e: Node2D = null
		var min_d := 480.0
		for e in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e):
				var d = global_position.distance_to(e.global_position)
				if d < min_d:
					min_d = d
					nearest_e = e
		if nearest_e:
			current_aim_target = nearest_e.global_position
			current_aim_dir = (current_aim_target - global_position).normalized()
		elif velocity.length() > 5.0:
			current_aim_dir = velocity.normalized()
			current_aim_target = global_position + current_aim_dir * 140.0
		else:
			current_aim_target = global_position + current_aim_dir * 140.0
			
	weapon_pivot.look_at(current_aim_target)
	
	if camera and player_index == 1:
		var look_offset = (current_aim_target - global_position) * 0.22
		look_offset = look_offset.limit_length(100.0)
		camera.offset = camera.offset.move_toward(look_offset, 280.0 * delta)
	
	# Smoothly return gun pivot after recoil
	weapon_pivot.position = weapon_pivot.position.move_toward(Vector2(0, 3), 40.0 * delta)
	
	# Flip character & gun based on aim angle
	if current_aim_target.x < global_position.x:
		body_sprite.flip_h = true
		weapon_pivot.scale.y = -1.0
	else:
		body_sprite.flip_h = false
		weapon_pivot.scale.y = 1.0

	# 2. Orbital Saw Check
	if GameState.has_orbital_saw and not is_instance_valid(saw_instance):
		saw_instance = orbital_saw_scene.instantiate()
		saw_instance.player = self
		get_parent().add_child(saw_instance)

	# 3. Reloading Cycle & Above-Head Progress Bar
	if is_reloading:
		reload_timer += delta
		var pct := clampf(reload_timer / GameState.reload_duration, 0.0, 1.0)
		emit_ammo_update(pct)
		
		# 360-degree weapon reload spin animation
		if is_instance_valid(gun_sprite):
			var spin_direction: float = -1.0 if weapon_pivot.scale.y < 0.0 else 1.0
			gun_sprite.rotation = pct * TAU * spin_direction
			
		queue_redraw()
		
		if reload_bar:
			reload_bar.visible = false
			
		if reload_timer >= GameState.reload_duration:
			finish_reload()
			if is_instance_valid(gun_sprite):
				gun_sprite.rotation = 0.0
			queue_redraw()
	else:
		if is_instance_valid(gun_sprite) and gun_sprite.rotation != 0.0:
			gun_sprite.rotation = 0.0
		if reload_bar:
			reload_bar.visible = false
		var is_melee = GameState.is_melee_active if player_index == 1 else GameState.p2_is_melee_active
		if not is_melee and local_ammo < local_max_ammo:
			var joy_reload := (dev_id >= 0 and Input.is_joy_button_pressed(dev_id, JOY_BUTTON_X))
			var want_reload: bool = (Input.is_action_just_pressed("reload") or joy_reload) if player_index == 1 else (Input.is_physical_key_pressed(KEY_KP_3) or (InputMap.has_action("p2_reload") and Input.is_action_just_pressed("p2_reload")) or joy_reload)
			if want_reload:
				start_reload()

	# 4. Shooting / Melee Slashing
	if shoot_cooldown > 0.0:
		shoot_cooldown -= delta
		
	var joy_shoot := (dev_id >= 0 and Input.get_joy_axis(dev_id, JOY_AXIS_TRIGGER_RIGHT) > 0.35)
	var joy_melee := (dev_id >= 0 and Input.get_joy_axis(dev_id, JOY_AXIS_TRIGGER_LEFT) > 0.35)
	
	# L2 Trigger (Left Trigger / LT) is dedicated Melee attack & slot switch!
	if joy_melee:
		if player_index == 1 and not GameState.is_melee_active:
			GameState.equip_slot(2)
		elif player_index == 2 and not GameState.p2_is_melee_active:
			GameState.equip_p2_slot(2)
		if not is_reloading and shoot_cooldown <= 0.0:
			perform_melee_slash()
	# R2 Trigger (Right Trigger / RT) is dedicated Primary Gun attack & slot switch!
	elif joy_shoot:
		if player_index == 1 and GameState.is_melee_active:
			GameState.equip_slot(1)
		elif player_index == 2 and GameState.p2_is_melee_active:
			GameState.equip_p2_slot(1)
		if not is_reloading and shoot_cooldown <= 0.0:
			if local_ammo > 0:
				fire_ranged_weapon()
			else:
				start_reload()
	else:
		var is_trying_to_attack: bool = (Input.is_action_pressed("primary_attack") if player_index == 1 else (Input.is_physical_key_pressed(KEY_KP_0) or Input.is_physical_key_pressed(KEY_ENTER) or (InputMap.has_action("p2_attack") and Input.is_action_pressed("p2_attack"))))
		if is_trying_to_attack and not is_reloading and shoot_cooldown <= 0.0:
			if (GameState.is_melee_active if player_index == 1 else GameState.p2_is_melee_active):
				perform_melee_slash()
			else:
				if local_ammo > 0:
					fire_ranged_weapon()
				else:
					start_reload()

	# 5. Weapon Swap Inputs (Y Button, Q Key, 1/2 Keys, or Numpad Keys)
	var cur_swap_cd = GameState.swap_cooldown_timer if player_index == 1 else GameState.p2_swap_cooldown_timer
	if not get_tree().paused and cur_swap_cd <= 0.0:
		var im = get_node_or_null("/root/InputManager")
		var p1_dev: int = im.p1_device_id if im else 0
		var p2_dev: int = im.p2_device_id if im else -1
		if player_index == 1:
			var joy_swap_p1 := (dev_id >= 0 and dev_id == p1_dev and Input.is_joy_button_pressed(dev_id, JOY_BUTTON_Y))
			var swap_pressed := (Input.is_physical_key_pressed(KEY_Q) or (InputMap.has_action("swap_weapon") and Input.is_action_pressed("swap_weapon")) or joy_swap_p1)
			if swap_pressed and not _prev_swap_pressed:
				GameState.toggle_slot()
			_prev_swap_pressed = swap_pressed
			
			var slot1_pressed := Input.is_physical_key_pressed(KEY_1)
			if slot1_pressed and not _prev_slot1_pressed:
				GameState.equip_slot(1)
			_prev_slot1_pressed = slot1_pressed
			
			var slot2_pressed := Input.is_physical_key_pressed(KEY_2)
			if slot2_pressed and not _prev_slot2_pressed:
				GameState.equip_slot(2)
			_prev_slot2_pressed = slot2_pressed
		else:
			var joy_swap_p2 := (dev_id >= 0 and dev_id == p2_dev and Input.is_joy_button_pressed(dev_id, JOY_BUTTON_Y))
			var swap_pressed := (Input.is_physical_key_pressed(KEY_KP_7) or (InputMap.has_action("p2_swap") and Input.is_action_pressed("p2_swap")) or joy_swap_p2)
			if swap_pressed and not _prev_swap_pressed:
				GameState.toggle_p2_slot()
			_prev_swap_pressed = swap_pressed
			
			var slot1_pressed := Input.is_physical_key_pressed(KEY_KP_1)
			if slot1_pressed and not _prev_slot1_pressed:
				GameState.equip_p2_slot(1)
			_prev_slot1_pressed = slot1_pressed
			
			var slot2_pressed := Input.is_physical_key_pressed(KEY_KP_2)
			if slot2_pressed and not _prev_slot2_pressed:
				GameState.equip_p2_slot(2)
			_prev_slot2_pressed = slot2_pressed

	# 6. Active Character Skill (L1 or R1 on gamepad, E/Space on P1 KBM, KP_9 on P2 KBM)
	var cur_skill_cd: float = GameState.skill_cooldown_timer if player_index == 1 else GameState.p2_skill_cooldown_timer
	var im_skill = get_node_or_null("/root/InputManager")
	var p1_dev_s: int = im_skill.p1_device_id if im_skill else 0
	var p2_dev_s: int = im_skill.p2_device_id if im_skill else -1
	var skill_key_pressed := false
	if player_index == 1:
		var joy_skill_p1 := (dev_id >= 0 and dev_id == p1_dev_s and (Input.is_joy_button_pressed(dev_id, JOY_BUTTON_LEFT_SHOULDER) or Input.is_joy_button_pressed(dev_id, JOY_BUTTON_RIGHT_SHOULDER)))
		skill_key_pressed = (Input.is_physical_key_pressed(KEY_E) or Input.is_physical_key_pressed(KEY_SPACE) or (InputMap.has_action("skill_action") and Input.is_action_pressed("skill_action")) or joy_skill_p1)
	else:
		var joy_skill_p2 := (dev_id >= 0 and dev_id == p2_dev_s and (Input.is_joy_button_pressed(dev_id, JOY_BUTTON_LEFT_SHOULDER) or Input.is_joy_button_pressed(dev_id, JOY_BUTTON_RIGHT_SHOULDER)))
		skill_key_pressed = (Input.is_physical_key_pressed(KEY_KP_9) or (InputMap.has_action("p2_skill") and Input.is_action_pressed("p2_skill")) or joy_skill_p2)

	if skill_key_pressed and cur_skill_cd <= 0.0 and not is_dashing:
		is_holding_skill = true
	elif is_holding_skill and not skill_key_pressed:
		is_holding_skill = false
		trigger_active_skill()

	# 7. Smooth Dynamic Character Scaling (20MTD Tome System)
	var target_scale = Vector2(GameState.player_scale_mult, GameState.player_scale_mult)
	if scale != target_scale:
		scale = scale.move_toward(target_scale, delta * 3.0)

	# 7. Update Skill Telegraphing Projection Indicator (Only visible while holding!)
	update_skill_telegraph(current_aim_target)

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

func update_skill_telegraph(target_pos: Vector2) -> void:
	if not telegraph_line: return
	
	var cur_skill_cd = GameState.skill_cooldown_timer if player_index == 1 else GameState.p2_skill_cooldown_timer
	if not is_holding_skill or cur_skill_cd > 0.0:
		telegraph_line.visible = false
		return
		
	telegraph_line.visible = true
	telegraph_line.clear_points()
	
	var to_target := (target_pos - global_position)
	var dir := to_target.normalized() if to_target.length() > 5.0 else current_aim_dir
	
	var cur_hero = GameState.selected_hero if player_index == 1 else GameState.coop_p2_hero
	match cur_hero:
		"kael":
			# Cyan dashed laser arrow in aimed direction (260px)
			telegraph_line.default_color = Color(0.0, 0.94, 1.0, 0.8)
			telegraph_line.add_point(Vector2.ZERO)
			telegraph_line.add_point(dir * 260.0)
		"vex":
			# Emerald green target point in aimed direction (320px)
			telegraph_line.default_color = Color(0.13, 0.95, 0.4, 0.8)
			telegraph_line.add_point(Vector2.ZERO)
			telegraph_line.add_point(dir * 320.0)
		"brutus":
			# High-voltage yellow circular ring around hero (+30% area, presisi 1:1 dengan radius damage)
			var s_lvl: int = GameState.skill_level if player_index == 1 else GameState.p2_skill_level
			var brutus_radius: float = (220.0 + s_lvl * 20.0) * 0.40 * 1.30
			telegraph_line.default_color = Color(1.0, 0.9, 0.1, 0.8)
			var pts := 32
			for i in range(pts + 1):
				var ang = (float(i) / float(pts)) * TAU
				telegraph_line.add_point(Vector2(cos(ang), sin(ang)) * brutus_radius)
		"nyx":
			# Glowing violet-magenta singularity targeting beam & vortex ring (117px - nerfed 55%) exactly at target!
			telegraph_line.default_color = Color(0.85, 0.25, 1.0, 0.85)
			telegraph_line.add_point(Vector2.ZERO)
			telegraph_line.add_point(to_target)
			var pts := 24
			for i in range(pts + 1):
				var ang = (float(i) / float(pts)) * TAU
				telegraph_line.add_point(to_target + Vector2(cos(ang), sin(ang)) * 117.0)

func _physics_process(delta: float) -> void:
	if is_downed:
		velocity = Vector2.ZERO
		return

	if player_index == 1:
		if GameState.skill_cooldown_timer > 0.0:
			GameState.skill_cooldown_timer -= delta
			GameState.update_skill_cooldown(GameState.skill_cooldown_timer, GameState.skill_cooldown_max)
	else:
		if GameState.p2_skill_cooldown_timer > 0.0:
			GameState.p2_skill_cooldown_timer -= delta
			GameState.update_p2_skill_cooldown(GameState.p2_skill_cooldown_timer, GameState.p2_skill_cooldown_max)

	if ui_lockout_timer > 0.0:
		ui_lockout_timer -= delta

	# Track player location history for chronomancy skills (3.2 seconds window)
	history_sample_timer += delta
	if history_sample_timer >= 0.05:
		history_sample_timer = 0.0
		position_history.append(global_position)
		if position_history.size() > 64:
			position_history.pop_front()

	if is_dashing:
		dash_timer -= delta
		dash_trail_timer -= delta
		if dash_trail_timer <= 0.0:
			dash_trail_timer = 0.04
			spawn_dash_ghost()

		velocity = dash_velocity
		move_and_slide()
		
		# Hero Ramming Dash (collision attack & squish animation)
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if is_instance_valid(e) and global_position.distance_to(e.global_position) < 42.0:
				if not e.has_meta("rammed_this_dash"):
					e.set_meta("rammed_this_dash", true)
					if e.has_method("take_damage"):
						var ram_dmg = 45 + GameState.skill_level * 10
						e.take_damage(ram_dmg, dash_velocity.normalized() * 320.0, true)
					if e.has_method("apply_freeze"):
						e.apply_freeze(0.2, 1.5)
					# Screen shake on impact
					GameState.screen_shake_requested.emit(5.0, 0.15)
					
		if dash_timer <= 0.0:
			is_dashing = false
			# Clear ram tags
			for e in enemies:
				if is_instance_valid(e) and e.has_meta("rammed_this_dash"):
					e.remove_meta("rammed_this_dash")
			# Reset squish visual
			if body_sprite:
				var tw = create_tween()
				tw.tween_property(body_sprite, "scale", Vector2(1, 1), 0.1)
		return

	# Passive Skill: Random Cyber Thunderstorm
	if GameState.has_random_lightning:
		lightning_storm_timer += delta
		if lightning_storm_timer >= 2.5:
			lightning_storm_timer = 0.0
			trigger_random_lightning_strike()

	# Passive Skill: Chrono Ghost Companion
	if GameState.has_ghost_pet:
		update_ghost_companion(delta)

	var input_vector := Vector2.ZERO
	var dev_id: int = -1
	if has_node("/root/InputManager"):
		var im = get_node("/root/InputManager")
		dev_id = im.p1_device_id if player_index == 1 else im.p2_device_id

	# Analog Stick / D-Pad movement
	if dev_id >= 0:
		var joy_x := Input.get_joy_axis(dev_id, JOY_AXIS_LEFT_X)
		var joy_y := Input.get_joy_axis(dev_id, JOY_AXIS_LEFT_Y)
		if Vector2(joy_x, joy_y).length() > 0.18:
			input_vector = Vector2(joy_x, joy_y)

	if input_vector == Vector2.ZERO:
		if player_index == 1:
			input_vector.x = Input.get_axis("move_left", "move_right")
			input_vector.y = Input.get_axis("move_up", "move_down")
			if input_vector == Vector2.ZERO:
				if Input.is_physical_key_pressed(KEY_A): input_vector.x -= 1.0
				if Input.is_physical_key_pressed(KEY_D): input_vector.x += 1.0
				if Input.is_physical_key_pressed(KEY_W): input_vector.y -= 1.0
				if Input.is_physical_key_pressed(KEY_S): input_vector.y += 1.0
		else:
			if InputMap.has_action("p2_move_left") and Input.is_action_pressed("p2_move_left"): input_vector.x -= 1.0
			if InputMap.has_action("p2_move_right") and Input.is_action_pressed("p2_move_right"): input_vector.x += 1.0
			if InputMap.has_action("p2_move_up") and Input.is_action_pressed("p2_move_up"): input_vector.y -= 1.0
			if InputMap.has_action("p2_move_down") and Input.is_action_pressed("p2_move_down"): input_vector.y += 1.0
			if input_vector == Vector2.ZERO:
				if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_KP_4): input_vector.x -= 1.0
				if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_KP_6): input_vector.x += 1.0
				if Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_KP_8): input_vector.y -= 1.0
				if Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_KP_2): input_vector.y += 1.0
				
	input_vector = input_vector.normalized()

	var is_attacking: bool = (Input.is_action_pressed("primary_attack") or (dev_id >= 0 and Input.get_joy_axis(dev_id, JOY_AXIS_TRIGGER_RIGHT) > 0.35)) if player_index == 1 else (Input.is_physical_key_pressed(KEY_KP_0) or Input.is_physical_key_pressed(KEY_SLASH) or (InputMap.has_action("p2_attack") and Input.is_action_pressed("p2_attack")) or (dev_id >= 0 and Input.get_joy_axis(dev_id, JOY_AXIS_TRIGGER_RIGHT) > 0.35))
	var speed_multiplier := GameState.move_speed_penalty if (is_attacking or is_reloading) else 1.0
	var target_speed := GameState.base_speed * speed_multiplier

	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * target_speed, 1200.0 * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 1400.0 * delta)

	move_and_slide()

	# Footsteps sound throttling per character
	if velocity.length() > 30.0 and footstep_player and footstep_stream:
		footstep_distance += velocity.length() * delta
		if footstep_distance >= footstep_interval:
			footstep_distance = 0.0
			footstep_player.pitch_scale = randf_range(0.94, 1.06)
			footstep_player.play()

	# Level-up visuals decay
	if level_up_aura_timer > 0.0:
		level_up_aura_timer = maxf(0.0, level_up_aura_timer - delta)
		queue_redraw()
	if level_up_text_timer > 0.0:
		level_up_text_timer = maxf(0.0, level_up_text_timer - delta)
		queue_redraw()

func _on_stacked_level_up(count: int) -> void:
	level_up_count = count
	level_up_aura_timer = 1.8
	level_up_text_timer = 1.8
	queue_redraw()

func trigger_active_skill() -> void:
	if player_index == 1:
		GameState.skill_cooldown_timer = GameState.skill_cooldown_max
		GameState.update_skill_cooldown(GameState.skill_cooldown_timer, GameState.skill_cooldown_max)
	else:
		GameState.p2_skill_cooldown_timer = GameState.p2_skill_cooldown_max
		GameState.update_p2_skill_cooldown(GameState.p2_skill_cooldown_timer, GameState.p2_skill_cooldown_max)
	play_hero_vo("skill")
	var active_hero = GameState.selected_hero if player_index == 1 else GameState.coop_p2_hero
	var s_lvl := GameState.skill_level if player_index == 1 else GameState.p2_skill_level
	if has_node("/root/InputManager"):
		get_node("/root/InputManager").vibrate_skill(active_hero, player_index)
	
	match active_hero:
		"kael":
			is_dashing = true
			dash_timer = 0.28
			var aim_dir := current_aim_dir
			dash_velocity = aim_dir * 720.0
			is_invulnerable = true
			invuln_timer = 0.42
			
			if sfx_skill_dash: sfx_skill_dash.play()
			if sfx_skill_freeze: sfx_skill_freeze.play()
			
			# Dynamic ram squish animation
			if body_sprite:
				var tw = create_tween()
				tw.tween_property(body_sprite, "scale", Vector2(1.5, 0.65), 0.08)
				tw.tween_property(body_sprite, "scale", Vector2(0.85, 1.25), 0.12)
				tw.tween_property(body_sprite, "scale", Vector2(1.0, 1.0), 0.10)
				
			# Initial shockwave
			var enemies = get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if is_instance_valid(e) and global_position.distance_to(e.global_position) < 140.0:
					if e.has_method("apply_freeze"):
						e.apply_freeze(0.4, 3.0)
					if e.has_method("take_damage"):
						e.take_damage(15, aim_dir * 120.0, false)
						
		"vex":
			is_dashing = true
			dash_timer = 0.20
			var aim_dir := current_aim_dir
			dash_velocity = aim_dir * 640.0
			is_invulnerable = true
			invuln_timer = 0.38
			if sfx_skill_dash: sfx_skill_dash.play()
			
			# Spawn Chrono Assassin Rewind Clone at starting position with past trajectory
			var decoy_scene = load("res://scenes/entities/ShadowDecoy.tscn")
			if decoy_scene:
				var decoy = decoy_scene.instantiate()
				decoy.global_position = global_position
				if position_history.size() > 0:
					decoy.set("recorded_path", position_history.duplicate())
				get_parent().call_deferred("add_child", decoy)

		"brutus":
			is_invulnerable = true
			invuln_timer = 2.0
			modulate = Color(2.5, 2.2, 0.4, 1.0) # Yellow Kinetic Shield
			if sfx_skill_slam: sfx_skill_slam.play()
			if has_node("/root/InputManager"):
				get_node("/root/InputManager").vibrate_explosion(1.0)
			
			# Indikator area diperbesar 30%, akurat 1:1 di dalam zona
			var brutus_radius: float = (220.0 + s_lvl * 20.0) * 0.40 * 1.30
			var brutus_dmg: int = maxi(1, int(round((65.0 + s_lvl * 8.0) * 0.40)))
			
			# Visual ground shockwave ring matching exact radius
			var shock_line = Line2D.new()
			shock_line.width = 5.0
			shock_line.default_color = Color(2.5, 2.2, 0.4, 0.9)
			shock_line.top_level = true
			shock_line.global_position = global_position
			var pts := 32
			for i in range(pts + 1):
				var ang = (float(i) / float(pts)) * TAU
				shock_line.add_point(Vector2(cos(ang), sin(ang)) * brutus_radius)
			get_parent().add_child(shock_line)
			var tw = shock_line.create_tween()
			tw.tween_property(shock_line, "modulate:a", 0.0, 0.35)
			tw.tween_callback(shock_line.queue_free)
			
			var enemies = get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if is_instance_valid(e):
					var dist = global_position.distance_to(e.global_position)
					# Akurat di dalam zona (memperhitungkan boundary tubuh musuh agar presisi)
					if dist <= (brutus_radius + 12.0):
						var to_e = (e.global_position - global_position).normalized()
						if e.has_method("take_damage"):
							e.take_damage(brutus_dmg, to_e * 240.0, false)

		"nyx":
			# Void Singularity: Spawns real pulsating gravitational black hole vortex!
			# Nerf Nyx: Radius -55% (remaining 45%), Damage -55% (remaining 45%)
			var target_pos := current_aim_target
			is_invulnerable = true
			invuln_timer = 0.40
			if sfx_skill_freeze: sfx_skill_freeze.play()
			
			var vortex_scene = load("res://scenes/entities/VoidVortex.tscn")
			if vortex_scene:
				var vortex = vortex_scene.instantiate()
				vortex.global_position = target_pos
				vortex.radius = 117.0 # Nerfed by 55% (was 260px)
				vortex.tick_damage = maxi(1, int(round((14.0 + s_lvl * 3.0) * 0.45))) # Nerfed by 55%
				vortex.final_damage = maxi(1, int(round((45.0 + s_lvl * 8.0) * 0.45))) # Nerfed by 55%
				get_parent().call_deferred("add_child", vortex)

	# Ensure HP and Ammo HUDs are immediately synchronized whenever a skill is activated
	if player_index == 1:
		GameState.health_changed.emit(GameState.health, GameState.max_health)
		GameState.p1_health_changed.emit(GameState.health, GameState.max_health)
		emit_ammo_update(0.0)
	else:
		GameState.p2_health_changed.emit(GameState.p2_health, GameState.p2_max_health)
		emit_ammo_update(0.0)

func sync_stats_from_game_state() -> void:
	if player_index == 1:
		local_max_ammo = GameState.max_ammo
		local_ammo = mini(local_ammo, local_max_ammo)
		GameState.health_changed.emit(GameState.health, GameState.max_health)
		GameState.p1_health_changed.emit(GameState.health, GameState.max_health)
	else:
		local_max_ammo = GameState.p2_max_ammo
		local_ammo = mini(local_ammo, local_max_ammo)
		GameState.p2_health_changed.emit(GameState.p2_health, GameState.p2_max_health)
	emit_ammo_update(0.0)

func perform_melee_slash() -> void:
	if is_melee_swinging: return
	is_melee_swinging = true
	var melee_rate := maxf(0.36, GameState.fire_rate)
	shoot_cooldown = melee_rate
	var active_hero = GameState.selected_hero if player_index == 1 else GameState.coop_p2_hero
	var aim_dir := current_aim_dir
	if has_node("/root/InputManager"):
		var im = get_node("/root/InputManager")
		var dev = im.p1_device_id if player_index == 1 else im.p2_device_id
		if dev >= 0:
			var rx = Input.get_joy_axis(dev, JOY_AXIS_RIGHT_X)
			var ry = Input.get_joy_axis(dev, JOY_AXIS_RIGHT_Y)
			var r_vec = Vector2(rx, ry)
			if r_vec.length() > 0.22:
				aim_dir = r_vec.normalized()
			else:
				var lx = Input.get_joy_axis(dev, JOY_AXIS_LEFT_X)
				var ly = Input.get_joy_axis(dev, JOY_AXIS_LEFT_Y)
				var l_vec = Vector2(lx, ly)
				if l_vec.length() > 0.20:
					aim_dir = l_vec.normalized()
	if aim_dir.length() < 0.1:
		if velocity.length() > 5.0:
			aim_dir = velocity.normalized()
		elif body_sprite and body_sprite.flip_h:
			aim_dir = Vector2.LEFT
		else:
			aim_dir = Vector2.RIGHT
	current_aim_dir = aim_dir
			
	# Balanced physical lunge impulse
	velocity += aim_dir * 45.0

	if has_node("/root/InputManager"):
		get_node("/root/InputManager").vibrate_melee(active_hero, player_index)
	
	# Character-specific melee swing SFX
	if sfx_melee_slash:
		match active_hero:
			"vex":
				sfx_melee_slash.stream = load("res://assets/audio/sfx_melee_kunai.wav")
			"brutus":
				sfx_melee_slash.stream = load("res://assets/audio/sfx_melee_hammer.wav")
			"nyx":
				sfx_melee_slash.stream = load("res://assets/audio/sfx_melee_scythe.wav")
			_:
				sfx_melee_slash.stream = load("res://assets/audio/sfx_melee_wrench.wav")
		sfx_melee_slash.pitch_scale = randf_range(0.96, 1.04)
		sfx_melee_slash.play()
		
	# Character-specific slash color and precision cursor rotation
	if slash_arc_sprite:
		slash_arc_sprite.visible = true
		slash_arc_sprite.rotation = aim_dir.angle()
		slash_arc_sprite.position = aim_dir * 28.0
		match active_hero:
			"vex":
				slash_arc_sprite.modulate = Color(0.2, 2.5, 0.8, 1.0)
			"brutus":
				slash_arc_sprite.modulate = Color(2.5, 2.0, 0.3, 1.0)
			"nyx":
				slash_arc_sprite.modulate = Color(1.8, 0.4, 2.5, 1.0)
			_:
				slash_arc_sprite.modulate = Color(0.3, 2.2, 2.5, 1.0)
				
		slash_arc_sprite.scale = Vector2(1.2, 1.2)
		var tw := create_tween()
		tw.tween_property(slash_arc_sprite, "scale", Vector2(1.5, 1.5), 0.12)
		tw.tween_callback(func(): 
			if is_instance_valid(slash_arc_sprite): slash_arc_sprite.visible = false
			is_melee_swinging = false
		)
	else:
		var tw := create_tween()
		tw.tween_interval(0.20)
		tw.tween_callback(func(): is_melee_swinging = false)

	# Melee Cleave: 125px radius in frontal 140 degree arc
	var enemies = get_tree().get_nodes_in_group("enemies")
	var hit_any := false
	
	for e in enemies:
		if is_instance_valid(e):
			var to_e = (e.global_position - global_position)
			var dist = to_e.length()
			if dist <= 125.0:
				var angle_diff = absf(aim_dir.angle_to(to_e.normalized()))
				if angle_diff <= deg_to_rad(70.0): # Within frontal arc
					hit_any = true
					if e.has_method("take_damage"):
						var melee_lvl_scale: float = 1.0 + 0.3 * float(maxi(0, int(GameState.level) - 1))
						var dmg: int = int(float(GameState.bullet_damage) * 1.5 * melee_lvl_scale)
						# 20 Minutes Till Dawn Assassin Execution (<20% HP)
						if GameState.has_assassin and not e.is_in_group("boss"):
							var e_hp = e.get("health")
							var e_max = e.get("max_health")
							if e_hp and e_max and (float(e_hp) / float(e_max)) <= 0.20:
								dmg = int(float(e_max) * 2.0)
								
						# CRUCIAL: from_melee = true triggers 100% Medkit Drop upon kill!
						e.take_damage(dmg, aim_dir * GameState.bullet_knockback, true)
						
	if hit_any and sfx_melee_hit:
		sfx_melee_hit.play()

func fire_ranged_weapon() -> void:
	var eff_rate: float = GameState.fire_rate
	if GameState.excitement_timer > 0.0: eff_rate *= 0.5
	if GameState.anger_point_timer > 0.0: eff_rate *= 0.6
	shoot_cooldown = maxf(0.04, eff_rate)
	var wep_type = GameState.primary_weapon if player_index == 1 else GameState.coop_p2_weapon
	if has_node("/root/InputManager"):
		get_node("/root/InputManager").vibrate_shot(wep_type, player_index)
	
	local_ammo -= 1
	if player_index == 1:
		GameState.ammo = local_ammo
	else:
		GameState.p2_ammo = local_ammo
	emit_ammo_update(0.0)
	
	var base_angle := weapon_pivot.rotation
	var aim_dir := Vector2.RIGHT.rotated(base_angle)

	# Distinct Weapon-Specific SFX, Muzzle & Recoil Impulse
	match wep_type:
		"shotgun":
			if sfx_gunshot:
				sfx_gunshot.stream = load("res://assets/audio/sfx_shotgun.wav")
				sfx_gunshot.pitch_scale = randf_range(0.94, 1.06)
				sfx_gunshot.play()
			if muzzle_flash:
				muzzle_flash.texture = load("res://assets/sprites/spr_muzzle_shotgun.png")
				muzzle.position = Vector2(28, 0)
			velocity -= aim_dir * 170.0 # Heavy shotgun kickback!
		"railgun":
			if sfx_gunshot:
				sfx_gunshot.stream = load("res://assets/audio/sfx_railgun.wav")
				sfx_gunshot.pitch_scale = randf_range(0.96, 1.04)
				sfx_gunshot.play()
			if muzzle_flash:
				muzzle_flash.texture = load("res://assets/sprites/spr_muzzle_railgun.png")
				muzzle.position = Vector2(34, 0)
			velocity -= aim_dir * 110.0 # High-voltage plasma kickback
		"smg":
			if sfx_gunshot:
				sfx_gunshot.stream = load("res://assets/audio/sfx_smg.wav")
				sfx_gunshot.pitch_scale = randf_range(0.93, 1.07)
				sfx_gunshot.play()
			if muzzle_flash:
				muzzle_flash.texture = load("res://assets/sprites/spr_muzzle_smg.png")
				muzzle.position = Vector2(22, 0)
		_:
			if sfx_gunshot:
				sfx_gunshot.stream = load("res://assets/audio/sfx_revolver.wav")
				sfx_gunshot.pitch_scale = randf_range(0.92, 1.08)
				sfx_gunshot.play()
			if muzzle_flash:
				muzzle_flash.texture = load("res://assets/sprites/spr_muzzle_revolver.png")
				muzzle.position = Vector2(24, 0)

	weapon_pivot.position = Vector2(0, 3) - aim_dir * 5.0
	
	if muzzle_flash:
		muzzle_flash.visible = true
		muzzle_flash.rotation = randf_range(-0.15, 0.15)
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

	# 20MTD Omni Burst Protocol: Shoots radial 8-direction 360 ring of bullets!
	if GameState.has_omni_burst:
		var omni_bullets: int = 8
		for oi in range(omni_bullets):
			var o_ang: float = base_angle + (TAU / float(omni_bullets)) * float(oi)
			spawn_bullet(o_ang)

	# 20MTD Fan Fire (Burst 8 bullets in 360 circle on last ammo)
	if local_ammo == 0 and GameState.has_fan_fire:
		for fi in range(8):
			var f_ang: float = (TAU / 8.0) * float(fi)
			spawn_bullet(f_ang)

	# 20MTD Tome of Electro: Call lightning storm on last ammo
	if local_ammo == 0 and GameState.has_tome_electro:
		var enemies = get_tree().get_nodes_in_group("enemies")
		var hit_count := 0
		for e in enemies:
			if is_instance_valid(e) and global_position.distance_to(e.global_position) < 220.0:
				if e.has_method("take_damage"):
					e.take_damage(40, Vector2.ZERO)
				hit_count += 1
				if hit_count >= 3: break
		if sfx_skill_freeze: sfx_skill_freeze.play()

	if local_ammo <= 0:
		start_reload()

func spawn_bullet(angle: float) -> void:
	if not bullet_scene: return
	var b = bullet_scene.instantiate()
	b.global_position = muzzle.global_position
	b.direction = Vector2.RIGHT.rotated(angle)
	b.rotation = angle
	b.speed = GameState.bullet_speed
	
	# Damage calculation with level scaling & synergies
	var lvl_scale: float = 1.0 + 0.3 * float(maxi(0, int(GameState.level) - 1))
	var dmg: int = int(float(GameState.bullet_damage) * lvl_scale)
	if GameState.fresh_clip_timer > 0.0: dmg = int(float(dmg) * 1.5)
	if GameState.anger_point_timer > 0.0: dmg = int(float(dmg) * 1.75)
	# Tome of Wind sprint damage scaling
	if GameState.has_tome_wind and velocity.length() > 10.0:
		var speed_factor = clampf(velocity.length() / maxf(1.0, GameState.base_speed), 0.0, 1.0)
		dmg = int(float(dmg) * (1.0 + speed_factor * 0.40))
	b.damage = dmg
	
	b.pierce = GameState.bullet_pierce
	b.knockback = GameState.bullet_knockback
	b.has_freeze = GameState.has_freeze
	b.has_lightning = GameState.has_lightning
	b.has_explosive_rounds = GameState.has_explosive_rounds
	
	if GameState.active_tomes.has("tome_power"):
		b.scale *= 2.0
	elif GameState.has_tome_stillness or GameState.active_tomes.has("tome_stillness"):
		b.scale *= 1.5
	
	var wep_type = GameState.primary_weapon if player_index == 1 else GameState.coop_p2_weapon
	var wep_skin = SaveManager.get_weapon_skin(wep_type) if SaveManager.has_method("get_weapon_skin") else SaveManager.equipped_weapon_skin
	match wep_type:
		"shotgun":
			b.bullet_tex = load("res://assets/sprites/spr_bullet_cyan.png") if wep_skin == "cyber" else load("res://assets/sprites/spr_bullet_pellet.png")
			b.lifespan = 0.28 # Point-blank range (< 110px)
			b.speed = 680.0
			b.knockback = maxf(b.knockback, 200.0)
		"smg":
			b.bullet_tex = load("res://assets/sprites/spr_bullet_violet.png") if wep_skin == "violet" else load("res://assets/sprites/spr_bullet_smg.png")
			b.lifespan = 1.0
			b.speed = 720.0
		"railgun":
			b.bullet_tex = load("res://assets/sprites/spr_bullet_plasma.png") if wep_skin == "cryo" else load("res://assets/sprites/spr_bullet_railgun.png")
			b.lifespan = 1.8
			b.speed = 950.0
			b.pierce = 99 # Pierces through all targets in laser line!
			b.is_beam = true
		_:
			b.bullet_tex = load("res://assets/sprites/spr_bullet_gold.png") if wep_skin == "gold" else load("res://assets/sprites/spr_bullet_cyan.png")
			b.lifespan = 1.6
			b.speed = 600.0
			
	get_parent().add_child(b)

func start_reload() -> void:
	if is_reloading or local_ammo >= local_max_ammo:
		return
	is_reloading = true
	reload_timer = 0.0
	if has_node("/root/InputManager"):
		get_node("/root/InputManager").vibrate_reload("start", player_index)
	if sfx_reload_start:
		var wep_type = GameState.primary_weapon if player_index == 1 else GameState.coop_p2_weapon
		match wep_type:
			"shotgun":
				sfx_reload_start.stream = load("res://assets/audio/sfx_reload_shotgun.wav")
			"smg":
				sfx_reload_start.stream = load("res://assets/audio/sfx_reload_smg.wav")
			"railgun":
				sfx_reload_start.stream = load("res://assets/audio/sfx_reload_railgun.wav")
			_:
				sfx_reload_start.stream = load("res://assets/audio/sfx_reload_revolver.wav")
		sfx_reload_start.pitch_scale = randf_range(0.97, 1.03)
		sfx_reload_start.play()
	emit_ammo_update(0.0)

func finish_reload() -> void:
	is_reloading = false
	reload_timer = 0.0
	local_ammo = local_max_ammo
	if player_index == 1:
		GameState.ammo = local_ammo
	else:
		GameState.p2_ammo = local_ammo
	if has_node("/root/InputManager"):
		get_node("/root/InputManager").vibrate_reload("finish", player_index)
	if GameState.has_fresh_clip:
		GameState.fresh_clip_timer = 1.5
	if sfx_reload_finish:
		sfx_reload_finish.play()
	emit_ammo_update(0.0)

func emit_ammo_update(pct: float = 0.0) -> void:
	if player_index == 1:
		GameState.ammo = local_ammo
		GameState.max_ammo = local_max_ammo
		GameState.update_ammo_state(local_ammo, local_max_ammo, is_reloading, pct)
	else:
		GameState.p2_ammo = local_ammo
		GameState.p2_max_ammo = local_max_ammo
		GameState.update_ammo_state_p(2, local_ammo, local_max_ammo, is_reloading, pct)

func take_hit(damage: int) -> void:
	if is_invulnerable:
		return

	if has_node("/root/InputManager"):
		get_node("/root/InputManager").vibrate_damage(1.0, player_index)

	# 20MTD Tome of Glass: Taking any damage is fatal
	var final_damage := 999 if GameState.has_tome_glass else damage
	if GameState.has_reactive_armor and not GameState.has_tome_glass:
		final_damage = maxi(1, final_damage - 1)

	# 20MTD Holy Shield: Absorb 1 complete hit!
	if GameState.has_holy_shield and GameState.holy_shield_active:
		GameState.holy_shield_active = false
		GameState.holy_shield_timer = 45.0
		is_invulnerable = true
		invuln_timer = 0.8
		modulate = Color(0.2, 3.0, 3.0, 1.0)
		var tw := create_tween()
		tw.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.25)
		if sfx_skill_freeze: sfx_skill_freeze.play()
		return

	# 20MTD Anger Point: Taking damage triggers rage (+75% dmg & fire rate)
	if GameState.has_anger_point and player_index == 1:
		GameState.anger_point_timer = 8.0

	var cur_hp = GameState.health if player_index == 1 else GameState.p2_health
	var _max_hp = GameState.max_health if player_index == 1 else GameState.p2_max_health

	# Phoenix Reboot Legendary Card Check (Mati Hidup Lagi!)
	if (cur_hp - final_damage) <= 0 and GameState.has_phoenix_reboot and not GameState.phoenix_used and player_index == 1:
		GameState.phoenix_used = true
		GameState.health = GameState.max_health # Full revive!
		is_invulnerable = true
		invuln_timer = 3.5 # 3.5s invulnerability!
		trigger_revive_animation()
		GameState.health_changed.emit(GameState.health, GameState.max_health)
		GameState.p1_health_changed.emit(GameState.health, GameState.max_health)
		return
	
	if GameState.is_coop_mode and (cur_hp - final_damage) <= 0 and not is_downed:
		GameState.take_damage(final_damage, player_index)
		enter_downed_state()
		return
	
	is_invulnerable = true
	invuln_timer = 1.0
	
	GameState.take_damage(final_damage, player_index)
	body_sprite.scale = Vector2(1.15, 0.85)
	
	if sfx_player_hurt:
		sfx_player_hurt.play()

func spawn_dash_ghost() -> void:
	if not body_sprite or not body_sprite.texture: return
	var ghost := Sprite2D.new()
	ghost.texture = body_sprite.texture
	ghost.hframes = body_sprite.hframes
	ghost.vframes = body_sprite.vframes
	ghost.frame = body_sprite.frame
	ghost.flip_h = body_sprite.flip_h
	ghost.global_position = body_sprite.global_position
	ghost.scale = body_sprite.scale
	ghost.rotation = body_sprite.rotation
	# Dynamic Cyberpunk Neon Trail matching active hero and equipped skin
	var hero_id = GameState.selected_hero if player_index == 1 else GameState.coop_p2_hero
	var skin_variant: String = SaveManager.get_hero_skin(hero_id) if SaveManager.has_method("get_hero_skin") else SaveManager.equipped_hero_skin
	match hero_id:
		"kael":
			ghost.modulate = Color(1.0, 0.22, 0.35, 0.8) if skin_variant == "crimson" else Color(0.16, 0.83, 1.0, 0.8)
		"vex":
			ghost.modulate = Color(0.13, 0.95, 0.4, 0.8) if skin_variant == "toxic" else Color(0.25, 0.85, 0.5, 0.8)
		"brutus":
			ghost.modulate = Color(0.98, 0.8, 0.08, 0.8) if skin_variant == "gold" else Color(1.0, 0.71, 0.16, 0.8)
		"nyx":
			ghost.modulate = Color(0.65, 0.2, 1.0, 0.8) if skin_variant == "void" else Color(0.9, 0.2, 1.2, 0.8)
		_:
			ghost.modulate = Color(0.16, 0.83, 1.0, 0.8)
	ghost.z_index = z_index - 1
	get_parent().add_child(ghost)
	
	var tw := ghost.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ghost, "modulate:a", 0.0, 0.22)
	tw.tween_property(ghost, "scale", body_sprite.scale * 1.25, 0.22)
	tw.chain().tween_callback(ghost.queue_free)

func trigger_random_lightning_strike() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var valid_targets: Array = []
	for e in enemies:
		if is_instance_valid(e) and global_position.distance_to(e.global_position) < 420.0:
			valid_targets.append(e)
	if valid_targets.size() == 0: return
	valid_targets.shuffle()
	var targets_to_hit = mini(3, valid_targets.size())
	for i in range(targets_to_hit):
		var target = valid_targets[i]
		if not is_instance_valid(target): continue
		var l_line := Line2D.new()
		l_line.width = 4.0
		l_line.default_color = Color(0.2, 0.9, 1.0, 1.0)
		var start_p = target.global_position + Vector2(randf_range(-30, 30), -380)
		var end_p = target.global_position
		var mid_p = (start_p + end_p) * 0.5 + Vector2(randf_range(-40, 40), 0)
		l_line.points = PackedVector2Array([start_p, mid_p, end_p])
		get_parent().add_child(l_line)
		
		var tw := l_line.create_tween()
		tw.tween_property(l_line, "width", 0.0, 0.18)
		tw.tween_callback(l_line.queue_free)
		
		if target.has_method("take_damage"):
			target.take_damage(50, Vector2.DOWN * 180.0, false)
		if target.has_method("apply_freeze"):
			target.apply_freeze(0.2, 1.0)
	if sfx_skill_freeze:
		sfx_skill_freeze.pitch_scale = randf_range(1.3, 1.6)
		sfx_skill_freeze.play()

func update_ghost_companion(delta: float) -> void:
	if not is_instance_valid(ghost_companion_node):
		ghost_companion_node = Sprite2D.new()
		var ghost_tex = load("res://assets/sprites/upg_ghost_pet.png")
		if ghost_tex:
			ghost_companion_node.texture = ghost_tex
		ghost_companion_node.scale = Vector2(0.28, 0.28)
		ghost_companion_node.modulate = Color(0.7, 1.2, 1.5, 0.85)
		get_parent().call_deferred("add_child", ghost_companion_node)

	var orbit_time: float = Time.get_ticks_msec() * 0.003
	var orbit_pos = global_position + Vector2(cos(orbit_time), sin(orbit_time)) * 68.0
	ghost_companion_node.global_position = ghost_companion_node.global_position.lerp(orbit_pos, delta * 8.0)
	
	ghost_pet_timer += delta
	if ghost_pet_timer >= 1.5:
		ghost_pet_timer = 0.0
		var enemies = get_tree().get_nodes_in_group("enemies")
		var nearest: Node2D = null
		var min_d := 280.0
		for e in enemies:
			if is_instance_valid(e):
				var d = ghost_companion_node.global_position.distance_to(e.global_position)
				if d < min_d:
					min_d = d
					nearest = e
		if nearest:
			if bullet_scene:
				var b = bullet_scene.instantiate()
				b.global_position = ghost_companion_node.global_position
				var dir = (nearest.global_position - ghost_companion_node.global_position).normalized()
				b.direction = dir
				b.rotation = dir.angle()
				b.speed = 520.0
				b.damage = 25
				b.has_freeze = true
				b.bullet_tex = load("res://assets/sprites/spr_bullet_cyan.png")
				get_parent().add_child(b)

func trigger_revive_animation() -> void:
	GameState.screen_shake_requested.emit(9.0, 0.45)
	modulate = Color(3.0, 2.5, 0.4, 1.0) # Solar Rebirth Gold
	
	# Repel and blast all surrounding enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and global_position.distance_to(e.global_position) < 260.0:
			var push_dir = (e.global_position - global_position).normalized()
			if e.has_method("take_damage"):
				e.take_damage(70, push_dir * 420.0, false)
			if e.has_method("apply_freeze"):
				e.apply_freeze(0.2, 2.0)
				
	# Dramatic pulsating visual & scale pop
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(0.5, 2.0), 0.12)
	tw.tween_property(self, "scale", Vector2(1.5, 1.5), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.20)
	tw.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.8)
	
	if sfx_skill_freeze:
		sfx_skill_freeze.pitch_scale = 0.6
		sfx_skill_freeze.play()
	if sfx_skill_slam:
		sfx_skill_slam.pitch_scale = 1.2
		sfx_skill_slam.play()
		
	var popup_scene = load("res://scenes/entities/DamagePopup.tscn")
	if popup_scene:
		var pop = popup_scene.instantiate()
		pop.global_position = global_position + Vector2(0, -40)
		pop.setup(999, true)
		get_parent().add_child(pop)

func enter_downed_state() -> void:
	if is_downed: return
	is_downed = true
	velocity = Vector2.ZERO
	is_dashing = false
	dash_timer = 0.0
	revive_progress = 0.0
	is_reloading = false
	if is_instance_valid(body_sprite):
		body_sprite.modulate = Color(1.0, 0.4, 0.4, 0.85)
		body_sprite.rotation_degrees = -90.0
	if is_instance_valid(weapon_pivot):
		weapon_pivot.visible = false
	queue_redraw()

func revive_from_downed() -> void:
	is_downed = false
	revive_progress = 0.0
	if is_instance_valid(body_sprite):
		body_sprite.modulate = Color.WHITE
		body_sprite.rotation_degrees = 0.0
	if is_instance_valid(weapon_pivot):
		weapon_pivot.visible = true
	var restore_hp: int = int(ceil((GameState.max_health if player_index == 1 else GameState.p2_max_health) * 0.5))
	GameState.heal(restore_hp, player_index)
	is_invulnerable = true
	invuln_timer = 2.5
	play_hero_vo("select")
	queue_redraw()

func _draw() -> void:
	# Level Up Aura & Floating Arrow + Text above reload position
	if level_up_aura_timer > 0.0:
		var prog: float = 1.0 - (level_up_aura_timer / 1.8)
		var aura_r: float = 24.0 + prog * 45.0
		var a: float = clampf(sin(prog * PI), 0.0, 1.0) * 0.92
		draw_arc(Vector2.ZERO, aura_r, 0, TAU, 36, Color(0.2, 0.9, 1.0, a), 3.0)
		draw_arc(Vector2.ZERO, aura_r * 0.72, 0, TAU, 28, Color(1.0, 0.85, 0.2, a * 0.75), 2.0)
		
		var t_pos := Vector2(-36, -38 - prog * 16.0)
		var txt := "▲ LEVEL UP +" + str(level_up_count)
		var font: Font = ThemeDB.fallback_font
		if font:
			draw_string(font, t_pos + Vector2(1, 1), txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color(0, 0, 0, a))
			draw_string(font, t_pos, txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color(1.0, 0.92, 0.2, a))

	if is_downed:
		var pulse := 0.5 + 0.5 * sin(downed_pulse_timer)
		draw_arc(Vector2.ZERO, 36.0 + pulse * 4.0, 0, TAU, 32, Color(1.0, 0.25, 0.25, 0.6 + pulse * 0.4), 2.5)
		if revive_progress > 0.0:
			var pct := clampf(revive_progress / revive_max_time, 0.0, 1.0)
			draw_arc(Vector2.ZERO, 44.0, -PI/2, -PI/2 + pct * TAU, 36, Color(0.15, 1.0, 0.55, 0.95), 4.5)
			# Plus icon above
			draw_line(Vector2(-8, -32), Vector2(8, -32), Color(0.2, 1.0, 0.6, 0.9), 3.0)
			draw_line(Vector2(0, -40), Vector2(0, -24), Color(0.2, 1.0, 0.6, 0.9), 3.0)

	# Tactical In-World Navigation Indicators (Teammate & Reactor)
	if not is_downed:
		var font: Font = ThemeDB.fallback_font
		
		# 1. Teammate Indicator (Coop Mode)
		var teammate: Node2D = null
		for p in get_tree().get_nodes_in_group("player"):
			if p != self and is_instance_valid(p):
				teammate = p
				break
				
		if is_instance_valid(teammate):
			var diff = teammate.global_position - global_position
			var dist = diff.length()
			if dist > 140.0:
				var dir = diff.normalized()
				var a = clampf((dist - 140.0) / 100.0, 0.0, 0.9)
				var is_tm_downed: bool = bool(teammate.get("is_downed"))
				var col = Color(0.0, 0.95, 1.0, a) if player_index == 1 else Color(0.2, 1.0, 0.5, a)
				if is_tm_downed:
					var pulse = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.008)
					col = Color(1.0, 0.25, 0.25, 0.6 + pulse * 0.4)
					
				var radius := 48.0
				var p_tip = dir * (radius + 9.0)
				var p_left = dir * radius + dir.orthogonal() * 6.5
				var p_right = dir * radius - dir.orthogonal() * 6.5
				var p_notch = dir * (radius + 2.5)
				
				# Drop shadow
				draw_colored_polygon(PackedVector2Array([
					p_tip + dir * 2.0,
					p_left + dir * 2.0,
					p_notch,
					p_right + dir * 2.0
				]), Color(0.0, 0.0, 0.0, a * 0.75))
				draw_colored_polygon(PackedVector2Array([p_tip, p_left, p_notch, p_right]), col)
				
				if font:
					var tm_idx = int(teammate.get("player_index")) if "player_index" in teammate else 2
					var dist_m := int(dist / 50.0)
					var txt = ("P%d %dm" % [tm_idx, dist_m]) if not is_tm_downed else ("SOS P%d %dm" % [tm_idx, dist_m])
					var text_pos = dir * (radius + 18.0) + Vector2(-16, 4)
					draw_string(font, text_pos + Vector2(1, 1), txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0, 0, 0, a * 0.9))
					draw_string(font, text_pos, txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, col)

		# 2. Defense Tower / Reactor Indicator (Defense Stage)
		var tower = get_tree().get_first_node_in_group("defense_tower")
		if is_instance_valid(tower):
			var diff_t = tower.global_position - global_position
			var dist_t = diff_t.length()
			if dist_t > 110.0:
				var dir_t = diff_t.normalized()
				var a_t = clampf((dist_t - 110.0) / 100.0, 0.0, 0.9)
				var t_hp: int = int(tower.get("current_hp")) if "current_hp" in tower else 1500
				var t_max: int = int(tower.get("max_hp")) if "max_hp" in tower else 1500
				var hp_ratio: float = float(t_hp) / float(maxi(1, t_max))
				var col_t = Color(1.0, 0.82, 0.15, a_t) # Amber Gold
				if hp_ratio <= 0.35:
					var pulse_t = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.01)
					col_t = Color(1.0, 0.25, 0.25, 0.6 + pulse_t * 0.4)
					
				var radius_t := 60.0
				var p_tip_t = dir_t * (radius_t + 10.0)
				var p_left_t = dir_t * radius_t + dir_t.orthogonal() * 6.5
				var p_right_t = dir_t * radius_t - dir_t.orthogonal() * 6.5
				var p_notch_t = dir_t * (radius_t + 3.0)
				
				# Drop shadow
				draw_colored_polygon(PackedVector2Array([
					p_tip_t + dir_t * 2.0,
					p_left_t + dir_t * 2.0,
					p_notch_t,
					p_right_t + dir_t * 2.0
				]), Color(0.0, 0.0, 0.0, a_t * 0.75))
				draw_colored_polygon(PackedVector2Array([p_tip_t, p_left_t, p_notch_t, p_right_t]), col_t)
				
				if font:
					var dist_tm := int(dist_t / 50.0)
					var txt_t = "REAKTOR %dm" % dist_tm
					var text_pos_t = dir_t * (radius_t + 18.0) + Vector2(-22, 4)
					draw_string(font, text_pos_t + Vector2(1, 1), txt_t, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0, 0, 0, a_t * 0.9))
					draw_string(font, text_pos_t, txt_t, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, col_t)
