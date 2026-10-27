extends Node2D

@export var duration: float = 3.2
@export var blast_damage: int = 40
@export var rewind_blast_damage: int = 75

@onready var sprite: Sprite2D = $Sprite2D
@onready var col_shape: CollisionShape2D = $CollisionShape2D

var owner_player: Node2D = null
var timer: float = 0.0
var attack_cooldown: float = 0.0
var time_label: Label = null
var is_rewound: bool = false

func _ready() -> void:
	add_to_group("decoy")
	if sprite:
		sprite.modulate = Color(0.2, 0.9, 1.4, 0.85)
		# Holographic glitch flicker
		var tw := create_tween().set_loops()
		tw.tween_property(sprite, "modulate:a", 0.4, 0.09)
		tw.tween_property(sprite, "modulate:a", 0.95, 0.09)

	# Label countdown
	time_label = Label.new()
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_override("font", load("res://assets/fonts/Silkscreen-Bold.ttf"))
	time_label.add_theme_font_size_override("font_size", 10)
	time_label.add_theme_color_override("font_color", Color(0.3, 0.95, 1.0))
	time_label.position = Vector2(-60, -38)
	time_label.custom_minimum_size = Vector2(120, 16)
	time_label.text = "[ ⏪ 3.0s REWIND ]"
	add_child(time_label)

func _process(delta: float) -> void:
	if is_rewound: return
	timer += delta
	var remaining: float = maxf(0.0, duration - timer)
	if time_label:
		time_label.text = "[ ⏪ %.1fs REWIND ]" % remaining
		if remaining < 1.0:
			time_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	
	queue_redraw()
	
	# Attack mechanism (Attacks nearby enemies like 3 seconds ago past echo)
	attack_cooldown -= delta
	if attack_cooldown <= 0.0:
		attack_cooldown = 0.38
		perform_chrono_attack()

	if timer >= duration:
		explode(false)

func _draw() -> void:
	# Holographic time dial ring
	var rem_ratio: float = clampf((duration - timer) / duration, 0.0, 1.0)
	var end_angle: float = rem_ratio * TAU - PI * 0.5
	var ring_col := Color(0.18, 0.85, 1.0, 0.6) if rem_ratio > 0.3 else Color(1.0, 0.35, 0.35, 0.8)
	draw_arc(Vector2.ZERO, 28.0, -PI * 0.5, end_angle, 32, ring_col, 2.5, true)
	draw_circle(Vector2.ZERO, 3.0, Color(0.3, 1.0, 1.0, 0.8))

func perform_chrono_attack() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var target_e: Node2D = null
	var closest_dist: float = 300.0
	for e in enemies:
		if is_instance_valid(e):
			var d := global_position.distance_to(e.global_position)
			if d < closest_dist:
				closest_dist = d
				target_e = e

	if target_e:
		var dir := (target_e.global_position - global_position).normalized()
		# Fire Chrono Phantom Dagger
		var b_scene = load("res://scenes/entities/Bullet.tscn")
		if b_scene:
			var b = b_scene.instantiate()
			b.global_position = global_position
			b.direction = dir
			b.damage = 26 + GameState.skill_level * 5
			b.speed = 640.0
			b.modulate = Color(0.3, 0.9, 1.8, 1.0)
			get_parent().call_deferred("add_child", b)
			
		# Visual attack flash on clone
		if sprite:
			var tw := create_tween()
			tw.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.05)
			tw.tween_property(sprite, "scale", Vector2.ONE, 0.08)

func trigger_rewind(player: Node2D) -> void:
	if is_rewound or not is_instance_valid(player): return
	is_rewound = true
	
	# Teleport player back to clone's position (Rewind 3 seconds!)
	player.global_position = global_position
	
	# Give invulnerability + heal
	if "is_invulnerable" in player:
		player.is_invulnerable = true
		player.invuln_timer = 0.60
	GameState.heal(1, player.player_index if "player_index" in player else 1)
	
	# Popup
	var arc_scene = load("res://scenes/entities/DamagePopup.tscn")
	if arc_scene:
		var pop = arc_scene.instantiate()
		pop.global_position = player.global_position + Vector2(0, -45)
		pop.setup(0, false)
		if pop.has_node("Label"):
			pop.get_node("Label").text = "[ ⏪ CHRONO REWIND ]"
		pop.modulate = Color(0.2, 1.0, 0.8)
		get_parent().add_child(pop)
	
	explode(true)

func explode(is_from_rewind: bool = false) -> void:
	var dmg: int = rewind_blast_damage if is_from_rewind else blast_damage
	var blast_radius: float = 200.0 if is_from_rewind else 140.0
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and global_position.distance_to(e.global_position) < blast_radius:
			var to_e = (e.global_position - global_position).normalized()
			if e.has_method("take_damage"):
				e.take_damage(dmg, to_e * 240.0, false)
			if e.has_method("apply_freeze"):
				e.apply_freeze(0.6, 2.0)
				
	# Spawn shockwave visual
	var arc_scene = load("res://scenes/entities/DamagePopup.tscn")
	if arc_scene:
		var pop = arc_scene.instantiate()
		pop.global_position = global_position + Vector2(0, -20)
		pop.setup(dmg, true)
		pop.modulate = Color(0.3, 0.9, 1.5) if is_from_rewind else Color(1.0, 0.8, 0.2)
		get_parent().add_child(pop)
		
	if owner_player and "active_chrono_clone" in owner_player:
		if owner_player.active_chrono_clone == self:
			owner_player.active_chrono_clone = null
			
	queue_free()
