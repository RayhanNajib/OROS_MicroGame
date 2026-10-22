extends CanvasLayer

@onready var stats_label: Label = $CenterContainer/PanelContainer/Margin/VBox/StatsLabel
@onready var retry_btn: Button = $CenterContainer/PanelContainer/Margin/VBox/HBoxBtns/RetryBtn
@onready var menu_btn: Button = $CenterContainer/PanelContainer/Margin/VBox/HBoxBtns/MenuBtn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	GameState.game_over_triggered.connect(_on_game_over)
	
	if retry_btn:
		retry_btn.pressed.connect(_on_retry_pressed)
	if menu_btn:
		menu_btn.pressed.connect(_on_menu_pressed)

func _process(_delta: float) -> void:
	if visible and Input.is_action_just_pressed("restart"):
		_on_retry_pressed()

func _on_game_over(time_survived: float, kills: int, lvl: int) -> void:
	get_tree().paused = true
	visible = true
	
	var total_sec := int(time_survived)
	var mins := total_sec / 60
	var secs := total_sec % 60
	
	if stats_label:
		stats_label.text = "TIME SURVIVED: %02d:%02d\nENEMIES ELIMINATED: %d\nLEVEL REACHED: %d" % [mins, secs, kills, lvl]

func _on_retry_pressed() -> void:
	get_tree().paused = false
	GameState.reset_run()
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	GameState.reset_run()
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
