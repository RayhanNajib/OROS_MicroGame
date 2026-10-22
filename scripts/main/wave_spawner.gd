extends Node2D

@export var spider_scene: PackedScene
@export var drone_scene: PackedScene
@export var golem_scene: PackedScene

var player: Node2D = null
var spawn_timer: float = 0.0
var base_interval: float = 1.0

var horde_timer: float = 0.0
var horde_interval: float = 25.0

func _ready() -> void:
	if not spider_scene:
		spider_scene = load("res://scenes/entities/EnemySpider.tscn")
	if not drone_scene:
		drone_scene = load("res://scenes/entities/EnemyDrone.tscn")
	if not golem_scene:
		golem_scene = load("res://scenes/entities/EnemyGolem.tscn")

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
		return

	GameState.survival_time += delta
	var time := GameState.survival_time

	# Difficulty scaling
	var current_interval := maxf(0.35, base_interval - (time * 0.005))
	
	spawn_timer += delta
	if spawn_timer >= current_interval:
		spawn_timer = 0.0
		spawn_enemy_wave(time)

	# Periodic Horde Swarm
	horde_timer += delta
	if horde_timer >= horde_interval:
		horde_timer = 0.0
		trigger_horde(time)

func spawn_enemy_wave(time: float) -> void:
	# Choose enemy type based on survival time
	var rand := randf()
	if time < 25.0:
		spawn_one(spider_scene)
	elif time < 60.0:
		if rand < 0.7:
			spawn_one(spider_scene)
		else:
			spawn_one(drone_scene)
	else:
		if rand < 0.55:
			spawn_one(spider_scene)
		elif rand < 0.82:
			spawn_one(drone_scene)
		else:
			spawn_one(golem_scene)

func trigger_horde(_time: float) -> void:
	# Spawn a ring of 6-8 spiders surrounding player
	var count := randi_range(6, 9)
	for i in range(count):
		var angle := (TAU / float(count)) * float(i)
		spawn_at_angle(spider_scene, angle, 420.0)

func spawn_one(scene: PackedScene) -> void:
	var angle := randf_range(0.0, TAU)
	spawn_at_angle(scene, angle, randf_range(380.0, 440.0))

func spawn_at_angle(scene: PackedScene, angle: float, radius: float) -> void:
	if not scene or not is_instance_valid(player): return
	var enemy = scene.instantiate()
	var offset := Vector2(cos(angle), sin(angle)) * radius
	enemy.global_position = player.global_position + offset
	get_parent().add_child(enemy)
