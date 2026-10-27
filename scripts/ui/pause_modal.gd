extends CanvasLayer

@onready var resume_btn: Button = $CenterContainer/Panel/Margin/VBox/ResumeBtn
@onready var settings_btn: Button = $CenterContainer/Panel/Margin/VBox/SettingsBtn
@onready var quit_btn: Button = $CenterContainer/Panel/Margin/VBox/QuitBtn
@onready var subtitle_lbl: Label = $CenterContainer/Panel/Margin/VBox/Subtitle
@onready var sfx_click: AudioStreamPlayer = $SFXClick

var settings_modal_instance: CanvasLayer = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	if resume_btn: resume_btn.pressed.connect(_on_resume_pressed)
	if settings_btn: settings_btn.pressed.connect(_on_settings_pressed)
	if quit_btn: quit_btn.pressed.connect(_on_quit_pressed)

	for btn in [resume_btn, settings_btn, quit_btn]:
		if btn:
			var h_style = btn.get_theme_stylebox("hover")
			if h_style:
				btn.add_theme_stylebox_override("focus", h_style)

func open_pause() -> void:
	visible = true
	get_tree().paused = true
	if subtitle_lbl:
		subtitle_lbl.text = "SEKTOR: [ STAGE %02d ] • STATUS: SISTEM DIJEDA" % GameState.current_stage
	if sfx_click: sfx_click.play()
	if resume_btn:
		resume_btn.grab_focus()

func _safe_handle_input() -> void:
	if is_inside_tree() and get_viewport():
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if not visible: return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_KP_0:
			_safe_handle_input()
			_on_resume_pressed()
	elif event is InputEventJoypadButton and event.is_pressed():
		match event.button_index:
			JOY_BUTTON_START, JOY_BUTTON_B:
				_safe_handle_input()
				_on_resume_pressed()
			JOY_BUTTON_BACK:
				_safe_handle_input()
				_on_settings_pressed()
			JOY_BUTTON_LEFT_SHOULDER:
				_safe_handle_input()
				_on_back_pressed()
			JOY_BUTTON_RIGHT_SHOULDER:
				_safe_handle_input()
				_on_resume_pressed()

func _on_back_pressed() -> void:
	_on_resume_pressed()

func _on_resume_pressed() -> void:
	if sfx_click: sfx_click.play()
	visible = false
	get_tree().paused = false

func _on_settings_pressed() -> void:
	if sfx_click: sfx_click.play()
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if not is_instance_valid(settings_modal_instance):
		# Look for existing SettingsModal in parent or root first
		if has_node("../SettingsModal"):
			settings_modal_instance = get_node("../SettingsModal")
		else:
			var existing = get_tree().root.find_child("SettingsModal", true, false)
			if existing:
				settings_modal_instance = existing
			else:
				var s_scene = load("res://scenes/ui/SettingsModal.tscn")
				if s_scene:
					settings_modal_instance = s_scene.instantiate()
					get_tree().root.add_child(settings_modal_instance)
		
		if is_instance_valid(settings_modal_instance) and settings_modal_instance.has_signal("settings_closed"):
			if not settings_modal_instance.settings_closed.is_connected(_on_settings_closed):
				settings_modal_instance.settings_closed.connect(_on_settings_closed)
	
	if is_instance_valid(settings_modal_instance):
		if settings_modal_instance is CanvasLayer:
			settings_modal_instance.layer = 100
		if settings_modal_instance.has_method("open_modal"):
			settings_modal_instance.open_modal()

func _on_settings_closed() -> void:
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if resume_btn:
		resume_btn.grab_focus()

func _on_quit_pressed() -> void:
	if sfx_click: sfx_click.play()
	if is_instance_valid(settings_modal_instance):
		settings_modal_instance.queue_free()
	visible = false
	get_tree().paused = false
	GameState.reset_run()
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")