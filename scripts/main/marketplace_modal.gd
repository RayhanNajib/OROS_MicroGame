extends ColorRect

@onready var shop_container: Control = $CenterContainer/Panel/Margin/VBox/ShopContainer
@onready var runes_container: Control = $CenterContainer/Panel/Margin/VBox/RunesContainer

@onready var items_grid: GridContainer = $CenterContainer/Panel/Margin/VBox/ShopContainer/Scroll/ItemsGrid
@onready var offense_nodes_vbox: VBoxContainer = $CenterContainer/Panel/Margin/VBox/RunesContainer/TreeHBox/OffenseBranch/NodesVBox
@onready var defense_nodes_vbox: VBoxContainer = $CenterContainer/Panel/Margin/VBox/RunesContainer/TreeHBox/DefenseBranch/NodesVBox

@onready var credits_label: Label = $CenterContainer/Panel/Margin/VBox/HeaderBox/CreditsLabel
@onready var shop_tab_btn: Button = $CenterContainer/Panel/Margin/VBox/TabButtons/ShopTabBtn
@onready var runes_tab_btn: Button = $CenterContainer/Panel/Margin/VBox/TabButtons/RunesTabBtn

@onready var respec_btn: Button = $CenterContainer/Panel/Margin/VBox/BottomBar/RespecBtn
@onready var close_btn: Button = $CenterContainer/Panel/Margin/VBox/BottomBar/CloseBtn

@onready var sfx_click: AudioStreamPlayer = $SFXClick

# Compact Visual Catalog (Blue / Yellow / Green theme) - Prices increased 3x
var catalog: Array[Dictionary] = [
	# Hero Skins
	{
		"id": "skin_kael_cobalt",
		"type": "hero_skin",
		"target": "kael",
		"variant": "cobalt",
		"name": "KAEL: COBALT ANVIL",
		"fx": "Pulsa Cyan Neon",
		"icon": "res://assets/sprites/avatar_kael_cobalt.png",
		"portrait": "res://assets/sprites/portrait_kael_cobalt.png",
		"cost": 450,
		"accent": Color(0, 0.94, 1.0)
	},
	{
		"id": "skin_kael_crimson",
		"type": "hero_skin",
		"target": "kael",
		"variant": "crimson",
		"name": "KAEL: CRIMSON FURY",
		"fx": "Pulsa Ruby Flare",
		"icon": "res://assets/sprites/avatar_kael_crimson.png",
		"portrait": "res://assets/sprites/portrait_kael_crimson.png",
		"cost": 540,
		"accent": Color(1.0, 0.2, 0.3)
	},
	{
		"id": "skin_vex_toxic",
		"type": "hero_skin",
		"target": "vex",
		"variant": "toxic",
		"name": "VEX: ACID MANTIS",
		"fx": "Trail Asap Emerald",
		"icon": "res://assets/sprites/avatar_vex_toxic.png",
		"portrait": "res://assets/sprites/portrait_vex_toxic.png",
		"cost": 600,
		"accent": Color(0.13, 0.95, 0.4)
	},
	{
		"id": "skin_brutus_gold",
		"type": "hero_skin",
		"target": "brutus",
		"variant": "gold",
		"name": "BRUTUS: TITAN GOLD",
		"fx": "Spark Listrik Emas",
		"icon": "res://assets/sprites/avatar_brutus_gold.png",
		"portrait": "res://assets/sprites/portrait_brutus_gold.png",
		"cost": 750,
		"accent": Color(0.98, 0.8, 0.08)
	},
	{
		"id": "skin_nyx_void",
		"type": "hero_skin",
		"target": "nyx",
		"variant": "void",
		"name": "NYX: VOID PHASE",
		"fx": "Aura Plasma Ungu-Biru",
		"icon": "res://assets/sprites/avatar_nyx_void.png",
		"portrait": "res://assets/sprites/portrait_nyx_void.png",
		"cost": 900,
		"accent": Color(0.45, 0.3, 0.95)
	},
	# Weapon Skins
	{
		"id": "wep_revolver_gold",
		"type": "weapon_skin",
		"target": "revolver",
		"variant": "gold",
		"name": "REVOLVER: SOVEREIGN GOLD",
		"fx": "Peluru Laser Emas",
		"icon": "res://assets/sprites/icon_wep_revolver.png",
		"cost": 450,
		"accent": Color(0.98, 0.8, 0.08)
	},
	{
		"id": "wep_shotgun_cyber",
		"type": "weapon_skin",
		"target": "shotgun",
		"variant": "cyber",
		"name": "SHOTGUN: CYBER BLAST",
		"fx": "Semburan Spark Cyan",
		"icon": "res://assets/sprites/icon_wep_shotgun.png",
		"cost": 540,
		"accent": Color(0, 0.94, 1.0)
	},
	{
		"id": "wep_smg_violet",
		"type": "weapon_skin",
		"target": "smg",
		"variant": "violet",
		"name": "SMG: MATRIX SPRAY",
		"fx": "Berkas Emerald Matrix",
		"icon": "res://assets/sprites/icon_wep_smg.png",
		"cost": 540,
		"accent": Color(0.13, 0.95, 0.4)
	},
	{
		"id": "wep_railgun_cryo",
		"type": "weapon_skin",
		"target": "railgun",
		"variant": "cryo",
		"name": "RAILGUN: CRYO BEAM",
		"fx": "Berkas Laser Cyan Beku",
		"icon": "res://assets/sprites/icon_wep_railgun.png",
		"cost": 660,
		"accent": Color(0, 0.94, 1.0)
	},
	# Custom EXP Core Models
	{
		"id": "gem_battery",
		"type": "gem_skin",
		"target": "battery",
		"variant": "battery",
		"name": "LOOT: ION BATTERY",
		"fx": "Baterai Cyan Berpendar",
		"icon": "res://assets/sprites/spr_skill_core.png",
		"cost": 300,
		"accent": Color(0, 0.94, 1.0)
	},
	{
		"id": "gem_emerald",
		"type": "gem_skin",
		"target": "emerald",
		"variant": "emerald",
		"name": "LOOT: EMERALD CORE",
		"fx": "Kristal Zamrud Hijau",
		"icon": "res://assets/sprites/spr_skill_core.png",
		"cost": 360,
		"accent": Color(0.13, 0.95, 0.4)
	}
]

var rune_defs: Array[Dictionary] = [
	# Offense Tech Tree (Tier 1 -> Tier 2 -> Tier 3 -> Tier 4) - Prices increased 3x
	{"id": "cyber_caliber", "branch": "offense", "tier": 1, "prereq": "", "name": "CYBER CALIBER", "desc": "+5% Bullet DMG per rank • Daya tembak proyektil plasma", "max": 5, "cost": 150, "icon": "res://assets/sprites/icon_rune_caliber.png"},
	{"id": "rapid_vent", "branch": "offense", "tier": 2, "prereq": "cyber_caliber", "name": "RAPID VENT", "desc": "-6% Reload Time per rank • Ventilasi pendingin magasin", "max": 5, "cost": 225, "icon": "res://assets/sprites/icon_rune_vent.png"},
	{"id": "heavy_impulse", "branch": "offense", "tier": 3, "prereq": "rapid_vent", "name": "HEAVY IMPULSE", "desc": "+18% Knockback per rank • Pendorong kinetik proyektil", "max": 5, "cost": 300, "icon": "res://assets/sprites/icon_rune_impulse.png"},
	{"id": "plasma_pierce", "branch": "offense", "tier": 4, "prereq": "heavy_impulse", "name": "PLASMA PIERCE", "desc": "+1 Peluru Tembus (Pierce) • Menembus kawanan musuh", "max": 3, "cost": 450, "icon": "res://assets/sprites/icon_rune_pierce.png"},

	# Defense Tech Tree (Tier 1 -> Tier 2 -> Tier 3 -> Tier 4) - Prices increased 3x
	{"id": "titan_alloy", "branch": "defense", "tier": 1, "prereq": "", "name": "TITAN ALLOY", "desc": "+1 Max Health per rank • Pelat baja penguat struktur tubuh", "max": 5, "cost": 150, "icon": "res://assets/sprites/icon_rune_alloy.png"},
	{"id": "ion_stride", "branch": "defense", "tier": 2, "prereq": "titan_alloy", "name": "ION STRIDE", "desc": "+5% Kecepatan Lari per rank • Thruster ion mikro di telapak kaki", "max": 5, "cost": 225, "icon": "res://assets/sprites/icon_rune_stride.png"},
	{"id": "melee_leech", "branch": "defense", "tier": 3, "prereq": "ion_stride", "name": "MELEE LEECH", "desc": "+30% Melee Heal Drop Rate • Konversi nano-serpihan jadi darah", "max": 3, "cost": 300, "icon": "res://assets/sprites/icon_rune_leech.png"},
	{"id": "overclock_core", "branch": "defense", "tier": 4, "prereq": "melee_leech", "name": "OVERCLOCK CORE", "desc": "-12% Cooldown Skill per rank • Akselerator prosesor kuantum", "max": 3, "cost": 450, "icon": "res://assets/sprites/icon_rune_overclock.png"}
]

var active_tab: int = 1

func _ready() -> void:
	visible = false
	if close_btn:
		close_btn.pressed.connect(func():
			if sfx_click: sfx_click.play()
			visible = false
		)
	if shop_tab_btn:
		shop_tab_btn.pressed.connect(func(): switch_tab(1))
	if runes_tab_btn:
		runes_tab_btn.pressed.connect(func(): switch_tab(2))
	if respec_btn:
		respec_btn.pressed.connect(_on_respec_pressed)

func open_marketplace() -> void:
	visible = true
	if sfx_click: sfx_click.play()
	switch_tab(1)
	if shop_tab_btn:
		shop_tab_btn.grab_focus()

func _safe_handle_input() -> void:
	if is_inside_tree() and get_viewport():
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if not visible: return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_KP_0:
			visible = false
			_safe_handle_input()
	elif event is InputEventJoypadButton and event.is_pressed():
		if event.button_index == JOY_BUTTON_B:
			visible = false
			_safe_handle_input()
		elif event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			switch_tab(1)
			if shop_tab_btn: shop_tab_btn.grab_focus()
			_safe_handle_input()
		elif event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			switch_tab(2)
			if runes_tab_btn: runes_tab_btn.grab_focus()
			_safe_handle_input()

func switch_tab(tab_idx: int) -> void:
	active_tab = tab_idx
	if sfx_click: sfx_click.play()
	
	var tex_conf_n = load("res://assets/ui/btn_confirm_normal.png")
	var tex_conf_h = load("res://assets/ui/btn_confirm_hover.png")
	var tex_sci_n = load("res://assets/ui/btn_sci_normal.png")
	var tex_sci_h = load("res://assets/ui/btn_sci_hover.png")
	
	var sb_conf_n = StyleBoxTexture.new(); sb_conf_n.texture = tex_conf_n; sb_conf_n.set_texture_margin_all(8)
	var sb_conf_h = StyleBoxTexture.new(); sb_conf_h.texture = tex_conf_h; sb_conf_h.set_texture_margin_all(8)
	var sb_sci_n = StyleBoxTexture.new(); sb_sci_n.texture = tex_sci_n; sb_sci_n.set_texture_margin_all(8)
	var sb_sci_h = StyleBoxTexture.new(); sb_sci_h.texture = tex_sci_h; sb_sci_h.set_texture_margin_all(8)
	
	if active_tab == 1:
		shop_container.visible = true
		runes_container.visible = false
		if shop_tab_btn:
			shop_tab_btn.add_theme_stylebox_override("normal", sb_conf_n)
			shop_tab_btn.add_theme_stylebox_override("hover", sb_conf_h)
			shop_tab_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.15, 1))
			shop_tab_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
			shop_tab_btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.95, 0.15, 1))
			shop_tab_btn.add_theme_color_override("font_focus_color", Color(1, 1, 1, 1))
		if runes_tab_btn:
			runes_tab_btn.add_theme_stylebox_override("normal", sb_sci_n)
			runes_tab_btn.add_theme_stylebox_override("hover", sb_sci_h)
			runes_tab_btn.add_theme_color_override("font_color", Color(0, 0.94, 1, 1))
			runes_tab_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.15, 1))
		refresh_shop()
	else:
		shop_container.visible = false
		runes_container.visible = true
		if runes_tab_btn:
			runes_tab_btn.add_theme_stylebox_override("normal", sb_conf_n)
			runes_tab_btn.add_theme_stylebox_override("hover", sb_conf_h)
			runes_tab_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.15, 1))
			runes_tab_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
			runes_tab_btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.95, 0.15, 1))
			runes_tab_btn.add_theme_color_override("font_focus_color", Color(1, 1, 1, 1))
		if shop_tab_btn:
			shop_tab_btn.add_theme_stylebox_override("normal", sb_sci_n)
			shop_tab_btn.add_theme_stylebox_override("hover", sb_sci_h)
			shop_tab_btn.add_theme_color_override("font_color", Color(0, 0.94, 1, 1))
			shop_tab_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.15, 1))
		refresh_runes()

func refresh_shop() -> void:
	if credits_label:
		credits_label.text = "SALDO: %d NC" % SaveManager.nano_credits
		
	if not items_grid: return
	for child in items_grid.get_children():
		child.queue_free()

	var font_orb = load("res://assets/fonts/Orbitron-Bold.ttf")
	var font_silk = load("res://assets/fonts/Silkscreen-Bold.ttf")
	var font_tech = load("res://assets/fonts/tech_font.ttf")

	var tex_conf_n = load("res://assets/ui/btn_confirm_normal.png")
	var tex_conf_h = load("res://assets/ui/btn_confirm_hover.png")
	var tex_sci_n = load("res://assets/ui/btn_sci_normal.png")
	var tex_sci_h = load("res://assets/ui/btn_sci_hover.png")

	var sb_conf_n = StyleBoxTexture.new(); sb_conf_n.texture = tex_conf_n; sb_conf_n.set_texture_margin_all(8)
	var sb_conf_h = StyleBoxTexture.new(); sb_conf_h.texture = tex_conf_h; sb_conf_h.set_texture_margin_all(8)
	var sb_sci_n = StyleBoxTexture.new(); sb_sci_n.texture = tex_sci_n; sb_sci_n.set_texture_margin_all(8)
	var sb_sci_h = StyleBoxTexture.new(); sb_sci_h.texture = tex_sci_h; sb_sci_h.set_texture_margin_all(8)

	for item in catalog:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(380, 290)
		
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.06, 0.09, 0.14, 0.96)
		style.border_color = item["accent"]
		style.set_border_width_all(2)
		style.set_corner_radius_all(6)
		panel.add_theme_stylebox_override("panel", style)
		
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 14)
		margin.add_theme_constant_override("margin_right", 14)
		margin.add_theme_constant_override("margin_top", 12)
		margin.add_theme_constant_override("margin_bottom", 12)
		
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 8)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		# Name
		var name_lbl := Label.new()
		name_lbl.text = item["name"]
		name_lbl.add_theme_font_override("font", font_orb)
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", item["accent"])
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(name_lbl)
		
		# BEFORE -> AFTER Skin Preview
		var preview_hbox := HBoxContainer.new()
		preview_hbox.add_theme_constant_override("separation", 6)
		preview_hbox.alignment = BoxContainer.ALIGNMENT_CENTER

		var before_lbl := Label.new()
		before_lbl.text = "AWAL"
		before_lbl.add_theme_font_override("font", font_tech)
		before_lbl.add_theme_font_size_override("font_size", 11)
		before_lbl.add_theme_color_override("font_color", Color(0.93, 0.89, 0.85))
		preview_hbox.add_child(before_lbl)

		var before_icon := TextureRect.new()
		var before_path = "res://assets/sprites/avatar_%s.png" % item["target"] if item.get("type") == "hero_skin" else item.get("icon", "")
		if ResourceLoader.exists(before_path):
			before_icon.texture = load(before_path)
		before_icon.custom_minimum_size = Vector2(72, 72)
		before_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		before_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview_hbox.add_child(before_icon)

		var arrow_lbl := Label.new()
		arrow_lbl.text = "[ > ]"
		arrow_lbl.add_theme_font_override("font", font_silk)
		arrow_lbl.add_theme_font_size_override("font_size", 16)
		arrow_lbl.add_theme_color_override("font_color", Color(0, 0.94, 1.0))
		preview_hbox.add_child(arrow_lbl)

		var after_icon := TextureRect.new()
		var after_path: String = item["icon"]
		if item.get("type") == "weapon_skin":
			var wep_skin_path = "res://assets/sprites/skins/spr_%s_%s.png" % [item["target"], item["variant"]]
			if ResourceLoader.exists(wep_skin_path):
				after_path = wep_skin_path
		elif item.get("type") == "gem_skin":
			var gem_skin_path = "res://assets/sprites/skins/spr_gem_%s.png" % item["variant"]
			if ResourceLoader.exists(gem_skin_path):
				after_path = gem_skin_path

		if ResourceLoader.exists(after_path):
			after_icon.texture = load(after_path)
		if item.get("type") == "hero_skin" or after_path.begins_with("res://assets/sprites/skins/"):
			after_icon.modulate = Color.WHITE
		else:
			after_icon.modulate = item["accent"].lightened(0.35)
		after_icon.custom_minimum_size = Vector2(72, 72)
		after_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		after_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview_hbox.add_child(after_icon)

		var after_lbl := Label.new()
		after_lbl.text = "SETELAH"
		after_lbl.add_theme_font_override("font", font_tech)
		after_lbl.add_theme_font_size_override("font_size", 11)
		after_lbl.add_theme_color_override("font_color", item["accent"])
		preview_hbox.add_child(after_lbl)

		vbox.add_child(preview_hbox)
		
		# Short FX Tag
		var fx_lbl := Label.new()
		fx_lbl.text = "[ %s ]" % item["fx"]
		fx_lbl.add_theme_font_override("font", font_tech)
		fx_lbl.add_theme_font_size_override("font_size", 13)
		fx_lbl.add_theme_color_override("font_color", Color(0.98, 0.8, 0.08))
		fx_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(fx_lbl)
		
		# Cost & Button
		var is_unlocked = SaveManager.unlocked_items.has(item["id"])
		var is_equipped = false
		if item["type"] == "hero_skin":
			var hero_id: String = item["target"]
			is_equipped = (SaveManager.get_hero_skin(hero_id) == item["variant"])
		elif item["type"] == "weapon_skin":
			var wep_id: String = item["target"]
			is_equipped = (SaveManager.get_weapon_skin(wep_id) == item["variant"])
		elif item["type"] == "gem_skin":
			is_equipped = (SaveManager.equipped_gem_skin == item["variant"])
			
		var action_btn := Button.new()
		action_btn.custom_minimum_size = Vector2(280, 46)
		action_btn.add_theme_font_override("font", font_orb)
		action_btn.add_theme_font_size_override("font_size", 13)
		
		if not is_unlocked:
			var can_afford = (SaveManager.nano_credits >= item["cost"])
			if can_afford:
				action_btn.add_theme_stylebox_override("normal", sb_conf_n)
				action_btn.add_theme_stylebox_override("hover", sb_conf_h)
				action_btn.add_theme_font_override("font", font_silk)
				action_btn.add_theme_font_size_override("font_size", 14)
				action_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.15, 1))
				action_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
				action_btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.95, 0.15, 1))
				action_btn.add_theme_color_override("font_focus_color", Color(1, 1, 1, 1))
				action_btn.text = "BELI [ %d NC ]" % item["cost"]
				action_btn.pressed.connect(func():
					SaveManager.nano_credits -= item["cost"]
					SaveManager.unlocked_items.append(item["id"])
					SaveManager.save_game()
					if sfx_click: sfx_click.play()
					refresh_shop()
				)
			else:
				action_btn.add_theme_stylebox_override("normal", sb_sci_n)
				action_btn.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8, 0.7))
				action_btn.text = "BUTUH %d NC" % item["cost"]
				action_btn.pressed.connect(func():
					if sfx_click:
						sfx_click.pitch_scale = 0.65
						sfx_click.play()
						sfx_click.pitch_scale = 1.0
					var tw := action_btn.create_tween()
					tw.tween_property(action_btn, "modulate", Color(2.0, 0.5, 0.5), 0.08)
					tw.tween_property(action_btn, "modulate", Color(1, 1, 1), 0.12)
				)
		else:
			if is_equipped:
				var sb_active := StyleBoxFlat.new()
				sb_active.bg_color = Color(0.08, 0.22, 0.14, 0.95)
				sb_active.border_color = Color(0.13, 0.95, 0.4, 1.0)
				sb_active.set_border_width_all(2)
				sb_active.set_corner_radius_all(4)
				action_btn.add_theme_stylebox_override("normal", sb_active)
				action_btn.add_theme_stylebox_override("hover", sb_active)
				action_btn.add_theme_color_override("font_color", Color(0.13, 0.95, 0.4, 1))
				action_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
				action_btn.text = "[ AKTIF TERPASANG ] (LEPAS)"
				action_btn.pressed.connect(func():
					if item["type"] == "hero_skin":
						SaveManager.set_hero_skin(item["target"], "default")
					elif item["type"] == "weapon_skin":
						SaveManager.set_weapon_skin(item["target"], "default")
					elif item["type"] == "gem_skin":
						SaveManager.equipped_gem_skin = "core"
					SaveManager.save_game()
					if sfx_click: sfx_click.play()
					refresh_shop()
				)
			else:
				action_btn.add_theme_stylebox_override("normal", sb_sci_n)
				action_btn.add_theme_stylebox_override("hover", sb_sci_h)
				action_btn.add_theme_color_override("font_color", Color(0, 0.94, 1.0))
				action_btn.add_theme_color_override("font_hover_color", Color(0.98, 0.8, 0.08))
				action_btn.text = "[ PASANG KE LOADOUT ]"
				action_btn.pressed.connect(func():
					if item["type"] == "hero_skin":
						SaveManager.set_hero_skin(item["target"], item["variant"])
					elif item["type"] == "weapon_skin":
						SaveManager.set_weapon_skin(item["target"], item["variant"])
					elif item["type"] == "gem_skin":
						SaveManager.equipped_gem_skin = item["variant"]
					SaveManager.save_game()
					if sfx_click: sfx_click.play()
					refresh_shop()
				)
				
		vbox.add_child(action_btn)
		margin.add_child(vbox)
		panel.add_child(margin)
		items_grid.add_child(panel)

func refresh_runes() -> void:
	if credits_label:
		credits_label.text = "SALDO: %d NC" % SaveManager.nano_credits

	for child in offense_nodes_vbox.get_children():
		child.queue_free()
	for child in defense_nodes_vbox.get_children():
		child.queue_free()

	var font_orb = load("res://assets/fonts/Orbitron-Bold.ttf")
	var font_silk = load("res://assets/fonts/Silkscreen-Bold.ttf")
	var font_tech = load("res://assets/fonts/tech_font.ttf")

	var tex_conf_n = load("res://assets/ui/btn_confirm_normal.png")
	var tex_conf_h = load("res://assets/ui/btn_confirm_hover.png")
	var tex_sci_n = load("res://assets/ui/btn_sci_normal.png")
	var tex_sci_h = load("res://assets/ui/btn_sci_hover.png")

	var sb_conf_n = StyleBoxTexture.new(); sb_conf_n.texture = tex_conf_n; sb_conf_n.set_texture_margin_all(8)
	var sb_conf_h = StyleBoxTexture.new(); sb_conf_h.texture = tex_conf_h; sb_conf_h.set_texture_margin_all(8)
	var sb_sci_n = StyleBoxTexture.new(); sb_sci_n.texture = tex_sci_n; sb_sci_n.set_texture_margin_all(8)
	var sb_sci_h = StyleBoxTexture.new(); sb_sci_h.texture = tex_sci_h; sb_sci_h.set_texture_margin_all(8)

	for r in rune_defs:
		var target_vbox = offense_nodes_vbox if r["branch"] == "offense" else defense_nodes_vbox
		var cur_rank = SaveManager.runes.get(r["id"], 0)
		var is_max = (cur_rank >= r["max"])
		
		# Tech Tree Prerequisite Check
		var is_unlocked = (r["prereq"] == "" or SaveManager.runes.get(r["prereq"], 0) >= 1)

		var p := PanelContainer.new()
		p.custom_minimum_size = Vector2(780, 84)
		
		var style := StyleBoxFlat.new()
		if is_unlocked:
			style.bg_color = Color(0.05, 0.08, 0.14, 0.96)
			style.border_color = Color(0, 0.94, 1) if r["branch"] == "offense" else Color(0.13, 0.95, 0.4)
		else:
			style.bg_color = Color(0.02, 0.03, 0.05, 0.85)
			style.border_color = Color(0.35, 0.4, 0.5, 0.4)
		style.set_border_width_all(2)
		style.set_corner_radius_all(6)
		p.add_theme_stylebox_override("panel", style)
		
		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_left", 16)
		m.add_theme_constant_override("margin_right", 16)
		m.add_theme_constant_override("margin_top", 10)
		m.add_theme_constant_override("margin_bottom", 10)
		
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 16)
		
		# Lock or Rune Icon
		var icon_rect := TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(48, 48)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if not is_unlocked:
			icon_rect.texture = load("res://assets/ui/icon_lock.png")
		elif ResourceLoader.exists(r["icon"]):
			icon_rect.texture = load(r["icon"])
		h.add_child(icon_rect)
		
		var info_box := VBoxContainer.new()
		info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var title_lbl := Label.new()
		var tier_prefix = "[ TIER %d ] " % r.get("tier", 1)
		title_lbl.text = "%s%s  (%d/%d)" % [tier_prefix, r["name"], cur_rank, r["max"]]
		title_lbl.add_theme_font_override("font", font_orb)
		title_lbl.add_theme_font_size_override("font_size", 15)
		if not is_unlocked:
			title_lbl.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7, 0.8))
		elif is_max:
			title_lbl.add_theme_color_override("font_color", Color(0.98, 0.8, 0.08))
		else:
			title_lbl.add_theme_color_override("font_color", Color(0, 0.94, 1) if r["branch"] == "offense" else Color(0.13, 0.95, 0.4))
		info_box.add_child(title_lbl)
		
		var desc_lbl := Label.new()
		if not is_unlocked:
			desc_lbl.text = "🔒 TERKUNCI: Beli minimal 1 Rank pada Tier sebelumnya untuk membuka jalur ini!"
			desc_lbl.add_theme_color_override("font_color", Color(0.9, 0.35, 0.4, 0.9))
		else:
			desc_lbl.text = r["desc"]
			desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
		desc_lbl.add_theme_font_override("font", font_tech)
		desc_lbl.add_theme_font_size_override("font_size", 13)
		info_box.add_child(desc_lbl)
		
		h.add_child(info_box)
		
		var upg_btn := Button.new()
		upg_btn.custom_minimum_size = Vector2(230, 48)
		upg_btn.add_theme_font_override("font", font_silk)
		upg_btn.add_theme_font_size_override("font_size", 12)
		
		if not is_unlocked:
			upg_btn.add_theme_stylebox_override("normal", sb_sci_n)
			upg_btn.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
			upg_btn.text = "[ 🔒 TERKUNCI ]"
			upg_btn.disabled = true
		elif is_max:
			upg_btn.add_theme_stylebox_override("normal", sb_sci_n)
			upg_btn.add_theme_color_override("font_color", Color(0.13, 0.95, 0.4))
			upg_btn.text = "[ ★ MAX RANK ★ ]"
			upg_btn.disabled = true
		else:
			var can_buy = (SaveManager.nano_credits >= r["cost"])
			if can_buy:
				upg_btn.add_theme_stylebox_override("normal", sb_conf_n)
				upg_btn.add_theme_stylebox_override("hover", sb_conf_h)
				upg_btn.add_theme_font_override("font", font_silk)
				upg_btn.add_theme_font_size_override("font_size", 13)
				upg_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.15, 1))
				upg_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
				upg_btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.95, 0.15, 1))
				upg_btn.add_theme_color_override("font_focus_color", Color(1, 1, 1, 1))
				upg_btn.text = "+1 RANK [%d NC]" % r["cost"]
				upg_btn.pressed.connect(func():
					if SaveManager.buy_rune(r["id"], r["max"], r["cost"]):
						if sfx_click: sfx_click.play()
						refresh_runes()
				)
			else:
				upg_btn.add_theme_stylebox_override("normal", sb_sci_n)
				upg_btn.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8, 0.7))
				upg_btn.text = "BUTUH %d NC" % r["cost"]
				upg_btn.pressed.connect(func():
					if sfx_click:
						sfx_click.pitch_scale = 0.65
						sfx_click.play()
						sfx_click.pitch_scale = 1.0
				)
				
		h.add_child(upg_btn)
		m.add_child(h)
		p.add_child(m)
		target_vbox.add_child(p)

func _on_respec_pressed() -> void:
	if sfx_click: sfx_click.play()
	SaveManager.respec_runes()
	refresh_runes()
