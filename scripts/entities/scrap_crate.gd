extends StaticBody2D

@export var max_hp: int = 120
var current_hp: int = 120

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("environment")
	current_hp = max_hp

func take_damage(amount: int, _knockback: Vector2 = Vector2.ZERO, _from_melee: bool = false) -> void:
	current_hp -= amount
	
	if sprite:
		sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
		var tw := create_tween()
		tw.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.08)
		
	if current_hp <= 0:
		destroy()

func destroy() -> void:
	# Drop Tactical Arena Item or Gold Gem
	var roll := randf()
	if roll < 0.45:
		var drop_scene = load("res://scenes/entities/ArenaDrop.tscn")
		if drop_scene:
			var drop = drop_scene.instantiate()
			drop.global_position = global_position
			var types = ["grenade", "overcharge", "emp_bomb", "credit_cache"]
			drop.item_type = types[randi() % types.size()]
			get_parent().call_deferred("add_child", drop)
	else:
		var xp_scene = load("res://scenes/entities/XPGem.tscn")
		if xp_scene:
			var gem = xp_scene.instantiate()
			gem.global_position = global_position
			gem.xp_value = 18
			gem.is_gold = true
			get_parent().call_deferred("add_child", gem)
		
	queue_free()
