extends CanvasLayer

@onready var avatar_frame: TextureRect = $TopLeftLoadout/AvatarFrame
@onready var weapon_frame: TextureRect = $TopLeftLoadout/WeaponFrame

@onready var vignette_overlay: TextureRect = $VignetteOverlay
@onready var death_audio_player: AudioStreamPlayer = $DeathAudioPlayer
@onready var center_box: VBoxContainer = $CenterBox
@onready var title_label: Label = $CenterBox/Title
@onready var subtitle_label: Label = $CenterBox/Subtitle
@onready var time_label: Label = $CenterBox/ScorePanel/Margin/VBox/TimeRow/Label
@onready var time_val: Label = $CenterBox/ScorePanel/Margin/VBox/TimeRow/Val
@onready var kills_label: Label = $CenterBox/ScorePanel/Margin/VBox/KillsRow/Label
@onready var kills_val: Label = $CenterBox/ScorePanel/Margin/VBox/KillsRow/Val
@onready var rank_val: Label = $CenterBox/ScorePanel/Margin/VBox/RankRow/Val
@onready var earned_val: Label = $CenterBox/ScorePanel/Margin/VBox/EarnedRow/Val

@onready var retry_btn: Button = $CenterBox/HBoxBtns/RetryBtn
@onready var menu_btn: Button = $CenterBox/HBoxBtns/MenuBtn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	GameState.game_over_triggered.connect(_on_game_over)
	GameState.mission_victory_triggered.connect(_on_mission_victory)
	
	if retry_btn:
		retry_btn.pressed.connect(_on_retry_pressed)
	if menu_btn:
		menu_btn.pressed.connect(_on_menu_pressed)

func _input(event: InputEvent) -> void:
	if not visible: return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_KP_0:
			if is_inside_tree() and get_viewport():
				get_viewport().set_input_as_handled()
			_on_menu_pressed()
	elif event is InputEventJoypadButton and event.is_pressed():
		if event.button_index == JOY_BUTTON_B or event.button_index == JOY_BUTTON_BACK or event.button_index == JOY_BUTTON_START:
			if is_inside_tree() and get_viewport():
				get_viewport().set_input_as_handled()
			_on_menu_pressed()
		elif event.button_index == JOY_BUTTON_X or event.button_index == JOY_BUTTON_Y:
			if is_inside_tree() and get_viewport():
				get_viewport().set_input_as_handled()
			_on_retry_pressed()

func _process(_delta: float) -> void:
	if visible and Input.is_action_just_pressed("restart"):
		_on_retry_pressed()
	elif visible and Input.is_physical_key_pressed(KEY_ESCAPE):
		_on_menu_pressed()

func _on_game_over(time_survived: float, kills: int, lvl: int) -> void:
	show_debriefing(false, time_survived, kills, lvl)

func _on_mission_victory(time_survived: float, kills: int, lvl: int) -> void:
	show_debriefing(true, time_survived, kills, lvl)

func show_debriefing(is_victory: bool, time_survived: float, kills: int, _lvl: int) -> void:
	get_tree().paused = true
	visible = true

	# Set top-left loadout icons
	var av_path = "res://assets/sprites/avatar_%s.png" % GameState.selected_hero
	if ResourceLoader.exists(av_path) and avatar_frame:
		avatar_frame.texture = load(av_path)
		
	var wep_path = "res://assets/sprites/icon_wep_%s.png" % (GameState.primary_weapon if not GameState.is_melee_active else "melee")
	if ResourceLoader.exists(wep_path) and weapon_frame:
		weapon_frame.texture = load(wep_path)

	var total_sec := int(time_survived)
	var mins := floori(float(total_sec) / 60.0)
	var secs := total_sec % 60

	var eval := GameState.calculate_mission_rank()
	var rank: String = eval["rank"]
	var total_nc: int = eval["total_nc"]

	if title_label:
		if is_victory:
			title_label.text = "[ MISSION ACCOMPLISHED // SECTOR PURGED ]"
			title_label.add_theme_color_override("font_color", Color(0, 0.94, 1.0))
			title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.6, 0.9, 0.9))
			title_label.add_theme_constant_override("shadow_offset_x", 3)
			title_label.add_theme_constant_override("shadow_offset_y", 3)
			if subtitle_label:
				subtitle_label.text = "ALL THREATS ELIMINATED — EXTRACTION SECURE"
				subtitle_label.add_theme_color_override("font_color", Color(0.3, 0.95, 0.7))
			if vignette_overlay:
				vignette_overlay.modulate = Color(0.1, 0.7, 1.0, 0.0)
				var tw := create_tween()
				tw.tween_property(vignette_overlay, "modulate:a", 0.75, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			if death_audio_player:
				death_audio_player.play()
			title_label.text = "[ CRITICAL FAILURE // CHASSIS DESTROYED ]"
			title_label.add_theme_color_override("font_color", Color(1.0, 0.22, 0.28))
			title_label.add_theme_color_override("font_shadow_color", Color(0.85, 0.0, 0.1, 0.95))
			title_label.add_theme_constant_override("shadow_offset_x", 4)
			title_label.add_theme_constant_override("shadow_offset_y", 4)
			if subtitle_label:
				subtitle_label.text = "NEURAL LINK SEVERED — RETREAT MANDATED"
				subtitle_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
			if vignette_overlay:
				vignette_overlay.modulate = Color(1.0, 0.15, 0.2, 0.0)
				var tw := create_tween()
				tw.tween_property(vignette_overlay, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if center_box:
		center_box.pivot_offset = center_box.size * 0.5
		center_box.scale = Vector2(1.15, 1.15)
		var box_tw := create_tween()
		box_tw.tween_property(center_box, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if time_label:
		time_label.text = "DURASI SURVIVAL (%02d:%02d)" % [mins, secs]
	if time_val:
		time_val.text = "%02d:%02d" % [mins, secs]

	if kills_label:
		kills_label.text = "ROBOT DIELIMINASI"
	if kills_val:
		kills_val.text = "%d UNITS" % kills

	if rank_val:
		rank_val.text = "RANK %s" % rank
		if rank == "S":
			rank_val.add_theme_color_override("font_color", Color(0.98, 0.8, 0.08))
		elif rank == "A":
			rank_val.add_theme_color_override("font_color", Color(0.13, 0.95, 0.4))
		else:
			rank_val.add_theme_color_override("font_color", Color(0, 0.94, 1.0))

	if earned_val:
		earned_val.text = "+%d NC" % total_nc
		SaveManager.nano_credits += total_nc
		SaveManager.save_game()

	if retry_btn and menu_btn:
		retry_btn.focus_mode = Control.FOCUS_ALL
		menu_btn.focus_mode = Control.FOCUS_ALL
		retry_btn.focus_neighbor_right = menu_btn.get_path()
		retry_btn.focus_neighbor_left = menu_btn.get_path()
		menu_btn.focus_neighbor_left = retry_btn.get_path()
		menu_btn.focus_neighbor_right = retry_btn.get_path()
		retry_btn.grab_focus()

func _on_retry_pressed() -> void:
	get_tree().paused = false
	GameState.reset_run()
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	GameState.reset_run()
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
