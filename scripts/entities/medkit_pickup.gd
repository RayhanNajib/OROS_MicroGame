extends Area2D

@export var heal_amount: int = 1
var bob_offset: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow: Sprite2D = $Shadow

func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	bob_offset = randf_range(0.0, TAU)

func _process(delta: float) -> void:
	# Subtle floating bob on sprite only (floating above shadow)
	if sprite:
		sprite.position.y = -6.0 + sin(Time.get_ticks_msec() * 0.006 + bob_offset) * 4.0
	if shadow and sprite:
		var s := 0.90 - (sprite.position.y / 24.0) * 0.2
		shadow.scale = Vector2(s, s)

	# Automatic Magnet / Vacuum Pull towards nearby player
	var rad = GameState.pickup_radius
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if is_instance_valid(p):
			var dist = global_position.distance_to(p.global_position)
			if dist <= rad:
				var pull_dir = (p.global_position - global_position).normalized()
				var spd = (1.0 - (dist / rad)) * 520.0 + 160.0
				global_position += pull_dir * spd * delta
				if dist <= 26.0:
					_collect(p)
					return

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect(body)

func _collect(body: Node2D) -> void:
	GameState.heal(heal_amount)
	if GameState.is_coop_mode:
		GameState.heal_p2(heal_amount)
	if body.has_node("SFXXPPickup"):
		var sfx = body.get_node("SFXXPPickup")
		sfx.pitch_scale = 1.4 # Higher chime for heal
		sfx.play()
	queue_free()
