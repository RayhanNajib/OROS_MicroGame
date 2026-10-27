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
var drop_timer: float = 0.0
var miniboss_1_flag: bool = false
var miniboss_2_flag: bool = false
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
		GameState.trigger_mission_victory(time, GameState.total_kills, GameState.level)

	# Nightmare difficulty spawn multiplier & early game pacing
	var rate_mult: float = 1.5 if GameState.current_stage == 5 else (1.2 if GameState.current_stage >= 3 else 1.0)
	var current_interval: float
	if time < 60.0:
		current_interval = 1.60 # Menit 0-1: Renggang & terkontrol
	elif time < 120.0:
		current_interval = 1.10 # Menit 1-2: Pacing bertahap
	else:
		# Menit 2 keatas: Spawn massal intensif
		var horde_time: float = time - 120.0
		current_interval = maxf(0.22, (0.70 - (horde_time * 0.006)) / rate_mult)
	
	spawn_timer += delta
	if spawn_timer >= current_interval:
		spawn_timer = 0.0
		spawn_enemy_wave(time)

	# Periodic Tactical Item Drops in Arena (every 35s)
	drop_timer += delta
	if drop_timer >= 35.0:
		drop_timer = 0.0
		spawn_arena_drop()

	# Periodic Horde Swarm
	horde_timer += delta
	if horde_timer >= horde_interval:
		horde_timer = 0.0
		trigger_horde(time)

	# Mini-Boss 1 at 3.0 Minutes (180s)
	if time >= 180.0 and not miniboss_1_flag:
		miniboss_1_flag = true
		spawn_mini_boss("ALPHA-PROTOTYPE", 0.5)

	# Mini-Boss 2 at 7.0 Minutes (420s)
	if time >= 420.0 and not miniboss_2_flag and target_time > 480.0:
		miniboss_2_flag = true
		spawn_mini_boss("BETA-SENTINEL", 0.5)

	# Main Boss spawn trigger at 1 Minute (60s) or 70% of target survival time
	var boss_spawn_time := minf(60.0, target_time * 0.70)
	if time >= boss_spawn_time and not boss_spawned_flag:
		boss_spawned_flag = true
		if current_boss_scene:
			spawn_one(current_boss_scene)
			if GameState.is_coop_mode:
				# Double boss for co-op mode balance!
				spawn_one(current_boss_scene)
			var roar = AudioStreamPlayer.new()
			roar.stream = load("res://assets/audio/sfx_boss_spawn_roar.wav")
			roar.volume_db = 2.0
			add_child(roar)
			roar.play()
			roar.finished.connect(roar.queue_free)
			if has_node("/root/InputManager"):
				get_node("/root/InputManager").vibrate_boss_roar()

func spawn_arena_drop() -> void:
	if not is_instance_valid(player): return
	var drop_scene = load("res://scenes/entities/ArenaDrop.tscn")
	if drop_scene:
		var drop = drop_scene.instantiate()
		var ang = randf_range(0, TAU)
		var dist = randf_range(160, 360)
		drop.global_position = player.global_position + Vector2(cos(ang), sin(ang)) * dist
		var types = ["grenade", "overcharge", "emp_bomb", "credit_cache"]
		drop.item_type = types[randi() % types.size()]
		get_parent().call_deferred("add_child", drop)

func spawn_mini_boss(_m_title: String, hp_mult: float) -> void:
	if not current_boss_scene or not is_instance_valid(player): return
	var mb = current_boss_scene.instantiate()
	var ang = randf_range(0, TAU)
	mb.global_position = player.global_position + Vector2(cos(ang), sin(ang)) * 480.0
	mb.scale = Vector2(0.8, 0.8)
	mb.modulate = Color(1.3, 1.2, 0.4, 1.0) # Golden-yellow elite aura
	mb.add_to_group("mini_boss")
	var cfg = GameState.stage_configs.get(GameState.current_stage, GameState.stage_configs[1])
	var calculated_hp: int = maxi(200, int(cfg["boss_hp"] * hp_mult))
	if "boss_max_hp" in mb:
		mb.boss_max_hp = calculated_hp
		mb.boss_hp = calculated_hp
	if "max_health" in mb:
		mb.max_health = calculated_hp
		mb.health = calculated_hp
	elif "health" in mb and not ("boss_hp" in mb):
		mb.health = calculated_hp
	get_parent().call_deferred("add_child", mb)
	
	if GameState.is_coop_mode:
		var mb2 = current_boss_scene.instantiate()
		var ang2 = randf_range(0, TAU)
		mb2.global_position = player.global_position + Vector2(cos(ang2), sin(ang2)) * 480.0
		mb2.scale = Vector2(0.8, 0.8)
		mb2.modulate = Color(1.3, 1.2, 0.4, 1.0)
		mb2.add_to_group("mini_boss")
		if "boss_max_hp" in mb2:
			mb2.boss_max_hp = calculated_hp
			mb2.boss_hp = calculated_hp
		if "max_health" in mb2:
			mb2.max_health = calculated_hp
			mb2.health = calculated_hp
		elif "health" in mb2 and not ("boss_hp" in mb2):
			mb2.health = calculated_hp
		get_parent().call_deferred("add_child", mb2)

	var siren = AudioStreamPlayer.new()
	siren.stream = load("res://assets/audio/sfx_miniboss_spawn.wav")
	siren.volume_db = 1.0
	add_child(siren)
	siren.play()
	siren.finished.connect(siren.queue_free)

func spawn_enemy_wave(time: float) -> void:
	var passes: int = 2 if GameState.is_coop_mode else 1
	if time >= 120.0:
		passes += 1 # Menit 2+ spawn lebih banyak per gelombang
	for _p in range(passes):
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
	if GameState.is_coop_mode:
		count *= 2
	for i in range(count):
		var angle := (TAU / float(count)) * float(i)
		var h_scene = kamikaze_scene if (GameState.current_stage == 2 and randf() < 0.5) else spider_scene
		spawn_at_angle(h_scene, angle, 420.0)

func get_cardinal_spawn_angle(time: float) -> float:
	# Wave Cardinal Rotation (North -> West -> South -> East)
	# Cycles every 16 seconds to force the player to dynamically move across the arena!
	var cardinal_dirs = [-PI * 0.5, PI, PI * 0.5, 0.0]
	var cycle_idx = int(time / 16.0) % 4
	var base_ang: float = cardinal_dirs[cycle_idx]
	if randf() < 0.75:
		return base_ang + randf_range(-0.45, 0.45)
	return randf_range(0.0, TAU)

func spawn_one(scene: PackedScene) -> void:
	var angle := get_cardinal_spawn_angle(GameState.survival_time)
	spawn_at_angle(scene, angle, randf_range(380.0, 440.0))

func spawn_at_angle(scene: PackedScene, angle: float, radius: float) -> void:
	if not scene or not is_instance_valid(player): return
	var enemy = scene.instantiate()
	var offset := Vector2(cos(angle), sin(angle)) * radius
	enemy.global_position = player.global_position + offset

	# Stage Progression Buff: Stage > 1 enemies get random 1.5x buff (attack speed or move speed)
	if GameState.current_stage > 1:
		if randf() < 0.5:
			if "base_speed" in enemy:
				enemy.base_speed *= 1.5
			if "move_speed" in enemy:
				enemy.move_speed *= 1.5
		else:
			if "attack_cooldown" in enemy:
				enemy.attack_cooldown /= 1.5
			if "shoot_interval" in enemy:
				enemy.shoot_interval /= 1.5

	get_parent().add_child(enemy)
