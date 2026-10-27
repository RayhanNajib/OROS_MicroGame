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
		
	# Apply Custom Loot Skin from Marketplace
	if has_node("Sprite2D"):
		var sprite = get_node("Sprite2D")
		if not is_gold:
			match SaveManager.equipped_gem_skin:
				"battery":
					sprite.texture = load("res://assets/sprites/skins/spr_gem_battery.png")
				"emerald":
					sprite.texture = load("res://assets/sprites/skins/spr_gem_emerald.png")

func _physics_process(delta: float) -> void:
	var target_player: Node2D = null
	var min_dist := 999999.0
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p):
			var d = global_position.distance_to(p.global_position)
			if d < min_dist:
				min_dist = d
				target_player = p
	if not target_player:
		return
		
	var magnet_range = GameState.pickup_radius
	if min_dist <= magnet_range or is_attracted:
		is_attracted = true
		current_speed = min(max_speed, current_speed + acceleration * delta)
		var dir := (target_player.global_position - global_position).normalized()
		global_position += dir * current_speed * delta
		
		if min_dist < 14.0:
			collect(target_player)

func collect(target_p: Node2D = null) -> void:
	GameState.add_xp(xp_value)
	
	# 20 Minutes Till Dawn Mechanics:
	if GameState.has_recharge and randf() < 0.15:
		if GameState.ammo < GameState.max_ammo:
			GameState.ammo = min(GameState.max_ammo, GameState.ammo + 1)
			GameState.update_ammo_state(GameState.ammo, GameState.max_ammo, false, 0.0)
		if GameState.is_coop_mode and GameState.p2_ammo < GameState.p2_max_ammo:
			GameState.p2_ammo = min(GameState.p2_max_ammo, GameState.p2_ammo + 1)
			GameState.update_p2_ammo_state(GameState.p2_ammo, GameState.p2_max_ammo, false, 0.0)
			
	if GameState.has_excitement:
		GameState.excitement_timer = 1.5

	if target_p and target_p.has_node("SFXXPPickup"):
		target_p.get_node("SFXXPPickup").play()
	elif player and player.has_node("SFXXPPickup"):
		player.get_node("SFXXPPickup").play()
	queue_free()
