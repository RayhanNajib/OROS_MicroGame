extends CanvasLayer

@onready var bgm_slider: HSlider = $CenterContainer/Panel/Margin/VBox/BGMBox/BGMSlider
@onready var bgm_lbl: Label = $CenterContainer/Panel/Margin/VBox/BGMBox/BGMLbl
@onready var sfx_slider: HSlider = $CenterContainer/Panel/Margin/VBox/SFXBox/SFXSlider
@onready var sfx_lbl: Label = $CenterContainer/Panel/Margin/VBox/SFXBox/SFXLbl

@onready var fullscreen_btn: Button = $CenterContainer/Panel/Margin/VBox/FullscreenBtn
@onready var shake_btn: Button = $CenterContainer/Panel/Margin/VBox/ShakeBtn
@onready var auto_reload_btn: Button = $CenterContainer/Panel/Margin/VBox/AutoReloadBtn
@onready var lang_btn: Button = $CenterContainer/Panel/Margin/VBox/LangBtn
@onready var back_btn: Button = $CenterContainer/Panel/Margin/VBox/BackBtn

@onready var sfx_click: AudioStreamPlayer = $SFXClick

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	if back_btn: back_btn.pressed.connect(_on_back_pressed)
	if fullscreen_btn: fullscreen_btn.pressed.connect(_on_fullscreen_toggled)
	if shake_btn: shake_btn.pressed.connect(_on_shake_toggled)
	if auto_reload_btn: auto_reload_btn.pressed.connect(_on_auto_reload_toggled)
	if lang_btn: lang_btn.pressed.connect(_on_lang_toggled)

	if bgm_slider:
		bgm_slider.value = SaveManager.audio_bgm * 100.0
		bgm_slider.value_changed.connect(_on_bgm_changed)
		update_bgm_label()

	if sfx_slider:
		sfx_slider.value = SaveManager.audio_sfx * 100.0
		sfx_slider.value_changed.connect(_on_sfx_changed)
		update_sfx_label()

	update_button_labels()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ESCAPE:
			var level_modal = get_parent().get_node_or_null("LevelUpModal")
			var game_over = get_parent().get_node_or_null("GameOverModal")
			if (level_modal and level_modal.visible) or (game_over and game_over.visible):
				return
			if visible:
				_on_back_pressed()
			else:
				open_pause()

func open_pause() -> void:
	visible = true
	get_tree().paused = true
	if sfx_click: sfx_click.play()

func _on_back_pressed() -> void:
	if sfx_click: sfx_click.play()
	visible = false
	get_tree().paused = false

func _on_bgm_changed(val: float) -> void:
	SaveManager.audio_bgm = val / 100.0
	SaveManager.save_game()
	update_bgm_label()
	var bgm_bus_idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bgm_bus_idx, linear_to_db(SaveManager.audio_bgm))

func _on_sfx_changed(val: float) -> void:
	SaveManager.audio_sfx = val / 100.0
	SaveManager.save_game()
	update_sfx_label()

func update_bgm_label() -> void:
	if bgm_lbl:
		bgm_lbl.text = "MUSIC VOLUME (%d%%):" % int(SaveManager.audio_bgm * 100.0)

func update_sfx_label() -> void:
	if sfx_lbl:
		sfx_lbl.text = "SFX VOLUME (%d%%):" % int(SaveManager.audio_sfx * 100.0)

func _on_fullscreen_toggled() -> void:
	if sfx_click: sfx_click.play()
	SaveManager.fullscreen = not SaveManager.fullscreen
	if SaveManager.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	SaveManager.save_game()
	update_button_labels()

func _on_shake_toggled() -> void:
	if sfx_click: sfx_click.play()
	SaveManager.camera_shake = not SaveManager.camera_shake
	SaveManager.save_game()
	update_button_labels()

func _on_auto_reload_toggled() -> void:
	if sfx_click: sfx_click.play()
	SaveManager.auto_reload = not SaveManager.auto_reload
	SaveManager.save_game()
	update_button_labels()

func _on_lang_toggled() -> void:
	if sfx_click: sfx_click.play()
	SaveManager.language = "en" if SaveManager.language == "id" else "id"
	SaveManager.save_game()
	update_button_labels()

func update_button_labels() -> void:
	if fullscreen_btn:
		fullscreen_btn.text = "FULLSCREEN: %s" % ("ON" if SaveManager.fullscreen else "OFF")
	if shake_btn:
		shake_btn.text = "CAMERA SHAKE: %s" % ("ON" if SaveManager.camera_shake else "OFF")
	if auto_reload_btn:
		auto_reload_btn.text = "AUTO-RELOAD: %s" % ("ON" if SaveManager.auto_reload else "OFF")
	if lang_btn:
		lang_btn.text = "LANGUAGE: %s" % ("INDONESIA" if SaveManager.language == "id" else "ENGLISH")