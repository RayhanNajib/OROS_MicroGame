extends CanvasLayer

@onready var container: PanelContainer = $CenterContainer/PanelContainer
@onready var cards_hbox: HBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBox/CardsHBox
@onready var confirm_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBox/ConfirmHBox/ConfirmBtn
@onready var sfx_tome: AudioStreamPlayer = $SFXTomeOpen
@onready var sfx_click: AudioStreamPlayer = $SFXClick

var tome_defs: Array[Dictionary] = [
	{
		"id": "tome_vitality",
		"title": "TOME OF VITALITY",
		"icon": "res://assets/sprites/tomes/tome_vitality.png",
		"pros": ["• MAX HEALTH +4 DARAH", "• SASIS TUMBUH RAKSASA +35%"],
		"cons": ["• KECEPATAN LARI -25%"],
		"desc": "Mentransformasi operative menjadi raksasa siber berkekuatan titan dengan sasis kokoh berlapis baja."
	},
	{
		"id": "tome_might",
		"title": "TOME OF MIGHT",
		"icon": "res://assets/sprites/tomes/tome_might.png",
		"pros": ["• MAX HEALTH +1 DARAH", "• BONUS +2 DAMAGE PER POIN MAX HP", "• UKURAN FISIK +15%"],
		"cons": ["• KECEPATAN LARI -10%"],
		"desc": "Menyalurkan daya ledak kinetik proporsional dengan kapasitas sasis operative."
	},
	{
		"id": "tome_speed",
		"title": "TOME OF SPEED",
		"icon": "res://assets/sprites/tomes/tome_speed.png",
		"pros": ["• KECEPATAN LARI +50%", "• PROFIL TUBUH RAMPING -15%"],
		"cons": ["• MAX HEALTH -1 DARAH"],
		"desc": "Memangkas bobot sasis ke batas minimum untuk manuver kiting ultra-lincah."
	},
	{
		"id": "tome_power",
		"title": "TOME OF POWER",
		"icon": "res://assets/sprites/tomes/tome_power.png",
		"pros": ["• BULLET DAMAGE +50%", "• UKURAN PELURU +100%", "• PELURU TEMBUS +1 PIERCE"],
		"cons": ["• LAJU TEMBAK -25%", "• MAX HEALTH -1 DARAH"],
		"desc": "Mengonsentrasikan seluruh daya reaktor ke dalam proyektil plasma masif penghancur horde."
	},
	{
		"id": "tome_rage",
		"title": "TOME OF RAGE",
		"icon": "res://assets/sprites/tomes/tome_rage.png",
		"pros": ["• LAJU TEMBAK +60% LEBIH CEPAT", "• KAPASITAS AMUNISI BERLIPAT x3!"],
		"cons": ["• DAMAGE PELURU -50%", "• GAYA TOLAK KNOCKBACK -95%"],
		"desc": "Mode amukan tak terbatas: semprotan peluru tiada henti bagaikan badai timah panas."
	},
	{
		"id": "tome_glass",
		"title": "TOME OF GLASS",
		"icon": "res://assets/sprites/tomes/tome_glass.png",
		"pros": ["• SELURUH DAMAGE BERLIPAT GANDA (+100%)", "• EFISIENSI TEMPUR MAKSIMAL"],
		"cons": ["• DARAH TERKUNCI 1 HP (1 HIT LANGSUNG MATI!)"],
		"desc": "Protokol Glass Cannon murni: kehancuran mutlak bagi musuh, namun 1 sentuhan fatal bagimu."
	},
	{
		"id": "tome_electro",
		"title": "TOME OF ELECTRO",
		"icon": "res://assets/sprites/tomes/tome_electro.png",
		"pros": ["• RELOAD RATE +25% LEBIH CEPAT", "• PELURU TERAKHIR MENYAMBAR PETIR 40 DMG!"],
		"cons": ["• BASE BULLET DAMAGE -16%"],
		"desc": "Mengalirkan muatan statis ke ruang magasin; tembakan terakhir memanggil petir katastropik."
	},
	{
		"id": "tome_elements",
		"title": "TOME OF ELEMENTS",
		"icon": "res://assets/sprites/tomes/tome_elements.png",
		"pros": ["• MEMBUKA EFEK CRYO ES (FREEZE)", "• MEMBUKA PETIR TESLA RANTAI"],
		"cons": ["• KNOCKBACK PELURU FISIK -30%"],
		"desc": "Menggabungkan dua elemen kehancuran: peluru kini mampu membekukan target sekaligus menyalurkan sengatan petir rantai ke musuh sekitar."
	},
	{
		"id": "tome_elasticity",
		"title": "TOME OF ELASTICITY",
		"icon": "res://assets/sprites/tomes/tome_elasticity.png",
		"pros": ["• PELURU TEMBUS +3 PIERCE", "• GAYA TOLAK KNOCKBACK +50%"],
		"cons": ["• BULLET DAMAGE -25%", "• MAX HEALTH -1 DARAH"],
		"desc": "Peluru berbahan polimer memantul dan menembus kerumunan horde secara impulsif."
	},
	{
		"id": "tome_stillness",
		"title": "TOME OF STILLNESS",
		"icon": "res://assets/sprites/tomes/tome_stillness.png",
		"pros": ["• BULLET DAMAGE +100%!", "• UKURAN PELURU +50%", "• +2 PROYEKTIL EKSTRA EKSPANSI", "• UKURAN TUBUH +25%"],
		"cons": ["• KECEPATAN LARI -75% (MODE BENTENG STATIS)"],
		"desc": "Menancapkan sasis ke tanah menjadi kubah tembak artileri tak tergoyahkan."
	},
	{
		"id": "tome_summoning",
		"title": "TOME OF SUMMONING",
		"icon": "res://assets/sprites/tomes/tome_summoning.png",
		"pros": ["• PLASMA SAW AKTIF OTOMATIS", "• DAMAGE GERGAJI ORBITAL BERLIPAT x2 (+100%)"],
		"cons": ["• DURASI RELOAD +30%"],
		"desc": "Memanggil cincin bilah gergaji plasma kembar yang berputar konstan mencabik musuh dekat."
	},
	{
		"id": "tome_wind",
		"title": "TOME OF WIND",
		"icon": "res://assets/sprites/tomes/tome_wind.png",
		"pros": ["• KECEPATAN GERAK +25%", "• DAMAGE BERTAMBAH SEIRING KECEPATAN LARI"],
		"cons": ["• KECEPATAN TERBANG PELURU -20%"],
		"desc": "Harmonisasi aerodinamis siber: semakin cepat operative berlari, semakin destruktif tembakannya."
	}
]

var active_tomes: Array[Dictionary] = []
var card_nodes: Array[Control] = []
var selected_slot_index: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	add_to_group("tome_modal")
	
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.tome_modal_triggered.connect(open_modal)
		
	if confirm_btn:
		setup_confirm_btn()

func setup_confirm_btn() -> void:
	confirm_btn.pressed.connect(_on_confirm_pressed)
	var font_orb = load("res://assets/fonts/Orbitron-Bold.ttf")
	confirm_btn.add_theme_font_override("font", font_orb)
	confirm_btn.add_theme_font_size_override("font_size", 20)
	confirm_btn.add_theme_color_override("font_color", Color(0.98, 0.85, 0.12, 1))
	confirm_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	confirm_btn.add_theme_color_override("font_pressed_color", Color(0.98, 0.85, 0.12, 1))
	confirm_btn.add_theme_color_override("font_focus_color", Color(1, 1, 1, 1))
	confirm_btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.55, 0.65, 0.8))
	
	var tex_n = load("res://assets/ui/btn_confirm_normal.png")
	var tex_h = load("res://assets/ui/btn_confirm_hover.png")
	var tex_p = load("res://assets/ui/btn_confirm_pressed.png")
	if tex_n and tex_h and tex_p:
		var sb_n = StyleBoxTexture.new(); sb_n.texture = tex_n; sb_n.set_texture_margin_all(8)
		var sb_h = StyleBoxTexture.new(); sb_h.texture = tex_h; sb_h.set_texture_margin_all(8)
		var sb_p = StyleBoxTexture.new(); sb_p.texture = tex_p; sb_p.set_texture_margin_all(8)
		confirm_btn.add_theme_stylebox_override("normal", sb_n)
		confirm_btn.add_theme_stylebox_override("hover", sb_h)
		confirm_btn.add_theme_stylebox_override("pressed", sb_p)

func _input(event: InputEvent) -> void:
	if not visible: return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_1 and active_tomes.size() >= 1:
			highlight_card(0)
		elif event.keycode == KEY_2 and active_tomes.size() >= 2:
			highlight_card(1)
		elif event.keycode == KEY_3 and active_tomes.size() >= 3:
			highlight_card(2)
		elif (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE) and selected_slot_index >= 0:
			_on_confirm_pressed()
	elif event is InputEventJoypadButton and event.is_pressed():
		if event.button_index == JOY_BUTTON_DPAD_LEFT:
			highlight_card(0)
		elif event.button_index == JOY_BUTTON_DPAD_RIGHT:
			highlight_card(mini(1, active_tomes.size() - 1))
		elif event.button_index == JOY_BUTTON_A and selected_slot_index >= 0:
			_on_confirm_pressed()

func open_modal() -> void:
	get_tree().paused = true
	visible = true
	selected_slot_index = -1
	
	if has_node("/root/InputManager"):
		get_node("/root/InputManager").vibrate_tome_open()
	
	if sfx_tome:
		sfx_tome.play()
		
	pick_random_tomes()
	render_cards()
	
	if confirm_btn:
		confirm_btn.disabled = true
		confirm_btn.text = "[ PILIH 1 CYBER TOME DI ATAS ]"
		confirm_btn.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65, 0.8))

func pick_random_tomes() -> void:
	active_tomes.clear()
	var pool = tome_defs.duplicate()
	pool.shuffle()
	# Pick 2 complementary Tomes for the Left & Right open pages
	for i in range(mini(2, pool.size())):
		active_tomes.append(pool[i])

func render_cards() -> void:
	if not cards_hbox: return
	for child in cards_hbox.get_children():
		child.queue_free()
	card_nodes.clear()
	
	for i in range(active_tomes.size()):
		var card = create_tome_card(active_tomes[i], i)
		cards_hbox.add_child(card)
		card_nodes.append(card)
		animate_book_page_open(card, i)

func animate_book_page_open(card: Control, index: int) -> void:
	# True Book Opening Animation:
	# Left page (index 0) hinges from its right edge (spine)
	# Right page (index 1) hinges from its left edge (spine)
	card.modulate.a = 0.0
	card.scale = Vector2(0.05, 0.9)
	if index == 0:
		card.pivot_offset = Vector2(560, 280)
		card.rotation = deg_to_rad(-8.0)
	else:
		card.pivot_offset = Vector2(0, 280)
		card.rotation = deg_to_rad(8.0)
		
	var tw := card.create_tween()
	tw.set_parallel(true)
	tw.tween_property(card, "scale:x", 1.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "scale:y", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "rotation", 0.0, 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "modulate:a", 1.0, 0.25)

func create_tome_card(data: Dictionary, slot_index: int) -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(580, 580)
	btn.flat = true
	
	var page_tag = "[ HALAMAN KIRI // KODEX I ]" if slot_index == 0 else "[ HALAMAN KANAN // KODEX II ]"
	
	var bg_panel := PanelContainer.new()
	bg_panel.name = "BGFrame"
	bg_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var sb := StyleBoxTexture.new()
	sb.texture = load("res://assets/ui/card_frame_legendary.png")
	sb.texture_margin_left = 18.0
	sb.texture_margin_top = 18.0
	sb.texture_margin_right = 18.0
	sb.texture_margin_bottom = 18.0
	bg_panel.add_theme_stylebox_override("panel", sb)
	btn.add_child(bg_panel)
	
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 16)
	
	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 8)
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	
	var font_orb = load("res://assets/fonts/Orbitron-Bold.ttf")
	var font_silk = load("res://assets/fonts/Silkscreen-Bold.ttf")
	var font_tech = load("res://assets/fonts/tech_font.ttf")
	
	# Glowing Grimoire Book Icon (Raised to top of card)
	var icon_rect := TextureRect.new()
	icon_rect.texture = load(data["icon"])
	icon_rect.custom_minimum_size = Vector2(110, 110)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(icon_rect)

	# Header Badge
	var badge_lbl := Label.new()
	badge_lbl.text = page_tag
	badge_lbl.add_theme_color_override("font_color", Color(0.98, 0.85, 0.12))
	badge_lbl.add_theme_font_override("font", font_silk)
	badge_lbl.add_theme_font_size_override("font_size", 12)
	badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(badge_lbl)
	
	# Tome Title
	var title_lbl := Label.new()
	title_lbl.text = data["title"]
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.15))
	title_lbl.add_theme_font_override("font", font_orb)
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)
	
	# Pros (Green)
	var pros_box := VBoxContainer.new()
	pros_box.add_theme_constant_override("separation", 3)
	for p in data["pros"]:
		var pl := Label.new()
		pl.text = p
		pl.add_theme_color_override("font_color", Color(0.13, 0.95, 0.4))
		pl.add_theme_font_override("font", font_silk)
		pl.add_theme_font_size_override("font_size", 15)
		pl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pros_box.add_child(pl)
	vbox.add_child(pros_box)
	
	# Cons (Warning Amber/Gold)
	var cons_box := VBoxContainer.new()
	cons_box.add_theme_constant_override("separation", 3)
	for c in data["cons"]:
		var cl := Label.new()
		cl.text = c
		cl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.2))
		cl.add_theme_font_override("font", font_silk)
		cl.add_theme_font_size_override("font_size", 15)
		cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cons_box.add_child(cl)
	vbox.add_child(cons_box)
	
	# Description Lore
	var desc_lbl := Label.new()
	desc_lbl.text = data["desc"]
	desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	desc_lbl.add_theme_font_override("font", font_tech)
	desc_lbl.add_theme_font_size_override("font_size", 16)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc_lbl)
	
	# Status Indicator
	var status_lbl := Label.new()
	status_lbl.name = "StatusLabel"
	status_lbl.text = "KLIK UNTUK MEMILIH"
	status_lbl.add_theme_color_override("font_color", Color(0.6, 0.75, 0.9))
	status_lbl.add_theme_font_override("font", font_orb)
	status_lbl.add_theme_font_size_override("font_size", 15)
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(status_lbl)
	
	margin.add_child(vbox)
	btn.add_child(margin)
	
	btn.pressed.connect(func():
		highlight_card(slot_index)
	)
	
	return btn

func highlight_card(index: int) -> void:
	if index < 0 or index >= active_tomes.size(): return
	selected_slot_index = index
	if sfx_click: sfx_click.play()
	if has_node("/root/InputManager"):
		get_node("/root/InputManager").vibrate_ui_card_select()
	
	for i in range(card_nodes.size()):
		var c = card_nodes[i]
		var status_lbl = c.find_child("StatusLabel", true, false) as Label
		
		if i == index:
			c.modulate = Color(1.0, 1.0, 1.0, 1.0)
			c.scale = Vector2(1.04, 1.04)
			c.position.y = -6.0
			if status_lbl:
				status_lbl.text = "[ TERPILIH // SIAP INSKRIPSI ]"
				status_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.15))
		else:
			c.modulate = Color(0.7, 0.75, 0.85, 0.6)
			c.scale = Vector2.ONE
			c.position.y = 0.0
			if status_lbl:
				status_lbl.text = "KLIK UNTUK MEMILIH"
				status_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
				
	if confirm_btn:
		confirm_btn.disabled = false
		var tome_title: String = active_tomes[index]["title"]
		confirm_btn.text = "[ > INSKRIPSI TOME: %s < ] (ENTER)" % tome_title
		confirm_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.15, 1))
		confirm_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))

func _on_confirm_pressed() -> void:
	if selected_slot_index < 0 or selected_slot_index >= active_tomes.size(): return
	var tome_data = active_tomes[selected_slot_index]
	if sfx_click: sfx_click.play()
	if has_node("/root/InputManager"):
		get_node("/root/InputManager").vibrate_ui_card_confirm(true)
	
	apply_tome_effect(tome_data["id"])
		
	visible = false
	get_tree().paused = false

func apply_tome_effect(tome_id: String) -> void:
	var gs = get_node_or_null("/root/GameState")
	if not gs: return
	
	match tome_id:
		"tome_vitality":
			gs.max_health += 4
			gs.heal(4)
			if gs.is_coop_mode:
				gs.p2_max_health += 4
				gs.heal_p2(4)
			gs.base_speed *= 0.75
			gs.player_scale_mult *= 1.35
		"tome_might":
			gs.max_health += 1
			gs.heal(1)
			if gs.is_coop_mode:
				gs.p2_max_health += 1
				gs.heal_p2(1)
			gs.bullet_damage += (gs.max_health * 2)
			gs.base_speed *= 0.90
			gs.player_scale_mult *= 1.15
		"tome_speed":
			gs.base_speed *= 1.50
			gs.max_health = maxi(1, gs.max_health - 1)
			gs.health = mini(gs.health, gs.max_health)
			gs.player_scale_mult *= 0.85
			gs.health_changed.emit(gs.health, gs.max_health)
			if gs.is_coop_mode:
				gs.p2_max_health = maxi(1, gs.p2_max_health - 1)
				gs.p2_health = mini(gs.p2_health, gs.p2_max_health)
				gs.p2_health_changed.emit(gs.p2_health, gs.p2_max_health)
		"tome_power":
			gs.bullet_damage = int(gs.bullet_damage * 1.5)
			gs.bullet_pierce += 1
			gs.fire_rate *= 1.25
			gs.max_health = maxi(1, gs.max_health - 1)
			gs.health = mini(gs.health, gs.max_health)
			gs.health_changed.emit(gs.health, gs.max_health)
			if gs.is_coop_mode:
				gs.p2_max_health = maxi(1, gs.p2_max_health - 1)
				gs.p2_health = mini(gs.p2_health, gs.p2_max_health)
				gs.p2_health_changed.emit(gs.p2_health, gs.p2_max_health)
		"tome_rage":
			gs.fire_rate = maxf(0.04, gs.fire_rate * 0.40)
			gs.max_ammo *= 3
			gs.ammo = gs.max_ammo
			gs.bullet_damage = maxi(3, int(gs.bullet_damage * 0.5))
			gs.bullet_knockback *= 0.05
			gs.update_ammo_state(gs.ammo, gs.max_ammo, false, 0.0)
			if gs.is_coop_mode:
				gs.p2_max_ammo *= 3
				gs.p2_ammo = gs.p2_max_ammo
				gs.update_p2_ammo_state(gs.p2_ammo, gs.p2_max_ammo, false, 0.0)
		"tome_glass":
			gs.has_tome_glass = true
			gs.bullet_damage *= 2
			gs.max_health = 1
			gs.health = 1
			gs.health_changed.emit(1, 1)
			if gs.is_coop_mode:
				gs.p2_max_health = 1
				gs.p2_health = 1
				gs.p2_health_changed.emit(1, 1)
		"tome_electro":
			gs.has_tome_electro = true
			gs.reload_duration = maxf(0.4, gs.reload_duration * 0.75)
			gs.bullet_damage = maxi(4, int(gs.bullet_damage * 0.84))
		"tome_elements":
			gs.has_freeze = true
			gs.has_lightning = true
			gs.bullet_knockback *= 0.70
		"tome_elasticity":
			gs.bullet_pierce += 3
			gs.bullet_knockback *= 1.50
			gs.bullet_damage = maxi(3, int(gs.bullet_damage * 0.75))
			gs.max_health = maxi(1, gs.max_health - 1)
			gs.health = mini(gs.health, gs.max_health)
			gs.health_changed.emit(gs.health, gs.max_health)
			if gs.is_coop_mode:
				gs.p2_max_health = maxi(1, gs.p2_max_health - 1)
				gs.p2_health = mini(gs.p2_health, gs.p2_max_health)
				gs.p2_health_changed.emit(gs.p2_health, gs.p2_max_health)
		"tome_stillness":
			gs.has_tome_stillness = true
			gs.bullet_damage *= 2
			gs.projectile_count += 2
			gs.projectile_spread += 0.12
			gs.base_speed *= 0.25
			gs.player_scale_mult *= 1.25
		"tome_summoning":
			gs.has_orbital_saw = true
			gs.reload_duration *= 1.30
		"tome_wind":
			gs.has_tome_wind = true
			gs.base_speed *= 1.25
			gs.bullet_speed *= 0.80

	var p_nodes_tome = get_tree().get_nodes_in_group("player")
	for p in p_nodes_tome:
		if is_instance_valid(p) and p.has_method("sync_stats_from_game_state"):
			p.sync_stats_from_game_state()

	gs.active_tomes.append(tome_id)
