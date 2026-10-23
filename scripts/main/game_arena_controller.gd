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

func _ready() -> void:
	GameState.boss_spawned.connect(_on_boss_spawned)
	GameState.boss_defeated.connect(_on_boss_defeated)
	update_zone_visual()
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	run_dramatic_intro()

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
	if st >= 45.0 and not event_beacon_done:
		event_beacon_done = true
		trigger_supply_beacon()
	elif st >= 95.0 and not event_elite_done:
		event_elite_done = true
		trigger_elite_invasion()
	elif st >= 145.0 and not event_overclock_done:
		event_overclock_done = true
		trigger_overclock_surge()

	# Handle Shrinking Zone
	if is_zone_shrinking and zone_radius > target_zone_radius:
		zone_radius = move_toward(zone_radius, target_zone_radius, 80.0 * delta)
		update_zone_visual()

	# Zone Damage Logic (Active at all times outside boundary)
	if is_instance_valid(player):
		var dist_from_center := player.global_position.length()
		if dist_from_center > zone_radius:
			zone_damage_timer += delta
			
			if zone_line:
				zone_line.default_color = Color(2.5, 0.3, 0.3, 1.0)
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
				zone_line.default_color = Color(1.0, 0.25, 0.35, 0.85)
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

func _on_boss_spawned(_b_name: String, _max_hp: int) -> void:
	is_zone_shrinking = true
	target_zone_radius = 550.0
	
	if alert_banner:
		alert_label.text = "[ ! ] LOCKDOWN: ZONA MENYUSUT // HADAPI COLOSSUS-OMEGA [ ! ]"
		alert_banner.visible = true
		var tw := create_tween()
		tw.tween_interval(4.0)
		tw.tween_callback(func(): 
			if is_instance_valid(player) and player.global_position.length() <= zone_radius:
				alert_banner.visible = false
		)
		
	if bgm_player:
		bgm_player.pitch_scale = 1.15
		bgm_player.volume_db = -2.5

func trigger_supply_beacon() -> void:
	if alert_banner:
		alert_label.text = "[ ! ] EVENT: CYBER SUPPLY BEACON DROPPED (MEDKIT & CORE) [ ! ]"
		alert_banner.visible = true
		var tw := create_tween()
		tw.tween_interval(3.5)
		tw.tween_callback(func(): alert_banner.visible = false)
		
	if is_instance_valid(player):
		var med_scene = load("res://scenes/entities/MedkitPickup.tscn")
		var core_scene = load("res://scenes/entities/SkillCorePickup.tscn")
		if med_scene:
			for i in range(2):
				var m = med_scene.instantiate()
				m.global_position = player.global_position + Vector2(randf_range(-140, 140), randf_range(-140, 140))
				add_child(m)
		if core_scene:
			var c = core_scene.instantiate()
			c.global_position = player.global_position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
			add_child(c)

func trigger_elite_invasion() -> void:
	if alert_banner:
		alert_label.text = "[ ! ] EVENT: ARMORED ELITE COLOSSUS INVASION [ ! ]"
		alert_banner.visible = true
		var tw := create_tween()
		tw.tween_interval(4.0)
		tw.tween_callback(func(): alert_banner.visible = false)
		
	if is_instance_valid(player):
		var golem_scene = load("res://scenes/entities/EnemyGolem.tscn")
		if golem_scene:
			var g = golem_scene.instantiate()
			g.global_position = player.global_position + Vector2(300, 0).rotated(randf_range(0, TAU))
			g.max_hp = 350
			g.modulate = Color(2.5, 0.4, 0.4, 1.0) # Elite Red Glow
			add_child(g)

func trigger_overclock_surge() -> void:
	if alert_banner:
		alert_label.text = "[ ! ] EVENT: REACTOR OVERCLOCK SURGE (+50% FIRE RATE & SPEED) [ ! ]"
		alert_banner.visible = true
		var tw := create_tween()
		tw.tween_interval(4.0)
		tw.tween_callback(func(): alert_banner.visible = false)
		
	# Temporary Buff for 15s
	var old_fr = GameState.fire_rate
	var old_spd = GameState.base_speed
	GameState.fire_rate *= 0.5
	GameState.base_speed *= 1.35
	
	var buff_tw := create_tween()
	buff_tw.tween_interval(15.0)
	buff_tw.tween_callback(func():
		GameState.fire_rate = old_fr
		GameState.base_speed = old_spd
	)

func _on_boss_defeated() -> void:
	is_zone_shrinking = false
	target_zone_radius = 1200.0
	zone_radius = 1200.0
	update_zone_visual()
	if bgm_player:
		bgm_player.pitch_scale = 1.0
		bgm_player.volume_db = -5.0