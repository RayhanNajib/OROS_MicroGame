extends Node2D

@export var radius: float = 117.0 # Nerfed by 55% (was 260.0)
@export var duration: float = 2.0
@export var tick_damage: int = 6 # Nerfed by 55% (was 14)
@export var final_damage: int = 22 # Nerfed by 55% (was 50)

@onready var vortex_sprite: Sprite2D = $VortexSprite

var elapsed: float = 0.0
var tick_timer: float = 0.0
var rot_angle: float = 0.0

func _ready() -> void:
	# Spawn scale pop
	scale = Vector2(0.2, 0.2)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	elapsed += delta
	rot_angle += delta * 6.0
	tick_timer += delta
	
	if vortex_sprite:
		vortex_sprite.rotation = rot_angle
		var pulse := 2.2 + sin(elapsed * 12.0) * 0.15
		vortex_sprite.scale = Vector2(pulse, pulse)
	
	queue_redraw()
	
	# Gravitational Suction on enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e):
			var to_center = global_position - e.global_position
			var dist = to_center.length()
			if dist <= radius and dist > 8.0:
				var pull_dir = to_center.normalized()
				var strength = (1.0 - (dist / radius)) * 320.0
				e.global_position += pull_dir * strength * delta
				
	# Periodic Ticking Damage
	if tick_timer >= 0.3:
		tick_timer = 0.0
		for e in enemies:
			if is_instance_valid(e) and global_position.distance_to(e.global_position) <= radius:
				if e.has_method("take_damage"):
					e.take_damage(tick_damage, Vector2.ZERO, false)
					
	# Final Implosion Collapse
	if elapsed >= duration:
		explode_and_finish(enemies)

func explode_and_finish(enemies: Array) -> void:
	set_process(false)
	for e in enemies:
		if is_instance_valid(e) and global_position.distance_to(e.global_position) <= radius:
			var to_e = (e.global_position - global_position).normalized()
			if e.has_method("take_damage"):
				e.take_damage(final_damage, to_e * 280.0, false)
				
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.6, 1.6), 0.15)
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(queue_free)

func _draw() -> void:
	# 1. Outer Gravitational Accretion Disc (Rotating Plasma Spirals)
	for ring_r in [radius, radius * 0.75, radius * 0.5]:
		draw_arc(Vector2.ZERO, ring_r, rot_angle, rot_angle + PI * 1.5, 32, Color(0.71, 0.2, 1.0, 0.4), 2.0)
		draw_arc(Vector2.ZERO, ring_r * 0.9, -rot_angle, -rot_angle + PI * 1.2, 24, Color(1.0, 0.24, 0.66, 0.3), 1.5)
		
	# 2. Inflowing Plasma Streams
	for i in range(6):
		var a = rot_angle + (TAU / 6.0) * i
		var p1 = Vector2(cos(a), sin(a)) * radius * 0.85
		var p2 = Vector2(cos(a + 0.6), sin(a + 0.6)) * 20.0
		draw_line(p1, p2, Color(0.85, 0.4, 1.0, 0.6), 2.0)
		
	# 3. Glowing Event Horizon Core
	draw_circle(Vector2.ZERO, 32.0, Color(0.12, 0.04, 0.22, 0.9))
	draw_circle(Vector2.ZERO, 18.0, Color(0.8, 0.1, 0.9, 0.8))
	draw_circle(Vector2.ZERO, 8.0, Color(1.0, 1.0, 1.0, 1.0))
