extends Node2D

@export var spider_scene: PackedScene
@export var drone_scene: PackedScene
@export var golem_scene: PackedScene
@export var viper_scene: PackedScene
@export var turret_scene: PackedScene
@export var kamikaze_scene: PackedScene

var current_boss_scene: PackedScene
var player: Node2D = null
var spawn_timer: float = 0.0
var base_interval: float = 1.0

var horde_timer: float = 0.0
var horde_interval: float = 25.0
var boss_spawned_flag: bool = false
var stage_victory_flag: bool = false

func _ready() -> void:
	spider_scene = load("res://scenes/entities/EnemySpider.tscn")
	drone_scene = load("res://scenes/entities/EnemyDrone.tscn")
	golem_scene = load("res://scenes/entities/EnemyGolem.tscn")
	viper_scene = load("res://scenes/entities/EnemyViper.tscn")
	turret_scene = load("res://scenes/entities/EnemyTurret.tscn")
	kamikaze_scene = load("res://scenes/entities/EnemyKamikaze.tscn")

	# Select boss for current stage
	match GameState.current_stage:
		1: current_boss_scene = load("res://scenes/entities/BossColossus.tscn")
		2: current_boss_scene = load("res://scenes/entities/BossArachnid.tscn")
		3: current_boss_scene = load("res://scenes/entities/BossNexus.tscn")
		4: current_boss_scene = load("res://scenes/entities/BossDreadnought.tscn")
		5: current_boss_scene = load("res://scenes/entities/BossChrono.tscn")
		_: current_boss_scene = load("res://scenes/entities/BossColossus.tscn")

	# If Stage 2, spawn the Defense Tower at center
	if GameState.current_stage == 2:
		var tower_res = load("res://scenes/entities/DefenseTower.tscn")
		if tower_res:
			var tower = tower_res.instantiate()
			tower.global_position = Vector2(0, -30)
			get_parent().call_deferred("add_child", tower)

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
		return

	GameState.survival_time += delta
	var time := GameState.survival_time
	var cfg = GameState.stage_configs.get(GameState.current_stage, GameState.stage_configs[1])
	var target_time: float = cfg.get("target_time", 180.0)

	# Check Stage Clear Victory
	if time >= target_time and not stage_victory_flag:
		stage_victory_flag = true
		GameState.mission_victory_triggered.emit(time, GameState.total_kills, GameState.level)

	# Nightmare difficulty spawn multiplier
	var rate_mult := 1.5 if GameState.current_stage == 5 else (1.2 if GameState.current_stage >= 3 else 1.0)
	var current_interval := maxf(0.24, (base_interval - (time * 0.005)) / rate_mult)
	
	spawn_timer += delta
	if spawn_timer >= current_interval:
		spawn_timer = 0.0
		spawn_enemy_wave(time)

	# Periodic Horde Swarm
	horde_timer += delta
	if horde_timer >= horde_interval:
		horde_timer = 0.0
		trigger_horde(time)

	# Boss spawn trigger at 65% of target survival time
	var boss_spawn_time := target_time * 0.65
	if time >= boss_spawn_time and not boss_spawned_flag:
		boss_spawned_flag = true
		if current_boss_scene:
			spawn_one(current_boss_scene)

func spawn_enemy_wave(time: float) -> void:
	var rand := randf()
	match GameState.current_stage:
		1: # Foundry: Spiders, Drones, Golems
			if time < 35.0:
				spawn_one(spider_scene)
			elif time < 80.0:
				if rand < 0.7: spawn_one(spider_scene)
				else: spawn_one(drone_scene)
			else:
				if rand < 0.5: spawn_one(spider_scene)
				elif rand < 0.8: spawn_one(drone_scene)
				else: spawn_one(golem_scene)
		2: # Cyber Ruins: Kamikaze rollers targeting tower/player
			if rand < 0.45: spawn_one(spider_scene)
			elif rand < 0.75: spawn_one(kamikaze_scene)
			else: spawn_one(drone_scene)
		3: # Overclock Reactor: Turrets, Vipers, Golems
			if rand < 0.35: spawn_one(viper_scene)
			elif rand < 0.65: spawn_one(turret_scene)
			elif rand < 0.85: spawn_one(spider_scene)
			else: spawn_one(golem_scene)
		4: # Plasma Wasteland: Fast Vipers, Kamikazes, Snipers
			if rand < 0.30: spawn_one(viper_scene)
			elif rand < 0.55: spawn_one(kamikaze_scene)
			elif rand < 0.80: spawn_one(turret_scene)
			else: spawn_one(golem_scene)
		5: # Apex Nightmare: All elite enemies combined
			if rand < 0.25: spawn_one(viper_scene)
			elif rand < 0.45: spawn_one(kamikaze_scene)
			elif rand < 0.65: spawn_one(turret_scene)
			elif rand < 0.85: spawn_one(golem_scene)
			else: spawn_one(drone_scene)

func trigger_horde(_time: float) -> void:
	var count := randi_range(7, 12) if GameState.current_stage >= 4 else randi_range(6, 9)
	for i in range(count):
		var angle := (TAU / float(count)) * float(i)
		var h_scene = kamikaze_scene if (GameState.current_stage == 2 and randf() < 0.5) else spider_scene
		spawn_at_angle(h_scene, angle, 420.0)

func spawn_one(scene: PackedScene) -> void:
	var angle := randf_range(0.0, TAU)
	spawn_at_angle(scene, angle, randf_range(380.0, 440.0))

func spawn_at_angle(scene: PackedScene, angle: float, radius: float) -> void:
	if not scene or not is_instance_valid(player): return
	var enemy = scene.instantiate()
	var offset := Vector2(cos(angle), sin(angle)) * radius
	enemy.global_position = player.global_position + offset
	get_parent().add_child(enemy)