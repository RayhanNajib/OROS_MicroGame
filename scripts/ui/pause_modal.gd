extends CanvasLayer

@onready var resume_btn: Button = $CenterContainer/Panel/Margin/VBox/ResumeBtn
@onready var bgm_slider: HSlider = $CenterContainer/Panel/Margin/VBox/BGMBox/BGMSlider
@onready var sfx_slider: HSlider = $CenterContainer/Panel/Margin/VBox/SFXBox/SFXSlider
@onready var lang_btn: Button = $CenterContainer/Panel/Margin/VBox/LangBox/LangBtn
@onready var menu_btn: Button = $CenterContainer/Panel/Margin/VBox/MenuBtn

@onready var sfx_click: AudioStreamPlayer = $SFXClick

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	if resume_btn:
		resume_btn.pressed.connect(_on_resume_pressed)
	if menu_btn:
		menu_btn.pressed.connect(_on_menu_pressed)
		
	if bgm_slider:
		bgm_slider.value = SaveManager.audio_bgm * 100.0
		bgm_slider.value_changed.connect(_on_bgm_changed)
		
	if sfx_slider:
		sfx_slider.value = SaveManager.audio_sfx * 100.0
		sfx_slider.value_changed.connect(_on_sfx_changed)
		
	if lang_btn:
		lang_btn.text = "BAHASA: INDONESIA" if SaveManager.language == "id" else "LANGUAGE: ENGLISH"
		lang_btn.pressed.connect(_on_lang_toggled)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ESCAPE:
			# Only toggle if level up modal or game over modal are not open
			var level_modal = get_parent().get_node_or_null("LevelUpModal")
			var game_over = get_parent().get_node_or_null("GameOverModal")
			if (level_modal and level_modal.visible) or (game_over and game_over.visible):
				return
				
			if visible:
				_on_resume_pressed()
			else:
				open_pause()

func open_pause() -> void:
	visible = true
	get_tree().paused = true
	if sfx_click: sfx_click.play()

func _on_resume_pressed() -> void:
	if sfx_click: sfx_click.play()
	visible = false
	get_tree().paused = false

func _on_bgm_changed(val: float) -> void:
	SaveManager.audio_bgm = val / 100.0
	SaveManager.save_game()
	var bgm_bus_idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bgm_bus_idx, linear_to_db(SaveManager.audio_bgm))

func _on_sfx_changed(val: float) -> void:
	SaveManager.audio_sfx = val / 100.0
	SaveManager.save_game()

func _on_lang_toggled() -> void:
	if sfx_click: sfx_click.play()
	SaveManager.language = "en" if SaveManager.language == "id" else "id"
	lang_btn.text = "BAHASA: INDONESIA" if SaveManager.language == "id" else "LANGUAGE: ENGLISH"
	SaveManager.save_game()

func _on_menu_pressed() -> void:
	if sfx_click: sfx_click.play()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
