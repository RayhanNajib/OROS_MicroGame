extends CanvasLayer

@onready var container: PanelContainer = $CenterContainer/PanelContainer
@onready var cards_hbox: HBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBox/CardsHBox
@onready var confirm_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBox/ConfirmHBox/ConfirmBtn
@onready var sfx_levelup: AudioStreamPlayer = $SFXLevelUp
@onready var sfx_click: AudioStreamPlayer = $SFXClick

var upgrade_defs: Array[Dictionary] = [
	{
		"id": "upg_damage",
		"title": "OVERCLOCK CORE",
		"desc": "Meningkatkan daya hancur peluru sebesar +30% dan menambah gaya tolak benturan (knockback) +40% ke robot musuh.",
		"detail": "• FORMULA: Base DMG x 1.30 (22 -> 29 DMG)\n• KNOCKBACK: 90 -> 126 Force\n• SINERGI: Sangat ampuh menembus armor tebal robot Golem & bersinergi dengan Shotgun.",
		"icon": "res://assets/sprites/upg_damage.png"
	},
	{
		"id": "upg_firerate",
		"title": "KAPASITOR CEPAT",
		"desc": "Mempersingkat jeda tembakan sebesar +25% lebih cepat dan memotong durasi reload magasin sebesar -20%.",
		"detail": "• LAJU TEMBAK: Interval tembak dipangkas 25%\n• RELOAD TIME: Durasi reload dipersingkat 20%\n• SINERGI: Menjadikan Dual Revolver dan Cyber SMG mematikan seketika.",
		"icon": "res://assets/sprites/upg_firerate.png"
	},
	{
		"id": "upg_multishot",
		"title": "EMITTER PENYEBAR",
		"desc": "Menambahkan +1 butir proyektil ekstra di setiap tembakan dalam formasi kipas menyebar.",
		"detail": "• PROYEKTIL: +1 Peluru ekstra per tembakan\n• SPREAD: Formasi kipas menyebar 0.08 radian\n• SINERGI: Menggandakan luas area kehancuran saat dikepung gerombolan.",
		"icon": "res://assets/sprites/upg_multishot.png"
	},
	{
		"id": "upg_piercing",
		"title": "PECAHAN TUNGSTEN",
		"desc": "Peluru menembus +1 lapisan badan robot musuh dan terus melesat menghantam musuh di belakangnya.",
		"detail": "• PIERCE: +1 robot musuh dapat ditembus tanpa memusnahkan peluru\n• PENETRASI: Mengikis barisan musuh yang berjejer rapat.",
		"icon": "res://assets/sprites/upg_piercing.png"
	},
	{
		"id": "upg_ammo",
		"title": "MAGASIN EKSPANSI",
		"desc": "Menambah +3 kapasitas maksimal magasin peluru dan mengisi ulang seluruh peluru secara instan.",
		"detail": "• KAPASITAS: Max Ammo bertambah +3 butir\n• INSTANT RELOAD: Magasin langsung terisi penuh 100% tanpa waktu tunggu.",
		"icon": "res://assets/sprites/upg_ammo.png"
	},
	{
		"id": "upg_freeze",
		"title": "PELURU CRYO ES",
		"desc": "Membekukan robot musuh yang terkena tembak, memotong kecepatan gerak mereka sebesar 50% selama 2.0 detik.",
		"detail": "• EFEK STATUS: Musuh membeku (tint cyan) selama 2.0 detik\n• SLOW FACTOR: Kecepatan lari musuh berkurang 50% untuk kiting aman.",
		"icon": "res://assets/sprites/upg_freeze.png"
	},
	{
		"id": "upg_lightning",
		"title": "BUSUR TESLA",
		"desc": "Benturan peluru memicu percikan petir bertegangan tinggi yang menyambar ke 2 musuh lain di sekitarnya.",
		"detail": "• EFEK LISTRIK: Petir menyambar 2 musuh dalam radius 120px\n• CHAIN DMG: Menyalurkan 14 damage listrik tambahan.",
		"icon": "res://assets/sprites/upg_lightning.png"
	},
	{
		"id": "upg_saw",
		"title": "PLASMA SAW ORBITAL",
		"desc": "Mengaktifkan 1 bilah gergaji plasma berputar mengelilingi hero yang memotong musuh yang mendekat.",
		"detail": "• ORBITAL DRONE: 1 Bilah pisau berputar konstan radius 65px\n• CONTACT DMG: Menghasilkan 18 damage per detik secara terus-menerus.",
		"icon": "res://assets/sprites/upg_saw.png"
	},
	{
		"id": "upg_heal",
		"title": "NANO RESTORASI",
		"desc": "Memulihkan 2 poin Health hero seketika dan menambah kapasitas maksimal darah sebesar +1 Max HP.",
		"detail": "• HEALING: +2 HP pulih instan\n• MAX HP: Kapasitas darah bertambah permanen +1 sasis robot.",
		"icon": "res://assets/sprites/spr_pickup_medkit.png"
	},
	{
		"id": "upg_vampire",
		"title": "CHIP VAMPIRIK",
		"desc": "Memberikan peluang 5% untuk menyerap daya inti robot hancur guna memulihkan 1 poin Health hero.",
		"detail": "• SIPHON RATE: 5% kemungkinan regenerasi darah per robot hancur\n• SUSTAIN: Menjaga darah tetap aman di ronde pertempuran panjang.",
		"icon": "res://assets/sprites/upg_damage.png"
	},
	{
		"id": "upg_speed",
		"title": "AKTUATOR NITRO",
		"desc": "Meningkatkan kecepatan lari hero sebesar +25% dan mengurangi penalti jalan lambat saat menembak.",
		"detail": "• SPEED: Base speed meningkat +25%\n• AGILITY: Hero tetap lincah menggocek musuh sambil menembak & reload.",
		"icon": "res://assets/sprites/upg_firerate.png"
	},
	{
		"id": "upg_magnet",
		"title": "VORTEX MAGNETIK",
		"desc": "Melipatgandakan jangkauan gravitasi penyedot EXP Core (+100% radius) di seluruh area arena.",
		"detail": "• MAGNET RADIUS: Jangkauan magnet 70px -> 140px\n• LOOTING: EXP tersedot otomatis tanpa harus mendekati kerumunan bahaya.",
		"icon": "res://assets/sprites/upg_ammo.png"
	},
	{
		"id": "upg_explosive",
		"title": "GRANAT PLASMA",
		"desc": "Peluru meledak dalam radius 45px saat menghantam musuh, memberikan damage area ke robot di sekitarnya.",
		"detail": "• AREA OF EFFECT: Ledakan plasma beradius 45px\n• BLAST DMG: Menghasilkan damage splash ke seluruh robot berdekatan.",
		"icon": "res://assets/sprites/upg_multishot.png"
	},
	{
		"id": "upg_shield",
		"title": "ARMOR REAKTIF",
		"desc": "Memperkuat ketahanan sasis, meredam -1 damage tabrakan musuh dan menambah +2 Max HP.",
		"detail": "• DAMAGE REDUCTION: -1 damage kontak musuh (min 1)\n• MAX HP: +2 HP maksimal sasis robot.",
		"icon": "res://assets/sprites/upg_piercing.png"
	}
]

var active_cards: Array[Dictionary] = []
var card_nodes: Array[Control] = []
var selected_slot_index: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.level_up_triggered.connect(_on_level_up)
		
	if confirm_btn:
		setup_confirm_btn()

func setup_confirm_btn() -> void:
	confirm_btn.pressed.connect(_on_confirm_pressed)
	var font_raj_bold = load("res://assets/fonts/Orbitron-Bold.ttf")
	confirm_btn.add_theme_font_override("font", font_raj_bold)
	confirm_btn.add_theme_font_size_override("font_size", 20)
	
	# Apply Texture to Confirm Button
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
		if event.keycode == KEY_1 and active_cards.size() >= 1:
			highlight_card(0)
		elif event.keycode == KEY_2 and active_cards.size() >= 2:
			highlight_card(1)
		elif event.keycode == KEY_3 and active_cards.size() >= 3:
			highlight_card(2)
		elif (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE) and selected_slot_index >= 0:
			_on_confirm_pressed()

func _on_level_up() -> void:
	get_tree().paused = true
	visible = true
	selected_slot_index = -1
	
	if confirm_btn:
		confirm_btn.disabled = true
		confirm_btn.text = "[ PILIH SALAH SATU KARTU DI ATAS DAHULU ]"
		confirm_btn.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
		
	if sfx_levelup:
		sfx_levelup.play()

	var pool_copy := upgrade_defs.duplicate()
	pool_copy.shuffle()
	active_cards = pool_copy.slice(0, 3)
	card_nodes.clear()

	for child in cards_hbox.get_children():
		child.queue_free()

	for i in range(active_cards.size()):
		var card := create_card_node(active_cards[i], i)
		cards_hbox.add_child(card)
		card_nodes.append(card)
		animate_poker_deal(card, i)

func animate_poker_deal(card: Control, index: int) -> void:
	card.modulate.a = 0.0
	card.position.y = 280.0
	card.scale = Vector2(0.7, 0.7)
	var fan_angle: float = deg_to_rad(-3.0 if index == 0 else (3.0 if index == 2 else 0.0))
	card.rotation = fan_angle
	
	var deal_delay := 0.10 + (float(index) * 0.14)
	var tw := card.create_tween()
	tw.tween_interval(deal_delay)
	tw.set_parallel(true)
	tw.tween_property(card, "position:y", 0.0, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "modulate:a", 1.0, 0.2)
	tw.tween_callback(func():
		if sfx_click:
			sfx_click.pitch_scale = 1.0 + float(index) * 0.15
			sfx_click.play()
	)

func create_card_node(data: Dictionary, slot_index: int = 0) -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(380, 520)
	btn.flat = true
	btn.pivot_offset = Vector2(190, 260)
	
	# Background Frame Image Texture
	var bg_rect := TextureRect.new()
	bg_rect.name = "BGFrame"
	bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_rect.texture = load("res://assets/ui/card_frame_normal.png")
	bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	btn.add_child(bg_rect)
	
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	
	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var font_raj_bold = load("res://assets/fonts/Orbitron-Bold.ttf")
	var font_raj_semi = load("res://assets/fonts/tech_font.ttf")
	
	# Slot hotkey indicator
	var key_lbl := Label.new()
	key_lbl.text = "[ MODUL %d ]  (TOMBOL %d)" % [slot_index + 1, slot_index + 1]
	key_lbl.add_theme_color_override("font_color", Color(0, 0.94, 1.0))
	key_lbl.add_theme_font_override("font", load("res://assets/fonts/Silkscreen-Bold.ttf"))
	key_lbl.add_theme_font_size_override("font_size", 14)
	key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(key_lbl)
	
	# Upgrade Icon
	var icon_rect := TextureRect.new()
	if ResourceLoader.exists(data["icon"]):
		icon_rect.texture = load(data["icon"])
	icon_rect.custom_minimum_size = Vector2(80, 80)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(icon_rect)
	
	# Title
	var title_lbl := Label.new()
	title_lbl.text = data["title"]
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	title_lbl.add_theme_font_override("font", font_raj_bold)
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(title_lbl)
	
	# Description (Clean & Large)
	var desc_lbl := Label.new()
	desc_lbl.text = data["desc"]
	desc_lbl.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	desc_lbl.add_theme_font_override("font", font_raj_semi)
	desc_lbl.add_theme_font_size_override("font_size", 16)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)
	
	# Detailed Stats Box (Toggleable info with formulas)
	var detail_lbl := Label.new()
	detail_lbl.visible = false
	detail_lbl.text = data.get("detail", "")
	detail_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.65))
	detail_lbl.add_theme_font_override("font", font_raj_semi)
	detail_lbl.add_theme_font_size_override("font_size", 14)
	detail_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(detail_lbl)
	
	# Info Toggle Button
	var info_btn := Button.new()
	info_btn.text = "[ ? BEDAH STATS & FORMULA ]"
	info_btn.add_theme_font_override("font", font_raj_bold)
	info_btn.add_theme_font_size_override("font_size", 14)
	info_btn.pressed.connect(func():
		detail_lbl.visible = not detail_lbl.visible
		desc_lbl.visible = not detail_lbl.visible
		info_btn.text = "[ TUTUP STATS ]" if detail_lbl.visible else "[ ? BEDAH STATS & FORMULA ]"
		if sfx_click: sfx_click.play()
	)
	vbox.add_child(info_btn)
	
	# Status Indicator
	var status_lbl := Label.new()
	status_lbl.name = "StatusLabel"
	status_lbl.text = "KLIK UNTUK MEMILIH"
	status_lbl.add_theme_color_override("font_color", Color(0.6, 0.75, 0.9))
	status_lbl.add_theme_font_override("font", font_raj_bold)
	status_lbl.add_theme_font_size_override("font_size", 15)
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(status_lbl)
	
	margin.add_child(vbox)
	btn.add_child(margin)
	
	# Click action -> Highlights card and activates Confirm Button
	btn.pressed.connect(func():
		highlight_card(slot_index)
	)
	
	return btn

func highlight_card(index: int) -> void:
	if index < 0 or index >= active_cards.size(): return
	selected_slot_index = index
	if sfx_click: sfx_click.play()
	
	for i in range(card_nodes.size()):
		var c = card_nodes[i]
		var bg = c.get_node_or_null("BGFrame") as TextureRect
		var status_lbl = c.find_child("StatusLabel", true, false) as Label
		
		if i == index:
			# Selected Card
			c.modulate = Color(1.0, 1.0, 1.0, 1.0)
			c.scale = Vector2(1.05, 1.05)
			c.position.y = -10.0
			if bg:
				bg.texture = load("res://assets/ui/card_frame_selected.png")
			if status_lbl:
				status_lbl.text = "[ TERPILIH // SIAP PASANG ]"
				status_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
		else:
			# Unselected Cards
			c.modulate = Color(0.7, 0.75, 0.85, 0.6)
			c.scale = Vector2.ONE
			c.position.y = 0.0
			if bg:
				bg.texture = load("res://assets/ui/card_frame_normal.png")
			if status_lbl:
				status_lbl.text = "KLIK UNTUK MEMILIH"
				status_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
				
	# Update Confirmation Button
	if confirm_btn:
		confirm_btn.disabled = false
		var card_title: String = active_cards[index]["title"]
		confirm_btn.text = "[ > KONFIRMASI PEMASANGAN: %s < ] (ENTER)" % card_title
		confirm_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
		
		# Bounce confirmation button
		var tw := confirm_btn.create_tween()
		tw.tween_property(confirm_btn, "scale", Vector2(1.03, 1.03), 0.08)
		tw.tween_property(confirm_btn, "scale", Vector2.ONE, 0.12)

func _on_confirm_pressed() -> void:
	if selected_slot_index < 0 or selected_slot_index >= active_cards.size(): return
	var upgrade_id: String = active_cards[selected_slot_index]["id"]
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