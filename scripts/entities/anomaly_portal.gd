extends Area2D

@export var portal_tag: String = "ALPHA" # "ALPHA" or "BETA"
var linked_portal: Node2D = null
var cooldown: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("portals")
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if cooldown > 0.0:
		cooldown -= delta
	if sprite:
		sprite.rotation += delta * 1.5
		var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.005) * 0.08
		sprite.scale = Vector2(pulse, pulse)

func _on_body_entered(body: Node2D) -> void:
	if cooldown > 0.0: return
	if body.is_in_group("player") and is_instance_valid(linked_portal):
		# Teleport player
		var target_dest = linked_portal.global_position + Vector2(0, 30)
		body.global_position = target_dest
		cooldown = 3.5
		if linked_portal.get("cooldown") != null:
			linked_portal.cooldown = 3.5
			
		# Screen shake & visual flash
		GameState.screen_shake_requested.emit(8.0, 0.25)
		if has_node("/root/InputManager"):
			get_node("/root/InputManager").vibrate(0.7, 0.4, 0.20, 1)
			
		# Visual flash ring on target
		var tw = create_tween()
		body.modulate = Color(2.5, 2.5, 0.5, 1.0)
		tw.tween_property(body, "modulate", Color.WHITE, 0.25)
