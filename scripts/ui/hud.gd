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

@onready var tower_container: VBoxContainer = $TowerBarContainer
@onready var tower_hp_bar: ProgressBar = $TowerBarContainer/TowerHPBar
@onready var tower_name_label: Label = $TowerBarContainer/TowerNameLabel

# Skill & Inventory UI
@onready var skill_name_label: Label = $BottomLeftSkill/SkillHeader/SkillNameLabel
@onready var skill_lvl_badge: Label = $BottomLeftSkill/SkillHeader/SkillLvlBadge
@onready var skill_cd_bar: ProgressBar = $BottomLeftSkill/SkillCDBar

@onready var synergy_badge: Label = $BottomRightInventory/SynergyBadge
@onready var slot1_panel: PanelContainer = $BottomRightInventory/WeaponSlots/Slot1
@onready var slot2_panel: PanelContainer = $BottomRightInventory/WeaponSlots/Slot2
@onready var slot3_panel: PanelContainer = $BottomRightInventory/WeaponSlots/Slot3
@onready var slot1_label: Label = $BottomRightInventory/WeaponSlots/Slot1/Label
@onready var slot2_label: Label = $BottomRightInventory/WeaponSlots/Slot2/Label
@onready var slot3_label: Label = $BottomRightInventory/WeaponSlots/Slot3/Label

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
	GameState.tower_hp_changed.connect(_on_tower_hp_changed)

	GameState.weapon_swapped.connect(_on_weapon_swapped)
	GameState.skill_cooldown_updated.connect(_on_skill_cooldown)
	GameState.skill_upgraded.connect(_on_skill_upgraded)

	if GameState.has_tower_event and tower_container:
		tower_container.visible = true
		tower_hp_bar.max_value = GameState.tower_max_hp
		tower_hp_bar.value = GameState.tower_hp

	update_hearts(GameState.health, GameState.max_health)
	update_ammo(GameState.ammo, GameState.max_ammo, false, 0.0)
	update_xp(GameState.current_xp, GameState.xp_to_next, GameState.level)
	
	init_skill_ui()
	update_inventory_ui(GameState.active_weapon_index, GameState.is_native_synergy_active)

func init_skill_ui() -> void:
	var s_name := "CRYO DASH"
	if GameState.selected_hero == "vex": s_name = "PHASE BLINK"
	elif GameState.selected_hero == "brutus": s_name = "SEISMIC SLAM"
	
	if skill_name_label:
		skill_name_label.text = "[ SPACE/E: %s ]" % s_name
	if skill_lvl_badge:
		skill_lvl_badge.text = "[ LVL %02d ]" % GameState.skill_level
	if skill_cd_bar:
		skill_cd_bar.max_value = GameState.skill_cooldown_max
		skill_cd_bar.value = 0.0

func _on_skill_cooldown(cur_cd: float, max_cd: float) -> void:
	if skill_cd_bar:
		skill_cd_bar.max_value = max_cd
		skill_cd_bar.value = maxf(0.0, max_cd - cur_cd)
	if skill_name_label:
		var s_name := "CRYO DASH"
		if GameState.selected_hero == "vex": s_name = "PHASE BLINK"
		elif GameState.selected_hero == "brutus": s_name = "SEISMIC SLAM"
		
		if cur_cd <= 0.05:
			skill_name_label.text = "[ SPACE/E: %s READY ]" % s_name
			skill_name_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
		else:
			skill_name_label.text = "[ %s CD: %.1fS ]" % [s_name, cur_cd]
			skill_name_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))

func _on_skill_upgraded(new_lvl: int) -> void:
	if skill_lvl_badge:
		skill_lvl_badge.text = "[ LVL %02d UPGRADED! ]" % new_lvl
		skill_lvl_badge.pivot_offset = skill_lvl_badge.size * 0.5
		var tw := skill_lvl_badge.create_tween()
		tw.tween_property(skill_lvl_badge, "scale", Vector2(1.3, 1.3), 0.15)
		tw.tween_property(skill_lvl_badge, "scale", Vector2.ONE, 0.2)
		tw.tween_callback(func():
			skill_lvl_badge.text = "[ LVL %02d ]" % new_lvl
		)

func _on_weapon_swapped(_wep_id: String, slot_idx: int, is_syn: bool) -> void:
	update_inventory_ui(slot_idx, is_syn)

func update_inventory_ui(slot_idx: int, is_syn: bool) -> void:
	var panels = [slot1_panel, slot2_panel, slot3_panel]
	var labels = [slot1_label, slot2_label, slot3_label]
	
	for i in range(3):
		var p = panels[i]
		var l = labels[i]
		if not p or not l: continue
		
		var style := StyleBoxFlat.new()
		if i == slot_idx:
			# Active Weapon Highlight
			style.bg_color = Color(0.12, 0.22, 0.35, 0.95)
			style.border_color = Color(1.0, 0.85, 0.25, 1.0)
			style.set_border_width_all(3)
			style.set_corner_radius_all(4)
			p.add_theme_stylebox_override("panel", style)
			l.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		else:
			# Inactive Slot
			style.bg_color = Color(0.04, 0.06, 0.1, 0.8)
			style.border_color = Color(0.2, 0.3, 0.45, 0.5)
			style.set_border_width_all(1)
			style.set_corner_radius_all(4)
			p.add_theme_stylebox_override("panel", style)
			l.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))

	if synergy_badge:
		if is_syn:
			synergy_badge.visible = true
			var syn_text = "+25% DMG"
			if GameState.selected_hero == "vex": syn_text = "+25% LAJU TEMBAK"
			elif GameState.selected_hero == "brutus": syn_text = "+3 PELLET & +20% KNOCKBACK"
			synergy_badge.text = "[ NATIVE SYNERGY BUFF AKTIF: %s ]" % syn_text
			synergy_badge.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		else:
			synergy_badge.visible = true
			synergy_badge.text = "[ NON-NATIVE: BUFF SENJATA PASIF NONAKTIF ]"
			synergy_badge.add_theme_color_override("font_color", Color(0.8, 0.55, 0.3))

func _on_tower_hp_changed(cur: int, max_hp: int) -> void:
	if tower_container:
		tower_container.visible = true
	if tower_hp_bar:
		tower_hp_bar.max_value = max_hp
		tower_hp_bar.value = cur
	if tower_name_label:
		tower_name_label.text = "[ ! ] POWER CORE TOWER: %d / %d [ ! ]" % [cur, max_hp]

func _on_boss_spawned(b_name: String, max_hp: int) -> void:
	if boss_container:
		boss_container.visible = true
	if boss_name_label:
		boss_name_label.text = "[ ! ] BOSS: %s [ ! ]" % b_name
	if boss_hp_bar:
		boss_hp_bar.max_value = max_hp
		boss_hp_bar.value = max_hp

func _on_boss_hp_changed(cur_hp: int, _max_hp: int) -> void:
	if boss_hp_bar:
		boss_hp_bar.value = cur_hp

func _on_boss_defeated() -> void:
	if boss_name_label:
		boss_name_label.text = "[ BOSS ANNIHILATED // SEKTOR DIBERSIHKAN ]"
	var tw := create_tween()
	tw.tween_interval(3.0)
	tw.tween_callback(func():
		if boss_container:
			boss_container.visible = false
	)

func _process(_delta: float) -> void:
	var total_sec := int(GameState.survival_time)
	var mins := floori(float(total_sec) / 60.0)
	var secs := total_sec % 60
	if timer_label:
		timer_label.text = "%02d:%02d" % [mins, secs]
	if kills_label:
		kills_label.text = "PURGED: %d UNITS" % GameState.total_kills

	if low_hp_vignette:
		if GameState.health == 1:
			low_hp_vignette.visible = true
			var pulse := (sin(Time.get_ticks_msec() * 0.007) + 1.0) * 0.5
			low_hp_vignette.modulate.a = 0.12 + (pulse * 0.16)
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

	if max_hp <= 5:
		for i in range(max_hp):
			var rect := TextureRect.new()
			rect.texture = heart_full_tex if (i < current) else heart_empty_tex
			rect.custom_minimum_size = Vector2(40, 40)
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hearts_container.add_child(rect)
	else:
		for i in range(5):
			var rect := TextureRect.new()
			var fill_point := int(float(i + 1) / 5.0 * float(max_hp))
			rect.texture = heart_full_tex if (current >= fill_point) else heart_empty_tex
			rect.custom_minimum_size = Vector2(40, 40)
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hearts_container.add_child(rect)
			
		var extra_lbl := Label.new()
		extra_lbl.text = " [+%d] (%d/%d)" % [max_hp - 5, current, max_hp]
		extra_lbl.add_theme_font_override("font", load("res://assets/fonts/tech_font.ttf"))
		extra_lbl.add_theme_font_size_override("font_size", 16)
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
			reload_label.text = "RELOAD %s %d%%" % [bar_str, int(reload_pct * 100)]
	else:
		if reload_label:
			reload_label.visible = false
		ammo_container.visible = true
		
		for child in ammo_container.get_children():
			child.queue_free()
			
		for i in range(max_cap):
			var rect := TextureRect.new()
			rect.texture = bullet_icon_tex
			rect.custom_minimum_size = Vector2(16, 34)
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			rect.modulate = Color(1, 1, 1, 1) if (i < current) else Color(0.3, 0.35, 0.45, 0.4)
			ammo_container.add_child(rect)

func update_xp(current: int, needed: int, lvl: int) -> void:
	if xp_bar:
		xp_bar.max_value = needed
		var tw := xp_bar.create_tween()
		tw.tween_property(xp_bar, "value", float(current), 0.15)
		
	if level_label:
		var old_text = level_label.text
		var new_text = "[ LVL %02d ]" % lvl
		if old_text != new_text:
			level_label.text = new_text
			level_label.pivot_offset = level_label.size * 0.5
			var pop_tw := level_label.create_tween()
			pop_tw.tween_property(level_label, "scale", Vector2(1.35, 1.35), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			pop_tw.tween_property(level_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)