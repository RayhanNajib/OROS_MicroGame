extends Area2D

var player: Node2D = null
var is_picked: bool = false

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("loot")
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	# Hover float & spin
	var hover := sin(Time.get_ticks_msec() * 0.006) * 3.0
	if sprite:
		sprite.position.y = hover
		sprite.rotation += delta * 2.5
		
	# Magnet pull
	if not is_picked and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < GameState.pickup_radius * 1.5:
			var dir = (player.global_position - global_position).normalized()
			global_position += dir * (320.0 * delta)
			if dist < 24.0:
				collect()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collect()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		collect()

func collect() -> void:
	if is_picked: return
	is_picked = true
	GameState.upgrade_skill()
	
	if is_instance_valid(player) and player.has_node("SFXPickupCore"):
		player.get_node("SFXPickupCore").play()
		
	# Spawn Floating Notification
	var popup_scene = load("res://scenes/entities/DamagePopup.tscn")
	if popup_scene:
		var popup = popup_scene.instantiate()
		popup.global_position = global_position + Vector2(0, -30)
		popup.setup(GameState.skill_level, false)
		get_parent().add_child(popup)
		
	queue_free()
