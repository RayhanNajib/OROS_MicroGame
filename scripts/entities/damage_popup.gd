extends Node2D

@onready var label: Label = $Label

func setup(amount: int, is_crit: bool = false) -> void:
	if not label:
		label = $Label
	label.text = str(amount)
	
	if is_crit or amount >= 30:
		label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25, 1.0))
		scale = Vector2(1.2, 1.2)
	else:
		label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.35, 1.0))
		scale = Vector2.ONE
		
	# Floating parabola animation
	var tw := create_tween()
	tw.set_parallel(true)
	var random_x := randf_range(-18.0, 18.0)
	tw.tween_property(self, "position:y", position.y - 36.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:x", position.x + random_x, 0.45)
	tw.tween_property(self, "modulate:a", 0.0, 0.45).set_delay(0.15)
	tw.chain().tween_callback(queue_free)
