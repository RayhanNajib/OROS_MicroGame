extends CanvasLayer

signal resume_requested

var disconnected_device_id: int = -1
var disconnected_player: int = 1
var is_reconnected: bool = false

var alert_title: Label
var alert_desc: Label
var status_lbl: Label
var resume_btn: Button
var keyboard_fallback_btn: Button
var panel_box: PanelContainer
var sfx_beep: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 110
	visible = false
	build_ui()
	
	if InputManager:
		if InputManager.has_signal("input_device_disconnected"):
			InputManager.input_device_disconnected.connect(_on_device_disconnected)
		if InputManager.has_signal("input_device_reconnected"):
			InputManager.input_device_reconnected.connect(_on_device_reconnected)

func build_ui() -> void:
	# Audio alert
	sfx_beep = AudioStreamPlayer.new()
	var beep_res = load("res://assets/audio/sfx_countdown_beep.wav")
	if beep_res:
		sfx_beep.stream = beep_res
	add_child(sfx_beep)
	
	# Dim Background Overlay
	var overlay = ColorRect.new()
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.color = Color(0.04, 0.01, 0.02, 0.88)
	add_child(overlay)
	
	# Center Container
	var center = CenterContainer.new()
	center.anchors_preset = Control.PRESET_FULL_RECT
	add_child(center)
	
	# Chamfered Cyber Panel
	panel_box = PanelContainer.new()
	panel_box.custom_minimum_size = Vector2(620, 360)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.02, 0.03, 0.98)
	sb.border_color = Color(1.0, 0.25, 0.25, 0.95)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.shadow_color = Color(1.0, 0.1, 0.15, 0.35)
	sb.shadow_size = 20
	sb.content_margin_left = 32
	sb.content_margin_right = 32
	sb.content_margin_top = 28
	sb.content_margin_bottom = 28
	panel_box.add_theme_stylebox_override("panel", sb)
	center.add_child(panel_box)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel_box.add_child(vbox)
	
	var font_orb = load("res://assets/fonts/Orbitron-Bold.ttf")
	var font_tech = load("res://assets/fonts/tech_font.ttf")
	
	# Title
	alert_title = Label.new()
	alert_title.text = "[ ! ] PERINGATAN SISTEM: KONTROLER TERPUTUS [ ! ]"
	alert_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_orb:
		alert_title.add_theme_font_override("font", font_orb)
	alert_title.add_theme_font_size_override("font_size", 21)
	alert_title.add_theme_color_override("font_color", Color(1.0, 0.25, 0.3, 1.0))
	vbox.add_child(alert_title)
	
	# Subtitle
	var sub = Label.new()
	sub.text = "// KONEKSI PERANGKAT INPUT TERPUTUS // GAME OTOMATIS DIJEDA //"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_tech:
		sub.add_theme_font_override("font", font_tech)
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2, 0.9))
	vbox.add_child(sub)
	
	# Separator line
	var sep = HSeparator.new()
	var sep_sb = StyleBoxFlat.new()
	sep_sb.bg_color = Color(1.0, 0.25, 0.25, 0.4)
	sep_sb.set_border_width_all(1)
	sep.add_theme_stylebox_override("separator", sep_sb)
	vbox.add_child(sep)
	
	# Description Box
	alert_desc = Label.new()
	alert_desc.text = "Perangkat Gamepad terputus di tengah pertempuran!\n\nSilakan colokkan / hubungkan kembali Gamepad Anda untuk melanjutkan, atau beralih ke kontrol Keyboard & Mouse darurat."
	alert_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if font_tech:
		alert_desc.add_theme_font_override("font", font_tech)
	alert_desc.add_theme_font_size_override("font_size", 16)
	alert_desc.add_theme_color_override("font_color", Color(0.9, 0.92, 0.96, 1.0))
	vbox.add_child(alert_desc)
	
	# Status Indicator
	status_lbl = Label.new()
	status_lbl.text = "STATUS: MENUNGGU PERANGKAT TERSAMBUNG KEMBALI..."
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_tech:
		status_lbl.add_theme_font_override("font", font_tech)
	status_lbl.add_theme_font_size_override("font_size", 15)
	status_lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.1, 1.0))
	vbox.add_child(status_lbl)
	
	# Button Row
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 18)
	vbox.add_child(btn_row)
	
	resume_btn = Button.new()
	resume_btn.text = "[ > SAMBUNGKAN ULANG & LANJUTKAN < ]"
	resume_btn.custom_minimum_size = Vector2(240, 48)
	if font_tech:
		resume_btn.add_theme_font_override("font", font_tech)
	resume_btn.add_theme_font_size_override("font_size", 15)
	style_action_button(resume_btn, Color(0.0, 0.8, 0.4))
	resume_btn.pressed.connect(_on_resume_pressed)
	btn_row.add_child(resume_btn)
	
	keyboard_fallback_btn = Button.new()
	keyboard_fallback_btn.text = "[ BERALIH KE KONTROL KEYBOARD ]"
	keyboard_fallback_btn.custom_minimum_size = Vector2(240, 48)
	if font_tech:
		keyboard_fallback_btn.add_theme_font_override("font", font_tech)
	keyboard_fallback_btn.add_theme_font_size_override("font_size", 15)
	style_action_button(keyboard_fallback_btn, Color(0.1, 0.7, 0.95))
	keyboard_fallback_btn.pressed.connect(_on_keyboard_fallback_pressed)
	btn_row.add_child(keyboard_fallback_btn)

func style_action_button(btn: Button, accent_col: Color) -> void:
	var sb_n = StyleBoxFlat.new()
	sb_n.bg_color = Color(0.1, 0.15, 0.22, 0.95)
	sb_n.border_color = accent_col
	sb_n.set_border_width_all(2)
	sb_n.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", sb_n)
	
	var sb_h = StyleBoxFlat.new()
	sb_h.bg_color = accent_col.lerp(Color.WHITE, 0.15)
	sb_h.border_color = Color.WHITE
	sb_h.set_border_width_all(2)
	sb_h.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.add_theme_stylebox_override("focus", sb_h)
	btn.add_theme_color_override("font_hover_color", Color(0.04, 0.07, 0.1))
	btn.add_theme_color_override("font_focus_color", Color(0.04, 0.07, 0.1))

func open_modal_for_disconnect(p_index: int, dev_name: String) -> void:
	disconnected_player = p_index
	is_reconnected = false
	
	alert_desc.text = "Koneksi Perangkat [ Player %d ] (%s) terputus di tengah pertempuran!\n\nSilakan sambungkan kembali Gamepad Anda untuk melanjutkan,\natau beralih ke kontrol Keyboard darurat." % [disconnected_player, dev_name]
	status_lbl.text = "STATUS: MENUNGGU PERANGKAT TERSAMBUNG KEMBALI..."
	status_lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.1, 1.0))
	
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if sfx_beep:
		sfx_beep.play()
	
	keyboard_fallback_btn.grab_focus()

func _on_device_disconnected(device_id: int, device_name: String, p_index: int) -> void:
	# Only interrupt if currently in an active game
	if get_tree().current_scene and get_tree().current_scene.name == "GameArena":
		open_modal_for_disconnect(p_index if p_index > 0 else 1, device_name)

func _on_device_reconnected(device_id: int, device_name: String, p_index: int) -> void:
	if visible:
		is_reconnected = true
		status_lbl.text = "[ OK ] PERANGKAT TERHUBUNG KEMBALI: %s!" % device_name
		status_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5, 1.0))
		resume_btn.grab_focus()

func _on_resume_pressed() -> void:
	close_modal()

func _on_keyboard_fallback_pressed() -> void:
	# Fallback player to keyboard
	if InputManager:
		if disconnected_player == 2:
			InputManager.p2_scheme = "keyboard"
			InputManager.scheme_changed.emit(2, "keyboard")
		else:
			InputManager.p1_scheme = "keyboard"
			InputManager.scheme_changed.emit(1, "keyboard")
	close_modal()

func _on_settings_closed() -> void:
	pass

func close_modal() -> void:
	visible = false
	get_tree().paused = false
	resume_requested.emit()
