extends Node2D

@onready var bgm_player: AudioStreamPlayer = $BGMPlayer
@onready var zone_line: Line2D = $ContainmentZone/ZoneLine
@onready var alert_banner: CanvasLayer = $BossAlertLayer

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

	# Shrink zone smoothly if active
	if is_zone_shrinking:
		zone_radius = move_toward(zone_radius, target_zone_radius, 65.0 * delta)
		update_zone_visual()
		
		# Check if player is outside containment zone
		if is_instance_valid(player):
			var dist_from_center := player.global_position.length()
			if dist_from_center > zone_radius:
				zone_damage_timer += delta
				if zone_damage_timer >= 1.2:
					zone_damage_timer = 0.0
					player.take_hit(1)
			else:
				zone_damage_timer = 0.0

func update_zone_visual() -> void:
	if not zone_line: return
	zone_line.clear_points()
	var points_count := 36
	for i in range(points_count + 1):
		var angle := (float(i) / float(points_count)) * TAU
		zone_line.add_point(Vector2(cos(angle), sin(angle)) * zone_radius)

func _on_boss_spawned(_b_name: String, _max_hp: int) -> void:
	is_zone_shrinking = true
	target_zone_radius = 550.0 # Shrink to intense 550px combat arena
	
	# Show Boss Alert Banner
	if alert_banner:
		alert_banner.visible = true
		var tw := create_tween()
		tw.tween_interval(3.5)
		tw.tween_callback(func(): alert_banner.visible = false)
		
	# Increase BGM intensity/pitch
	if bgm_player:
		bgm_player.pitch_scale = 1.15
		bgm_player.volume_db = -3.0

func _on_boss_defeated() -> void:
	is_zone_shrinking = false
	target_zone_radius = 1200.0
	zone_radius = 1200.0
	update_zone_visual()
	if bgm_player:
		bgm_player.pitch_scale = 1.0
		bgm_player.volume_db = -5.0
