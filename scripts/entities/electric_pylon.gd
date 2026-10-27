extends StaticBody2D

@export var max_charge: int = 50
var current_charge: int = 0
var is_discharging: bool = false

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("environment")

func take_damage(amount: int, _knockback: Vector2 = Vector2.ZERO, _from_melee: bool = false) -> void:
	if is_discharging: return
	current_charge += amount
	
	# Pylon Charge Glitch Tween
	if sprite:
		sprite.modulate = Color(2.5, 2.2, 0.4, 1.0) # Yellow energy pulse
		var tw := create_tween()
		tw.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.1)
		
	if current_charge >= max_charge:
		discharge_emp()

func discharge_emp() -> void:
	is_discharging = true
	current_charge = 0
	
	# Discharge Sound & Shockwave
	var sfx = AudioStreamPlayer2D.new()
	sfx.stream = load("res://assets/audio/sfx_skill_freeze.wav")
	add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
	
	# Visual Shockwave Ring
	if sprite:
		var flash_tw := create_tween()
		flash_tw.tween_property(sprite, "modulate", Color(0, 3.0, 3.0, 1.0), 0.15)
		flash_tw.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.25)
		
	# Zap all nearby enemies in 260px radius
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and global_position.distance_to(e.global_position) < 260.0:
			var to_e = (e.global_position - global_position).normalized()
			if e.has_method("take_damage"):
				e.take_damage(35, to_e * 200.0, false)
			if e.has_method("apply_freeze"):
				e.apply_freeze(0.3, 2.5)
				
	var cd_tw := create_tween()
	cd_tw.tween_interval(4.0) # 4s recharge cooldown
	cd_tw.tween_callback(func(): is_discharging = false)
