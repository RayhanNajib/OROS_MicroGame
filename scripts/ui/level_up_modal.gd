extends CanvasLayer

@onready var container: PanelContainer = $CenterContainer/PanelContainer
@onready var cards_hbox: HBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBox/CardsHBox
@onready var sfx_levelup: AudioStreamPlayer = $SFXLevelUp
@onready var sfx_click: AudioStreamPlayer = $SFXClick

var upgrade_defs: Array[Dictionary] = [
	{
		"id": "upg_damage",
		"title": "OVERCLOCK CORE",
		"desc": "+30% Bullet Damage & +40% Knockback force against robot hordes.",
		"icon": "res://assets/sprites/upg_damage.png"
	},
	{
		"id": "upg_firerate",
		"title": "RAPID CAPACITOR",
		"desc": "+25% Fire Rate and -20% Reload Duration.",
		"icon": "res://assets/sprites/upg_firerate.png"
	},
	{
		"id": "upg_multishot",
		"title": "SPREAD EMITTER",
		"desc": "+1 Additional Projectile per shot in a tight fan pattern.",
		"icon": "res://assets/sprites/upg_multishot.png"
	},
	{
		"id": "upg_piercing",
		"title": "TUNGSTEN SHARDS",
		"desc": "Bullets penetrate and pierce through +1 enemy.",
		"icon": "res://assets/sprites/upg_piercing.png"
	},
	{
		"id": "upg_ammo",
		"title": "EXPANDED DRUM",
		"desc": "+3 Max Ammo capacity and instant full magazine reload.",
		"icon": "res://assets/sprites/upg_ammo.png"
	},
	{
		"id": "upg_freeze",
		"title": "CRYO ROUNDS",
		"desc": "Bullets freeze enemies on hit, slowing movement by 50% for 2.0s.",
		"icon": "res://assets/sprites/upg_freeze.png"
	},
	{
		"id": "upg_lightning",
		"title": "TESLA ARC",
		"desc": "Bullet impacts trigger chain lightning striking 2 nearby enemies.",
		"icon": "res://assets/sprites/upg_lightning.png"
	},
	{
		"id": "upg_saw",
		"title": "ORBITAL PLASMA SAW",
		"desc": "Spawns a spinning plasma blade that circles around Kael dealing constant damage.",
		"icon": "res://assets/sprites/upg_saw.png"
	}
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.level_up_triggered.connect(_on_level_up)

func _on_level_up() -> void:
	get_tree().paused = true
	visible = true
	if sfx_levelup:
		sfx_levelup.play()

	var pool_copy := upgrade_defs.duplicate()
	pool_copy.shuffle()
	var selected_three := pool_copy.slice(0, 3)

	for child in cards_hbox.get_children():
		child.queue_free()

	for item in selected_three:
		var card := create_card_node(item)
		cards_hbox.add_child(card)

func create_card_node(data: Dictionary) -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(170, 220)
	
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.theme_override_constants.separation = 8
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var icon_rect := TextureRect.new()
	icon_rect.texture = load(data["icon"])
	icon_rect.custom_minimum_size = Vector2(48, 48)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(icon_rect)
	
	var title_lbl := Label.new()
	title_lbl.text = data["title"]
	title_lbl.theme_override_colors.font_color = Color(1.0, 0.88, 0.25)
	title_lbl.theme_override_font_sizes.font_size = 11
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(title_lbl)
	
	var desc_lbl := Label.new()
	desc_lbl.text = data["desc"]
	desc_lbl.theme_override_colors.font_color = Color(0.85, 0.9, 0.98)
	desc_lbl.theme_override_font_sizes.font_size = 9
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)
	
	btn.add_child(vbox)
	
	btn.pressed.connect(func():
		if sfx_click: sfx_click.play()
		apply_upgrade(data["id"])
		visible = false
		get_tree().paused = false
	)
	
	return btn

func apply_upgrade(upgrade_id: String) -> void:
	var gs = get_node_or_null("/root/GameState")
	if not gs: return
	
	match upgrade_id:
		"upg_damage":
			gs.bullet_damage = int(gs.bullet_damage * 1.3)
			gs.bullet_knockback *= 1.4
		"upg_firerate":
			gs.fire_rate = maxf(0.1, gs.fire_rate * 0.75)
			gs.reload_duration = maxf(0.5, gs.reload_duration * 0.8)
		"upg_multishot":
			gs.projectile_count += 1
			gs.projectile_spread += 0.08
		"upg_piercing":
			gs.bullet_pierce += 1
		"upg_ammo":
			gs.max_ammo += 3
			gs.ammo = gs.max_ammo
			gs.emit_signal("ammo_changed", gs.ammo, gs.max_ammo, false, 0.0)
		"upg_freeze":
			gs.has_freeze = true
		"upg_lightning":
			gs.has_lightning = true
		"upg_saw":
			gs.has_orbital_saw = true
