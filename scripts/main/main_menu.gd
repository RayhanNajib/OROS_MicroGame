extends Control

@onready var start_btn: Button = $VBoxCenter/ButtonsVBox/StartBtn
@onready var controls_btn: Button = $VBoxCenter/ButtonsVBox/ControlsBtn
@onready var credits_btn: Button = $VBoxCenter/ButtonsVBox/CreditsBtn
@onready var quit_btn: Button = $VBoxCenter/ButtonsVBox/QuitBtn

@onready var controls_modal: ColorRect = $ControlsModal
@onready var close_controls_btn: Button = $ControlsModal/Center/Panel/Margin/VBox/CloseControlsBtn

@onready var credits_modal: ColorRect = $CreditsModal
@onready var close_credits_btn: Button = $CreditsModal/Center/Panel/Margin/VBox/CloseCreditsBtn

@onready var sfx_click: AudioStreamPlayer = $SFXClick

func _ready() -> void:
	# Setup button micro-interactions
	setup_btn(start_btn, _on_start_pressed, Vector2(120, 18))
	setup_btn(controls_btn, _on_controls_pressed, Vector2(120, 15))
	setup_btn(credits_btn, _on_credits_pressed, Vector2(120, 15))
	setup_btn(quit_btn, _on_quit_pressed, Vector2(120, 14))
	
	if close_controls_btn:
		setup_btn(close_controls_btn, func(): controls_modal.visible = false, Vector2(80, 14))
	if close_credits_btn:
		setup_btn(close_credits_btn, func(): credits_modal.visible = false, Vector2(80, 14))

func setup_btn(btn: Button, callback: Callable, pivot: Vector2) -> void:
	if not btn: return
	btn.pivot_offset = pivot
	btn.pressed.connect(func():
		if sfx_click: sfx_click.play()
		callback.call()
	)
	btn.mouse_entered.connect(func():
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func():
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ESCAPE:
			if controls_modal and controls_modal.visible:
				controls_modal.visible = false
			elif credits_modal and credits_modal.visible:
				credits_modal.visible = false
		elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			if not (controls_modal and controls_modal.visible) and not (credits_modal and credits_modal.visible):
				_on_start_pressed()

func _on_start_pressed() -> void:
	GameState.reset_run()
	get_tree().change_scene_to_file("res://scenes/main/GameArena.tscn")

func _on_controls_pressed() -> void:
	if controls_modal:
		controls_modal.visible = true

func _on_credits_pressed() -> void:
	if credits_modal:
		credits_modal.visible = true

func _on_quit_pressed() -> void:
	get_tree().quit()
