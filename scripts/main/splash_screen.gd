extends Control

@onready var logo_rect: TextureRect = $Center/VBox/LogoRect
@onready var subtitle: Label = $Center/VBox/Subtitle
@onready var jingle_player: AudioStreamPlayer = $JinglePlayer

var has_transitioned: bool = false

func _ready() -> void:
	logo_rect.scale = Vector2(0.6, 0.6)
	logo_rect.pivot_offset = Vector2(250, 55)
	logo_rect.modulate.a = 0.0
	subtitle.modulate.a = 0.0
	
	if jingle_player:
		jingle_player.play()
		
	# Cinematic Intro Animation Sequence
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(logo_rect, "modulate:a", 1.0, 0.8)
	tw.tween_property(logo_rect, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(subtitle, "modulate:a", 1.0, 0.6).set_delay(0.5)
	
	tw.chain().tween_interval(1.4)
	tw.chain().tween_callback(transition_to_menu)

func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		if event.is_pressed() and not has_transitioned:
			transition_to_menu()

func transition_to_menu() -> void:
	if has_transitioned: return
	has_transitioned = true
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.4)
	fade.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
	)
