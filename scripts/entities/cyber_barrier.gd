extends StaticBody2D

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("obstacles")
	# Modulate color based on current stage
	match GameState.current_stage:
		2: # Ruins: mossy green-tinted rock
			modulate = Color(0.8, 1.2, 0.9)
		3: # Reactor: volcanic amber-burnt obsidian
			modulate = Color(1.3, 0.9, 0.7)
		4: # EMP Desert: crystal violet
			modulate = Color(1.1, 0.8, 1.3)
		5: # Apex: cosmic dark purple
			modulate = Color(0.9, 0.7, 1.4)
		_:
			modulate = Color(1.0, 1.0, 1.0)
