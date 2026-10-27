extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 580.0
var damage: int = 20
var pierce: int = 0
var knockback: float = 90.0
var has_freeze: bool = false
var has_lightning: bool = false
var has_explosive_rounds: bool = false
var lifespan: float = 2.0
var bullet_tex: Texture2D = null
var is_beam: bool = false

var enemies_hit: Array[Node2D] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	if bullet_tex and has_node("Sprite2D"):
		get_node("Sprite2D").texture = bullet_tex
		
	if is_beam and has_node("CollisionShape2D"):
		get_node("CollisionShape2D").scale = Vector2(5.5, 1.2)
	
	# Despawn timer
	var timer := get_tree().create_timer(lifespan)
	timer.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		hit_enemy(body)
	elif not body.is_in_group("player") and not body.is_in_group("loot"):
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		hit_enemy(area)

func hit_enemy(enemy: Node2D) -> void:
	if enemies_hit.has(enemy):
		return
	enemies_hit.append(enemy)
	
	var kb_vec := direction * knockback
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage, kb_vec)
		
	# Apply Freeze Synergy
	if has_freeze and enemy.has_method("apply_freeze"):
		enemy.apply_freeze(0.5, 2.5)
		
	# Apply Chain Lightning Synergy
	if has_lightning:
		chain_lightning(enemy)

	# Apply Explosive Rounds Synergy
	if has_explosive_rounds:
		trigger_plasma_explosion()
		
	if pierce > 0:
		pierce -= 1
	else:
		queue_free()

func trigger_plasma_explosion() -> void:
	var tree := get_tree()
	if not tree: return
	var blast_radius: float = 45.0
	var splash_damage: int = maxi(1, int(damage * 0.6))
	var all_enemies = tree.get_nodes_in_group("enemies")
	for other in all_enemies:
		if is_instance_valid(other) and not enemies_hit.has(other):
			if global_position.distance_to(other.global_position) <= blast_radius:
				enemies_hit.append(other)
				var kb_dir = (other.global_position - global_position).normalized()
				if other.has_method("take_damage"):
					other.take_damage(splash_damage, kb_dir * 120.0)
				if has_freeze and other.has_method("apply_freeze"):
					other.apply_freeze(0.5, 2.5)
	var circle := Line2D.new()
	circle.width = 3.0
	circle.default_color = Color(1.0, 0.45, 0.15, 0.9)
	var pts := PackedVector2Array()
	var segments := 12
	for i in range(segments + 1):
		var a := (TAU / float(segments)) * float(i)
		pts.append(Vector2(cos(a), sin(a)) * blast_radius)
	circle.points = pts
	circle.global_position = global_position
	get_parent().add_child(circle)
	var tw := circle.create_tween()
	tw.set_parallel(true)
	tw.tween_property(circle, "scale", Vector2(1.3, 1.3), 0.15)
	tw.tween_property(circle, "modulate:a", 0.0, 0.15)
	tw.chain().tween_callback(circle.queue_free)

func chain_lightning(target: Node2D) -> void:
	var tree := get_tree()
	if not tree: return
	var all_enemies = tree.get_nodes_in_group("enemies")
	var zapped := 0
	var max_zaps: int = 4 if GameState.has_random_lightning else 2
	var dmg_mult: float = 2.0 if GameState.has_random_lightning else 1.0
	for other in all_enemies:
		if other != target and is_instance_valid(other):
			var dist = target.global_position.distance_to(other.global_position)
			if dist < 120.0:
				if other.has_method("take_damage"):
					other.take_damage(int(damage * 0.75 * dmg_mult), Vector2.ZERO)
				zapped += 1
				if zapped >= max_zaps:
					break
