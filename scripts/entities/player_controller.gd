extends CharacterBody2D

@export var move_speed: float = 180.0
@export var acceleration: float = 1200.0
@export var friction: float = 1400.0

@export var projectile_scene: PackedScene

@onready var body_sprite: Sprite2D = $BodySprite
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var muzzle: Marker2D = $WeaponPivot/Muzzle
@onready var sfx_shoot: AudioStreamPlayer2D = $SFXShoot

var can_shoot: bool = true
var shoot_cooldown: float = 0.2
var cooldown_timer: float = 0.0

# Animation timer
var anim_timer: float = 0.0
var walk_frame: int = 0

func _ready() -> void:
	add_to_group("player")
	if not projectile_scene:
		projectile_scene = load("res://scenes/entities/Projectile.tscn")

func _process(delta: float) -> void:
	# Rotate weapon towards mouse
	var mouse_pos := get_global_mouse_position()
	weapon_pivot.look_at(mouse_pos)
	
	# Flip player sprite based on mouse direction
	if mouse_pos.x < global_position.x:
		body_sprite.flip_h = true
		weapon_pivot.scale.y = -1.0
	else:
		body_sprite.flip_h = false
		weapon_pivot.scale.y = 1.0

	# Handle shooting
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
		
	if Input.is_action_pressed("primary_attack") and cooldown_timer <= 0.0:
		shoot()

	# Handle walking animation frames
	if velocity.length() > 10.0:
		anim_timer += delta * 10.0
		walk_frame = int(anim_timer) % 4
		body_sprite.frame = walk_frame
	else:
		body_sprite.frame = 0
		anim_timer = 0.0

func _physics_process(delta: float) -> void:
	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_axis("move_left", "move_right")
	input_vector.y = Input.get_axis("move_up", "move_down")
	input_vector = input_vector.normalized()

	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * move_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()

func shoot() -> void:
	cooldown_timer = shoot_cooldown
	if projectile_scene:
		var proj = projectile_scene.instantiate()
		proj.global_position = muzzle.global_position
		proj.direction = (get_global_mouse_position() - muzzle.global_position).normalized()
		proj.rotation = proj.direction.angle()
		get_parent().add_child(proj)
		
	if sfx_shoot:
		sfx_shoot.play()
