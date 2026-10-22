extends Node2D

@onready var bgm_player: AudioStreamPlayer = $BGMPlayer
@onready var zone_line: Line2D = $ContainmentZone/ZoneLine
@onready var alert_banner: CanvasLayer = $BossAlertLayer
@onready var alert_label: Label = $BossAlertLayer/Banner/Label

var zone_radius: float = 1200.0
var target_zone_radius: float = 1200.0
var is_zone_shrinking: bool = false
var zone_damage_timer: float = 0.0
var player: CharacterBody2D = null

func _ready() -> void:
	GameState.boss_spawned.connect(_on_boss_spawned)
	GameState.boss_defeated.connect(_on_boss_defeated)
	update_zone_visual()
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]

	# Handle Shrinking Zone
	if is_zone_shrinking and zone_radius > target_zone_radius:
		zone_radius = move_toward(zone_radius, target_zone_radius, 80.0 * delta)
		update_zone_visual()

	# Zone Damage Logic (Active at all times outside boundary)
	if is_instance_valid(player):
		var dist_from_center := player.global_position.length()
		if dist_from_center > zone_radius:
			zone_damage_timer += delta
			
			# Pulse zone line brighter red when player is violating perimeter
			if zone_line:
				zone_line.default_color = Color(2.5, 0.3, 0.3, 1.0)
				zone_line.width = 7.0
				
			if alert_banner and not alert_banner.visible:
				alert_label.text = "[ ! ] PERINGATAN: DI LUAR ZONA AMAN - TERKENA DAMAGE RADIASI [ ! ]"
				alert_banner.visible = true
				
			if zone_damage_timer >= 1.0:
				zone_damage_timer = 0.0
				player.take_hit(1)
				
				# Spawn floating damage number on player
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
	target_zone_radius = 550.0 # Shrink to intense 550px combat arena
	
	# Show Boss Alert Banner
	if alert_banner:
		alert_label.text = "[ ! ] LOCKDOWN: ZONA MENYUSUT // HADAPI COLOSSUS-OMEGA [ ! ]"
		alert_banner.visible = true
		var tw := create_tween()
		tw.tween_interval(4.0)
		tw.tween_callback(func(): 
			if is_instance_valid(player) and player.global_position.length() <= zone_radius:
				alert_banner.visible = false
		)
		
	# Increase BGM intensity/pitch
	if bgm_player:
		bgm_player.pitch_scale = 1.15
		bgm_player.volume_db = -2.5

func _on_boss_defeated() -> void:
	is_zone_shrinking = false
	target_zone_radius = 1200.0
	zone_radius = 1200.0
	update_zone_visual()
	if alert_banner:
		alert_banner.visible = false
	if bgm_player:
		bgm_player.pitch_scale = 1.0
		bgm_player.volume_db = -5.0
