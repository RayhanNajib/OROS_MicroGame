extends CanvasLayer

@onready var container: PanelContainer = $CenterContainer/PanelContainer
@onready var cards_hbox: HBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBox/CardsHBox
@onready var confirm_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBox/ConfirmHBox/ConfirmBtn
@onready var sfx_levelup: AudioStreamPlayer = $SFXLevelUp
@onready var sfx_click: AudioStreamPlayer = $SFXClick

var upgrade_defs: Array[Dictionary] = [
	# COMMON CARDS (Silver / White)
	{
		"id": "upg_damage",
		"rarity": "common",
		"title": "OVERCLOCK CORE",
		"desc": "Meningkatkan daya hancur peluru sebesar +25% dan menambah gaya tolak benturan +35%.",
		"detail": "• FORMULA: Base DMG x 1.25\n• KNOCKBACK: +35% Gaya Hempas\n• SINERGI: Efektif menembus robot musuh berarmor.",
		"icon": "res://assets/sprites/upg_damage.png"
	},
	{
		"id": "upg_firerate",
		"rarity": "common",
		"title": "KAPASITOR CEPAT",
		"desc": "Mempersingkat jeda tembakan sebesar +20% lebih cepat dan memotong durasi reload -15%.",
		"detail": "• LAJU TEMBAK: Interval tembak dipangkas 20%\n• RELOAD TIME: Durasi reload dipersingkat 15%\n• SINERGI: Menjadikan senjata lebih responsif.",
		"icon": "res://assets/sprites/upg_firerate.png"
	},
	{
		"id": "upg_speed",
		"rarity": "common",
		"title": "AKTUATOR NITRO",
		"desc": "Meningkatkan kecepatan lari hero sebesar +20% untuk kiting aman.",
		"detail": "• SPEED: Base speed meningkat +20%\n• AGILITY: Hero tetap lincah menggocek musuh sambil menembak.",
		"icon": "res://assets/sprites/upg_speed.png"
	},
	{
		"id": "upg_ammo",
		"rarity": "common",
		"title": "MAGASIN EKSPANSI",
		"desc": "Menambah +3 kapasitas maksimal peluru dan mengisi ulang magasin seketika.",
		"detail": "• KAPASITAS: Max Ammo bertambah +3 butir\n• INSTANT RELOAD: Magasin langsung terisi penuh 100%.",
		"icon": "res://assets/sprites/upg_ammo.png"
	},
	{
		"id": "upg_magnet",
		"rarity": "common",
		"title": "VORTEX MAGNETIK",
		"desc": "Melipatgandakan radius gravitasi penyedot EXP Core (+80% radius).",
		"detail": "• MAGNET RADIUS: Jangkauan magnet 70px -> 130px\n• LOOTING: EXP tersedot tanpa harus mendekati kerumunan.",
		"icon": "res://assets/sprites/upg_magnet.png"
	},

	# RARE CARDS (Cyan / Emerald)
	{
		"id": "upg_multishot",
		"rarity": "rare",
		"title": "EMITTER PENYEBAR",
		"desc": "Menambahkan +1 proyektil ekstra di setiap tembakan dalam formasi kipas.",
		"detail": "• PROYEKTIL: +1 Peluru ekstra per tembakan\n• SPREAD: Formasi kipas menyebar 0.08 radian\n• SINERGI: Memperluas area kehancuran tembakan.",
		"icon": "res://assets/sprites/upg_multishot.png"
	},
	{
		"id": "upg_piercing",
		"rarity": "rare",
		"title": "PECAHAN TUNGSTEN",
		"desc": "Peluru menembus +1 lapisan badan robot musuh tanpa hancur.",
		"detail": "• PIERCE: +1 robot musuh dapat ditembus\n• PENETRASI: Mengikis barisan musuh yang berjejer rapat.",
		"icon": "res://assets/sprites/upg_piercing.png"
	},
	{
		"id": "upg_freeze",
		"rarity": "rare",
		"title": "PELURU CRYO ES",
		"desc": "Membekukan robot musuh yang terkena tembak, memperlambat gerak 50% selama 2.5s.",
		"detail": "• EFEK STATUS: Musuh membeku (tint cyan) 2.5 detik\n• SLOW FACTOR: Kecepatan lari musuh dipangkas 50%.",
		"icon": "res://assets/sprites/upg_freeze.png"
	},
	{
		"id": "upg_lightning",
		"rarity": "rare",
		"title": "BUSUR TESLA",
		"desc": "Benturan peluru memicu percikan petir yang menyambar ke 2 musuh di sekitarnya.",
		"detail": "• EFEK LISTRIK: Petir menyambar 2 musuh radius 120px\n• CHAIN DMG: Menyalurkan 75% damage peluru sebagai sengatan petir.",
		"icon": "res://assets/sprites/upg_lightning.png"
	},
	{
		"id": "upg_saw",
		"rarity": "rare",
		"title": "PLASMA SAW ORBITAL",
		"desc": "Mengaktifkan 1 bilah gergaji plasma berputar mengelilingi tubuh hero.",
		"detail": "• ORBITAL DRONE: 1 Pisau berputar konstan radius 60px\n• CONTACT DMG: Menghasilkan 15 damage (+30% per level hero) pada musuh dekat.",
		"icon": "res://assets/sprites/upg_saw.png"
	},
	{
		"id": "upg_explosive",
		"rarity": "rare",
		"title": "GRANAT PLASMA",
		"desc": "Peluru meledak area 45px saat benturan menghantam musuh.",
		"detail": "• AREA OF EFFECT: Ledakan plasma beradius 45px\n• BLAST DMG: Menghasilkan damage splash ke robot sekitar.",
		"icon": "res://assets/sprites/upg_explosive.png"
	},
	{
		"id": "upg_shield",
		"rarity": "rare",
		"title": "ARMOR REAKTIF",
		"desc": "Memperkuat ketahanan sasis, meredam -1 damage kontak musuh dan +2 Max HP.",
		"detail": "• DAMAGE REDUCTION: -1 damage kontak musuh (min 1)\n• MAX HP: +2 HP maksimal sasis robot.",
		"icon": "res://assets/sprites/upg_shield.png"
	},

	# LEGENDARY CARDS (High-Voltage Gold Shimmer - Rare & Game-Changing)
	{
		"id": "upg_phoenix_reboot",
		"rarity": "legendary",
		"title": "PHOENIX REBOOT",
		"desc": "MATI HIDUP LAGI! Jika HP menyentuh 0, bangkit kembali seketika dengan 100% darah penuh & 3.0 detik kebal mutlak!",
		"detail": "• RESURRECTION: 1x Kesempatan hidup kembali dari kematian\n• REBOOT INVULN: 3.0 detik kebal mutlak dari segala jenis serangan.",
		"icon": "res://assets/sprites/upg_phoenix_reboot.png"
	},
	{
		"id": "upg_chrono_matrix",
		"rarity": "legendary",
		"title": "CHRONO MATRIX",
		"desc": "Memanipulasi aliran waktu reaktor! Seluruh pergerakan robot musuh di arena melambat -25% secara permanen.",
		"detail": "• TIME DILATION: Semua musuh di arena geraknya melambat 25%\n• KITING DOMINANCE: Sangat mudah menjaga jarak aman.",
		"icon": "res://assets/sprites/upg_chrono_matrix.png"
	},
	{
		"id": "upg_omni_burst",
		"rarity": "legendary",
		"title": "OMNI-BURST PROTOCOL",
		"desc": "Setiap peluru ditembakkan, melepaskan 8 proyektil plasma tambahan menyebar 360 derajat radial mengelilingi hero!",
		"detail": "• 360 DEGREE BURST: 8 peluru ekstra radial per tembakan\n• CROWD PURGE: Memusnahkan musuh yang mengepung dari segala arah.",
		"icon": "res://assets/sprites/upg_omni_burst.png"
	},
	{
		"id": "upg_magnetic_vacuum",
		"rarity": "rare",
		"title": "MAGNETIC FLUX HARVESTER",
		"desc": "Generator medan magnet siber! Radius sedotan vacuum untuk EXP Gem, Medkit, dan Drop meluas drastis ke 340px & EXP +20%!",
		"detail": "• VACUUM RADIUS: Radius sedot item meluas drastis ke 340px\n• EXP BONUS: Perolehan EXP dari Gem meningkat +20%.",
		"icon": "res://assets/sprites/upg_magnetic_vacuum.png"
	},
	{
		"id": "upg_lightning_storm",
		"rarity": "rare",
		"title": "CYBER THUNDERSTORM",
		"desc": "Memicu Badai Petir Otomatis menyambar hingga 3 musuh (50 DMG) tiap 2.5 detik & mengaktifkan Petir Rantai!",
		"detail": "• RANDOM LIGHTNING: Petir menyambar hingga 3 musuh radius 420px tiap 2.5s\n• SHOCK DAMAGE: 50 Damage petir per sambaran + Petir Rantai peluru.",
		"icon": "res://assets/sprites/upg_lightning_storm.png"
	},
	{
		"id": "upg_ghost_pet",
		"rarity": "rare",
		"title": "CHRONO GHOST COMPANION",
		"desc": "Memanggil pet hantu es siber yang melayang mengitari hero dan otomatis menembakkan proyektil pembeku ke musuh terdekat!",
		"detail": "• SUMMON PET: Entitas companion melayang orbit radius 68px\n• AUTO-CRYO: Menembak peluru Cryo (25 DMG) membekukan musuh tiap 1.5s.",
		"icon": "res://assets/sprites/upg_ghost_pet.png"
	},
	{
		"id": "upg_weapon_evolution",
		"rarity": "legendary",
		"title": "NANITE WEAPON EVOLUTION",
		"desc": "EVOLUSI SENJATA LEVEL MAKSIMAL! Mengubah senjata aktif ke wujud pamungkas legendaris dengan peningkatan drastis!",
		"detail": "• REVOLVER -> ⚡ MJOLNIR: +60% DMG, Efek Petir, +1 Peluru\n• SHOTGUN -> ❄️ GLACIAL FROST: +40% DMG, Efek Cryo Es, +3 Peluru, Pierce +2\n• SMG -> 💥 MICRO-MISSILE VULCAN: Peluru Peledak Area, Fire Rate +30%, +15 Ammo\n• RAILGUN -> 🌀 TACHYON LANCE: +100% DMG Masif, Laser Tembus Tak Terbatas",
		"icon": "res://assets/sprites/upg_weapon_evolution.png"
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
		if event.keycode == KEY_1 and active_cards.size() >= 1:
			highlight_card(0)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_2 and active_cards.size() >= 2:
			highlight_card(1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_3 and active_cards.size() >= 3:
			highlight_card(2)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_KP_4 or event.keycode == KEY_LEFT:
			var prev_idx = maxi(0, (selected_slot_index if selected_slot_index >= 0 else 1) - 1)
			highlight_card(prev_idx)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_KP_6 or event.keycode == KEY_RIGHT:
			var next_idx = mini(active_cards.size() - 1, (selected_slot_index if selected_slot_index >= 0 else -1) + 1)
			highlight_card(next_idx)
			get_viewport().set_input_as_handled()
		elif (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE):
			if selected_slot_index >= 0:
				_on_confirm_pressed()
			elif active_cards.size() > 0:
				highlight_card(0)
			get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.is_pressed():
		if event.button_index == JOY_BUTTON_DPAD_LEFT or event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			var prev_idx = maxi(0, (selected_slot_index if selected_slot_index >= 0 else 1) - 1)
			highlight_card(prev_idx)
			get_viewport().set_input_as_handled()
		elif event.button_index == JOY_BUTTON_DPAD_RIGHT or event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			var next_idx = mini(active_cards.size() - 1, (selected_slot_index if selected_slot_index >= 0 else -1) + 1)
			highlight_card(next_idx)
			get_viewport().set_input_as_handled()
		elif event.button_index == JOY_BUTTON_A:
			if selected_slot_index >= 0:
				_on_confirm_pressed()
			elif active_cards.size() > 0:
				highlight_card(0)
			get_viewport().set_input_as_handled()

func _on_level_up() -> void:
	get_tree().paused = true
	visible = true
	selected_slot_index = -1
	
	if confirm_btn:
		confirm_btn.disabled = true
		confirm_btn.text = "[ PILIH SALAH SATU KARTU DI ATAS DAHULU ]"
		confirm_btn.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))

	roll_active_cards()
	card_nodes.clear()

	for child in cards_hbox.get_children():
		child.queue_free()

	var has_legendary := false
	for i in range(active_cards.size()):
		if active_cards[i]["rarity"] == "legendary":
			has_legendary = true
		var card := create_card_node(active_cards[i], i)
		cards_hbox.add_child(card)
		card_nodes.append(card)
		animate_poker_deal(card, i)

	if has_legendary:
		var leg_sfx = load("res://assets/audio/sfx_legendary_card.wav")
		if leg_sfx:
			var p := AudioStreamPlayer.new()
			p.stream = leg_sfx
			add_child(p)
			p.play()
			p.finished.connect(p.queue_free)
	elif sfx_levelup:
		sfx_levelup.play()

func roll_active_cards() -> void:
	active_cards.clear()
	var commons: Array[Dictionary] = []
	var rares: Array[Dictionary] = []
	var legendaries: Array[Dictionary] = []

	for u in upgrade_defs:
		# Don't offer phoenix if already taken
		if u["id"] == "upg_phoenix_reboot" and GameState.has_phoenix_reboot:
			continue
		if u["id"] == "upg_weapon_evolution" and GameState.is_weapon_evolved:
			continue
		if u["rarity"] == "legendary":
			legendaries.append(u)
		elif u["rarity"] == "rare":
			rares.append(u)
		else:
			commons.append(u)

	commons.shuffle()
	rares.shuffle()
	legendaries.shuffle()

	# Dynamic Rarity Roll: Balanced lower legendary drop rate (2% - 4% per slot)
	var leg_chance := 0.04 if GameState.total_kills >= 60 else 0.02

	for slot in range(3):
		var roll := randf()
		var picked: Dictionary
		if roll < leg_chance and legendaries.size() > 0:
			picked = legendaries.pop_front()
		elif roll < 0.35 and rares.size() > 0:
			picked = rares.pop_front()
		else:
			if commons.size() > 0:
				picked = commons.pop_front()
			elif rares.size() > 0:
				picked = rares.pop_front()
			else:
				picked = legendaries.pop_front()
		active_cards.append(picked)

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
		if has_node("/root/InputManager"):
			get_node("/root/InputManager").vibrate_ui_card_deal()
	)

func create_card_node(data: Dictionary, slot_index: int = 0) -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(400, 560)
	btn.flat = true
	btn.pivot_offset = Vector2(200, 280)
	
	var rarity: String = data.get("rarity", "common")
	var border_col := Color(0.75, 0.85, 0.95) # Common Silver
	var tag_text := "[ COMMON MODULE ]"
	if rarity == "rare":
		border_col = Color(0, 0.94, 1) # Rare Cyan
		tag_text = "[ RARE ENHANCED ]"
	elif rarity == "legendary":
		border_col = Color(0.98, 0.8, 0.08) # Legendary Gold
		tag_text = "[ ★ ANCIENT LEGENDARY ★ ]"

	var bg_panel := PanelContainer.new()
	bg_panel.name = "BGFrame"
	bg_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var sb := StyleBoxTexture.new()
	if rarity == "legendary":
		sb.texture = load("res://assets/ui/card_frame_legendary.png")
	elif rarity == "rare":
		sb.texture = load("res://assets/ui/card_frame_rare.png")
	else:
		sb.texture = load("res://assets/ui/card_frame_normal.png")
	sb.texture_margin_left = 18.0
	sb.texture_margin_top = 18.0
	sb.texture_margin_right = 18.0
	sb.texture_margin_bottom = 18.0
	bg_panel.add_theme_stylebox_override("panel", sb)
	btn.add_child(bg_panel)
	
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	
	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var font_orb = load("res://assets/fonts/Orbitron-Bold.ttf")
	var font_silk = load("res://assets/fonts/Silkscreen-Bold.ttf")
	var font_tech = load("res://assets/fonts/tech_font.ttf")
	
	# Rarity Header Badge
	var rarity_lbl := Label.new()
	rarity_lbl.text = tag_text
	rarity_lbl.add_theme_color_override("font_color", border_col)
	rarity_lbl.add_theme_font_override("font", font_silk)
	rarity_lbl.add_theme_font_size_override("font_size", 12)
	rarity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(rarity_lbl)

	# Slot hotkey indicator
	var key_lbl := Label.new()
	key_lbl.text = "[ MODUL %d ]  (TOMBOL %d)" % [slot_index + 1, slot_index + 1]
	key_lbl.add_theme_color_override("font_color", Color(0, 0.94, 1.0))
	key_lbl.add_theme_font_override("font", font_silk)
	key_lbl.add_theme_font_size_override("font_size", 14)
	key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(key_lbl)
	
	# Upgrade Icon
	var icon_rect := TextureRect.new()
	if ResourceLoader.exists(data["icon"]):
		icon_rect.texture = load(data["icon"])
	icon_rect.custom_minimum_size = Vector2(115, 115)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(icon_rect)
	
	# Title
	var title_lbl := Label.new()
	title_lbl.text = data["title"]
	title_lbl.add_theme_color_override("font_color", Color(0.98, 0.8, 0.08) if rarity == "legendary" else Color(0.95, 0.98, 1.0))
	title_lbl.add_theme_font_override("font", font_orb)
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(title_lbl)
	
	# Description
	var desc_lbl := Label.new()
	desc_lbl.text = data["desc"]
	desc_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	desc_lbl.add_theme_font_override("font", font_tech)
	desc_lbl.add_theme_font_size_override("font_size", 17)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)
	
	# Detailed Stats Box
	var detail_lbl := Label.new()
	detail_lbl.visible = false
	detail_lbl.text = data.get("detail", "")
	detail_lbl.add_theme_color_override("font_color", Color(0.13, 0.95, 0.4))
	detail_lbl.add_theme_font_override("font", font_tech)
	detail_lbl.add_theme_font_size_override("font_size", 15)
	detail_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(detail_lbl)
	
	# Info Toggle Button
	var info_btn := Button.new()
	info_btn.text = "[ ? BEDAH STATS & FORMULA ]"
	info_btn.add_theme_font_override("font", font_orb)
	info_btn.add_theme_font_size_override("font_size", 13)
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
	status_lbl.add_theme_font_override("font", font_orb)
	status_lbl.add_theme_font_size_override("font_size", 14)
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(status_lbl)
	
	margin.add_child(vbox)
	btn.add_child(margin)
	
	btn.pressed.connect(func():
		highlight_card(slot_index)
	)
	
	return btn

func highlight_card(index: int) -> void:
	if index < 0 or index >= active_cards.size(): return
	selected_slot_index = index
	if sfx_click: sfx_click.play()
	if has_node("/root/InputManager"):
		get_node("/root/InputManager").vibrate_ui_card_select()
	
	for i in range(card_nodes.size()):
		var c = card_nodes[i]
		var bg = c.get_node_or_null("BGFrame") as PanelContainer
		var status_lbl = c.find_child("StatusLabel", true, false) as Label
		var card_data: Dictionary = active_cards[i] if i < active_cards.size() else {}
		var r: String = card_data.get("rarity", "common")
		
		if i == index:
			c.modulate = Color(1.0, 1.0, 1.0, 1.0)
			c.scale = Vector2(1.03, 1.03)
			c.position.y = -4.0
			if bg:
				var sb_sel := StyleBoxTexture.new()
				sb_sel.texture = load("res://assets/ui/card_frame_legendary.png") if r == "legendary" else load("res://assets/ui/card_frame_selected.png")
				sb_sel.texture_margin_left = 18.0; sb_sel.texture_margin_top = 18.0; sb_sel.texture_margin_right = 18.0; sb_sel.texture_margin_bottom = 18.0
				bg.add_theme_stylebox_override("panel", sb_sel)
			if status_lbl:
				status_lbl.text = "[ TERPILIH // SIAP PASANG ]"
				status_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.15))
		else:
			c.modulate = Color(0.7, 0.75, 0.85, 0.6)
			c.scale = Vector2.ONE
			c.position.y = 0.0
			if bg:
				var sb_norm := StyleBoxTexture.new()
				if r == "legendary":
					sb_norm.texture = load("res://assets/ui/card_frame_legendary.png")
				elif r == "rare":
					sb_norm.texture = load("res://assets/ui/card_frame_rare.png")
				else:
					sb_norm.texture = load("res://assets/ui/card_frame_normal.png")
				sb_norm.texture_margin_left = 18.0; sb_norm.texture_margin_top = 18.0; sb_norm.texture_margin_right = 18.0; sb_norm.texture_margin_bottom = 18.0
				bg.add_theme_stylebox_override("panel", sb_norm)
			if status_lbl:
				status_lbl.text = "KLIK UNTUK MEMILIH"
				status_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
				
	if confirm_btn:
		confirm_btn.disabled = false
		var card_title: String = active_cards[index]["title"]
		confirm_btn.text = "[ > KONFIRMASI PEMASANGAN: %s < ] (ENTER)" % card_title
		confirm_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.15, 1))
		confirm_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
		confirm_btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.95, 0.15, 1))
		confirm_btn.add_theme_color_override("font_focus_color", Color(1, 1, 1, 1))
		
		var tw := confirm_btn.create_tween()
		tw.tween_property(confirm_btn, "scale", Vector2(1.03, 1.03), 0.08)
		tw.tween_property(confirm_btn, "scale", Vector2.ONE, 0.12)

func _on_confirm_pressed() -> void:
	if selected_slot_index < 0 or selected_slot_index >= active_cards.size(): return
	var upgrade_id: String = active_cards[selected_slot_index]["id"]
	var card_rarity: String = active_cards[selected_slot_index].get("rarity", "common")
	if sfx_click: sfx_click.play()
	if has_node("/root/InputManager"):
		get_node("/root/InputManager").vibrate_ui_card_confirm(card_rarity == "legendary")
	apply_upgrade(upgrade_id)
	
	# Prevent UI confirm button bleed into player dash/skill
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if is_instance_valid(p) and "ui_lockout_timer" in p:
			p.ui_lockout_timer = 0.35
			p.is_holding_skill = false
			
	visible = false
	get_tree().paused = false

func apply_upgrade(upgrade_id: String) -> void:
	var gs = get_node_or_null("/root/GameState")
	if not gs: return
	
	match upgrade_id:
		"upg_damage":
			gs.bullet_damage = int(gs.bullet_damage * 1.25)
			gs.bullet_knockback *= 1.35
		"upg_firerate":
			gs.fire_rate = maxf(0.06, gs.fire_rate * 0.80)
			gs.reload_duration = maxf(0.45, gs.reload_duration * 0.85)
		"upg_multishot":
			gs.projectile_count += 1
			gs.projectile_spread += 0.08
		"upg_piercing":
			gs.bullet_pierce += 1
		"upg_ammo":
			var add_p1 := 3
			gs.max_ammo += add_p1
			gs.ammo = gs.max_ammo
			gs.update_ammo_state(gs.ammo, gs.max_ammo, false, 0.0)
			if gs.is_coop_mode:
				var add_p2 := 3
				gs.p2_max_ammo += add_p2
				gs.p2_ammo = gs.p2_max_ammo
				gs.update_p2_ammo_state(gs.p2_ammo, gs.p2_max_ammo, false, 0.0)
			var p_nodes_ammo = get_tree().get_nodes_in_group("player")
			for p in p_nodes_ammo:
				if is_instance_valid(p) and p.has_method("sync_stats_from_game_state"):
					p.sync_stats_from_game_state()
		"upg_freeze":
			gs.has_freeze = true
		"upg_lightning":
			gs.has_lightning = true
		"upg_saw":
			gs.has_orbital_saw = true
		"upg_speed":
			gs.base_speed *= 1.20
		"upg_magnet":
			gs.pickup_radius *= 1.8
		"upg_explosive":
			gs.has_explosive_rounds = true
		"upg_shield":
			gs.max_health += 2
			gs.heal(2)
			gs.has_reactive_armor = true
			if gs.is_coop_mode:
				gs.p2_max_health += 2
				gs.heal_p2(2)
		"upg_phoenix_reboot":
			gs.has_phoenix_reboot = true
		"upg_chrono_matrix":
			gs.has_chrono_matrix = true
		"upg_omni_burst":
			gs.has_omni_burst = true
		"upg_magnetic_vacuum":
			gs.has_magnetic_vacuum = true
			gs.pickup_radius = 340.0
		"upg_lightning_storm":
			gs.has_lightning = true
			gs.has_random_lightning = true
		"upg_ghost_pet":
			gs.has_ghost_pet = true
		"upg_weapon_evolution":
			gs.evolve_active_weapon()

	gs.check_synergies()
