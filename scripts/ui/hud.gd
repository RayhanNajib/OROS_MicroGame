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
@onready var skill_icon_container: Control = $BottomLeftSkill/SkillRow/SkillIconContainer
@onready var skill_icon: TextureRect = $BottomLeftSkill/SkillRow/SkillIconContainer/SkillIcon
@onready var skill_cd_overlay: ColorRect = $BottomLeftSkill/SkillRow/SkillIconContainer/SkillCDOverlay
@onready var skill_cd_text: Label = $BottomLeftSkill/SkillRow/SkillIconContainer/SkillCDText
@onready var skill_status_label: Label = $BottomLeftSkill/SkillRow/SkillTextCol/SkillStatusLabel
@onready var skill_name_label: Label = $BottomLeftSkill/SkillRow/SkillTextCol/SkillHeader/SkillNameLabel
@onready var skill_lvl_badge: Label = $BottomLeftSkill/SkillRow/SkillTextCol/SkillHeader/SkillLvlBadge
@onready var prompt_icon: TextureRect = $BottomLeftSkill/SkillRow/SkillTextCol/SkillHeader/ControllerPromptIcon
@onready var controls_reminder: Label = $BottomLeftSkill/ControlsReminder
var was_skill_on_cd: bool = false

@onready var healing_rule_badge: Label = $BottomRightInventory/HealingRuleBadge
@onready var slot1_panel: PanelContainer = $BottomRightInventory/WeaponSlots/Slot1
@onready var slot2_panel: PanelContainer = $BottomRightInventory/WeaponSlots/Slot2
@onready var slot1_label: Label = $BottomRightInventory/WeaponSlots/Slot1/Label
@onready var slot2_label: Label = $BottomRightInventory/WeaponSlots/Slot2/Label

var heart_full_tex: Texture2D
var heart_empty_tex: Texture2D
var bullet_icon_tex: Texture2D

var p1_badge_lbl: Label
var p2_container: VBoxContainer
var p2_badge_lbl: Label
var p2_hearts_container: HBoxContainer
var p2_ammo_container: HBoxContainer
var p2_reload_label: Label

# Player 1 Co-op Weapon Switcher on BottomLeft
var p1_coop_weapon_slots: HBoxContainer
var p1_coop_slot1_panel: PanelContainer
var p1_coop_slot1_label: Label
var p1_coop_slot2_panel: PanelContainer
var p1_coop_slot2_label: Label

# Player 2 Bottom Panel (Skill + Weapon Switcher)
var p2_bottom_vbox: VBoxContainer
var p2_skill_icon_container: Control
var p2_skill_icon: TextureRect
var p2_skill_cd_overlay: ColorRect
var p2_skill_cd_text: Label
var p2_skill_name_label: Label
var p2_skill_lvl_badge: Label
var p2_skill_status_label: Label
var was_p2_skill_on_cd: bool = false

var p2_weapon_container: HBoxContainer
var p2_slot1_panel: PanelContainer
var p2_slot1_label: Label
var p2_slot2_panel: PanelContainer
var p2_slot2_label: Label
var p2_controls_reminder: Label

func _ready() -> void:
	heart_full_tex = load("res://assets/sprites/ui_heart_full.png")
	heart_empty_tex = load("res://assets/sprites/ui_heart_empty.png")
	bullet_icon_tex = load("res://assets/sprites/ui_bullet_icon.png")

	GameState.health_changed.connect(_on_health_changed)
	GameState.ammo_changed.connect(_on_ammo_changed)
	GameState.xp_changed.connect(_on_xp_changed)

	if GameState.has_signal("p1_health_changed"):
		GameState.p1_health_changed.connect(_on_p1_health_changed)
	if GameState.has_signal("p2_health_changed"):
		GameState.p2_health_changed.connect(_on_p2_health_changed)
	if GameState.has_signal("p1_ammo_changed"):
		GameState.p1_ammo_changed.connect(_on_p1_ammo_changed)
	if GameState.has_signal("p2_ammo_changed"):
		GameState.p2_ammo_changed.connect(_on_p2_ammo_changed)

	if GameState.has_signal("p1_weapon_slot_swapped"):
		GameState.p1_weapon_slot_swapped.connect(_on_weapon_slot_swapped)
	if GameState.has_signal("p2_weapon_slot_swapped"):
		GameState.p2_weapon_slot_swapped.connect(_on_p2_weapon_slot_swapped)
	if GameState.has_signal("p1_skill_cooldown_updated"):
		GameState.p1_skill_cooldown_updated.connect(_on_skill_cooldown)
	if GameState.has_signal("p2_skill_cooldown_updated"):
		GameState.p2_skill_cooldown_updated.connect(_on_p2_skill_cooldown)

	if GameState.is_coop_mode:
		setup_coop_hud()

	GameState.boss_spawned.connect(_on_boss_spawned)
	GameState.boss_hp_changed.connect(_on_boss_hp_changed)
	GameState.boss_defeated.connect(_on_boss_defeated)
	GameState.tower_hp_changed.connect(_on_tower_hp_changed)

	GameState.weapon_slot_swapped.connect(_on_weapon_slot_swapped)
	GameState.skill_cooldown_updated.connect(_on_skill_cooldown)
	GameState.skill_upgraded.connect(_on_skill_upgraded)

	if GameState.has_tower_event and tower_container:
		setup_tower_hud()
		_on_tower_hp_changed(GameState.tower_hp, GameState.tower_max_hp)

	# Apply Calibrated Sci-Fi Ruler Gauges
	if xp_bar:
		var sb_g = StyleBoxTexture.new(); sb_g.texture = load("res://assets/ui/bar_ruler_groove.png")
		var sb_f = StyleBoxTexture.new(); sb_f.texture = load("res://assets/ui/bar_ruler_xp_fill.png")
		xp_bar.add_theme_stylebox_override("background", sb_g)
		xp_bar.add_theme_stylebox_override("fill", sb_f)
		xp_bar.custom_minimum_size = Vector2(680, 22)
		
	if boss_hp_bar:
		var sb_bg = StyleBoxTexture.new(); sb_bg.texture = load("res://assets/ui/bar_ruler_groove.png")
		var sb_bf = StyleBoxTexture.new(); sb_bf.texture = load("res://assets/ui/bar_ruler_boss_fill.png")
		boss_hp_bar.add_theme_stylebox_override("background", sb_bg)
		boss_hp_bar.add_theme_stylebox_override("fill", sb_bf)
		boss_hp_bar.custom_minimum_size = Vector2(680, 22)

	update_hearts(GameState.health, GameState.max_health)
	update_ammo(GameState.ammo, GameState.max_ammo, false, 0.0)
	update_xp(GameState.current_xp, GameState.xp_to_next, GameState.level)
	
	if has_node("/root/InputManager"):
		var im = get_node("/root/InputManager")
		im.scheme_changed.connect(_on_input_scheme_changed)
		update_controls_prompt(im.p1_scheme)
		
	init_skill_ui()
	update_inventory_ui(GameState.equipped_slot, GameState.is_melee_active)

func _on_input_scheme_changed(player_idx: int, scheme: String) -> void:
	if player_idx == 1:
		update_controls_prompt(scheme)

func update_controls_prompt(_scheme: String) -> void:
	if has_node("/root/InputManager"):
		var im = get_node("/root/InputManager")
		if controls_reminder:
			controls_reminder.text = im.get_controls_summary(1)
		if prompt_icon:
			prompt_icon.texture = im.get_skill_button_icon(1)
	init_skill_ui()

func get_skill_prefix() -> String:
	var scheme = "keyboard"
	if has_node("/root/InputManager"):
		scheme = get_node("/root/InputManager").p1_scheme
	match scheme:
		"playstation": return "[L1/R1]"
		"nintendo": return "[L/R]"
		"xbox": return "[LB/RB]"
		_: return "[SPACE/E]"

func get_p2_skill_prefix() -> String:
	var scheme = "keyboard"
	if has_node("/root/InputManager"):
		scheme = get_node("/root/InputManager").p2_scheme
	match scheme:
		"playstation": return "[L1/R1]"
		"nintendo": return "[L/R]"
		"xbox": return "[LB/RB]"
		_: return "[NUM 9]"

func get_skill_icon_for_hero(hero: String) -> String:
	match hero:
		"kael", "brutus": return "res://assets/sprites/skill_kael_shield.png"
		"vex", "nyx": return "res://assets/sprites/skill_lyra_dash.png"
		_: return "res://assets/sprites/skill_kael_shield.png"

func get_skill_name_for_hero(hero: String) -> String:
	match hero:
		"kael": return "EMP CRYO DASH"
		"vex": return "SHADOW DASH"
		"brutus": return "TITAN SLAM"
		"nyx": return "VOID SINGULARITY"
		_: return "OVERCLOCK DASH"

func get_ammo_texture_for_weapon(wep_name: String) -> Texture2D:
	match wep_name:
		"revolver":
			return load("res://assets/sprites/ammo_revolver.png")
		"shotgun":
			return load("res://assets/sprites/ammo_shotgun.png")
		"smg":
			return load("res://assets/sprites/ammo_smg.png")
		"railgun":
			return load("res://assets/sprites/ammo_railgun.png")
		_:
			return load("res://assets/sprites/ammo_revolver.png")

func init_skill_ui() -> void:
	var s_name := "EMP CRYO DASH"
	var icon_path := "res://assets/sprites/skill_kael_shield.png"
	if GameState.selected_hero == "vex":
		s_name = "SHADOW DASH"
		icon_path = "res://assets/sprites/skill_lyra_dash.png"
	elif GameState.selected_hero == "brutus":
		s_name = "TITAN SLAM"
		icon_path = "res://assets/sprites/skill_kael_shield.png"
	elif GameState.selected_hero == "nyx":
		s_name = "VOID SINGULARITY"
		icon_path = "res://assets/sprites/skill_lyra_dash.png"
	
	if skill_icon and ResourceLoader.exists(icon_path):
		skill_icon.texture = load(icon_path)
	if skill_name_label:
		skill_name_label.text = "%s %s" % [get_skill_prefix(), s_name]
	if skill_lvl_badge:
		if GameState.skill_level >= 15:
			skill_lvl_badge.text = "[ LVL 15 MAX ]"
		else:
			skill_lvl_badge.text = "[ LVL %02d ]" % GameState.skill_level
	if skill_cd_overlay:
		skill_cd_overlay.visible = false
	if skill_cd_text:
		skill_cd_text.visible = false
	if skill_status_label:
		skill_status_label.text = "[ READY // PRESS SPACE ]"
		skill_status_label.add_theme_color_override("font_color", Color(0, 0.94, 1.0))

func _on_skill_cooldown(cur_cd: float, max_cd: float) -> void:
	var s_name := "EMP CRYO DASH"
	if GameState.selected_hero == "vex": s_name = "SHADOW DASH"
	elif GameState.selected_hero == "brutus": s_name = "TITAN SLAM"
	elif GameState.selected_hero == "nyx": s_name = "VOID SINGULARITY"
	
	if cur_cd > 0.05:
		was_skill_on_cd = true
		if skill_icon:
			skill_icon.modulate = Color(0.28, 0.32, 0.38, 0.85)
		if skill_cd_overlay:
			skill_cd_overlay.visible = true
			var ratio := clampf(cur_cd / maxf(0.01, max_cd), 0.0, 1.0)
			skill_cd_overlay.size = Vector2(56.0, 56.0 * ratio)
		if skill_cd_text:
			skill_cd_text.visible = true
			skill_cd_text.text = "%.1fs" % cur_cd
		if skill_status_label:
			skill_status_label.text = "[ RECHARGING... ]"
			skill_status_label.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
		if skill_name_label:
			skill_name_label.text = "%s %s" % [get_skill_prefix(), s_name]
			skill_name_label.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
	else:
		if was_skill_on_cd:
			was_skill_on_cd = false
			# Pop and glowing glitter shine animation!
			if skill_icon_container:
				skill_icon_container.pivot_offset = Vector2(28, 28)
				var pop_tw := skill_icon_container.create_tween()
				pop_tw.tween_property(skill_icon_container, "scale", Vector2(1.26, 1.26), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				pop_tw.tween_property(skill_icon_container, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_CUBIC)
			if skill_icon:
				skill_icon.modulate = Color(2.5, 2.5, 3.0, 1.0)
				var glow_tw := skill_icon.create_tween()
				glow_tw.tween_property(skill_icon, "modulate", Color.WHITE, 0.35)
		else:
			if skill_icon:
				skill_icon.modulate = Color.WHITE
		if skill_cd_overlay:
			skill_cd_overlay.visible = false
		if skill_cd_text:
			skill_cd_text.visible = false
		if skill_status_label:
			skill_status_label.text = "[ READY // PRESS SPACE ]"
			skill_status_label.add_theme_color_override("font_color", Color(0, 0.94, 1.0))
		if skill_name_label:
			skill_name_label.text = "%s %s READY" % [get_skill_prefix(), s_name]
			skill_name_label.add_theme_color_override("font_color", Color(0, 0.94, 1.0))

func _on_skill_upgraded(new_lvl: int) -> void:
	if skill_lvl_badge:
		if new_lvl >= 15:
			skill_lvl_badge.text = "[ LVL 15 MAX! ]"
		else:
			skill_lvl_badge.text = "[ LVL %02d UPGRADED! ]" % new_lvl
		skill_lvl_badge.pivot_offset = skill_lvl_badge.size * 0.5
		var tw := skill_lvl_badge.create_tween()
		tw.tween_property(skill_lvl_badge, "scale", Vector2(1.3, 1.3), 0.15)
		tw.tween_property(skill_lvl_badge, "scale", Vector2.ONE, 0.2)
		tw.tween_callback(func():
			if new_lvl >= 15:
				skill_lvl_badge.text = "[ LVL 15 MAX ]"
			else:
				skill_lvl_badge.text = "[ LVL %02d ]" % new_lvl
		)

func _on_weapon_slot_swapped(slot_idx: int, _wep_name: String, is_melee: bool) -> void:
	update_inventory_ui(slot_idx, is_melee)

func update_inventory_ui(slot_idx: int, is_melee: bool) -> void:
	if slot1_panel and slot1_label:
		var style1 := StyleBoxFlat.new()
		style1.set_corner_radius_all(4)
		if slot_idx == 1:
			style1.bg_color = Color(0.12, 0.22, 0.35, 0.95)
			style1.border_color = Color(0.98, 0.8, 0.08, 1.0) # Yellow highlight
			style1.set_border_width_all(3)
			slot1_label.add_theme_color_override("font_color", Color(0.98, 0.8, 0.08))
		else:
			style1.bg_color = Color(0.04, 0.06, 0.1, 0.8)
			style1.border_color = Color(0.2, 0.35, 0.5, 0.5)
			style1.set_border_width_all(1)
			slot1_label.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
		slot1_panel.add_theme_stylebox_override("panel", style1)
		slot1_label.text = "[1] PRIMARY: %s" % GameState.primary_weapon.to_upper()

	if slot2_panel and slot2_label:
		var style2 := StyleBoxFlat.new()
		style2.set_corner_radius_all(4)
		if slot_idx == 2:
			style2.bg_color = Color(0.08, 0.25, 0.16, 0.95)
			style2.border_color = Color(0.13, 0.95, 0.4, 1.0) # Emerald highlight
			style2.set_border_width_all(3)
			slot2_label.add_theme_color_override("font_color", Color(0.13, 0.95, 0.4))
		else:
			style2.bg_color = Color(0.04, 0.06, 0.1, 0.8)
			style2.border_color = Color(0.2, 0.35, 0.5, 0.5)
			style2.set_border_width_all(1)
			slot2_label.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
		slot2_panel.add_theme_stylebox_override("panel", style2)
		slot2_label.text = "[2] SECONDARY: CYBER BLADE"

	if healing_rule_badge:
		if is_melee:
			healing_rule_badge.text = "[ MODE MELEE: TEBASAN MEMICU 100% HEAL DROP! ]"
			healing_rule_badge.add_theme_color_override("font_color", Color(0.13, 0.95, 0.4))
		else:
			healing_rule_badge.text = "[ MODE RANGED: TEMBAKAN JARAK JAUH TIDAK DROP HEAL (0%) ]"
			healing_rule_badge.add_theme_color_override("font_color", Color(0.98, 0.8, 0.08))

	# Also update P1 co-op switcher on BottomLeft if active
	if p1_coop_slot1_panel and p1_coop_slot1_label:
		var style1 := StyleBoxFlat.new()
		style1.set_corner_radius_all(4)
		if slot_idx == 1:
			style1.bg_color = Color(0.12, 0.22, 0.35, 0.95)
			style1.border_color = Color(0.98, 0.8, 0.08, 1.0)
			style1.set_border_width_all(3)
			p1_coop_slot1_label.add_theme_color_override("font_color", Color(0.98, 0.8, 0.08))
		else:
			style1.bg_color = Color(0.04, 0.06, 0.1, 0.8)
			style1.border_color = Color(0.2, 0.35, 0.5, 0.5)
			style1.set_border_width_all(1)
			p1_coop_slot1_label.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
		p1_coop_slot1_panel.add_theme_stylebox_override("panel", style1)
		p1_coop_slot1_label.text = "[1] PRIMARY: %s" % GameState.primary_weapon.to_upper()

	if p1_coop_slot2_panel and p1_coop_slot2_label:
		var style2 := StyleBoxFlat.new()
		style2.set_corner_radius_all(4)
		if slot_idx == 2:
			style2.bg_color = Color(0.08, 0.25, 0.16, 0.95)
			style2.border_color = Color(0.13, 0.95, 0.4, 1.0)
			style2.set_border_width_all(3)
			p1_coop_slot2_label.add_theme_color_override("font_color", Color(0.13, 0.95, 0.4))
		else:
			style2.bg_color = Color(0.04, 0.06, 0.1, 0.8)
			style2.border_color = Color(0.2, 0.35, 0.5, 0.5)
			style2.set_border_width_all(1)
			p1_coop_slot2_label.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
		p1_coop_slot2_panel.add_theme_stylebox_override("panel", style2)
		p1_coop_slot2_label.text = "[2] BLADE"

func _on_p2_weapon_slot_swapped(slot_idx: int, _wep_name: String, _is_melee: bool) -> void:
	update_p2_inventory_ui(slot_idx)

func update_p2_inventory_ui(slot_idx: int) -> void:
	if p2_slot1_panel and p2_slot1_label:
		var style1 := StyleBoxFlat.new()
		style1.set_corner_radius_all(4)
		if slot_idx == 1:
			style1.bg_color = Color(0.12, 0.22, 0.35, 0.95)
			style1.border_color = Color(0.98, 0.8, 0.08, 1.0)
			style1.set_border_width_all(3)
			p2_slot1_label.add_theme_color_override("font_color", Color(0.98, 0.8, 0.08))
		else:
			style1.bg_color = Color(0.04, 0.06, 0.1, 0.8)
			style1.border_color = Color(0.2, 0.35, 0.5, 0.5)
			style1.set_border_width_all(1)
			p2_slot1_label.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
		p2_slot1_panel.add_theme_stylebox_override("panel", style1)
		var p2_wep = GameState.coop_p2_weapon if "coop_p2_weapon" in GameState and GameState.coop_p2_weapon != "" else "revolver"
		p2_slot1_label.text = "[1] PRIMARY: %s" % p2_wep.to_upper()

	if p2_slot2_panel and p2_slot2_label:
		var style2 := StyleBoxFlat.new()
		style2.set_corner_radius_all(4)
		if slot_idx == 2:
			style2.bg_color = Color(0.08, 0.25, 0.16, 0.95)
			style2.border_color = Color(0.13, 0.95, 0.4, 1.0)
			style2.set_border_width_all(3)
			p2_slot2_label.add_theme_color_override("font_color", Color(0.13, 0.95, 0.4))
		else:
			style2.bg_color = Color(0.04, 0.06, 0.1, 0.8)
			style2.border_color = Color(0.2, 0.35, 0.5, 0.5)
			style2.set_border_width_all(1)
			p2_slot2_label.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
		p2_slot2_panel.add_theme_stylebox_override("panel", style2)
		p2_slot2_label.text = "[2] BLADE"

func _on_p2_skill_cooldown(cur_cd: float, max_cd: float) -> void:
	if not p2_bottom_vbox: return
	var p2_hero = GameState.coop_p2_hero if "coop_p2_hero" in GameState and GameState.coop_p2_hero != "" else "kael"
	var s_name := get_skill_name_for_hero(p2_hero)
	
	if cur_cd > 0.05:
		was_p2_skill_on_cd = true
		if p2_skill_icon:
			p2_skill_icon.modulate = Color(0.28, 0.32, 0.38, 0.85)
		if p2_skill_cd_overlay:
			p2_skill_cd_overlay.visible = true
			var ratio := clampf(cur_cd / maxf(0.01, max_cd), 0.0, 1.0)
			p2_skill_cd_overlay.size = Vector2(56.0, 56.0 * ratio)
		if p2_skill_cd_text:
			p2_skill_cd_text.visible = true
			p2_skill_cd_text.text = "%.1fs" % cur_cd
		if p2_skill_status_label:
			p2_skill_status_label.text = "[ RECHARGING... ]"
			p2_skill_status_label.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
		if p2_skill_name_label:
			p2_skill_name_label.text = "%s %s" % [get_p2_skill_prefix(), s_name]
			p2_skill_name_label.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
	else:
		if was_p2_skill_on_cd:
			was_p2_skill_on_cd = false
			if p2_skill_icon_container:
				p2_skill_icon_container.pivot_offset = Vector2(28, 28)
				var pop_tw := p2_skill_icon_container.create_tween()
				pop_tw.tween_property(p2_skill_icon_container, "scale", Vector2(1.26, 1.26), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				pop_tw.tween_property(p2_skill_icon_container, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_CUBIC)
			if p2_skill_icon:
				p2_skill_icon.modulate = Color(2.5, 2.5, 3.0, 1.0)
				var glow_tw := p2_skill_icon.create_tween()
				glow_tw.tween_property(p2_skill_icon, "modulate", Color.WHITE, 0.35)
		else:
			if p2_skill_icon:
				p2_skill_icon.modulate = Color.WHITE
		if p2_skill_cd_overlay:
			p2_skill_cd_overlay.visible = false
		if p2_skill_cd_text:
			p2_skill_cd_text.visible = false
		if p2_skill_status_label:
			p2_skill_status_label.text = "[ READY // PRESS KP_9 / L1 ]"
			p2_skill_status_label.add_theme_color_override("font_color", Color(0.98, 0.8, 0.08))
		if p2_skill_name_label:
			p2_skill_name_label.text = "%s %s READY" % [get_p2_skill_prefix(), s_name]
			p2_skill_name_label.add_theme_color_override("font_color", Color(0.98, 0.8, 0.08))

var tower_hint_label: Label = null

func setup_tower_hud() -> void:
	if not tower_container: return
	tower_container.custom_minimum_size = Vector2(680, 52)
	tower_container.offset_left = -340.0
	tower_container.offset_right = 340.0
	if boss_container and boss_container.visible:
		tower_container.offset_top = 136.0
	else:
		tower_container.offset_top = 76.0
	tower_container.add_theme_constant_override("separation", 4)
	
	if tower_hp_bar:
		tower_hp_bar.custom_minimum_size = Vector2(680, 20)
		var sb_bg = StyleBoxFlat.new()
		sb_bg.bg_color = Color(0.04, 0.07, 0.14, 0.90)
		sb_bg.border_color = Color(0.12, 0.38, 0.65, 0.85)
		sb_bg.set_border_width_all(2)
		sb_bg.set_corner_radius_all(4)
		tower_hp_bar.add_theme_stylebox_override("background", sb_bg)
		
	if tower_name_label:
		tower_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var font_tech = load("res://assets/fonts/Silkscreen-Bold.ttf")
		if font_tech:
			tower_name_label.add_theme_font_override("font", font_tech)
		tower_name_label.add_theme_font_size_override("font_size", 13)
		tower_name_label.add_theme_color_override("font_color", Color(0.0, 0.95, 1.0))
		tower_name_label.text = "[ ⬡ SECTOR CORE DEFENSE MATRIX: 1500 / 1500 HP (100%) ⬡ ]"
		
	if not tower_hint_label and tower_container:
		tower_hint_label = Label.new()
		tower_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var font_tech = load("res://assets/fonts/Silkscreen-Bold.ttf")
		if font_tech:
			tower_hint_label.add_theme_font_override("font", font_tech)
		tower_hint_label.add_theme_font_size_override("font_size", 10)
		tower_hint_label.add_theme_color_override("font_color", Color(0.35, 0.95, 0.75, 0.95))
		tower_hint_label.text = "✦ NANITE SIPHON REPAIR ONLINE: Kill enemies to siphon core integrity ✦"
		tower_container.add_child(tower_hint_label)

func _on_tower_hp_changed(cur: int, max_hp: int) -> void:
	if tower_container:
		tower_container.visible = true
	if not tower_hint_label:
		setup_tower_hud()
		
	if tower_hp_bar:
		tower_hp_bar.max_value = max_hp
		var tw := create_tween()
		tw.tween_property(tower_hp_bar, "value", float(cur), 0.22).set_trans(Tween.TRANS_SINE)
		
		# Cyberpunk dynamic status based on integrity
		var pct := float(cur) / float(max_hp) if max_hp > 0 else 0.0
		var sb_fill = StyleBoxFlat.new()
		sb_fill.set_border_width_all(1)
		sb_fill.set_corner_radius_all(3)
		
		if pct > 0.5:
			sb_fill.bg_color = Color(0.0, 0.9, 1.0, 1.0) # Neon Cyan
			sb_fill.border_color = Color(0.6, 1.0, 1.0, 0.95)
			if tower_name_label:
				tower_name_label.text = "[ ⬡ SECTOR CORE DEFENSE MATRIX: %d / %d HP (%d%%) ⬡ ]" % [cur, max_hp, int(pct * 100)]
				tower_name_label.add_theme_color_override("font_color", Color(0.0, 0.95, 1.0))
		elif pct > 0.25:
			sb_fill.bg_color = Color(1.0, 0.75, 0.1, 1.0) # Amber Warning
			sb_fill.border_color = Color(1.0, 0.9, 0.4, 0.95)
			if tower_name_label:
				tower_name_label.text = "[ ⚠ CORE WARNING: INTEGRITY COMPROMISED: %d / %d HP (%d%%) ⚠ ]" % [cur, max_hp, int(pct * 100)]
				tower_name_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.1))
		else:
			sb_fill.bg_color = Color(1.0, 0.2, 0.25, 1.0) # Crimson Breach
			sb_fill.border_color = Color(1.0, 0.5, 0.5, 1.0)
			if tower_name_label:
				tower_name_label.text = "[ 🚨 CRITICAL ALERT: CORE BREACH IMMINENT: %d / %d HP (%d%%) 🚨 ]" % [cur, max_hp, int(pct * 100)]
				tower_name_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
				
		tower_hp_bar.add_theme_stylebox_override("fill", sb_fill)

var current_boss_title: String = "SECTOR BOSS"

func _on_boss_spawned(b_name: String, max_hp: int) -> void:
	current_boss_title = b_name
	if boss_container:
		boss_container.visible = true
		boss_container.offset_top = 76.0
	if tower_container:
		var tw_t = create_tween()
		tw_t.tween_property(tower_container, "offset_top", 136.0, 0.3).set_trans(Tween.TRANS_QUAD)
	if boss_hp_bar:
		boss_hp_bar.max_value = max_hp
		boss_hp_bar.value = max_hp
	if boss_name_label:
		boss_name_label.text = "[ ! ] %s // INTEGRITAS: 100%% (%d HP) [ ! ]" % [current_boss_title, max_hp]

func _on_boss_hp_changed(cur_hp: int, _max_hp: int) -> void:
	if boss_hp_bar:
		boss_hp_bar.value = cur_hp
		var max_val = maxi(1, int(boss_hp_bar.max_value))
		var pct := int((float(cur_hp) / float(max_val)) * 100.0)
		if boss_name_label:
			boss_name_label.text = "[ ! ] %s // INTEGRITAS: %d%% (%d / %d HP) [ ! ]" % [current_boss_title, pct, cur_hp, max_val]

func _on_boss_defeated() -> void:
	if boss_name_label:
		boss_name_label.text = "[ BOSS ANNIHILATED // SEKTOR DIBERSIHKAN ]"
	var tw := create_tween()
	tw.tween_interval(3.0)
	tw.tween_callback(func():
		if boss_container:
			boss_container.visible = false
		if tower_container:
			var tw_t = create_tween()
			tw_t.tween_property(tower_container, "offset_top", 76.0, 0.4).set_trans(Tween.TRANS_QUAD)
	)

func _process(_delta: float) -> void:
	var total_sec := int(GameState.survival_time)
	var mins := floori(float(total_sec) / 60.0)
	var secs := total_sec % 60
	if timer_label:
		timer_label.text = "%02d:%02d" % [mins, secs]
	if kills_label:
		kills_label.text = "SURVIVE! | PURGED: %d" % GameState.total_kills

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
		extra_lbl.add_theme_font_override("font", load("res://assets/fonts/Silkscreen-Bold.ttf"))
		extra_lbl.add_theme_font_size_override("font_size", 16)
		extra_lbl.add_theme_color_override("font_color", Color(0.98, 0.8, 0.08))
		extra_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hearts_container.add_child(extra_lbl)

func update_ammo(current: int, max_cap: int, is_reloading: bool, _reload_pct: float) -> void:
	if not ammo_container: return
	if reload_label:
		reload_label.visible = false
	
	if GameState.is_melee_active:
		ammo_container.visible = true
		for child in ammo_container.get_children():
			child.queue_free()
		var melee_lbl := Label.new()
		melee_lbl.text = "[ CYBER BLADE: UNLIMITED ENERGY ]"
		melee_lbl.add_theme_font_override("font", load("res://assets/fonts/Silkscreen-Bold.ttf"))
		melee_lbl.add_theme_font_size_override("font_size", 22)
		melee_lbl.add_theme_color_override("font_color", Color(0.13, 0.95, 0.4))
		ammo_container.add_child(melee_lbl)
		return
	
	ammo_container.visible = true
	for child in ammo_container.get_children():
		child.queue_free()
		
	var wep_tex := get_ammo_texture_for_weapon(GameState.primary_weapon)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	
	for i in range(max_cap):
		var rect := TextureRect.new()
		rect.texture = wep_tex
		rect.custom_minimum_size = Vector2(18, 34)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if is_reloading:
			rect.modulate = Color(0.6, 0.6, 0.6, 0.3)
		else:
			rect.modulate = Color(1.1, 1.1, 1.1, 1) if (i < current) else Color(0.25, 0.3, 0.4, 0.35)
		grid.add_child(rect)
	hbox.add_child(grid)
		
	var num_lbl := Label.new()
	if is_reloading:
		num_lbl.text = "  [ RELOADING... ]"
		num_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.15))
	else:
		num_lbl.text = "  [ %02d / %02d ]" % [current, max_cap]
		num_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3) if current <= 2 else Color(0.0, 0.95, 1.0))
	num_lbl.add_theme_font_override("font", load("res://assets/fonts/Silkscreen-Bold.ttf"))
	num_lbl.add_theme_font_size_override("font_size", 20)
	num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(num_lbl)
	
	ammo_container.add_child(hbox)

func update_xp(current: int, needed: int, lvl: int) -> void:
	if xp_bar:
		xp_bar.max_value = needed
		var tw := xp_bar.create_tween()
		tw.tween_property(xp_bar, "value", float(current), 0.15)
		
	if level_label:
		var pct := int((float(current) / float(maxi(1, needed))) * 100.0)
		var new_text = "[ LVL %02d // OVERCLOCK: %d%% (%d/%d XP) ]" % [lvl, pct, current, needed]
		if level_label.text != new_text:
			level_label.text = new_text
			level_label.pivot_offset = level_label.size * 0.5
			var pop_tw := level_label.create_tween()
			pop_tw.tween_property(level_label, "scale", Vector2(1.35, 1.35), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			pop_tw.tween_property(level_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func setup_coop_hud() -> void:
	# 1. Setup Player 1 Badge on TopLeft
	if not p1_badge_lbl and has_node("TopLeft"):
		p1_badge_lbl = Label.new()
		var p1_hero = GameState.selected_hero if "selected_hero" in GameState and GameState.selected_hero != "" else "P1"
		p1_badge_lbl.text = "[ P1 // %s ]" % p1_hero.to_upper()
		p1_badge_lbl.add_theme_font_override("font", load("res://assets/fonts/Silkscreen-Bold.ttf"))
		p1_badge_lbl.add_theme_font_size_override("font_size", 14)
		p1_badge_lbl.add_theme_color_override("font_color", Color(0, 0.94, 1.0))
		$TopLeft.add_child(p1_badge_lbl)
		$TopLeft.move_child(p1_badge_lbl, 0)

	# 2. Relocate Timer and Kills to TopCenter so they don't collide with P2 HUD
	if timer_label and kills_label and has_node("TopCenter") and has_node("TopRight"):
		if timer_label.get_parent() == $TopRight:
			$TopRight.remove_child(timer_label)
			$TopRight.remove_child(kills_label)
			
			var stats_hbox = HBoxContainer.new()
			stats_hbox.name = "StatsHBox"
			stats_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
			stats_hbox.add_theme_constant_override("separation", 24)
			
			timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			
			stats_hbox.add_child(timer_label)
			stats_hbox.add_child(kills_label)
			$TopCenter.add_child(stats_hbox)

	# 3. Create Player 2 HUD on TopRight
	if not p2_container and has_node("TopRight"):
		p2_container = VBoxContainer.new()
		p2_container.name = "P2HUDContainer"
		p2_container.add_theme_constant_override("separation", 4)
		$TopRight.add_child(p2_container)
		
		p2_badge_lbl = Label.new()
		var p2_hero = GameState.coop_p2_hero if "coop_p2_hero" in GameState and GameState.coop_p2_hero != "" else "P2"
		p2_badge_lbl.text = "[ P2 // %s ]" % p2_hero.to_upper()
		p2_badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		p2_badge_lbl.add_theme_font_override("font", load("res://assets/fonts/Silkscreen-Bold.ttf"))
		p2_badge_lbl.add_theme_font_size_override("font_size", 14)
		p2_badge_lbl.add_theme_color_override("font_color", Color(0.98, 0.8, 0.08))
		p2_container.add_child(p2_badge_lbl)
		
		p2_hearts_container = HBoxContainer.new()
		p2_hearts_container.name = "P2HeartsContainer"
		p2_hearts_container.alignment = BoxContainer.ALIGNMENT_END
		p2_hearts_container.add_theme_constant_override("separation", 4)
		p2_container.add_child(p2_hearts_container)
		
		p2_ammo_container = HBoxContainer.new()
		p2_ammo_container.name = "P2AmmoContainer"
		p2_ammo_container.alignment = BoxContainer.ALIGNMENT_END
		p2_ammo_container.add_theme_constant_override("separation", 3)
		p2_container.add_child(p2_ammo_container)
		
		p2_reload_label = Label.new()
		p2_reload_label.name = "P2ReloadLabel"
		p2_reload_label.text = "RELOAD [----------] 0%"
		p2_reload_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		p2_reload_label.add_theme_font_override("font", load("res://assets/fonts/Silkscreen-Bold.ttf"))
		p2_reload_label.add_theme_font_size_override("font_size", 16)
		p2_reload_label.add_theme_color_override("font_color", Color(0.98, 0.8, 0.08))
		p2_reload_label.visible = false
		p2_container.add_child(p2_reload_label)
		
		var p2_hp = GameState.p2_health if "p2_health" in GameState else 5
		var p2_max = GameState.p2_max_health if "p2_max_health" in GameState else 5
		update_p2_hearts(p2_hp, p2_max)
		
		var p2_am = GameState.p2_ammo if "p2_ammo" in GameState else 6
		var p2_am_max = GameState.p2_max_ammo if "p2_max_ammo" in GameState else 6
		var p2_rel = GameState.p2_is_reloading if "p2_is_reloading" in GameState else false
		var p2_rel_pct = GameState.p2_reload_pct if "p2_reload_pct" in GameState else 0.0
		update_p2_ammo(p2_am, p2_am_max, p2_rel, p2_rel_pct)

	# 4. In Co-op, create P1 Weapon Switcher under P1 Skill on BottomLeft
	if not p1_coop_weapon_slots and has_node("BottomLeftSkill"):
		p1_coop_weapon_slots = HBoxContainer.new()
		p1_coop_weapon_slots.name = "P1CoopWeaponSlots"
		p1_coop_weapon_slots.add_theme_constant_override("separation", 8)
		
		p1_coop_slot1_panel = PanelContainer.new()
		p1_coop_slot1_panel.custom_minimum_size = Vector2(150, 28)
		p1_coop_slot1_label = Label.new()
		p1_coop_slot1_label.add_theme_font_override("font", load("res://assets/fonts/Silkscreen-Bold.ttf"))
		p1_coop_slot1_label.add_theme_font_size_override("font_size", 10)
		p1_coop_slot1_label.text = "[1] PRIMARY: %s" % GameState.primary_weapon.to_upper()
		p1_coop_slot1_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p1_coop_slot1_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		p1_coop_slot1_panel.add_child(p1_coop_slot1_label)
		p1_coop_weapon_slots.add_child(p1_coop_slot1_panel)
		
		p1_coop_slot2_panel = PanelContainer.new()
		p1_coop_slot2_panel.custom_minimum_size = Vector2(150, 28)
		p1_coop_slot2_label = Label.new()
		p1_coop_slot2_label.add_theme_font_override("font", load("res://assets/fonts/Silkscreen-Bold.ttf"))
		p1_coop_slot2_label.add_theme_font_size_override("font_size", 10)
		p1_coop_slot2_label.text = "[2] BLADE"
		p1_coop_slot2_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p1_coop_slot2_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		p1_coop_slot2_panel.add_child(p1_coop_slot2_label)
		p1_coop_weapon_slots.add_child(p1_coop_slot2_panel)
		
		$BottomLeftSkill.add_child(p1_coop_weapon_slots)
		if controls_reminder:
			$BottomLeftSkill.move_child(controls_reminder, -1)
		update_inventory_ui(GameState.equipped_slot, GameState.is_melee_active)

	# 5. In Co-op, repurpose BottomRightInventory for Player 2 (Skill HUD + Weapon Switcher)
	if has_node("BottomRightInventory"):
		for child in $BottomRightInventory.get_children():
			child.queue_free()
			
		p2_bottom_vbox = VBoxContainer.new()
		p2_bottom_vbox.name = "P2BottomVBox"
		p2_bottom_vbox.alignment = BoxContainer.ALIGNMENT_END
		p2_bottom_vbox.add_theme_constant_override("separation", 6)
		$BottomRightInventory.add_child(p2_bottom_vbox)
		
		# P2 Skill Row (HBox: Text Column on left, Icon on right for right-alignment aesthetic)
		var p2_s_row = HBoxContainer.new()
		p2_s_row.alignment = BoxContainer.ALIGNMENT_END
		p2_s_row.add_theme_constant_override("separation", 10)
		
		var p2_text_col = VBoxContainer.new()
		p2_text_col.alignment = BoxContainer.ALIGNMENT_CENTER
		p2_text_col.add_theme_constant_override("separation", 2)
		
		var p2_title_row = HBoxContainer.new()
		p2_title_row.alignment = BoxContainer.ALIGNMENT_END
		p2_title_row.add_theme_constant_override("separation", 6)
		
		p2_skill_name_label = Label.new()
		p2_skill_name_label.add_theme_font_override("font", load("res://assets/fonts/Silkscreen-Bold.ttf"))
		p2_skill_name_label.add_theme_font_size_override("font_size", 12)
		p2_skill_name_label.add_theme_color_override("font_color", Color(0.98, 0.8, 0.08))
		var p2_h_name = GameState.coop_p2_hero if "coop_p2_hero" in GameState and GameState.coop_p2_hero != "" else "nyx"
		p2_skill_name_label.text = "%s %s" % [get_p2_skill_prefix(), get_skill_name_for_hero(p2_h_name)]
		p2_title_row.add_child(p2_skill_name_label)
		
		p2_skill_lvl_badge = Label.new()
		p2_skill_lvl_badge.add_theme_font_override("font", load("res://assets/fonts/Silkscreen-Bold.ttf"))
		p2_skill_lvl_badge.add_theme_font_size_override("font_size", 10)
		p2_skill_lvl_badge.add_theme_color_override("font_color", Color(0.0, 0.95, 1.0))
		p2_skill_lvl_badge.text = "[ LVL 01 ]"
		p2_title_row.add_child(p2_skill_lvl_badge)
		p2_text_col.add_child(p2_title_row)
		
		p2_skill_status_label = Label.new()
		p2_skill_status_label.add_theme_font_override("font", load("res://assets/fonts/Silkscreen-Bold.ttf"))
		p2_skill_status_label.add_theme_font_size_override("font_size", 10)
		p2_skill_status_label.add_theme_color_override("font_color", Color(0.98, 0.8, 0.08))
		p2_skill_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		p2_skill_status_label.text = "[ READY // PRESS KP_9 / L1 ]"
		p2_text_col.add_child(p2_skill_status_label)
		
		p2_s_row.add_child(p2_text_col)
		
		# P2 Skill Icon Container
		p2_skill_icon_container = Control.new()
		p2_skill_icon_container.custom_minimum_size = Vector2(56, 56)
		
		p2_skill_icon = TextureRect.new()
		p2_skill_icon.custom_minimum_size = Vector2(56, 56)
		p2_skill_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		p2_skill_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var icon_path_p2 = get_skill_icon_for_hero(p2_h_name)
		if ResourceLoader.exists(icon_path_p2):
			p2_skill_icon.texture = load(icon_path_p2)
		p2_skill_icon_container.add_child(p2_skill_icon)
		
		p2_skill_cd_overlay = ColorRect.new()
		p2_skill_cd_overlay.color = Color(0.04, 0.06, 0.12, 0.80)
		p2_skill_cd_overlay.custom_minimum_size = Vector2(56, 56)
		p2_skill_cd_overlay.visible = false
		p2_skill_icon_container.add_child(p2_skill_cd_overlay)
		
		p2_skill_cd_text = Label.new()
		p2_skill_cd_text.add_theme_font_override("font", load("res://assets/fonts/Silkscreen-Bold.ttf"))
		p2_skill_cd_text.add_theme_font_size_override("font_size", 14)
		p2_skill_cd_text.add_theme_color_override("font_color", Color(1.0, 0.85, 0.15))
		p2_skill_cd_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p2_skill_cd_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		p2_skill_cd_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		p2_skill_cd_text.visible = false
		p2_skill_icon_container.add_child(p2_skill_cd_text)
		
		p2_s_row.add_child(p2_skill_icon_container)
		p2_bottom_vbox.add_child(p2_s_row)
		
		# P2 Weapon Switcher
		p2_weapon_container = HBoxContainer.new()
		p2_weapon_container.alignment = BoxContainer.ALIGNMENT_END
		p2_weapon_container.add_theme_constant_override("separation", 8)
		
		p2_slot1_panel = PanelContainer.new()
		p2_slot1_panel.custom_minimum_size = Vector2(150, 28)
		p2_slot1_label = Label.new()
		p2_slot1_label.add_theme_font_override("font", load("res://assets/fonts/Silkscreen-Bold.ttf"))
		p2_slot1_label.add_theme_font_size_override("font_size", 10)
		var p2_wep = GameState.coop_p2_weapon if "coop_p2_weapon" in GameState and GameState.coop_p2_weapon != "" else "revolver"
		p2_slot1_label.text = "[1] PRIMARY: %s" % p2_wep.to_upper()
		p2_slot1_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p2_slot1_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		p2_slot1_panel.add_child(p2_slot1_label)
		p2_weapon_container.add_child(p2_slot1_panel)
		
		p2_slot2_panel = PanelContainer.new()
		p2_slot2_panel.custom_minimum_size = Vector2(150, 28)
		p2_slot2_label = Label.new()
		p2_slot2_label.add_theme_font_override("font", load("res://assets/fonts/Silkscreen-Bold.ttf"))
		p2_slot2_label.add_theme_font_size_override("font_size", 10)
		p2_slot2_label.text = "[2] BLADE"
		p2_slot2_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p2_slot2_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		p2_slot2_panel.add_child(p2_slot2_label)
		p2_weapon_container.add_child(p2_slot2_panel)
		
		p2_bottom_vbox.add_child(p2_weapon_container)
		
		# P2 Controls reminder
		p2_controls_reminder = Label.new()
		p2_controls_reminder.add_theme_font_override("font", load("res://assets/fonts/Silkscreen-Bold.ttf"))
		p2_controls_reminder.add_theme_font_size_override("font_size", 9)
		p2_controls_reminder.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85, 0.8))
		p2_controls_reminder.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if has_node("/root/InputManager"):
			p2_controls_reminder.text = get_node("/root/InputManager").get_controls_summary(2)
		else:
			p2_controls_reminder.text = "[NUMPAD] MOVE | [KP_0] SHOOT | [KP_1] MELEE | [KP_9] SKILL | [KP_7] SWAP"
		p2_bottom_vbox.add_child(p2_controls_reminder)
		
		update_p2_inventory_ui(GameState.p2_equipped_slot)

func _on_p1_health_changed(current: int, max_hp: int) -> void:
	update_hearts(current, max_hp)

func _on_p2_health_changed(current: int, max_hp: int) -> void:
	if not p2_container:
		setup_coop_hud()
	update_p2_hearts(current, max_hp)

func _on_p1_ammo_changed(current: int, max_cap: int, is_reloading: bool, reload_pct: float) -> void:
	update_ammo(current, max_cap, is_reloading, reload_pct)

func _on_p2_ammo_changed(current: int, max_cap: int, is_reloading: bool, reload_pct: float) -> void:
	if not p2_container:
		setup_coop_hud()
	update_p2_ammo(current, max_cap, is_reloading, reload_pct)

func update_p2_hearts(current: int, max_hp: int) -> void:
	if not p2_hearts_container: return
	for child in p2_hearts_container.get_children():
		child.queue_free()

	if max_hp <= 5:
		for i in range(max_hp):
			var rect := TextureRect.new()
			rect.texture = heart_full_tex if (i < current) else heart_empty_tex
			rect.custom_minimum_size = Vector2(40, 40)
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			p2_hearts_container.add_child(rect)
	else:
		for i in range(5):
			var rect := TextureRect.new()
			var fill_point := int(float(i + 1) / 5.0 * float(max_hp))
			rect.texture = heart_full_tex if (current >= fill_point) else heart_empty_tex
			rect.custom_minimum_size = Vector2(40, 40)
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			p2_hearts_container.add_child(rect)
			
		var extra_lbl := Label.new()
		extra_lbl.text = " [+%d] (%d/%d)" % [max_hp - 5, current, max_hp]
		extra_lbl.add_theme_font_override("font", load("res://assets/fonts/Silkscreen-Bold.ttf"))
		extra_lbl.add_theme_font_size_override("font_size", 16)
		extra_lbl.add_theme_color_override("font_color", Color(0.98, 0.8, 0.08))
		extra_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		p2_hearts_container.add_child(extra_lbl)

func update_p2_ammo(current: int, max_cap: int, is_reloading: bool, _reload_pct: float) -> void:
	if not p2_ammo_container: return
	if p2_reload_label:
		p2_reload_label.visible = false
	p2_ammo_container.visible = true
	
	for child in p2_ammo_container.get_children():
		child.queue_free()
		
	var p2_is_melee = GameState.p2_is_melee_active if "p2_is_melee_active" in GameState else false
	if p2_is_melee:
		var melee_lbl := Label.new()
		melee_lbl.text = "[ BLADE: UNLIMITED ]"
		melee_lbl.add_theme_font_override("font", load("res://assets/fonts/Silkscreen-Bold.ttf"))
		melee_lbl.add_theme_font_size_override("font_size", 16)
		melee_lbl.add_theme_color_override("font_color", Color(0.13, 0.95, 0.4))
		p2_ammo_container.add_child(melee_lbl)
		return
		
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_END
	hbox.add_theme_constant_override("separation", 8)
	
	var num_lbl := Label.new()
	if is_reloading:
		num_lbl.text = "[ RELOADING... ] "
		num_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.15))
	else:
		num_lbl.text = "[ %02d / %02d ] " % [current, max_cap]
		num_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3) if current <= 2 else Color(0.98, 0.8, 0.08))
	num_lbl.add_theme_font_override("font", load("res://assets/fonts/Silkscreen-Bold.ttf"))
	num_lbl.add_theme_font_size_override("font_size", 16)
	num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(num_lbl)

	var p2_wep = GameState.coop_p2_weapon if "coop_p2_weapon" in GameState and GameState.coop_p2_weapon != "" else "revolver"
	var wep_tex := get_ammo_texture_for_weapon(p2_wep)

	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)

	for i in range(max_cap):
		var rect := TextureRect.new()
		rect.texture = wep_tex
		rect.custom_minimum_size = Vector2(16, 30)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if is_reloading:
			rect.modulate = Color(0.6, 0.6, 0.6, 0.3)
		else:
			rect.modulate = Color(1, 1, 1, 1) if (i < current) else Color(0.3, 0.35, 0.45, 0.4)
		grid.add_child(rect)
	hbox.add_child(grid)
	p2_ammo_container.add_child(hbox)
