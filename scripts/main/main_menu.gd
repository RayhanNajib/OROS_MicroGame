extends Control

@onready var start_btn: Button = $VBoxCenter/StartBtn
@onready var sfx_click: AudioStreamPlayer = $SFXClick

func _ready() -> void:
	if start_btn:
		start_btn.pressed.connect(_on_start_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("primary_attack") or event.is_action_pressed("interact"):
		_on_start_pressed()

func _on_start_pressed() -> void:
	if sfx_click:
		sfx_click.play()
	GameState.reset_run()
	get_tree().change_scene_to_file("res://scenes/main/GameArena.tscn")
