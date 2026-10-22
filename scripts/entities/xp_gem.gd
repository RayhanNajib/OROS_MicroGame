extends Area2D

@export var xp_value: int = 5
@export var is_gold: bool = false

var player: Node2D = null
var current_speed: float = 0.0
var max_speed: float = 600.0
var acceleration: float = 1200.0
var is_attracted: bool = false

func _ready() -> void:
	add_to_group("loot")
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
		
	var dist := global_position.distance_to(player.global_position)
	var magnet_range = GameState.pickup_radius
	
	if dist <= magnet_range or is_attracted:
		is_attracted = true
		current_speed = min(max_speed, current_speed + acceleration * delta)
		var dir := (player.global_position - global_position).normalized()
		global_position += dir * current_speed * delta
		
		if dist < 14.0:
			collect()

func collect() -> void:
	GameState.add_xp(xp_value)
	if player and player.has_node("SFXXPPickup"):
		player.get_node("SFXXPPickup").play()
	queue_free()
