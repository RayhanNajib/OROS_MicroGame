extends Area2D

@export var speed: float = 480.0
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Auto despawn after 2 seconds
	var timer := get_tree().create_timer(2.0)
	timer.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("on_hit"):
		body.on_hit(self)
		queue_free()
	elif not body.is_in_group("player"):
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("on_hit"):
		area.on_hit(self)
		queue_free()
