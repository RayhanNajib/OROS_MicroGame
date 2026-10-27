extends CanvasLayer

signal settings_closed

@onready var sfx_click: AudioStreamPlayer = $SFXClick
var active_tab: int = 0 # 0: Input, 1: Controls Guide, 2: Haptic, 3: Audio, 4: Graphics
var was_tree_paused: bool = false

# Tab buttons
var tab_buttons: Array[Button] = []
var tab_contents: Array[Control] = []

# Live Joypad Tester Label
var live_joypad_lbl: Label = null
var gamepad_prompt_footer: Label = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	build_ui()
	load_saved_values()

func open_modal() -> void:
	was_tree_paused = get_tree().paused
	visible = true
	get_tree().paused = true
	load_saved_values()
	switch_tab(0)
	if tab_buttons.size() > 0 and is_instance_valid(tab_buttons[0]):
		tab_buttons[0].grab_focus()

func close_modal() -> void:
	save_all_values()
	visible = false
	get_tree().paused = was_tree_paused
	settings_closed.emit()

func _safe_handle_input() -> void:
	if is_inside_tree() and get_viewport():
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if not visible: return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_KP_0:
			_safe_handle_input()
			close_modal()
	elif event is InputEventJoypadButton and event.is_pressed():
		if event.button_index == JOY_BUTTON_B:
			_safe_handle_input()
			close_modal()
		elif event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			switch_tab((active_tab + tab_buttons.size() - 1) % tab_buttons.size())
			_safe_handle_input()
		elif event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			switch_tab((active_tab + 1) % tab_buttons.size())
			_safe_handle_input()
		elif event.button_index == JOY_BUTTON_Y:
			reset_defaults()
			_safe_handle_input()

func _process(_delta: float) -> void:
	if not visible: return
	# Update Live Joypad Visualizer if on Input tab
	if active_tab == 0 and live_joypad_lbl:
		update_live_joypad_visualizer()

func update_live_joypad_visualizer() -> void:
	var pads = Input.get_connected_joypads()
	if pads.size() == 0:
		live_joypad_lbl.text = "[ STATUS: MENUNGGU KONTROLER // SAMBUNGKAN XBOX, PLAYSTATION, ATAU NINTENDO SWITCH ]\n  Saat analog atau tombol disentuh, pembacaan hardware real-time akan muncul di kotak ini."
		live_joypad_lbl.add_theme_color_override("font_color", Color(0.65, 0.72, 0.85))
		return
		
	var dev_id = pads[0]
	var pad_name = Input.get_joy_name(dev_id).to_upper()
	var lx = Input.get_joy_axis(dev_id, JOY_AXIS_LEFT_X)
	var ly = Input.get_joy_axis(dev_id, JOY_AXIS_LEFT_Y)
	var rx = Input.get_joy_axis(dev_id, JOY_AXIS_RIGHT_X)
	var ry = Input.get_joy_axis(dev_id, JOY_AXIS_RIGHT_Y)
	var lt = Input.get_joy_axis(dev_id, JOY_AXIS_TRIGGER_LEFT)
	var rt = Input.get_joy_axis(dev_id, JOY_AXIS_TRIGGER_RIGHT)
	
	var pressed_btns: Array[String] = []
	if Input.is_joy_button_pressed(dev_id, JOY_BUTTON_A): pressed_btns.append("[A/✕/B]")
	if Input.is_joy_button_pressed(dev_id, JOY_BUTTON_B): pressed_btns.append("[B/○/A]")
	if Input.is_joy_button_pressed(dev_id, JOY_BUTTON_X): pressed_btns.append("[X/▢/Y]")
	if Input.is_joy_button_pressed(dev_id, JOY_BUTTON_Y): pressed_btns.append("[Y/△/X]")
	if Input.is_joy_button_pressed(dev_id, JOY_BUTTON_LEFT_SHOULDER): pressed_btns.append("[LB/L1]")
	if Input.is_joy_button_pressed(dev_id, JOY_BUTTON_RIGHT_SHOULDER): pressed_btns.append("[RB/R1]")
	if Input.is_joy_button_pressed(dev_id, JOY_BUTTON_START): pressed_btns.append("[START]")
	
	var text := "● KONTROLER TERDETEKSI: [%s // PORT 0]\n" % pad_name
	text += "  L-STICK: X: %+0.2f | Y: %+0.2f  |  R-STICK: X: %+0.2f | Y: %+0.2f\n" % [lx, ly, rx, ry]
	text += "  TRIGGERS: LT: %d%% | RT: %d%%   |  TOMBOL AKTIF: %s" % [int(maxf(0, lt) * 100), int(maxf(0, rt) * 100), (" ".join(pressed_btns) if pressed_btns.size() > 0 else "[STANDBY]")]
	live_joypad_lbl.text = text
	live_joypad_lbl.add_theme_color_override("font_color", Color(0, 0.94, 1.0))

func build_ui() -> void:
	var font_orb = load("res://assets/fonts/Orbitron-Bold.ttf")
	var font_silk = load("res://assets/fonts/Silkscreen-Bold.ttf")
	var font_tech = load("res://assets/fonts/tech_font.ttf")

	# Base Overlay
	var overlay = ColorRect.new()
	overlay.name = "Overlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.02, 0.03, 0.06, 0.94)
	add_child(overlay)

	# Main 2.5D Panel
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(1240, 820)
	var sb_panel = StyleBoxTexture.new()
	sb_panel.texture = load("res://assets/ui/panel_settings_25d.png")
	sb_panel.set_texture_margin_all(28.0)
	panel.add_theme_stylebox_override("panel", sb_panel)
	center.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 14)
	margin.add_child(root_vbox)

	# 1. Header Title
	var title_lbl = Label.new()
	title_lbl.text = "// PROTOKOL KONFIGURASI SISTEM // SETTINGS MATRIX"
	title_lbl.add_theme_font_override("font", font_orb)
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.add_theme_color_override("font_color", Color(0.0, 0.94, 1.0))
	root_vbox.add_child(title_lbl)

	# 2. Tabs Row (5 Tabs)
	var tabs_hbox = HBoxContainer.new()
	tabs_hbox.add_theme_constant_override("separation", 8)
	root_vbox.add_child(tabs_hbox)

	var tab_names = [
		"[ INPUT & KONTROL ]",
		"[ PANDUAN TOMBOL ]",
		"[ HAPTIK & VIBRASI ]",
		"[ AUDIO & AKUSTIK ]",
		"[ GRAFIS & TAMPILAN ]"
	]

	for i in range(tab_names.size()):
		var tbtn = Button.new()
		tbtn.text = tab_names[i]
		tbtn.custom_minimum_size = Vector2(220, 46)
		tbtn.add_theme_font_override("font", font_orb)
		tbtn.add_theme_font_size_override("font_size", 13)
		var idx = i
		tbtn.pressed.connect(func(): switch_tab(idx))
		tabs_hbox.add_child(tbtn)
		tab_buttons.append(tbtn)

	# 3. Content Panel
	var content_panel = PanelContainer.new()
	content_panel.custom_minimum_size = Vector2(1168, 520)
	var sb_c = StyleBoxFlat.new()
	sb_c.bg_color = Color(0.03, 0.06, 0.11, 0.88)
	sb_c.border_color = Color(0.0, 0.75, 1.0, 0.5)
	sb_c.set_border_width_all(2)
	sb_c.set_corner_radius_all(6)
	content_panel.add_theme_stylebox_override("panel", sb_c)
	root_vbox.add_child(content_panel)

	var content_margin = MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left", 32)
	content_margin.add_theme_constant_override("margin_right", 32)
	content_margin.add_theme_constant_override("margin_top", 20)
	content_margin.add_theme_constant_override("margin_bottom", 20)
	content_panel.add_child(content_margin)

	# Tab 0: Input & Controller
	var tab0_vbox = VBoxContainer.new()
	tab0_vbox.add_theme_constant_override("separation", 16)
	content_margin.add_child(tab0_vbox)
	tab_contents.append(tab0_vbox)
	build_tab_input(tab0_vbox, font_orb, font_tech, font_silk)

	# Tab 1: Controls Guide & Diagram
	var tab1_vbox = VBoxContainer.new()
	tab1_vbox.add_theme_constant_override("separation", 14)
	content_margin.add_child(tab1_vbox)
	tab_contents.append(tab1_vbox)
	build_tab_controls_guide(tab1_vbox, font_orb, font_tech, font_silk)

	# Tab 2: Haptic & Vibration
	var tab2_vbox = VBoxContainer.new()
	tab2_vbox.add_theme_constant_override("separation", 14)
	content_margin.add_child(tab2_vbox)
	tab_contents.append(tab2_vbox)
	build_tab_haptics(tab2_vbox, font_orb, font_tech, font_silk)

	# Tab 3: Audio & Acoustics
	var tab3_vbox = VBoxContainer.new()
	tab3_vbox.add_theme_constant_override("separation", 18)
	content_margin.add_child(tab3_vbox)
	tab_contents.append(tab3_vbox)
	build_tab_audio(tab3_vbox, font_orb, font_tech, font_silk)

	# Tab 4: Graphics & Display
	var tab4_vbox = VBoxContainer.new()
	tab4_vbox.add_theme_constant_override("separation", 18)
	content_margin.add_child(tab4_vbox)
	tab_contents.append(tab4_vbox)
	build_tab_graphics(tab4_vbox, font_orb, font_tech, font_silk)

	# 4. Bottom Row Action Buttons & Gamepad Prompts
	var bot_hbox = HBoxContainer.new()
	bot_hbox.add_theme_constant_override("separation", 20)
	root_vbox.add_child(bot_hbox)

	gamepad_prompt_footer = Label.new()
	gamepad_prompt_footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gamepad_prompt_footer.text = "[ (A/LMB) PILIH ]  [ (B/ESC) KEMBALI & SIMPAN ]  [ (LB/RB) GANTI TAB ]  [ (Y) RESET ]"
	gamepad_prompt_footer.add_theme_font_override("font", font_silk)
	gamepad_prompt_footer.add_theme_font_size_override("font_size", 12)
	gamepad_prompt_footer.add_theme_color_override("font_color", Color(0.5, 0.75, 0.95))
	bot_hbox.add_child(gamepad_prompt_footer)

	var reset_btn = Button.new()
	reset_btn.text = "[ RESET DEFAULT ]"
	reset_btn.custom_minimum_size = Vector2(210, 48)
	reset_btn.add_theme_font_override("font", font_orb)
	reset_btn.add_theme_font_size_override("font_size", 14)
	apply_sci_button_style(reset_btn)
	reset_btn.pressed.connect(reset_defaults)
	bot_hbox.add_child(reset_btn)

	var confirm_btn = Button.new()
	confirm_btn.text = "[ > SIMPAN & KELUAR (ESC) < ]"
	confirm_btn.custom_minimum_size = Vector2(340, 48)
	confirm_btn.add_theme_font_override("font", font_orb)
	confirm_btn.add_theme_font_size_override("font_size", 16)
	apply_confirm_button_style(confirm_btn)
	confirm_btn.pressed.connect(close_modal)
	bot_hbox.add_child(confirm_btn)

func switch_tab(idx: int) -> void:
	active_tab = idx
	for i in range(tab_buttons.size()):
		var b = tab_buttons[i]
		var is_active = (i == idx)
		var tex_path = "res://assets/ui/tab_selected.png" if is_active else "res://assets/ui/tab_normal.png"
		var sb = StyleBoxTexture.new()
		sb.texture = load(tex_path)
		sb.set_texture_margin_all(8)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("pressed", sb)
		b.add_theme_color_override("font_color", Color(1.0, 0.95, 0.15) if is_active else Color(0.7, 0.8, 0.9))
		
		tab_contents[i].visible = is_active
	if sfx_click: sfx_click.play()

# -------------------------------------------------------------
# TAB 0: INPUT & CONTROLLER
# -------------------------------------------------------------
var slider_mouse_sens: HSlider
var lbl_mouse_sens_val: Label
var slider_pad_sens: HSlider
var lbl_pad_sens_val: Label
var slider_pad_deadzone: HSlider
var lbl_pad_deadzone_val: Label
var btn_aim_assist: Button

func build_tab_input(p: VBoxContainer, font_orb: Font, font_tech: Font, font_silk: Font) -> void:
	# Live Hardware Visualizer Panel
	var tester_panel = PanelContainer.new()
	var sb_t = StyleBoxFlat.new()
	sb_t.bg_color = Color(0.02, 0.04, 0.08, 0.9)
	sb_t.border_color = Color(0.0, 0.8, 1.0, 0.7)
	sb_t.set_border_width_all(1)
	sb_t.set_corner_radius_all(4)
	tester_panel.add_theme_stylebox_override("panel", sb_t)
	p.add_child(tester_panel)

	var t_margin = MarginContainer.new()
	t_margin.add_theme_constant_override("margin_left", 16)
	t_margin.add_theme_constant_override("margin_right", 16)
	t_margin.add_theme_constant_override("margin_top", 10)
	t_margin.add_theme_constant_override("margin_bottom", 10)
	tester_panel.add_child(t_margin)

	live_joypad_lbl = Label.new()
	live_joypad_lbl.add_theme_font_override("font", font_silk)
	live_joypad_lbl.add_theme_font_size_override("font_size", 12)
	t_margin.add_child(live_joypad_lbl)

	# Gamepad Stick Sensitivity
	var r1 = make_row(p, "SENSIVITAS ANALOG GAMEPAD", "Mengatur kecepatan putaran twin-stick & virtual cursor", font_orb, font_tech)
	slider_pad_sens = make_slider(r1, 0.5, 3.0, 0.1)
	lbl_pad_sens_val = make_val_badge(r1, font_silk)
	slider_pad_sens.value_changed.connect(func(v): lbl_pad_sens_val.text = "%.1fx" % v)

	# Mouse Aim Sensitivity
	var r2 = make_row(p, "SENSIVITAS BIDIKAN MOUSE", "Kecepatan pergerakan crosshair kursor mouse", font_orb, font_tech)
	slider_mouse_sens = make_slider(r2, 0.5, 3.0, 0.1)
	lbl_mouse_sens_val = make_val_badge(r2, font_silk)
	slider_mouse_sens.value_changed.connect(func(v): lbl_mouse_sens_val.text = "%.1fx" % v)

	# Gamepad Deadzone
	var r3 = make_row(p, "DEADZONE ANALOG GAMEPAD", "Ambang batas gerakan stik agar tidak drifting", font_orb, font_tech)
	slider_pad_deadzone = make_slider(r3, 0.05, 0.35, 0.02)
	lbl_pad_deadzone_val = make_val_badge(r3, font_silk)
	slider_pad_deadzone.value_changed.connect(func(v): lbl_pad_deadzone_val.text = "%d%%" % int(v * 100))

	# Auto-Aim Assist
	var r4 = make_row(p, "BANTUAN BIDIKAN OTOMATIS (AIM ASSIST)", "Mengarahkan tembakan sedikit ke musuh terdekat saat analog netral", font_orb, font_tech)
	btn_aim_assist = make_toggle_btn(r4, font_orb)

# -------------------------------------------------------------
# TAB 1: PANDUAN KONTROL & DIAGRAM (VISUAL BUTTON GUIDE)
# -------------------------------------------------------------
func build_tab_controls_guide(p: VBoxContainer, font_orb: Font, font_tech: Font, font_silk: Font) -> void:
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1100, 460)
	p.add_child(scroll)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 32)
	scroll.add_child(hbox)

	# Left Column: GAMEPAD MAPPING
	var pad_col = VBoxContainer.new()
	pad_col.custom_minimum_size = Vector2(530, 440)
	pad_col.add_theme_constant_override("separation", 10)
	hbox.add_child(pad_col)

	var pad_header = Label.new()
	pad_header.text = "■ DIAGRAM TOMBOL KONTROLER (XBOX / PS / SWITCH)"
	pad_header.add_theme_font_override("font", font_orb)
	pad_header.add_theme_font_size_override("font_size", 16)
	pad_header.add_theme_color_override("font_color", Color(0, 0.94, 1.0))
	pad_col.add_child(pad_header)

	var pad_bindings = [
		{"btn": "[ RT / R2 / ZR ]", "desc": "TEMBAK SENJATA RANGED (TAHAN UNTUK FULL-AUTO)"},
		{"btn": "[ LT / L2 / ZL ]", "desc": "TEBASAN MELEE INSTAN (AREA 120 DERAJAT DEPAN)"},
		{"btn": "[ LEFT STICK ]", "desc": "GERAK KARAKTER 360 DERAJAT ANALOG"},
		{"btn": "[ RIGHT STICK ]", "desc": "BIDIKAN BEBAS TWIN-STICK 360 DERAJAT"},
		{"btn": "[ RB / R1 / R ]", "desc": "AKTIFKAN SKILL HERO (TAHAN BIDIK, LEPAS CAST)"},
		{"btn": "[ X / ▢ / Y ]", "desc": "ISI ULANG AMUNISI (RELOAD WEAPON)"},
		{"btn": "[ Y / △ / X ]", "desc": "GANTI SENJATA PRIMER / SEKUNDER (SWAP)"},
		{"btn": "[ START / MENU ]", "desc": "JEDA PERMAINAN (PAUSE MENU)"},
		{"btn": "[ D-PAD / LB/RB ]", "desc": "NAVIGASI KARTU & GANTI TAB PENGATURAN"}
	]

	for b in pad_bindings:
		var r = HBoxContainer.new()
		var b_lbl = Label.new()
		b_lbl.custom_minimum_size = Vector2(160, 24)
		b_lbl.text = b["btn"]
		b_lbl.add_theme_font_override("font", font_silk)
		b_lbl.add_theme_font_size_override("font_size", 12)
		b_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.29))
		r.add_child(b_lbl)

		var d_lbl = Label.new()
		d_lbl.text = b["desc"]
		d_lbl.add_theme_font_override("font", font_tech)
		d_lbl.add_theme_font_size_override("font_size", 13)
		d_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
		r.add_child(d_lbl)
		pad_col.add_child(r)

	# Right Column: KEYBOARD & MOUSE MAPPING
	var kbm_col = VBoxContainer.new()
	kbm_col.custom_minimum_size = Vector2(530, 440)
	kbm_col.add_theme_constant_override("separation", 10)
	hbox.add_child(kbm_col)

	var kbm_header = Label.new()
	kbm_header.text = "■ PANDUAN TOMBOL KEYBOARD & MOUSE"
	kbm_header.add_theme_font_override("font", font_orb)
	kbm_header.add_theme_font_size_override("font_size", 16)
	kbm_header.add_theme_color_override("font_color", Color(0, 0.94, 1.0))
	kbm_col.add_child(kbm_header)

	var kbm_bindings = [
		{"btn": "[ W, A, S, D ]", "desc": "GERAK KARAKTER (ATAS, KIRI, BAWAH, KANAN)"},
		{"btn": "[ MOUSE MOVE ]", "desc": "BIDIKAN KURSOR CROSSHAIR DINAMIS"},
		{"btn": "[ KLIK KIRI / LMB ]", "desc": "TEMBAK SENJATA JARAK JAUH"},
		{"btn": "[ KLIK KANAN / RMB ]", "desc": "TEBASAN MELEE INSTAN"},
		{"btn": "[ SPACE / TOMBOL E ]", "desc": "AKTIFKAN SKILL HERO (PROYEKSI LUBANG HITAM)"},
		{"btn": "[ TOMBOL R ]", "desc": "RELOAD AMUNISI SENJATA"},
		{"btn": "[ TOMBOL Q / 1 / 2 ]", "desc": "GANTI SENJATA PRIMER & SEKUNDER"},
		{"btn": "[ TOMBOL ESC ]", "desc": "MENU JEDA / TUTUP MODAL"},
		{"btn": "[ TOMBOL F2 ]", "desc": "TOGGLE MODE 2-PLAYER SPLIT-SCREEN"}
	]

	for b in kbm_bindings:
		var r = HBoxContainer.new()
		var b_lbl = Label.new()
		b_lbl.custom_minimum_size = Vector2(170, 24)
		b_lbl.text = b["btn"]
		b_lbl.add_theme_font_override("font", font_silk)
		b_lbl.add_theme_font_size_override("font_size", 12)
		b_lbl.add_theme_color_override("font_color", Color(0, 0.94, 1.0))
		r.add_child(b_lbl)

		var d_lbl = Label.new()
		d_lbl.text = b["desc"]
		d_lbl.add_theme_font_override("font", font_tech)
		d_lbl.add_theme_font_size_override("font_size", 13)
		d_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
		r.add_child(d_lbl)
		kbm_col.add_child(r)

# -------------------------------------------------------------
# TAB 1: HAPTIC & VIBRATION
# -------------------------------------------------------------
var btn_vib_master: Button
var btn_vib_shooting: Button
var btn_vib_melee: Button
var btn_vib_damage: Button
var btn_vib_reload: Button
var btn_vib_ui: Button
var slider_vib_strength: HSlider
var lbl_vib_strength_val: Label

func build_tab_haptics(p: VBoxContainer, font_orb: Font, font_tech: Font, font_silk: Font) -> void:
	var r0 = make_row(p, "VIBRASI HAPTIK MASTER", "Aktifkan atau matikan seluruh getaran 2 motor kontroler", font_orb, font_tech)
	btn_vib_master = make_toggle_btn(r0, font_orb)

	var r1 = make_row(p, "GETARAN TEMBAKAN SENJATA", "Hentakan recoil motor kiri & kanan saat menembakkan senjata api", font_orb, font_tech)
	btn_vib_shooting = make_toggle_btn(r1, font_orb)

	var r1b = make_row(p, "GETARAN SERANGAN MELEE / TEBASAN", "Efek haptik saat mengayunkan senjata jarak dekat (pedang, wrench, kunai)", font_orb, font_tech)
	btn_vib_melee = make_toggle_btn(r1b, font_orb)

	var r2 = make_row(p, "HENTAKAN SAAT TERKENA SERANGAN", "Sentakan berat motor kiri saat armor tertembus serangan musuh", font_orb, font_tech)
	btn_vib_damage = make_toggle_btn(r2, font_orb)

	var r3 = make_row(p, "KLIK MEKANIS KOKANGAN RELOAD", "Dengungan taktis saat mencabut magasin & mengunci selongsong", font_orb, font_tech)
	btn_vib_reload = make_toggle_btn(r3, font_orb)

	var r4 = make_row(p, "HAPTIK KARTU & CYBER TOME", "Getaran halus saat kartu level-up dibagikan atau grimoire terbuka", font_orb, font_tech)
	btn_vib_ui = make_toggle_btn(r4, font_orb)

	var r5 = make_row(p, "INTENSITAS GETARAN (STRENGTH)", "Persentase kekuatan total kedua motor haptik", font_orb, font_tech)
	slider_vib_strength = make_slider(r5, 0.1, 1.0, 0.05)
	lbl_vib_strength_val = make_val_badge(r5, font_silk)
	slider_vib_strength.value_changed.connect(func(v): lbl_vib_strength_val.text = "%d%%" % int(v * 100))

	# Live Test Rumble Button
	var test_btn = Button.new()
	test_btn.text = "[ >> UJI GETARAN MOTOR KIRI & KANAN (TEST RUMBLE) << ]"
	test_btn.custom_minimum_size = Vector2(560, 42)
	test_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	test_btn.add_theme_font_override("font", font_orb)
	test_btn.add_theme_font_size_override("font_size", 14)
	apply_sci_button_style(test_btn)
	test_btn.pressed.connect(func():
		var im = get_node_or_null("/root/InputManager")
		if im: im.vibrate(0.85, 0.85, 0.50, 1)
	)
	p.add_child(test_btn)

# -------------------------------------------------------------
# TAB 2: AUDIO & ACOUSTICS
# -------------------------------------------------------------
var slider_vol_master: HSlider; var lbl_vol_master: Label
var slider_vol_bgm: HSlider; var lbl_vol_bgm: Label
var slider_vol_sfx: HSlider; var lbl_vol_sfx: Label
var slider_vol_reload: HSlider; var lbl_vol_reload: Label

func build_tab_audio(p: VBoxContainer, font_orb: Font, font_tech: Font, font_silk: Font) -> void:
	var r1 = make_row(p, "VOLUME MASTER UTAMA", "Tingkat audio keseluruhan sistem game", font_orb, font_tech)
	slider_vol_master = make_slider(r1, 0.0, 1.0, 0.05); lbl_vol_master = make_val_badge(r1, font_silk)
	slider_vol_master.value_changed.connect(func(v): lbl_vol_master.text = "%d%%" % int(v * 100))

	var r2 = make_row(p, "VOLUME MUSIK CYBERPUNK (BGM)", "Volume synthesizer background musik arena tempur", font_orb, font_tech)
	slider_vol_bgm = make_slider(r2, 0.0, 1.0, 0.05); lbl_vol_bgm = make_val_badge(r2, font_silk)
	slider_vol_bgm.value_changed.connect(func(v): lbl_vol_bgm.text = "%d%%" % int(v * 100))

	var r3 = make_row(p, "VOLUME EFEK TEMBAKAN & MELEE (SFX)", "Dentuman peluru, tebasan pedang, ledakan granat & skill", font_orb, font_tech)
	slider_vol_sfx = make_slider(r3, 0.0, 1.0, 0.05); lbl_vol_sfx = make_val_badge(r3, font_silk)
	slider_vol_sfx.value_changed.connect(func(v): lbl_vol_sfx.text = "%d%%" % int(v * 100))

	var r4 = make_row(p, "VOLUME EFEK RELOAD SENJATA", "Kejelasan bunyi selongsong jatuh & kokangan pompa", font_orb, font_tech)
	slider_vol_reload = make_slider(r4, 0.0, 1.0, 0.05); lbl_vol_reload = make_val_badge(r4, font_silk)
	slider_vol_reload.value_changed.connect(func(v): lbl_vol_reload.text = "%d%%" % int(v * 100))

# -------------------------------------------------------------
# TAB 3: GRAPHICS & DISPLAY
# -------------------------------------------------------------
var slider_shake: HSlider; var lbl_shake: Label
var btn_fullscreen: Button
var btn_scanlines: Button
var btn_damage_popups: Button

func build_tab_graphics(p: VBoxContainer, font_orb: Font, font_tech: Font, font_silk: Font) -> void:
	var r1 = make_row(p, "INTENSITAS GUNCANGAN LAYAR (CAMERA SHAKE)", "Goncangan visual saat ledakan bom, slam, & tembakan railgun", font_orb, font_tech)
	slider_shake = make_slider(r1, 0.0, 1.0, 0.05); lbl_shake = make_val_badge(r1, font_silk)
	slider_shake.value_changed.connect(func(v): lbl_shake.text = "%d%%" % int(v * 100))

	var r2 = make_row(p, "MODE LAYAR PENUH (FULLSCREEN)", "Tampilan borderless layar penuh 1920x1080", font_orb, font_tech)
	btn_fullscreen = make_toggle_btn(r2, font_orb)

	var r3 = make_row(p, "EFEK CRT SCANLINE & NEON GLOW", "Garis pemindai retro arcade dan pendaran sirkuit cyberpunk", font_orb, font_tech)
	btn_scanlines = make_toggle_btn(r3, font_orb)

	var r4 = make_row(p, "POPUP ANGKA DAMAGE TERBANG", "Memunculkan angka damage dinamis di atas kepala robot musuh", font_orb, font_tech)
	btn_damage_popups = make_toggle_btn(r4, font_orb)

# -------------------------------------------------------------
# HELPER BUILDERS & STYLES
# -------------------------------------------------------------
func make_row(parent: Control, title: String, desc: String, font_orb: Font, font_tech: Font) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 24)
	parent.add_child(hbox)

	var text_vbox = VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_vbox)

	var lbl_title = Label.new()
	lbl_title.text = title
	lbl_title.add_theme_font_override("font", font_orb)
	lbl_title.add_theme_font_size_override("font_size", 16)
	lbl_title.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	text_vbox.add_child(lbl_title)

	var lbl_desc = Label.new()
	lbl_desc.text = desc
	lbl_desc.add_theme_font_override("font", font_tech)
	lbl_desc.add_theme_font_size_override("font_size", 13)
	lbl_desc.add_theme_color_override("font_color", Color(0.65, 0.78, 0.95))
	text_vbox.add_child(lbl_desc)

	return hbox

func make_slider(row: HBoxContainer, min_v: float, max_v: float, step_v: float) -> HSlider:
	var s = HSlider.new()
	s.custom_minimum_size = Vector2(300, 28)
	s.min_value = min_v
	s.max_value = max_v
	s.step = step_v
	
	# High-contrast bold rectangular bounding box for slider track
	var sb_groove = StyleBoxFlat.new()
	sb_groove.bg_color = Color(0.04, 0.08, 0.15, 0.95)
	sb_groove.border_color = Color(0.0, 0.85, 1.0, 0.9)
	sb_groove.set_border_width_all(2)
	sb_groove.set_corner_radius_all(4)
	sb_groove.content_margin_top = 6
	sb_groove.content_margin_bottom = 6
	s.add_theme_stylebox_override("slider", sb_groove)

	var sb_fill = StyleBoxFlat.new()
	sb_fill.bg_color = Color(0.0, 0.94, 1.0, 0.95)
	sb_fill.set_corner_radius_all(3)
	sb_fill.content_margin_top = 4
	sb_fill.content_margin_bottom = 4
	s.add_theme_stylebox_override("grabber_area", sb_fill)
	s.add_theme_stylebox_override("grabber_area_highlight", sb_fill)

	var grabber_tex = load("res://assets/ui/slider_grabber.png")
	if grabber_tex:
		s.add_theme_icon_override("grabber", grabber_tex)
		s.add_theme_icon_override("grabber_highlight", grabber_tex)
		
	row.add_child(s)
	return s

func make_val_badge(row: HBoxContainer, font_silk: Font) -> Label:
	var l = Label.new()
	l.custom_minimum_size = Vector2(75, 26)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", font_silk)
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(1.0, 0.88, 0.29))
	row.add_child(l)
	return l

func make_toggle_btn(row: HBoxContainer, _font_orb: Font) -> Button:
	var b = Button.new()
	b.custom_minimum_size = Vector2(84, 34)
	b.focus_mode = Control.FOCUS_ALL
	b.set_meta("state", true)
	update_toggle_visual(b, true)
	b.pressed.connect(func():
		var cur: bool = b.get_meta("state", true)
		var nxt: bool = not cur
		b.set_meta("state", nxt)
		update_toggle_visual(b, nxt)
		if sfx_click: sfx_click.play()
	)
	row.add_child(b)
	return b

func update_toggle_visual(b: Button, on: bool) -> void:
	b.text = "" # Text removed completely as requested
	var tex = load("res://assets/ui/toggle_on.png" if on else "res://assets/ui/toggle_off.png")
	var sb = StyleBoxTexture.new(); sb.texture = tex; sb.set_texture_margin_all(4)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	
	var sb_focus = StyleBoxFlat.new()
	sb_focus.draw_center = false
	sb_focus.border_width_left = 2
	sb_focus.border_width_top = 2
	sb_focus.border_width_right = 2
	sb_focus.border_width_bottom = 2
	sb_focus.border_color = Color(1.0, 0.88, 0.29, 0.95)
	sb_focus.corner_radius_top_left = 17
	sb_focus.corner_radius_top_right = 17
	sb_focus.corner_radius_bottom_right = 17
	sb_focus.corner_radius_bottom_left = 17
	b.add_theme_stylebox_override("focus", sb_focus)

func apply_sci_button_style(b: Button) -> void:
	var tex_n = load("res://assets/ui/btn_sci_normal.png")
	var tex_h = load("res://assets/ui/btn_sci_hover.png")
	if tex_n and tex_h:
		var sb_n = StyleBoxTexture.new(); sb_n.texture = tex_n; sb_n.set_texture_margin_all(8)
		var sb_h = StyleBoxTexture.new(); sb_h.texture = tex_h; sb_h.set_texture_margin_all(8)
		b.add_theme_stylebox_override("normal", sb_n)
		b.add_theme_stylebox_override("hover", sb_h)
		b.add_theme_stylebox_override("pressed", sb_h)

func apply_confirm_button_style(b: Button) -> void:
	var tex_n = load("res://assets/ui/btn_confirm_normal.png")
	var tex_h = load("res://assets/ui/btn_confirm_hover.png")
	if tex_n and tex_h:
		var sb_n = StyleBoxTexture.new(); sb_n.texture = tex_n; sb_n.set_texture_margin_all(10)
		var sb_h = StyleBoxTexture.new(); sb_h.texture = tex_h; sb_h.set_texture_margin_all(10)
		b.add_theme_stylebox_override("normal", sb_n)
		b.add_theme_stylebox_override("hover", sb_h)
		b.add_theme_stylebox_override("pressed", sb_h)
		b.add_theme_color_override("font_color", Color(1.0, 0.95, 0.15))
		b.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))

# -------------------------------------------------------------
# PERSISTENCE LOAD / SAVE
# -------------------------------------------------------------
func load_saved_values() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if not sm: return
	
	if slider_pad_sens: slider_pad_sens.value = sm.gamepad_sensitivity; lbl_pad_sens_val.text = "%.1fx" % sm.gamepad_sensitivity
	if slider_mouse_sens: slider_mouse_sens.value = sm.mouse_sensitivity; lbl_mouse_sens_val.text = "%.1fx" % sm.mouse_sensitivity
	if slider_pad_deadzone: slider_pad_deadzone.value = sm.gamepad_deadzone; lbl_pad_deadzone_val.text = "%d%%" % int(sm.gamepad_deadzone * 100)
	if btn_aim_assist: btn_aim_assist.set_meta("state", sm.aim_assist); update_toggle_visual(btn_aim_assist, sm.aim_assist)
	
	if btn_vib_master: btn_vib_master.set_meta("state", sm.vib_master); update_toggle_visual(btn_vib_master, sm.vib_master)
	if btn_vib_shooting: btn_vib_shooting.set_meta("state", sm.vib_shooting); update_toggle_visual(btn_vib_shooting, sm.vib_shooting)
	if btn_vib_melee: btn_vib_melee.set_meta("state", sm.vib_melee); update_toggle_visual(btn_vib_melee, sm.vib_melee)
	if btn_vib_damage: btn_vib_damage.set_meta("state", sm.vib_damage); update_toggle_visual(btn_vib_damage, sm.vib_damage)
	if btn_vib_reload: btn_vib_reload.set_meta("state", sm.vib_reload); update_toggle_visual(btn_vib_reload, sm.vib_reload)
	if btn_vib_ui: btn_vib_ui.set_meta("state", sm.vib_ui); update_toggle_visual(btn_vib_ui, sm.vib_ui)
	if slider_vib_strength: slider_vib_strength.value = sm.vib_strength; lbl_vib_strength_val.text = "%d%%" % int(sm.vib_strength * 100)
	
	if slider_vol_master: slider_vol_master.value = sm.volume_master; lbl_vol_master.text = "%d%%" % int(sm.volume_master * 100)
	if slider_vol_bgm: slider_vol_bgm.value = sm.volume_bgm; lbl_vol_bgm.text = "%d%%" % int(sm.volume_bgm * 100)
	if slider_vol_sfx: slider_vol_sfx.value = sm.volume_sfx; lbl_vol_sfx.text = "%d%%" % int(sm.volume_sfx * 100)
	if slider_vol_reload: slider_vol_reload.value = sm.volume_reload; lbl_vol_reload.text = "%d%%" % int(sm.volume_reload * 100)
	
	if slider_shake: slider_shake.value = sm.screen_shake_strength; lbl_shake.text = "%d%%" % int(sm.screen_shake_strength * 100)
	if btn_fullscreen: btn_fullscreen.set_meta("state", sm.fullscreen); update_toggle_visual(btn_fullscreen, sm.fullscreen)
	if btn_scanlines: btn_scanlines.set_meta("state", sm.crt_scanlines); update_toggle_visual(btn_scanlines, sm.crt_scanlines)
	if btn_damage_popups: btn_damage_popups.set_meta("state", sm.damage_popups); update_toggle_visual(btn_damage_popups, sm.damage_popups)

func save_all_values() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if not sm: return
	
	if slider_pad_sens: sm.gamepad_sensitivity = slider_pad_sens.value
	if slider_mouse_sens: sm.mouse_sensitivity = slider_mouse_sens.value
	if slider_pad_deadzone: sm.gamepad_deadzone = slider_pad_deadzone.value
	if btn_aim_assist: sm.aim_assist = btn_aim_assist.get_meta("state", true)
	
	if btn_vib_master: sm.vib_master = btn_vib_master.get_meta("state", true)
	if btn_vib_shooting: sm.vib_shooting = btn_vib_shooting.get_meta("state", true)
	if btn_vib_melee: sm.vib_melee = btn_vib_melee.get_meta("state", true)
	if btn_vib_damage: sm.vib_damage = btn_vib_damage.get_meta("state", true)
	if btn_vib_reload: sm.vib_reload = btn_vib_reload.get_meta("state", true)
	if btn_vib_ui: sm.vib_ui = btn_vib_ui.get_meta("state", true)
	if slider_vib_strength: sm.vib_strength = slider_vib_strength.value
	
	if slider_vol_master: sm.volume_master = slider_vol_master.value
	if slider_vol_bgm: sm.volume_bgm = slider_vol_bgm.value
	if slider_vol_sfx: sm.volume_sfx = slider_vol_sfx.value
	if slider_vol_reload: sm.volume_reload = slider_vol_reload.value
	
	if slider_shake: sm.screen_shake_strength = slider_shake.value
	if btn_fullscreen: sm.fullscreen = btn_fullscreen.get_meta("state", false)
	if btn_scanlines: sm.crt_scanlines = btn_scanlines.get_meta("state", true)
	if btn_damage_popups: sm.damage_popups = btn_damage_popups.get_meta("state", true)
	
	# Apply fullscreen to engine window
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN and sm.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN and not sm.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
	sm.save_game()

func reset_defaults() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if not sm: return
	sm.gamepad_sensitivity = 1.0
	sm.mouse_sensitivity = 1.0
	sm.gamepad_deadzone = 0.15
	sm.aim_assist = true
	sm.vib_master = true
	sm.vib_shooting = false
	sm.vib_melee = true
	sm.vib_damage = true
	sm.vib_reload = true
	sm.vib_ui = true
	sm.vib_strength = 1.0
	sm.volume_master = 1.0
	sm.volume_bgm = 0.8
	sm.volume_sfx = 1.0
	sm.volume_reload = 1.0
	sm.screen_shake_strength = 1.0
	sm.crt_scanlines = true
	sm.damage_popups = true
	sm.fullscreen = false
	load_saved_values()
	if sfx_click: sfx_click.play()
