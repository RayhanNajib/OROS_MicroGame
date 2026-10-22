extends CanvasLayer

@onready var stats_label: Label = $CenterContainer/PanelContainer/Margin/VBox/StatsLabel
@onready var retry_btn: Button = $CenterContainer/PanelContainer/Margin/VBox/HBoxBtns/RetryBtn
@onready var menu_btn: Button = $CenterContainer/PanelContainer/Margin/VBox/HBoxBtns/MenuBtn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	GameState.game_over_triggered.connect(_on_game_over)
	
	if retry_btn:
		retry_btn.pivot_offset = Vector2(60, 16)
		retry_btn.pressed.connect(_on_retry_pressed)
		retry_btn.mouse_entered.connect(func():
			var tw := retry_btn.create_tween()
			tw.tween_property(retry_btn, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		)
		retry_btn.mouse_exited.connect(func():
			var tw := retry_btn.create_tween()
			tw.tween_property(retry_btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		)
		
	if menu_btn:
		menu_btn.pivot_offset = Vector2(60, 16)
		menu_btn.pressed.connect(_on_menu_pressed)
		menu_btn.mouse_entered.connect(func():
			var tw := menu_btn.create_tween()
			tw.tween_property(menu_btn, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
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
	get_tree().paused = true
	visible = true
	
	var total_sec := int(time_survived)
	var mins := floori(float(total_sec) / 60.0)
	var secs := total_sec % 60
	
	var rank := "CADET OPERATIVE [ C ]"
	if time_survived >= 180.0 or kills >= 100:
		rank = "OVERCLOCKED MASTER [ S ]"
	elif time_survived >= 120.0 or kills >= 60:
		rank = "VETERAN SURVIVOR [ A ]"
	elif time_survived >= 60.0 or kills >= 25:
		rank = "COMBAT OPERATIVE [ B ]"
	
	if stats_label:
		stats_label.text = """[ COMBAT EVALUATION // MISSION TERMINATED ]

TACTICAL RANK      : %s
OPERATIVE PROFILE  : %s
ACTIVE ARSENAL     : %s

SURVIVAL DURATION  : %02d:%02d
AUTOMATONS PURGED  : %d UNITS
OVERCLOCK LEVEL    : LVL %02d
""" % [rank, GameState.selected_hero.to_upper(), GameState.selected_weapon.to_upper(), mins, secs, kills, lvl]

func _on_retry_pressed() -> void:
	get_tree().paused = false
	GameState.reset_run()
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	GameState.reset_run()
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
