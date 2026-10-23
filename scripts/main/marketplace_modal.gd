extends ColorRect

@onready var credits_label: Label = $CenterContainer/Panel/Margin/VBox/HeaderBox/CreditsLabel
@onready var items_container: GridContainer = $CenterContainer/Panel/Margin/VBox/Scroll/ItemsGrid
@onready var close_btn: Button = $CenterContainer/Panel/Margin/VBox/CloseBtn
@onready var sfx_click: AudioStreamPlayer = $SFXClick

var catalog: Array[Dictionary] = [
	# Hero Skins
	{
		"id": "skin_kael_crimson",
		"type": "hero_skin",
		"target": "kael",
		"variant": "crimson",
		"name": "KAEL: CRIMSON ANVIL",
		"desc": "Tema zirah pandai besi warna merah tua & aksen emas murni.",
		"cost": 150
	},
	{
		"id": "skin_vex_toxic",
		"type": "hero_skin",
		"target": "vex",
		"variant": "toxic",
		"name": "VEX: TOXIC MANTIS",
		"desc": "Syal & mata laser hijau bio-hazard untuk kamuflase asam.",
		"cost": 200
	},
	{
		"id": "skin_brutus_gold",
		"type": "hero_skin",
		"target": "brutus",
		"variant": "gold",
		"name": "BRUTUS: GOLD FORTRESS",
		"desc": "Plat baja sepuhan kuningan kilap dengan reactor dada cyan.",
		"cost": 250
	},
	# Weapon Skins
	{
		"id": "wep_revolver_gold",
		"type": "weapon_skin",
		"target": "revolver",
		"variant": "gold",
		"name": "REVOLVER: GOLD SOVEREIGN",
		"desc": "Laras revolver sepuhan emas murni 24 karat.",
		"cost": 150
	},
	{
		"id": "wep_shotgun_cyber",
		"type": "weapon_skin",
		"target": "shotgun",
		"variant": "cyber",
		"name": "SHOTGUN: CYBER BLAST",
		"desc": "Rel energi neon cyan futuristik pada laras ganda shotgun.",
		"cost": 180
	},
	{
		"id": "wep_smg_violet",
		"type": "weapon_skin",
		"target": "smg",
		"variant": "violet",
		"name": "SMG: HYPER VIOLET",
		"desc": "Sasis polimer ungu ultraviolet dengan laju tembak berpendar.",
		"cost": 180
	},
	# Custom Drop Loot Gems
	{
		"id": "gem_battery",
		"type": "gem_skin",
		"target": "battery",
		"variant": "battery",
		"name": "LOOT: HEX BATTERY CELL",
		"desc": "Mengubah bentuk core EXP musuh menjadi baterai mini bersinar.",
		"cost": 100
	},
	{
		"id": "gem_emerald",
		"type": "gem_skin",
		"target": "emerald",
		"variant": "emerald",
		"name": "LOOT: EMERALD CRYSTAL",
		"desc": "Mengubah core EXP menjadi pecahan kristal zamrud pixel.",
		"cost": 120
	}
]

func _ready() -> void:
	visible = false
	if close_btn:
		close_btn.pressed.connect(func():
			if sfx_click: sfx_click.play()
			visible = false
		)

func open_marketplace() -> void:
	visible = true
	if sfx_click: sfx_click.play()
	refresh_shop()

func refresh_shop() -> void:
	if credits_label:
		credits_label.text = "SALDO: %d NANO-CREDITS" % SaveManager.nano_credits
		
	if not items_container: return
	for child in items_container.get_children():
		child.queue_free()
		
	var font_orb = load("res://assets/fonts/Orbitron-Bold.ttf")
	var font_pix = load("res://assets/fonts/PixelifySans-Regular.ttf")
	
	for item in catalog:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(440, 160)
		
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.12, 0.18, 0.95)
		style.border_color = Color(0.18, 0.65, 0.92, 0.8)
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		panel.add_theme_stylebox_override("panel", style)
		
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 14)
		margin.add_theme_constant_override("margin_right", 14)
		margin.add_theme_constant_override("margin_top", 12)
		margin.add_theme_constant_override("margin_bottom", 12)
		
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		
		var name_lbl := Label.new()
		name_lbl.text = item["name"]
		name_lbl.add_theme_font_override("font", font_orb)
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
		vbox.add_child(name_lbl)
		
		var desc_lbl := Label.new()
		desc_lbl.text = item["desc"]
		desc_lbl.add_theme_font_override("font", font_pix)
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(desc_lbl)
		
		var hbox := HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var is_unlocked = SaveManager.unlocked_items.has(item["id"])
		var is_equipped = false
		if item["type"] == "hero_skin":
			is_equipped = (SaveManager.equipped_hero_skin == item["variant"])
		elif item["type"] == "weapon_skin":
			is_equipped = (SaveManager.equipped_weapon_skin == item["variant"])
		elif item["type"] == "gem_skin":
			is_equipped = (SaveManager.equipped_gem_skin == item["variant"])
			
		var action_btn := Button.new()
		action_btn.custom_minimum_size = Vector2(260, 38)
		action_btn.add_theme_font_override("font", font_pix)
		action_btn.add_theme_font_size_override("font_size", 11)
		
		if not is_unlocked:
			action_btn.text = "BELI [ %d NC ]" % item["cost"]
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
				
		hbox.add_child(action_btn)
		vbox.add_child(hbox)
		
		margin.add_child(vbox)
		panel.add_child(margin)
		items_container.add_child(panel)
