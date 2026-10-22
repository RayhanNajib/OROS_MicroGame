extends Area2D

var direction: Vector2 = Vector2.DOWN
var speed: float = 240.0
var damage: int = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var timer := get_tree().create_timer(3.0)
	timer.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_hit"):
			body.take_hit(damage)
		queue_free()
	elif not body.is_in_group("enemies") and not body.is_in_group("loot"):
		queue_free()
