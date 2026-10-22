extends Area2D

@export var heal_amount: int = 1
var bob_offset: float = 0.0

func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	bob_offset = randf_range(0.0, TAU)

func _process(delta: float) -> void:
	# Subtle floating bob
	position.y += sin(Time.get_ticks_msec() * 0.006 + bob_offset) * 12.0 * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameState.heal(heal_amount)
		# Audio feedback on player
		if body.has_node("SFXXPPickup"):
			var sfx = body.get_node("SFXXPPickup")
			sfx.pitch_scale = 1.4 # Higher chime for heal
			sfx.play()
		queue_free()
