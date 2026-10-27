extends Area2D

@export var rotation_speed: float = 4.5
@export var damage: int = 15
var current_angle: float = 0.0
var radius: float = 60.0
var player: Node2D = null

var hit_cooldowns: Dictionary = {}

func _ready() -> void:
	add_to_group("player_weapons")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
		return
		
	current_angle += rotation_speed * delta
	global_position = player.global_position + Vector2(cos(current_angle), sin(current_angle)) * radius
	
	# Update hit cooldowns
	var to_remove := []
	for k in hit_cooldowns.keys():
		hit_cooldowns[k] -= delta
		if hit_cooldowns[k] <= 0.0:
			to_remove.append(k)
	for r in to_remove:
		hit_cooldowns.erase(r)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		deal_saw_damage(body)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		deal_saw_damage(area)

func deal_saw_damage(enemy: Node2D) -> void:
	if hit_cooldowns.has(enemy):
		return
	hit_cooldowns[enemy] = 0.25 # Can hit same enemy every 0.25s
	if enemy.has_method("take_damage"):
		var lvl_scale: float = 1.0 + 0.3 * float(maxi(0, int(GameState.level) - 1))
		if GameState.active_tomes.has("tome_summoning"):
			lvl_scale *= 2.0
		var dmg: int = int(float(damage) * lvl_scale)
		var kb: Vector2 = (enemy.global_position - global_position).normalized() * 60.0
		enemy.take_damage(dmg, kb)
