extends Node2D

var floor_sprite: Sprite2D
var timer: float = 0.0
var stage_cycle: int = 1
var actors: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var particles: Array[Dictionary] = []

func _ready() -> void:
	z_index = -10
	floor_sprite = Sprite2D.new()
	var tex = load("res://assets/sprites/tile_floor_stage1.png")
	if tex:
		floor_sprite.texture = tex
		floor_sprite.region_enabled = true
		floor_sprite.region_rect = Rect2(0, 0, 1920, 1080)
	add_child(floor_sprite)
	floor_sprite.centered = false
	
	spawn_actors()

func spawn_actors() -> void:
	# 3 Hero Bots
	var heroes = [
		{"name": "kael", "pos": Vector2(380, 520), "dir": Vector2.RIGHT, "cooldown": 0.3},
		{"name": "nyx", "pos": Vector2(480, 720), "dir": Vector2(1, -0.4).normalized(), "cooldown": 0.6},
		{"name": "brutus", "pos": Vector2(320, 360), "dir": Vector2(1, 0.3).normalized(), "cooldown": 0.8}
	]
	for h in heroes:
		var sp = Sprite2D.new()
		var tex = load("res://assets/sprites/player_%s_run.png" % h["name"])
		if tex:
			sp.texture = tex
			sp.hframes = 4
			sp.frame = 1
		sp.position = h["pos"]
		add_child(sp)
		h["sprite"] = sp
		actors.append(h)
		
	# Swarm of Enemy Spiders on right side
	for i in range(8):
		spawn_enemy_bot()

func spawn_enemy_bot() -> void:
	var e = {
		"pos": Vector2(randf_range(1300, 1850), randf_range(250, 950)),
		"speed": randf_range(60.0, 110.0),
		"hp": 2
	}
	var sp = Sprite2D.new()
	var tex = load("res://assets/sprites/spr_enemy_spider.png")
	if not tex:
		tex = load("res://assets/sprites/spr_enemy_drone.png")
	if tex:
		sp.texture = tex
	sp.position = e["pos"]
	add_child(sp)
	e["sprite"] = sp
	enemies.append(e)

func _process(delta: float) -> void:
	timer += delta
	
	# Stage cycle every 10 seconds with seamless crossfade
	if int(timer) % 10 == 0 and int(timer) != 0:
		var next_stage = (stage_cycle % 4) + 1
		if next_stage != stage_cycle:
			stage_cycle = next_stage
			var tex = load("res://assets/sprites/tile_floor_stage%d.png" % stage_cycle)
			if tex and floor_sprite:
				var tw = create_tween()
				tw.tween_property(floor_sprite, "modulate:a", 0.3, 0.4)
				tw.tween_callback(func():
					floor_sprite.texture = tex
				)
				tw.tween_property(floor_sprite, "modulate:a", 1.0, 0.4)

	# Update Hero Actors
	for h in actors:
		var sp: Sprite2D = h["sprite"]
		h["cooldown"] -= delta
		
		# Slight patrol sway
		h["pos"].y += sin(timer * 2.0 + h["pos"].x) * 18.0 * delta
		sp.position = h["pos"]
		
		# Fire projectile periodically towards enemies
		if h["cooldown"] <= 0.0:
			h["cooldown"] = randf_range(0.35, 0.65)
			fire_backdrop_laser(h["pos"], h["name"])

	# Update Enemy Bots
	for i in range(enemies.size() - 1, -1, -1):
		var e = enemies[i]
		var sp: Sprite2D = e["sprite"]
		e["pos"].x -= e["speed"] * delta
		sp.position = e["pos"]
		
		if e["pos"].x < 650:
			# Recycle enemy to right side
			e["pos"] = Vector2(randf_range(1600, 1920), randf_range(250, 950))

	# Update laser particles
	for i in range(particles.size() - 1, -1, -1):
		var p = particles[i]
		p["pos"] += p["vel"] * delta
		p["sprite"].position = p["pos"]
		p["life"] -= delta
		if p["life"] <= 0.0 or p["pos"].x > 1920:
			p["sprite"].queue_free()
			particles.remove_at(i)

func fire_backdrop_laser(from_pos: Vector2, hero_name: String) -> void:
	var sp = Sprite2D.new()
	var col = Color(0, 0.94, 1.0)
	if hero_name == "nyx": col = Color(0.85, 0.25, 1.0)
	elif hero_name == "brutus": col = Color(1.0, 0.88, 0.29)
	
	var img = Image.create(16, 4, false, Image.FORMAT_RGBA8)
	img.fill(col)
	var tex = ImageTexture.create_from_image(img)
	sp.texture = tex
	sp.position = from_pos + Vector2(25, 0)
	add_child(sp)
	
	var aim = Vector2(randf_range(0.85, 1.0), randf_range(-0.15, 0.15)).normalized()
	particles.append({
		"sprite": sp,
		"pos": sp.position,
		"vel": aim * 950.0,
		"life": 1.6
	})
