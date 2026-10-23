extends ColorRect

@onready var credits_label: Label = $CenterContainer/Panel/Margin/VBox/HeaderBox/CreditsLabel

@onready var shop_tab_btn: Button = $CenterContainer/Panel/Margin/VBox/TabButtons/ShopTabBtn
@onready var runes_tab_btn: Button = $CenterContainer/Panel/Margin/VBox/TabButtons/RunesTabBtn

@onready var shop_container: Control = $CenterContainer/Panel/Margin/VBox/ShopContainer
@onready var items_grid: GridContainer = $CenterContainer/Panel/Margin/VBox/ShopContainer/Scroll/ItemsGrid

@onready var runes_container: Control = $CenterContainer/Panel/Margin/VBox/RunesContainer
@onready var offense_nodes_vbox: VBoxContainer = $CenterContainer/Panel/Margin/VBox/RunesContainer/TreeHBox/OffenseBranch/NodesVBox
@onready var defense_nodes_vbox: VBoxContainer = $CenterContainer/Panel/Margin/VBox/RunesContainer/TreeHBox/DefenseBranch/NodesVBox

@onready var respec_btn: Button = $CenterContainer/Panel/Margin/VBox/BottomBar/RespecBtn
@onready var close_btn: Button = $CenterContainer/Panel/Margin/VBox/BottomBar/CloseBtn

@onready var sfx_click: AudioStreamPlayer = $SFXClick

# Compact Visual Catalog (Blue / Yellow / Green theme)
var catalog: Array[Dictionary] = [
	# Hero Skins
	{
		"id": "skin_kael_cobalt",
		"type": "hero_skin",
		"target": "kael",
		"variant": "crimson",
		"name": "KAEL: COBALT ANVIL",
		"fx": "Pulsa Cyan Neon",
		"icon": "res://assets/sprites/avatar_kael.png",
		"cost": 150,
		"accent": Color(0, 0.94, 1.0)
	},
	{
		"id": "skin_vex_toxic",
		"type": "hero_skin",
		"target": "vex",
		"variant": "toxic",
		"name": "VEX: ACID MANTIS",
		"fx": "Trail Asap Emerald",
		"icon": "res://assets/sprites/avatar_vex.png",
		"cost": 200,
		"accent": Color(0.13, 0.95, 0.4)
	},
	{
		"id": "skin_brutus_gold",
		"type": "hero_skin",
		"target": "brutus",
		"variant": "gold",
		"name": "BRUTUS: TITAN GOLD",
		"fx": "Spark Listrik Emas",
		"icon": "res://assets/sprites/avatar_brutus.png",
		"cost": 250,
		"accent": Color(0.98, 0.8, 0.08)
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
		"cost": 150,
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
		"cost": 180,
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
		"cost": 180,
		"accent": Color(0.13, 0.95, 0.4)
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
		"cost": 100,
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
		"cost": 120,
		"accent": Color(0.13, 0.95, 0.4)
	}
]

var rune_defs: Array[Dictionary] = [
	# Offense
	{"id": "cyber_caliber", "branch": "offense", "name": "CYBER CALIBER", "desc": "+5% Bullet DMG per rank", "max": 5, "cost": 50},
	{"id": "rapid_vent", "branch": "offense", "name": "RAPID VENT", "desc": "-5% Reload Time per rank", "max": 5, "cost": 50},
	{"id": "heavy_impulse", "branch": "offense", "name": "HEAVY IMPULSE", "desc": "+15% Knockback per rank", "max": 5, "cost": 50},
	{"id": "plasma_pierce", "branch": "offense", "name": "PLASMA PIERCE", "desc": "+1 Peluru Tembus (Pierce)", "max": 3, "cost": 100},

	# Defense
	{"id": "titan_alloy", "branch": "defense", "name": "TITAN ALLOY", "desc": "+1 Max Health per rank", "max": 5, "cost": 50},
	{"id": "ion_stride", "branch": "defense", "name": "ION STRIDE", "desc": "+4% Kecepatan Lari per rank", "max": 5, "cost": 50},
	{"id": "melee_leech", "branch": "defense", "name": "MELEE LEECH", "desc": "+25% Melee Heal Drop Rate", "max": 3, "cost": 100},
	{"id": "overclock_core", "branch": "defense", "name": "OVERCLOCK CORE", "desc": "-10% Skill Cooldown per rank", "max": 3, "cost": 100}
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

func switch_tab(tab_idx: int) -> void:
	active_tab = tab_idx
	if sfx_click: sfx_click.play()
	if active_tab == 1:
		shop_container.visible = true
		runes_container.visible = false
		refresh_shop()
	else:
		shop_container.visible = false
		runes_container.visible = true
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
		
		# Icon / Sprite visual box
		var icon_rect := TextureRect.new()
		if ResourceLoader.exists(item["icon"]):
			icon_rect.texture = load(item["icon"])
		icon_rect.custom_minimum_size = Vector2(80, 80)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vbox.add_child(icon_rect)
		
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
			is_equipped = (SaveManager.equipped_hero_skin == item["variant"])
		elif item["type"] == "weapon_skin":
			is_equipped = (SaveManager.equipped_weapon_skin == item["variant"])
		elif item["type"] == "gem_skin":
			is_equipped = (SaveManager.equipped_gem_skin == item["variant"])
			
		var action_btn := Button.new()
		action_btn.custom_minimum_size = Vector2(280, 46)
		action_btn.add_theme_font_override("font", font_orb)
		action_btn.add_theme_font_size_override("font_size", 13)
		
		if not is_unlocked:
			action_btn.text = "BELI [ %d NC ]" % item["cost"]
			action_btn.add_theme_font_override("font", font_silk)
			action_btn.add_theme_font_size_override("font_size", 14)
			action_btn.pressed.connect(func():
				if SaveManager.nano_credits >= item["cost"]:
					SaveManager.nano_credits -= item["cost"]
					SaveManager.unlocked_items.append(item["id"])
					SaveManager.save_game()
					if sfx_click: sfx_click.play()
					refresh_shop()
			)
		else:
			if is_equipped:
				action_btn.text = "[ SEDANG TERPASANG ]"
				action_btn.disabled = true
			else:
				action_btn.text = "[ PASANG SEKARANG ]"
				action_btn.pressed.connect(func():
					if item["type"] == "hero_skin":
						SaveManager.equipped_hero_skin = item["variant"]
					elif item["type"] == "weapon_skin":
						SaveManager.equipped_weapon_skin = item["variant"]
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

	for r in rune_defs:
		var target_vbox = offense_nodes_vbox if r["branch"] == "offense" else defense_nodes_vbox
		var cur_rank = SaveManager.runes.get(r["id"], 0)
		var is_max = (cur_rank >= r["max"])

		var p := PanelContainer.new()
		p.custom_minimum_size = Vector2(780, 80)
		
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.06, 0.09, 0.14, 0.96)
		style.border_color = Color(0, 0.94, 1) if r["branch"] == "offense" else Color(0.13, 0.95, 0.4)
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		p.add_theme_stylebox_override("panel", style)
		
		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_left", 16)
		m.add_theme_constant_override("margin_right", 16)
		m.add_theme_constant_override("margin_top", 10)
		m.add_theme_constant_override("margin_bottom", 10)
		
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 16)
		
		var info_box := VBoxContainer.new()
		info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var title_lbl := Label.new()
		title_lbl.text = "%s  (%d/%d)" % [r["name"], cur_rank, r["max"]]
		title_lbl.add_theme_font_override("font", font_orb)
		title_lbl.add_theme_font_size_override("font_size", 15)
		title_lbl.add_theme_color_override("font_color", Color(0.98, 0.8, 0.08) if is_max else (Color(0, 0.94, 1) if r["branch"] == "offense" else Color(0.13, 0.95, 0.4)))
		info_box.add_child(title_lbl)
		
		var desc_lbl := Label.new()
		desc_lbl.text = r["desc"]
		desc_lbl.add_theme_font_override("font", font_tech)
		desc_lbl.add_theme_font_size_override("font_size", 14)
		desc_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
		info_box.add_child(desc_lbl)
		
		h.add_child(info_box)
		
		var upg_btn := Button.new()
		upg_btn.custom_minimum_size = Vector2(220, 46)
		upg_btn.add_theme_font_override("font", font_silk)
		upg_btn.add_theme_font_size_override("font_size", 12)
		
		if is_max:
			upg_btn.text = "[ MAX RANK ]"
			upg_btn.disabled = true
		else:
			upg_btn.text = "+1 RANK [%d NC]" % r["cost"]
			upg_btn.disabled = (SaveManager.nano_credits < r["cost"])
			upg_btn.pressed.connect(func():
				if SaveManager.buy_rune(r["id"], r["max"], r["cost"]):
					if sfx_click: sfx_click.play()
					refresh_runes()
			)
			
		h.add_child(upg_btn)
		m.add_child(h)
		p.add_child(m)
		target_vbox.add_child(p)

func _on_respec_pressed() -> void:
	if sfx_click: sfx_click.play()
	SaveManager.respec_runes()
	refresh_runes()