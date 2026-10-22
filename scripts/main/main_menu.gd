extends Control

@onready var start_btn: Button = $VBoxCenter/StartBtn
@onready var sfx_click: AudioStreamPlayer = $SFXClick

func _ready() -> void:
	if start_btn:
		start_btn.pivot_offset = Vector2(120, 18)
		start_btn.pressed.connect(_on_start_pressed)
		start_btn.mouse_entered.connect(func():
			var tw := start_btn.create_tween()
			tw.tween_property(start_btn, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		)
		start_btn.mouse_exited.connect(func():
			var tw := start_btn.create_tween()
			tw.tween_property(start_btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_on_start_pressed()

func _on_start_pressed() -> void:
	if sfx_click:
		sfx_click.play()
	GameState.reset_run()
	get_tree().change_scene_to_file("res://scenes/main/GameArena.tscn")
