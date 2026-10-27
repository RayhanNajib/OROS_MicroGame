extends Node2D

@onready var bgm_player: AudioStreamPlayer = $BGMPlayer
@onready var zone_line: Line2D = $ContainmentZone/ZoneLine
@onready var alert_banner: CanvasLayer = $BossAlertLayer
@onready var alert_label: Label = $BossAlertLayer/Banner/Label

@onready var intro_layer: CanvasLayer = $IntroLayer
@onready var intro_overlay: ColorRect = $IntroLayer/BlackOverlay
@onready var intro_stage_banner: Label = $IntroLayer/Center/VBox/StageBanner
@onready var intro_stage_sub: Label = $IntroLayer/Center/VBox/StageSub
@onready var intro_countdown: Label = $IntroLayer/Center/VBox/CountdownLabel
@onready var sfx_beep: AudioStreamPlayer = $IntroLayer/SFXBeep
@onready var sfx_start: AudioStreamPlayer = $IntroLayer/SFXStart

@onready var wave_spawner: Node2D = $WaveSpawner

var zone_radius: float = 1800.0
var target_zone_radius: float = 1800.0
var is_zone_shrinking: bool = false
var zone_damage_timer: float = 0.0
var player: CharacterBody2D = null

var event_beacon_done: bool = false
var event_elite_done: bool = false
var event_overclock_done: bool = false

func show_alert_message(msg: String, duration: float = 4.0) -> void:
	if not alert_banner or not alert_label:
		return
	alert_label.text = msg
	alert_banner.visible = true
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_interval(duration)
	tw.tween_callback(func():
		if is_instance_valid(alert_banner):
			alert_banner.visible = false
	)

func _ready() -> void:
	add_to_group("arena_controller")
	var crosshair_tex = load("res://assets/ui/cursor_crosshair.png")
	if crosshair_tex:
		Input.set_custom_mouse_cursor(crosshair_tex, Input.CURSOR_ARROW, Vector2(16, 16))

	if has_node("/root/InputManager"):
		var im = get_node("/root/InputManager")
		im.scheme_changed.connect(func(p_idx, scheme):
			if p_idx == 1:
				if scheme != "keyboard":
					Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
				else:
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		)
		if im.p1_scheme != "keyboard":
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	GameState.boss_spawned.connect(_on_boss_spawned)
	GameState.boss_defeated.connect(_on_boss_defeated)
	update_zone_visual()
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		
	if GameState.is_coop_mode:
		toggle_coop_mode()

	spawn_environment_objects()
	apply_stage_theme()
	run_dramatic_intro()

func apply_stage_theme() -> void:
	var floor_node = get_node_or_null("Floor") as Sprite2D
	var void_bg = get_node_or_null("VoidBackground") as ColorRect
	var fence_p = get_node_or_null("FencePerimeter")
	
	# Load authentic themed floor texture per stage
	var stage_tex_path = "res://assets/sprites/tile_floor_stage%d.png" % GameState.current_stage
	if ResourceLoader.exists(stage_tex_path) and floor_node:
		floor_node.texture = load(stage_tex_path)

	# Dynamic Stage BGM Stream
	var stage_bgm_path = "res://assets/audio/bgm_stage%d.wav" % GameState.current_stage
	if ResourceLoader.exists(stage_bgm_path) and bgm_player:
		var bgm_stream = load(stage_bgm_path)
		if bgm_stream:
			if bgm_stream is AudioStreamWAV:
				bgm_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			bgm_player.stream = bgm_stream
			bgm_player.play()
	
	match GameState.current_stage:
		1:
			if floor_node: floor_node.modulate = Color(0.9, 1.0, 1.1)
			if void_bg: void_bg.color = Color(0.01, 0.02, 0.04)
			if fence_p: fence_p.modulate = Color(0, 0.94, 1.0)
		2:
			if floor_node: floor_node.modulate = Color(0.85, 1.05, 0.9)
			if void_bg: void_bg.color = Color(0.01, 0.03, 0.02)
			if fence_p: fence_p.modulate = Color(0.13, 0.95, 0.4)
			var tower_scene = load("res://scenes/entities/DefenseTower.tscn")
			if tower_scene and not has_node("DefenseTower"):
				var tower = tower_scene.instantiate()
				tower.name = "DefenseTower"
				tower.global_position = Vector2.ZERO
				call_deferred("add_child", tower)
		3:
			if floor_node: floor_node.modulate = Color(1.2, 0.9, 0.7)
			if void_bg: void_bg.color = Color(0.04, 0.015, 0.01)
			if fence_p: fence_p.modulate = Color(0.98, 0.8, 0.08)
		4:
			if floor_node: floor_node.modulate = Color(1.0, 0.85, 1.25)
			if void_bg: void_bg.color = Color(0.03, 0.01, 0.05)
			if fence_p: fence_p.modulate = Color(0.82, 0.24, 1.0)
		5:
			if floor_node: floor_node.modulate = Color(0.85, 0.75, 1.35)
			if void_bg: void_bg.color = Color(0.015, 0.005, 0.03)
			if fence_p: fence_p.modulate = Color(1.0, 0.24, 0.66)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_F2:
			toggle_coop_mode()
		elif event.keycode == KEY_ESCAPE or event.keycode == KEY_KP_0:
			var pause_modal = get_node_or_null("PauseModal")
			if pause_modal and not pause_modal.visible:
				pause_modal.open_pause()
	elif event is InputEventJoypadButton and event.is_pressed():
		if event.button_index == JOY_BUTTON_START or event.button_index == JOY_BUTTON_BACK:
			var pause_modal = get_node_or_null("PauseModal")
			if pause_modal and not pause_modal.visible:
				pause_modal.open_pause()

func toggle_coop_mode() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() >= 2:
		players[1].queue_free()
		var cam_ctrl = get_node_or_null("CoopCameraController")
		if cam_ctrl:
			cam_ctrl.queue_free()
		GameState.is_coop_mode = false
		if has_node("/root/InputManager"):
			get_node("/root/InputManager").refresh_device_assignments()
	else:
		GameState.is_coop_mode = true
		if has_node("/root/InputManager"):
			get_node("/root/InputManager").refresh_device_assignments()
		var p_scene = load("res://scenes/entities/Player.tscn")
		if p_scene and player:
			var p2 = p_scene.instantiate()
			p2.player_index = 2
			p2.global_position = player.global_position + Vector2(100, 0)
			call_deferred("add_child", p2)
			
			var cam_ctrl_scene = load("res://scripts/main/coop_camera_controller.gd")
			if cam_ctrl_scene and not has_node("CoopCameraController"):
				var cam_ctrl = Node2D.new()
				cam_ctrl.name = "CoopCameraController"
				cam_ctrl.set_script(cam_ctrl_scene)
				call_deferred("add_child", cam_ctrl)
			
			var hud = get_node_or_null("HUD")
			if hud and hud.has_method("setup_coop_hud"):
				hud.call_deferred("setup_coop_hud")

func spawn_environment_objects() -> void:
	var pylon_scene = load("res://scenes/entities/ElectricPylon.tscn")
	var crate_scene = load("res://scenes/entities/ScrapCrate.tscn")
	var barrier_scene = load("res://scenes/entities/CyberBarrier.tscn")
	var portal_scene = load("res://scenes/entities/AnomalyPortal.tscn")
	
	# 1. Procedural Electric Pylons (4 to 6 randomly placed with safe distance)
	if pylon_scene:
		var pylon_count := randi_range(4, 6)
		for i in range(pylon_count):
			var ang := (float(i) / float(pylon_count)) * TAU + randf_range(-0.3, 0.3)
			var dist := randf_range(420.0, 750.0)
			var p = pylon_scene.instantiate()
			p.global_position = Vector2(cos(ang), sin(ang)) * dist
			call_deferred("add_child", p)

	# 2. Procedural Scrap Crates (8 to 12 scattered)
	if crate_scene:
		var crate_count := randi_range(8, 12)
		for i in range(crate_count):
			var ang := randf_range(0.0, TAU)
			var dist := randf_range(280.0, 850.0)
			var c = crate_scene.instantiate()
			c.global_position = Vector2(cos(ang), sin(ang)) * dist
			call_deferred("add_child", c)

	# 3. Procedural Cyber Barrier Obstacles (12 to 18 clustered blocks)
	if barrier_scene:
		var cluster_centers := [
			Vector2(-350, -320), Vector2(350, -320),
			Vector2(-350, 320), Vector2(350, 320)
		]
		for center in cluster_centers:
			var jitter_c = center + Vector2(randf_range(-60, 60), randf_range(-60, 60))
			var b_count := randi_range(3, 4)
			for j in range(b_count):
				var b = barrier_scene.instantiate()
				b.global_position = jitter_c + Vector2(randf_range(-45, 45), randf_range(-45, 45))
				call_deferred("add_child", b)

	# 4. Interactive Quantum Anomaly Portals (Paired Alpha & Beta Teleporters)
	if portal_scene:
		var portal_a = portal_scene.instantiate()
		portal_a.portal_tag = "ALPHA"
		portal_a.global_position = Vector2(-720, 0) + Vector2(randf_range(-40, 40), randf_range(-120, 120))
		call_deferred("add_child", portal_a)

		var portal_b = portal_scene.instantiate()
		portal_b.portal_tag = "BETA"
		portal_b.global_position = Vector2(720, 0) + Vector2(randf_range(-40, 40), randf_range(-120, 120))
		call_deferred("add_child", portal_b)

		portal_a.linked_portal = portal_b
		portal_b.linked_portal = portal_a

func run_dramatic_intro() -> void:
	if not intro_layer: return
	
	# Freeze gameplay during intro
	if wave_spawner:
		wave_spawner.set_process(false)
	if player:
		player.set_physics_process(false)
		player.set_process(false)
	if bgm_player:
		bgm_player.volume_db = -80.0 # Mute during countdown

	var cfg = GameState.stage_configs.get(GameState.current_stage, GameState.stage_configs[1])
	intro_stage_banner.text = "[ STAGE %02d: %s ]" % [GameState.current_stage, cfg["title"]]
	intro_stage_sub.text = "TINGKAT: %s // TARGET SURVIVE: %d DETIK // MISI: %s" % [cfg["difficulty"], int(cfg["target_time"]), cfg["objective"]]

	# Countdown 3-2-1
	var tw := create_tween()
	
	# Step 3
	tw.tween_callback(func():
		intro_countdown.text = "3"
		intro_countdown.pivot_offset = intro_countdown.size * 0.5
		intro_countdown.scale = Vector2(1.4, 1.4)
		var pop = intro_countdown.create_tween()
		pop.tween_property(intro_countdown, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
		if sfx_beep:
			sfx_beep.pitch_scale = 1.0
			sfx_beep.play()
	)
	tw.tween_interval(0.75)
	
	# Step 2
	tw.tween_callback(func():
		intro_countdown.text = "2"
		intro_countdown.scale = Vector2(1.4, 1.4)
		var pop = intro_countdown.create_tween()
		pop.tween_property(intro_countdown, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
		if sfx_beep:
			sfx_beep.pitch_scale = 1.15
			sfx_beep.play()
	)
	tw.tween_interval(0.75)
	
	# Step 1
	tw.tween_callback(func():
		intro_countdown.text = "1"
		intro_countdown.scale = Vector2(1.4, 1.4)
		var pop = intro_countdown.create_tween()
		pop.tween_property(intro_countdown, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
		if sfx_beep:
			sfx_beep.pitch_scale = 1.30
			sfx_beep.play()
	)
	tw.tween_interval(0.75)
	
	# START!
	tw.tween_callback(func():
		intro_countdown.text = "[ MISSION COMMENCE! ]"
		intro_countdown.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
		intro_countdown.scale = Vector2(1.2, 1.2)
		if sfx_start:
			sfx_start.play()
		if bgm_player:
			var bgm_tw = bgm_player.create_tween()
			bgm_tw.tween_property(bgm_player, "volume_db", -5.0, 0.6)
	)
	tw.tween_interval(0.6)
	
	# Fade overlay and resume
	tw.tween_property(intro_overlay, "color:a", 0.0, 0.5)
	tw.tween_callback(func():
		if wave_spawner:
			wave_spawner.set_process(true)
		if player:
			player.set_physics_process(true)
			player.set_process(true)
		intro_layer.queue_free()
	)

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]

	# Dynamic In-Game Random Events
	var st = GameState.survival_time
	if st >= 45.0 and not event_beacon_done and st < 60.0:
		event_beacon_done = true
		trigger_supply_beacon()
	elif st >= 95.0 and not event_elite_done:
		event_elite_done = true
		trigger_elite_invasion()
	elif st >= 145.0 and not event_overclock_done:
		event_overclock_done = true
		trigger_overclock_surge()

	# Safety sync: Jika tidak ada boss / mini-boss aktif di arena, zona WAJIB membesar kembali normal (1800px)
	var has_live_boss: bool = GameState.is_boss_active
	if not has_live_boss:
		var threats = get_tree().get_nodes_in_group("boss") + get_tree().get_nodes_in_group("mini_boss")
		for t in threats:
			if is_instance_valid(t) and not t.is_queued_for_deletion():
				if ("current_hp" in t and t.current_hp > 0) or ("health" in t and t.health > 0):
					has_live_boss = true
					break
	if not has_live_boss and target_zone_radius < 1800.0:
		target_zone_radius = 1800.0
		is_zone_shrinking = false

	# Smooth Zone Radius Transition (mengecil saat boss/mini-boss, membesar normal setelah kalah)
	if absf(zone_radius - target_zone_radius) > 1.0:
		var speed: float = 80.0 if zone_radius > target_zone_radius else 280.0
		zone_radius = move_toward(zone_radius, target_zone_radius, speed * delta)
		update_zone_visual()

	# Zone Damage Logic (Active at all times outside boundary)
	if is_instance_valid(player):
		var dist_from_center := player.global_position.length()
		if dist_from_center > zone_radius:
			zone_damage_timer += delta
			
			if zone_line:
				zone_line.default_color = Color(2.5, 2.0, 0.2, 1.0) # High-voltage yellow pulse
				zone_line.width = 7.0
				
			if alert_banner and not alert_banner.visible:
				alert_label.text = "[ ! ] PERINGATAN: DI LUAR ZONA AMAN - TERKENA DAMAGE RADIASI [ ! ]"
				alert_banner.visible = true
				
			if zone_damage_timer >= 1.0:
				zone_damage_timer = 0.0
				player.take_hit(1)
				
				var popup_scene = load("res://scenes/entities/DamagePopup.tscn")
				if popup_scene:
					var popup = popup_scene.instantiate()
					popup.global_position = player.global_position + Vector2(0, -22)
					popup.setup(1, true)
					get_parent().add_child(popup)
		else:
			zone_damage_timer = 0.0
			if zone_line:
				zone_line.default_color = Color(0.0, 0.9, 1.0, 0.85) # Electric Cyan
				zone_line.width = 4.5
			if alert_banner and alert_banner.visible and not is_zone_shrinking:
				alert_banner.visible = false

func update_zone_visual() -> void:
	if not zone_line: return
	zone_line.clear_points()
	var points_count := 48
	for i in range(points_count + 1):
		var angle := (float(i) / float(points_count)) * TAU
		zone_line.add_point(Vector2(cos(angle), sin(angle)) * zone_radius)

func _on_boss_spawned(b_name: String, _max_hp: int) -> void:
	is_zone_shrinking = true
	target_zone_radius = 550.0
	var display_name: String = b_name if b_name != "" else "BOSS THREAT"
	show_alert_message("[ ! ] LOCKDOWN: ZONA MENYUSUT // HADAPI %s [ ! ]" % display_name, 4.0)
		
	if bgm_player:
		bgm_player.pitch_scale = 1.15
		bgm_player.volume_db = -2.5

func trigger_supply_beacon() -> void:
	show_alert_message("[ ! ] EVENT: SWARM FRENZY // DARAH +30%, SPEED +50% & ATTACK SPEED NAIK! [ ! ]", 4.0)
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	for e in all_enemies:
		if is_instance_valid(e):
			if "max_hp" in e: e.max_hp = int(e.max_hp * 1.3)
			if "current_hp" in e: e.current_hp = int(e.current_hp * 1.3)
			if "base_speed" in e: e.base_speed *= 1.5
			if "move_speed" in e: e.move_speed *= 1.5
			if "attack_cooldown" in e: e.attack_cooldown *= 0.5
			if "shoot_interval" in e: e.shoot_interval *= 0.5
			e.modulate = Color(2.5, 0.4, 0.4, 1.0)

func trigger_elite_invasion() -> void:
	show_alert_message("[ ! ] EVENT: NANO REINFORCEMENT // DARAH NAIK 1.5X, SPEED +30% & SERANGAN CEPAT! [ ! ]", 4.0)
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	for e in all_enemies:
		if is_instance_valid(e):
			if "max_hp" in e: e.max_hp = int(e.max_hp * 1.5)
			if "current_hp" in e: e.current_hp = int(e.current_hp * 1.5)
			if "base_speed" in e: e.base_speed *= 1.3
			if "move_speed" in e: e.move_speed *= 1.3
			if "attack_cooldown" in e: e.attack_cooldown *= 0.7
			if "shoot_interval" in e: e.shoot_interval *= 0.7
			e.modulate = Color(2.2, 1.8, 0.3, 1.0)
	if is_instance_valid(player):
		var golem_scene = load("res://scenes/entities/EnemyGolem.tscn")
		if golem_scene:
			var g = golem_scene.instantiate()
			g.global_position = player.global_position + Vector2(300, 0).rotated(randf_range(0, TAU))
			g.max_hp = 1800 # 3x scaled elite golem
			g.modulate = Color(2.5, 2.2, 0.4, 1.0)
			add_child(g)

func trigger_overclock_surge() -> void:
	show_alert_message("[ ! ] EVENT: CORE OVERCHARGE // HYPER SPEED 1.8X, DARAH +50% & ENRAGE SELURUH MUSUH! [ ! ]", 4.0)
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	for e in all_enemies:
		if is_instance_valid(e):
			if "max_hp" in e: e.max_hp = int(e.max_hp * 1.5)
			if "current_hp" in e: e.current_hp = int(e.current_hp * 1.5)
			if "base_speed" in e: e.base_speed *= 1.8
			if "move_speed" in e: e.move_speed *= 1.8
			if "attack_cooldown" in e: e.attack_cooldown *= 0.4
			if "shoot_interval" in e: e.shoot_interval *= 0.4
			e.modulate = Color(2.5, 0.8, 0.2, 1.0)

func _on_boss_defeated() -> void:
	# Verifikasi apakah masih ada boss/mini-boss lain yang masih aktif
	var active_threats: int = 0
	var all_bosses = get_tree().get_nodes_in_group("boss") + get_tree().get_nodes_in_group("mini_boss")
	for b in all_bosses:
		if is_instance_valid(b) and not b.is_queued_for_deletion():
			if "current_hp" in b and b.current_hp > 0:
				active_threats += 1
			elif "health" in b and b.health > 0:
				active_threats += 1
				
	if active_threats <= 1:
		is_zone_shrinking = false
		target_zone_radius = 1800.0 # Kembali membesar normal ke ukuran awal 1800px!
		show_alert_message("[ ! ] THREAT ELIMINATED: ARENA BARRIER DINONAKTIFKAN // ZONA MEMBESAR NORMAL [ ! ]", 4.0)
		if bgm_player:
			bgm_player.pitch_scale = 1.0
			bgm_player.volume_db = -5.0
			
		var sfx_def = AudioStreamPlayer.new()
		sfx_def.stream = load("res://assets/audio/sfx_boss_defeated.wav")
		sfx_def.volume_db = 3.0
		add_child(sfx_def)
		sfx_def.play()
		sfx_def.finished.connect(sfx_def.queue_free)
		
		if has_node("/root/InputManager"):
			get_node("/root/InputManager").vibrate_explosion(1.5)
		
	# Drop Ancient Tech Tome right at player position!
	var tome_scene = load("res://scenes/entities/TomePickup.tscn")
	if tome_scene:
		var tome = tome_scene.instantiate()
		var drop_pos = Vector2.ZERO
		if player and is_instance_valid(player):
			drop_pos = player.global_position + Vector2(randf_range(-60, 60), randf_range(-60, 60))
		tome.global_position = drop_pos
		call_deferred("add_child", tome)