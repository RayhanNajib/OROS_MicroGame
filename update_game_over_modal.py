content = '''extends CanvasLayer

@onready var title_label: Label = $CenterContainer/PanelContainer/Margin/VBox/Title
@onready var stats_label: Label = $CenterContainer/PanelContainer/Margin/VBox/StatsLabel
@onready var retry_btn: Button = $CenterContainer/PanelContainer/Margin/VBox/HBoxBtns/RetryBtn
@onready var menu_btn: Button = $CenterContainer/PanelContainer/Margin/VBox/HBoxBtns/MenuBtn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	GameState.game_over_triggered.connect(_on_game_over)
	GameState.mission_victory_triggered.connect(_on_mission_victory)
	
	if retry_btn:
		retry_btn.pivot_offset = Vector2(170, 26)
		retry_btn.pressed.connect(_on_retry_pressed)
		retry_btn.mouse_entered.connect(func():
			var tw := retry_btn.create_tween()
			tw.tween_property(retry_btn, "scale", Vector2(1.04, 1.04), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		)
		retry_btn.mouse_exited.connect(func():
			var tw := retry_btn.create_tween()
			tw.tween_property(retry_btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		)
		
	if menu_btn:
		menu_btn.pivot_offset = Vector2(170, 26)
		menu_btn.pressed.connect(_on_menu_pressed)
		menu_btn.mouse_entered.connect(func():
			var tw := menu_btn.create_tween()
			tw.tween_property(menu_btn, "scale", Vector2(1.04, 1.04), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		)
		menu_btn.mouse_exited.connect(func():
			var tw := menu_btn.create_tween()
			tw.tween_property(menu_btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		)

func _process(_delta: float) -> void:
	if visible and Input.is_action_just_pressed("restart"):
		_on_retry_pressed()
	elif visible and Input.is_physical_key_pressed(KEY_ESCAPE):
		_on_menu_pressed()

func _on_game_over(time_survived: float, kills: int, lvl: int) -> void:
	show_debriefing(false, time_survived, kills, lvl)

func _on_mission_victory(time_survived: float, kills: int, lvl: int) -> void:
	show_debriefing(true, time_survived, kills, lvl)

func show_debriefing(is_victory: bool, time_survived: float, kills: int, lvl: int) -> void:
	get_tree().paused = true
	visible = true
	
	var total_sec := int(time_survived)
	var mins := floori(float(total_sec) / 60.0)
	var secs := total_sec % 60
	
	var eval := GameState.calculate_mission_rank()
	var rank: String = eval["rank"]
	var total_nc: int = eval["total_nc"]
	var bonus_nc: int = eval["bonus_nc"]
	
	if title_label:
		if is_victory:
			title_label.text = "[ MISI SELESAI // SEKTOR DIBERSIHKAN ]"
			title_label.add_theme_color_override("font_color", Color(0.2, 0.9, 1.0))
		else:
			title_label.text = "[ CRITICAL OVERHEAT // REAKTOR MELTDOWN ]"
			title_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.35))
			
	var cfg = GameState.stage_configs.get(GameState.current_stage, GameState.stage_configs[1])
	
	if stats_label:
		stats_label.text = """[ LAPORAN DEBRIEFING OPERASI SIBER ]

STATUS MISI        : %s
SEKTOR OPERASI     : STAGE %02d // %s
EVALUASI RANK      : RANK [ %s ]

HERO OPERATIVE     : %s
SENJATA AKTIF      : %s

DURASI SURVIVAL    : %02d:%02d (TARGET: %02d:00)
ROBOT DIELIMINASI  : %d UNIT
LEVEL OVERCLOCK    : LVL %02d

HADIAH MISI        : +%d NANO-CREDITS (BONUS: +%d NC)
SALDO REKENING     : %d NANO-CREDITS
""" % [
			"BERHASIL // SEKTOR BEBAS" if is_victory else "GAGAL // REAKTOR HANCUR",
			GameState.current_stage, cfg["title"],
			rank,
			GameState.selected_hero.to_upper(),
			GameState.selected_weapon.to_upper(),
			mins, secs, int(cfg["target_time"] / 60.0),
			kills, lvl,
			total_nc, bonus_nc,
			SaveManager.nano_credits
		]

func _on_retry_pressed() -> void:
	get_tree().paused = false
	GameState.reset_run()
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	GameState.reset_run()
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
'''

with open("C:/Users/WA/Documents/OROS_MicroGame/scripts/ui/game_over_modal.gd", "w", encoding="utf-8") as f:
    f.write(content.strip())
print("Saved scripts/ui/game_over_modal.gd successfully!")
