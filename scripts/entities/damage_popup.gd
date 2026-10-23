extends Node2D

@onready var label: Label = $Label

func setup(amount: int, is_crit: bool = false) -> void:
	if not label:
		label = $Label
	label.text = str(amount)
	
	if is_crit or amount >= 30:
		label.add_theme_color_override("font_color", Color(0.0, 0.95, 1.0, 1.0)) # Electric Cyan
		scale = Vector2(1.3, 1.3)
	else:
		label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.15, 1.0)) # High-Voltage Yellow
		scale = Vector2.ONE
		
	# Floating parabola animation
	var tw := create_tween()
	tw.set_parallel(true)
	var random_x := randf_range(-18.0, 18.0)
	tw.tween_property(self, "position:y", position.y - 36.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:x", position.x + random_x, 0.45)
	tw.tween_property(self, "modulate:a", 0.0, 0.45).set_delay(0.15)
	tw.chain().tween_callback(queue_free)
