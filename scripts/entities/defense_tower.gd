extends StaticBody2D

@export var max_hp: int = 500
var current_hp: int = 500

@onready var sprite: Sprite2D = $Sprite2D
@onready var hp_bar: ProgressBar = $HPBar

func _ready() -> void:
	add_to_group("defense_tower")
	current_hp = max_hp
	GameState.tower_max_hp = max_hp
	GameState.tower_hp = max_hp
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp

func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)
	GameState.damage_tower(amount)
	if hp_bar:
		hp_bar.value = current_hp
		
	# Damage Flash
	modulate = Color(2.5, 0.4, 0.4, 1.0)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.12)
	
	# Spawn damage popup
	var popup_scene = load("res://scenes/entities/DamagePopup.tscn")
	if popup_scene:
		var popup = popup_scene.instantiate()
		popup.global_position = global_position + Vector2(0, -50)
		popup.setup(amount, true)
		get_parent().add_child(popup)
		
	if current_hp <= 0:
		queue_free()
