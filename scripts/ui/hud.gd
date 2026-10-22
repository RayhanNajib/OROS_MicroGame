extends CanvasLayer

@onready var hearts_container: HBoxContainer = $TopLeft/HeartsContainer
@onready var ammo_container: HBoxContainer = $TopLeft/AmmoContainer
@onready var reload_label: Label = $TopLeft/ReloadLabel

@onready var xp_bar: ProgressBar = $TopCenter/XPBar
@onready var level_label: Label = $TopCenter/LevelLabel

@onready var timer_label: Label = $TopRight/TimerLabel
@onready var kills_label: Label = $TopRight/KillsLabel

var heart_full_tex: Texture2D
var heart_empty_tex: Texture2D
var bullet_icon_tex: Texture2D

func _ready() -> void:
	heart_full_tex = load("res://assets/sprites/ui_heart_full.png")
	heart_empty_tex = load("res://assets/sprites/ui_heart_empty.png")
	bullet_icon_tex = load("res://assets/sprites/ui_bullet_icon.png")

	GameState.health_changed.connect(_on_health_changed)
	GameState.ammo_changed.connect(_on_ammo_changed)
	GameState.xp_changed.connect(_on_xp_changed)

	update_hearts(GameState.health, GameState.max_health)
	update_ammo(GameState.ammo, GameState.max_ammo, false, 0.0)
	update_xp(GameState.current_xp, GameState.xp_to_next, GameState.level)

func _process(_delta: float) -> void:
	# Update Timer
	var total_sec := int(GameState.survival_time)
	var mins := total_sec / 60
	var secs := total_sec % 60
	if timer_label:
		timer_label.text = "%02d:%02d" % [mins, secs]
	if kills_label:
		kills_label.text = "KILL: %d" % GameState.total_kills

func _on_health_changed(current: int, max_hp: int) -> void:
	update_hearts(current, max_hp)

func _on_ammo_changed(current: int, max_cap: int, is_reloading: bool, reload_pct: float) -> void:
	update_ammo(current, max_cap, is_reloading, reload_pct)

func _on_xp_changed(current: int, needed: int, lvl: int) -> void:
	update_xp(current, needed, lvl)

func update_hearts(current: int, max_hp: int) -> void:
	if not hearts_container: return
	for child in hearts_container.get_children():
		child.queue_free()

	for i in range(max_hp):
		var rect := TextureRect.new()
		rect.texture = heart_full_tex if (i < current) else heart_empty_tex
		rect.custom_minimum_size = Vector2(20, 20)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hearts_container.add_child(rect)

func update_ammo(current: int, max_cap: int, is_reloading: bool, reload_pct: float) -> void:
	if not ammo_container: return
	
	if is_reloading:
		ammo_container.visible = false
		if reload_label:
			reload_label.visible = true
			var filled := int(reload_pct * 10)
			var bar_str := "[" + "=".repeat(filled) + "-".repeat(10 - filled) + "]"
			reload_label.text = "RELOADING %s %d%%" % [bar_str, int(reload_pct * 100)]
	else:
		if reload_label:
			reload_label.visible = false
		ammo_container.visible = true
		
		# Rebuild bullet icons
		for child in ammo_container.get_children():
			child.queue_free()
			
		for i in range(max_cap):
			var rect := TextureRect.new()
			rect.texture = bullet_icon_tex
			rect.custom_minimum_size = Vector2(10, 20)
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			rect.modulate = Color(1, 1, 1, 1) if (i < current) else Color(0.3, 0.35, 0.45, 0.4)
			ammo_container.add_child(rect)

func update_xp(current: int, needed: int, lvl: int) -> void:
	if xp_bar:
		xp_bar.max_value = needed
		xp_bar.value = current
	if level_label:
		level_label.text = "LVL %02d" % lvl
