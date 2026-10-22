extends Area2D

signal pod_activated(member_info: Dictionary)

@export var member_id: String = "najib"
@export var member_name: String = "Muhammad Rayhan Najib"
@export var member_nim: String = "240533600012"
@export var member_role: String = "Lead Programmer & Engine Integrator"
@export var member_desc: String = "Arsitektur Godot 4.7, GDScript static typing, sistem fisika & integrasi sistem kolaboratif."
@export var activation_type: String = "shoot" # "shoot", "step", "interact"
@export var avatar_texture: Texture2D

@export var texture_inactive: Texture2D
@export var texture_active: Texture2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt_label: Label = $PromptLabel
@onready var sfx_activate: AudioStreamPlayer2D = $SFXActivate
@onready var sfx_step: AudioStreamPlayer2D = $SFXStep

var is_activated: bool = false
var player_in_range: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if prompt_label:
		prompt_label.visible = false
		update_prompt_text()
		
	if texture_inactive:
		sprite.texture = texture_inactive

func update_prompt_text() -> void:
	if not prompt_label: return
	match activation_type:
		"shoot":
			prompt_label.text = "[TEMBAK SASARAN]"
			prompt_label.modulate = Color(0.0, 0.9, 1.0)
		"step":
			prompt_label.text = "[INJAK PLATFORM]"
			prompt_label.modulate = Color(0.8, 0.3, 1.0)
		"interact":
			prompt_label.text = "[TEKAN E]"
			prompt_label.modulate = Color(0.2, 0.95, 0.5)

func _process(_delta: float) -> void:
	if is_activated:
		return
		
	if activation_type == "interact" and player_in_range:
		if Input.is_action_just_pressed("interact"):
			activate()

func on_hit(_projectile: Node2D) -> void:
	if is_activated: return
	if activation_type == "shoot":
		activate()

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	player_in_range = true
	
	if not is_activated:
		if prompt_label:
			prompt_label.visible = true
		if activation_type == "step":
			if sfx_step: sfx_step.play()
			activate()

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	player_in_range = false
	if prompt_label:
		prompt_label.visible = false

func activate() -> void:
	if is_activated: return
	is_activated = true
	
	if texture_active:
		sprite.texture = texture_active
		
	if sfx_activate:
		sfx_activate.play()
		
	if prompt_label:
		prompt_label.text = "ONLINE"
		prompt_label.modulate = Color(0.2, 1.0, 0.4)
		prompt_label.visible = true
		
	var info := {
		"id": member_id,
		"name": member_name,
		"nim": member_nim,
		"role": member_role,
		"desc": member_desc,
		"avatar": avatar_texture
	}
	
	emit_signal("pod_activated", info)
