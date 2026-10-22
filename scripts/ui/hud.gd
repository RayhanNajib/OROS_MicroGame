extends CanvasLayer

@onready var hearts_container: HBoxContainer = $TopLeft/HeartsContainer
@onready var ammo_container: HBoxContainer = $TopLeft/AmmoContainer
@onready var reload_label: Label = $TopLeft/ReloadLabel

@onready var xp_bar: ProgressBar = $TopCenter/XPBar
@onready var level_label: Label = $TopCenter/LevelLabel

@onready var timer_label: Label = $TopRight/TimerLabel
@onready var kills_label: Label = $TopRight/KillsLabel

@onready var boss_container: VBoxContainer = $BossBarContainer
@onready var boss_name_label: Label = $BossBarContainer/BossNameLabel
@onready var boss_hp_bar: ProgressBar = $BossBarContainer/BossHPBar
@onready var low_hp_vignette: TextureRect = $LowHPVignette

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

	GameState.boss_spawned.connect(_on_boss_spawned)
	GameState.boss_hp_changed.connect(_on_boss_hp_changed)
	GameState.boss_defeated.connect(_on_boss_defeated)

	update_hearts(GameState.health, GameState.max_health)
	update_ammo(GameState.ammo, GameState.max_ammo, false, 0.0)
	update_xp(GameState.current_xp, GameState.xp_to_next, GameState.level)

func _on_boss_spawned(b_name: String, max_hp: int) -> void:
	if boss_container:
		boss_container.visible = true
	if boss_name_label:
		boss_name_label.text = "★ BOSS: %s ★" % b_name
	if boss_hp_bar:
		boss_hp_bar.max_value = max_hp
		boss_hp_bar.value = max_hp

func _on_boss_hp_changed(cur_hp: int, _max_hp: int) -> void:
	if boss_hp_bar:
		boss_hp_bar.value = cur_hp

func _on_boss_defeated() -> void:
	if boss_name_label:
		boss_name_label.text = "★ BOSS ANNIHILATED // SECTOR LIBERATED ★"
	var tw := create_tween()
	tw.tween_interval(3.0)
	tw.tween_callback(func():
		if boss_container:
			boss_container.visible = false
	)

func _process(_delta: float) -> void:
	# Update Timer
	var total_sec := int(GameState.survival_time)
	var mins := floori(float(total_sec) / 60.0)
	var secs := total_sec % 60
	if timer_label:
		timer_label.text = "%02d:%02d" % [mins, secs]
	if kills_label:
		kills_label.text = "PURGED: %d" % GameState.total_kills

	# Low HP Vignette Warning Pulse (HP <= 2)
	if low_hp_vignette:
		if GameState.health <= 2 and GameState.health > 0:
			low_hp_vignette.visible = true
			var speed := 0.009 if GameState.health == 1 else 0.005
			var pulse := (sin(Time.get_ticks_msec() * speed) + 1.0) * 0.5
			low_hp_vignette.modulate.a = 0.3 + (pulse * (0.55 if GameState.health == 1 else 0.35))
		else:
			low_hp_vignette.visible = false

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

	# Compact 5+ Health Rule
	if max_hp <= 5:
		for i in range(max_hp):
			var rect := TextureRect.new()
			rect.texture = heart_full_tex if (i < current) else heart_empty_tex
			rect.custom_minimum_size = Vector2(26, 26)
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hearts_container.add_child(rect)
	else:
		# Show 5 hearts scaled to proportion + Badge [+N] (Current/Max)
		for i in range(5):
			var rect := TextureRect.new()
			var fill_point := int(float(i + 1) / 5.0 * float(max_hp))
			rect.texture = heart_full_tex if (current >= fill_point) else heart_empty_tex
			rect.custom_minimum_size = Vector2(26, 26)
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hearts_container.add_child(rect)
			
		var extra_lbl := Label.new()
		extra_lbl.text = " [+%d] (%d/%d)" % [max_hp - 5, current, max_hp]
		extra_lbl.add_theme_font_override("font", load("res://assets/fonts/PressStart2P-Regular.ttf"))
		extra_lbl.add_theme_font_size_override("font_size", 9)
		extra_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		extra_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hearts_container.add_child(extra_lbl)

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
