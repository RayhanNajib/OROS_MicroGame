extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow: Sprite2D = $Shadow

var base_y: float = 0.0
var anim_time: float = 0.0

func _ready() -> void:
	add_to_group("loot")
	base_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	anim_time += delta
	var bob := sin(anim_time * 4.0) * 4.0
	if sprite:
		# Floating higher up above the floor
		sprite.position.y = -26.0 + bob
		sprite.rotation = sin(anim_time * 2.5) * 0.08
	if shadow:
		var s := 1.0 - (bob / 12.0)
		shadow.scale = Vector2(s, s)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collect()

func collect() -> void:
	set_deferred("monitoring", false)
	
	# Spawn Tome Selection Modal
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_method("open_tome_modal"):
		gs.open_tome_modal()
	else:
		# Fallback: search tree for TomeModal
		var tm = get_tree().get_first_node_in_group("tome_modal")
		if tm and tm.has_method("open_modal"):
			tm.open_modal()
			
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.2)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.2)
	tw.tween_callback(queue_free)
