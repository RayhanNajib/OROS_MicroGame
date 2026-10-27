extends Area2D

@export var item_type: String = "grenade" # "grenade", "overcharge", "emp_bomb", "credit_cache"

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow: Sprite2D = $Shadow

var anim_time: float = 0.0

func _ready() -> void:
	add_to_group("arena_item")
	body_entered.connect(_on_body_entered)
	update_visual()

func update_visual() -> void:
	if not sprite: return
	match item_type:
		"grenade":
			sprite.texture = load("res://assets/sprites/spr_pickup_grenade.png")
		"overcharge":
			sprite.texture = load("res://assets/sprites/spr_pickup_overcharge.png")
		"emp_bomb":
			sprite.texture = load("res://assets/sprites/spr_pickup_emp_bomb.png")
		"credit_cache":
			sprite.texture = load("res://assets/sprites/spr_pickup_credit_cache.png")

func _process(delta: float) -> void:
	anim_time += delta
	var bob := sin(anim_time * 5.0) * 3.5
	if sprite:
		sprite.position.y = bob
	if shadow:
		var s := 1.0 - (bob / 12.0)
		shadow.scale = Vector2(s, s)

	# Automatic Magnet / Vacuum Pull towards nearby player
	var gs = get_node_or_null("/root/GameState")
	var rad = gs.pickup_radius if gs else 140.0
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if is_instance_valid(p):
			var dist = global_position.distance_to(p.global_position)
			if dist <= rad:
				var pull_dir = (p.global_position - global_position).normalized()
				var spd = (1.0 - (dist / rad)) * 540.0 + 180.0
				global_position += pull_dir * spd * delta
				if dist <= 32.0:
					collect(p)
					return

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collect(body)

func collect(_player: Node2D) -> void:
	set_deferred("monitoring", false)
	var gs = get_node_or_null("/root/GameState")
	
	match item_type:
		"grenade":
			# Immediate tactical 220px plasma blast!
			var enemies = get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if is_instance_valid(e) and global_position.distance_to(e.global_position) <= 220.0:
					var to_e = (e.global_position - global_position).normalized()
					if e.has_method("take_damage"):
						e.take_damage(120, to_e * 300.0, false)
			# Shockwave visual
			modulate = Color(3.0, 2.0, 0.5, 1.0)
		"overcharge":
			if gs:
				gs.excitement_timer = 6.0
				gs.ammo = gs.max_ammo
				gs.update_ammo_state(gs.ammo, gs.max_ammo, false, 0.0)
		"emp_bomb":
			var enemies = get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if is_instance_valid(e) and e.has_method("apply_freeze"):
					e.apply_freeze(0.2, 4.0)
		"credit_cache":
			if gs:
				gs.session_credits += 50
				var sm = get_node_or_null("/root/SaveManager")
				if sm: sm.add_credits(50)
				
	# Pop scale effect and queue_free
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(sprite, "scale", Vector2(1.6, 1.6), 0.15)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.15)
	tw.tween_callback(queue_free)
