extends Node2D

@onready var pod_najib: Area2D = $Entities/PodNajib
@onready var pod_luigy: Area2D = $Entities/PodLuigy
@onready var pod_faizun: Area2D = $Entities/PodFaizun
@onready var blast_gate: Sprite2D = $Environment/BlastGate
@onready var hud: CanvasLayer = $HUD
@onready var bgm_player: AudioStreamPlayer = $BGMPlayer
@onready var sfx_victory: AudioStreamPlayer = $SFXVictory

var activated_pods: Array[String] = []
var gate_opened: bool = false

func _ready() -> void:
	if pod_najib: pod_najib.pod_activated.connect(_on_pod_activated)
	if pod_luigy: pod_luigy.pod_activated.connect(_on_pod_activated)
	if pod_faizun: pod_faizun.pod_activated.connect(_on_pod_activated)
	
	if bgm_player:
		bgm_player.play()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()

func _on_pod_activated(info: Dictionary) -> void:
	var mid: String = info.get("id", "")
	if not activated_pods.has(mid):
		activated_pods.append(mid)
		
	if hud:
		hud.show_member_popup(info)
		
	# Check if all 3 are activated
	if activated_pods.size() >= 3 and not gate_opened:
		gate_opened = true
		open_blast_gate()

func open_blast_gate() -> void:
	var gate_open_tex := load("res://assets/sprites/blast_gate_open.png")
	if gate_open_tex and blast_gate:
		blast_gate.texture = gate_open_tex
		
	if sfx_victory:
		sfx_victory.play()
		
	# Wait brief moment for dramatic effect, then show victory overlay
	var timer := get_tree().create_timer(1.2)
	timer.timeout.connect(func():
		if hud:
			hud.show_victory_screen()
	)
