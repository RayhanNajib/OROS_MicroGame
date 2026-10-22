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
	},
	{
		"id": "upg_heal",
		"title": "NANO RESTORATION",
		"desc": "Instantly heals +2 HP and permanently expands Max HP by +1.",
		"icon": "res://assets/sprites/spr_pickup_medkit.png"
	},
	{
		"id": "upg_vampire",
		"title": "VAMPIRIC CHIP",
		"desc": "5% chance on each robot kill to siphon energy and repair 1 HP.",
		"icon": "res://assets/sprites/upg_damage.png"
	},
	{
		"id": "upg_speed",
		"title": "NITRO ACTUATORS",
		"desc": "+25% Movement Speed and reduces kiting firing penalties.",
		"icon": "res://assets/sprites/upg_firerate.png"
	},
	{
		"id": "upg_magnet",
		"title": "MAGNETIC VORTEX",
		"desc": "+100% XP core magnetic attraction radius across the foundry.",
		"icon": "res://assets/sprites/upg_ammo.png"
	},
	{
		"id": "upg_explosive",
		"title": "PLASMA GRENADE",
		"desc": "Bullets detonate on impact with a 45px area-of-effect blast.",
		"icon": "res://assets/sprites/upg_multishot.png"
	},
	{
		"id": "upg_shield",
		"title": "REACTIVE ARMOR",
		"desc": "Reinforces chassis, reducing incoming contact damage by 1.",
		"icon": "res://assets/sprites/upg_piercing.png"
	}
]

var active_cards: Array[Dictionary] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.level_up_triggered.connect(_on_level_up)

func _input(event: InputEvent) -> void:
	if not visible: return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_1 and active_cards.size() >= 1:
			select_card(active_cards[0]["id"])
		elif event.keycode == KEY_2 and active_cards.size() >= 2:
			select_card(active_cards[1]["id"])
		elif event.keycode == KEY_3 and active_cards.size() >= 3:
			select_card(active_cards[2]["id"])

func _on_level_up() -> void:
	get_tree().paused = true
	visible = true
	if sfx_levelup:
		sfx_levelup.play()

	var pool_copy := upgrade_defs.duplicate()
	pool_copy.shuffle()
	active_cards = pool_copy.slice(0, 3)

	for child in cards_hbox.get_children():
		child.queue_free()

	# Staggered Poker Card Dealing Animation
	for i in range(active_cards.size()):
		var card := create_card_node(active_cards[i], i)
		cards_hbox.add_child(card)
		animate_poker_deal(card, i)

func animate_poker_deal(card: Control, index: int) -> void:
	card.modulate.a = 0.0
	card.position.y = 260.0
	card.scale = Vector2(0.7, 0.7)
	# Slight poker fan angle: left card -4 deg, center 0 deg, right +4 deg
	var fan_angle: float = deg_to_rad(-4.0 if index == 0 else (4.0 if index == 2 else 0.0))
	card.rotation = fan_angle
	
	var deal_delay := 0.12 + (float(index) * 0.16)
	var tw := card.create_tween()
	tw.tween_interval(deal_delay)
	tw.set_parallel(true)
	tw.tween_property(card, "position:y", 0.0, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "modulate:a", 1.0, 0.2)
	tw.tween_callback(func():
		if sfx_click:
			sfx_click.pitch_scale = 1.0 + float(index) * 0.15
			sfx_click.play()
	)

func create_card_node(data: Dictionary, slot_index: int = 0) -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(330, 440)
	btn.flat = true
	btn.pivot_offset = Vector2(165, 220)
	
	# Background Frame - Retro Pixel Border
	var bg_panel := Panel.new()
	bg_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.12, 0.96)
	style.border_color = Color(0.18, 0.65, 0.92, 0.85)
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	bg_panel.add_theme_stylebox_override("panel", style)
	btn.add_child(bg_panel)
	
	# Content Container
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	
	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var font_pixel = load("res://assets/fonts/PressStart2P-Regular.ttf")
	
	# Slot hotkey indicator
	var key_lbl := Label.new()
	key_lbl.text = "[ KARTU %d ]" % (slot_index + 1)
	key_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
	key_lbl.add_theme_font_override("font", font_pixel)
	key_lbl.add_theme_font_size_override("font_size", 10)
	key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(key_lbl)
	
	# Upgrade Icon
	var icon_rect := TextureRect.new()
	if ResourceLoader.exists(data["icon"]):
		icon_rect.texture = load(data["icon"])
	icon_rect.custom_minimum_size = Vector2(64, 64)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(icon_rect)
	
	# Title
	var title_lbl := Label.new()
	title_lbl.text = data["title"]
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	title_lbl.add_theme_font_override("font", font_pixel)
	title_lbl.add_theme_font_size_override("font_size", 11)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(title_lbl)
	
	# Description
	var desc_lbl := Label.new()
	desc_lbl.text = data["desc"]
	desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	desc_lbl.add_theme_font_override("font", font_pixel)
	desc_lbl.add_theme_font_size_override("font_size", 9)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)
	
	# Equip Hint
	var equip_lbl := Label.new()
	equip_lbl.text = "TEKAN [%d] ATAU KLIK" % (slot_index + 1)
	equip_lbl.add_theme_color_override("font_color", Color(0.55, 0.7, 0.85))
	equip_lbl.add_theme_font_override("font", font_pixel)
	equip_lbl.add_theme_font_size_override("font_size", 8)
	equip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(equip_lbl)
	
	margin.add_child(vbox)
	btn.add_child(margin)
	
	# Hover Animations - Poker Elevate
	btn.mouse_entered.connect(func():
		var tw := btn.create_tween()
		tw.set_parallel(true)
		tw.tween_property(btn, "position:y", -12.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		style.border_color = Color(1.0, 0.85, 0.2, 1.0)
		style.bg_color = Color(0.08, 0.14, 0.22, 0.98)
	)
	
	btn.mouse_exited.connect(func():
		var tw := btn.create_tween()
		tw.set_parallel(true)
		tw.tween_property(btn, "position:y", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		style.border_color = Color(0.18, 0.65, 0.92, 0.85)
		style.bg_color = Color(0.06, 0.08, 0.12, 0.95)
	)
	
	btn.pressed.connect(func():
		select_card(data["id"])
	)
	
	return btn

func select_card(upgrade_id: String) -> void:
	if sfx_click: sfx_click.play()
	apply_upgrade(upgrade_id)
	visible = false
	get_tree().paused = false

func apply_upgrade(upgrade_id: String) -> void:
	var gs = get_node_or_null("/root/GameState")
	if not gs: return
	
	match upgrade_id:
		"upg_damage":
			gs.bullet_damage = int(gs.bullet_damage * 1.3)
			gs.bullet_knockback *= 1.4
		"upg_firerate":
			gs.fire_rate = maxf(0.06, gs.fire_rate * 0.75)
			gs.reload_duration = maxf(0.45, gs.reload_duration * 0.8)
		"upg_multishot":
			gs.projectile_count += 1
			gs.projectile_spread += 0.08
		"upg_piercing":
			gs.bullet_pierce += 1
		"upg_ammo":
			gs.max_ammo += 3
			gs.ammo = gs.max_ammo
			gs.update_ammo_state(gs.ammo, gs.max_ammo, false, 0.0)
		"upg_freeze":
			gs.has_freeze = true
		"upg_lightning":
			gs.has_lightning = true
		"upg_saw":
			gs.has_orbital_saw = true
		"upg_heal":
			gs.max_health += 1
			gs.heal(2)
		"upg_vampire":
			gs.has_vampire_chip = true
		"upg_speed":
			gs.base_speed *= 1.25
		"upg_magnet":
			gs.pickup_radius *= 2.0
		"upg_explosive":
			gs.has_explosive_rounds = true
		"upg_shield":
			gs.max_health += 2
			gs.heal(2)
