extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 580.0
var damage: int = 20
var pierce: int = 0
var knockback: float = 90.0
var has_freeze: bool = false
var has_lightning: bool = false

var enemies_hit: Array[Node2D] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# Despawn timer
	var timer := get_tree().create_timer(2.2)
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
		enemy.apply_freeze(0.5, 2.0)
		
	# Apply Chain Lightning Synergy
	if has_lightning:
		chain_lightning(enemy)
		
	if pierce > 0:
		pierce -= 1
	else:
		queue_free()

func chain_lightning(target: Node2D) -> void:
	var tree := get_tree()
	if not tree: return
	var all_enemies = tree.get_nodes_in_group("enemies")
	var zapped := 0
	for other in all_enemies:
		if other != target and is_instance_valid(other):
			var dist = target.global_position.distance_to(other.global_position)
			if dist < 120.0:
				if other.has_method("take_damage"):
					other.take_damage(int(damage * 0.75), Vector2.ZERO)
				zapped += 1
				if zapped >= 2:
					break
