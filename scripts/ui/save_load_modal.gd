extends CanvasLayer

signal modal_closed

var font_orb: Font = null
var font_tech: Font = null
var font_silk: Font = null

var slot_rows: Array[Dictionary] = []
var active_rename_slot: int = -1
var rename_dialog: PanelContainer = null
var rename_input: LineEdit = null
var confirm_delete_dialog: PanelContainer = null
var delete_target_slot: int = -1

var status_banner: Label = null
var active_slot_label: Label = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	if ResourceLoader.exists("res://assets/fonts/Orbitron-Bold.ttf"):
		font_orb = load("res://assets/fonts/Orbitron-Bold.ttf")
	if ResourceLoader.exists("res://assets/fonts/tech_font.ttf"):
		font_tech = load("res://assets/fonts/tech_font.ttf")
	if ResourceLoader.exists("res://assets/fonts/Silkscreen-Bold.ttf"):
		font_silk = load("res://assets/fonts/Silkscreen-Bold.ttf")
		
	build_ui()
	refresh_slots_display()

func open_modal() -> void:
	visible = true
	refresh_slots_display()
	show_feedback("PILIH SLOT UNTUK MENYIMPAN, MEMUAT, GANTI NAMA, ATAU HAPUS DATA ARSIP.")

func close_modal() -> void:
	visible = false
	if rename_dialog: rename_dialog.visible = false
	if confirm_delete_dialog: confirm_delete_dialog.visible = false
	modal_closed.emit()

func _input(event: InputEvent) -> void:
	if not visible: return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ESCAPE:
			if rename_dialog and rename_dialog.visible:
				rename_dialog.visible = false
				get_viewport().set_input_as_handled()
				return
			if confirm_delete_dialog and confirm_delete_dialog.visible:
				confirm_delete_dialog.visible = false
				get_viewport().set_input_as_handled()
				return
			get_viewport().set_input_as_handled()
			close_modal()
	elif event is InputEventJoypadButton and event.is_pressed():
		if event.button_index == JOY_BUTTON_B:
			if rename_dialog and rename_dialog.visible:
				rename_dialog.visible = false
				get_viewport().set_input_as_handled()
				return
			if confirm_delete_dialog and confirm_delete_dialog.visible:
				confirm_delete_dialog.visible = false
				get_viewport().set_input_as_handled()
				return
			get_viewport().set_input_as_handled()
			close_modal()

func play_sfx() -> void:
	if ResourceLoader.exists("res://assets/sfx/ui_click.wav"):
		var p = AudioStreamPlayer.new()
		p.stream = load("res://assets/sfx/ui_click.wav")
		p.bus = "SFX"
		add_child(p)
		p.play()
		p.finished.connect(p.queue_free)

func show_feedback(msg: String, is_error: bool = false) -> void:
	if status_banner:
		status_banner.text = msg
		status_banner.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35) if is_error else Color(0.15, 0.95, 1.0))

func build_ui() -> void:
	layer = 125
	
	# Backdrop Dim
	var bg = ColorRect.new()
	bg.name = "Backdrop"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.015, 0.02, 0.05, 0.94)
	add_child(bg)
	
	# Main Center Container
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	# Panel Card
	var main_panel = PanelContainer.new()
	main_panel.custom_minimum_size = Vector2(1100, 780)
	var sb_box = StyleBoxFlat.new()
	sb_box.bg_color = Color(0.04, 0.06, 0.11, 0.96)
	sb_box.border_color = Color(0.0, 0.85, 1.0, 0.9)
	sb_box.set_border_width_all(2)
	sb_box.corner_radius_top_left = 10
	sb_box.corner_radius_top_right = 10
	sb_box.corner_radius_bottom_left = 10
	sb_box.corner_radius_bottom_right = 10
	sb_box.shadow_color = Color(0, 0.8, 1, 0.3)
	sb_box.shadow_size = 18
	main_panel.add_theme_stylebox_override("panel", sb_box)
	center.add_child(main_panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	main_panel.add_child(margin)
	
	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 12)
	margin.add_child(root_vbox)
	
	# Header
	var title = Label.new()
	title.text = "PROTOKOL ARSIP SIBER // 5 SLOT SAVE & LOAD"
	if font_orb: title.add_theme_font_override("font", font_orb)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "MANUAL SAVE & LOAD EXCLUSIVE HOMESCREEN • AUTOSAVE DINONAKTIFKAN • PROGRES TIDAK TERSIMPAN JIKA TIDAK DI-SAVE"
	if font_tech: subtitle.add_theme_font_override("font", font_tech)
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(subtitle)
	
	active_slot_label = Label.new()
	active_slot_label.text = "SLOT AKTIF DALAM MEMORI: [ TIDAK ADA / DEFAULT RESET ]"
	if font_tech: active_slot_label.add_theme_font_override("font", font_tech)
	active_slot_label.add_theme_font_size_override("font_size", 13)
	active_slot_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4))
	active_slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(active_slot_label)
	
	# Status Feedback Banner
	status_banner = Label.new()
	status_banner.text = "SIAP MELAKUKAN OPERASI DATA."
	if font_tech: status_banner.add_theme_font_override("font", font_tech)
	status_banner.add_theme_font_size_override("font_size", 14)
	status_banner.add_theme_color_override("font_color", Color(0.15, 0.95, 1.0))
	status_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(status_banner)
	
	var div = HSeparator.new()
	root_vbox.add_child(div)
	
	# 5 Slots Container
	var slots_vbox = VBoxContainer.new()
	slots_vbox.add_theme_constant_override("separation", 10)
	slots_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(slots_vbox)
	
	slot_rows.clear()
	for i in range(1, SaveManager.MAX_SLOTS + 1):
		var row_panel = PanelContainer.new()
		var row_sb = StyleBoxFlat.new()
		row_sb.bg_color = Color(0.06, 0.09, 0.16, 0.85)
		row_sb.border_color = Color(0.18, 0.4, 0.6, 0.7)
		row_sb.set_border_width_all(1)
		row_sb.corner_radius_top_left = 6
		row_sb.corner_radius_top_right = 6
		row_sb.corner_radius_bottom_left = 6
		row_sb.corner_radius_bottom_right = 6
		row_panel.add_theme_stylebox_override("panel", row_sb)
		slots_vbox.add_child(row_panel)
		
		var row_margin = MarginContainer.new()
		row_margin.add_theme_constant_override("margin_left", 16)
		row_margin.add_theme_constant_override("margin_right", 16)
		row_margin.add_theme_constant_override("margin_top", 10)
		row_margin.add_theme_constant_override("margin_bottom", 10)
		row_panel.add_child(row_margin)
		
		var row_hbox = HBoxContainer.new()
		row_hbox.add_theme_constant_override("separation", 16)
		row_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		row_margin.add_child(row_hbox)
		
		# Slot Info VBox
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 4)
		row_hbox.add_child(info_vbox)
		
		var name_lbl = Label.new()
		name_lbl.text = "SLOT %02d" % i
		if font_orb: name_lbl.add_theme_font_override("font", font_orb)
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		info_vbox.add_child(name_lbl)
		
		var details_lbl = Label.new()
		details_lbl.text = "[ DATA KOSONG ]"
		if font_tech: details_lbl.add_theme_font_override("font", font_tech)
		details_lbl.add_theme_font_size_override("font_size", 13)
		details_lbl.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
		info_vbox.add_child(details_lbl)
		
		# Buttons HBox
		var btn_hbox = HBoxContainer.new()
		btn_hbox.add_theme_constant_override("separation", 8)
		row_hbox.add_child(btn_hbox)
		
		var btn_save = create_custom_button("[ SIMPAN ]", Color(0.2, 0.9, 0.4))
		var btn_load = create_custom_button("[ MUAT ]", Color(0.15, 0.9, 1.0))
		var btn_rename = create_custom_button("[ GANTI NAMA ]", Color(1.0, 0.85, 0.2))
		var btn_delete = create_custom_button("[ HAPUS ]", Color(1.0, 0.35, 0.35))
		
		var s_idx = i
		btn_save.pressed.connect(func(): on_save_clicked(s_idx))
		btn_load.pressed.connect(func(): on_load_clicked(s_idx))
		btn_rename.pressed.connect(func(): on_rename_clicked(s_idx))
		btn_delete.pressed.connect(func(): on_delete_clicked(s_idx))
		
		btn_hbox.add_child(btn_save)
		btn_hbox.add_child(btn_load)
		btn_hbox.add_child(btn_rename)
		btn_hbox.add_child(btn_delete)
		
		slot_rows.append({
			"index": i,
			"name_lbl": name_lbl,
			"details_lbl": details_lbl,
			"btn_save": btn_save,
			"btn_load": btn_load,
			"btn_rename": btn_rename,
			"btn_delete": btn_delete,
			"panel": row_panel
		})
		
	# Bottom Controls
	var bottom_div = HSeparator.new()
	root_vbox.add_child(bottom_div)
	
	var bottom_hbox = HBoxContainer.new()
	bottom_hbox.add_theme_constant_override("separation", 20)
	bottom_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	root_vbox.add_child(bottom_hbox)
	
	var wipe_all_btn = create_custom_button("[ RESET SEMUA ARSIP / WIPE ALL ]", Color(1.0, 0.25, 0.25), Vector2(280, 44))
	wipe_all_btn.pressed.connect(on_wipe_all_clicked)
	bottom_hbox.add_child(wipe_all_btn)
	
	var close_btn = create_custom_button("[ KEMBALI KE HOMESCREEN ]", Color(0.9, 0.9, 0.9), Vector2(280, 44))
	close_btn.pressed.connect(func():
		play_sfx()
		close_modal()
	)
	bottom_hbox.add_child(close_btn)
	
	build_rename_dialog()
	build_delete_dialog()

func create_custom_button(txt: String, col: Color, min_size: Vector2 = Vector2(105, 38)) -> Button:
	var btn = Button.new()
	btn.text = txt
	btn.custom_minimum_size = min_size
	if font_orb: btn.add_theme_font_override("font", font_orb)
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", col)
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	
	var sb_n = StyleBoxFlat.new()
	sb_n.bg_color = Color(col.r * 0.15, col.g * 0.15, col.b * 0.15, 0.85)
	sb_n.border_color = col
	sb_n.set_border_width_all(1)
	sb_n.corner_radius_top_left = 4
	sb_n.corner_radius_top_right = 4
	sb_n.corner_radius_bottom_left = 4
	sb_n.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", sb_n)
	
	var sb_h = StyleBoxFlat.new()
	sb_h.bg_color = Color(col.r * 0.35, col.g * 0.35, col.b * 0.35, 0.95)
	sb_h.border_color = Color(1, 1, 1)
	sb_h.set_border_width_all(1)
	sb_h.corner_radius_top_left = 4
	sb_h.corner_radius_top_right = 4
	sb_h.corner_radius_bottom_left = 4
	sb_h.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.add_theme_stylebox_override("pressed", sb_h)
	
	return btn

func build_rename_dialog() -> void:
	rename_dialog = PanelContainer.new()
	rename_dialog.visible = false
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.05, 0.09, 0.98)
	sb.border_color = Color(1.0, 0.85, 0.2)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	rename_dialog.add_theme_stylebox_override("panel", sb)
	rename_dialog.custom_minimum_size = Vector2(480, 220)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.add_child(rename_dialog)
	
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 24)
	m.add_theme_constant_override("margin_right", 24)
	m.add_theme_constant_override("margin_top", 20)
	m.add_theme_constant_override("margin_bottom", 20)
	rename_dialog.add_child(m)
	
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	m.add_child(vb)
	
	var title = Label.new()
	title.text = "GANTI NAMA SLOT ARSIP"
	if font_orb: title.add_theme_font_override("font", font_orb)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	
	rename_input = LineEdit.new()
	rename_input.placeholder_text = "Masukkan nama slot baru..."
	rename_input.max_length = 24
	if font_tech: rename_input.add_theme_font_override("font", font_tech)
	rename_input.add_theme_font_size_override("font_size", 15)
	vb.add_child(rename_input)
	rename_input.text_submitted.connect(func(_new_text): confirm_rename())
	
	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb)
	
	var ok_btn = create_custom_button("[ KONFIRMASI ]", Color(0.2, 0.9, 0.4), Vector2(140, 38))
	ok_btn.pressed.connect(confirm_rename)
	hb.add_child(ok_btn)
	
	var cancel_btn = create_custom_button("[ BATAL ]", Color(0.7, 0.7, 0.7), Vector2(140, 38))
	cancel_btn.pressed.connect(func():
		play_sfx()
		rename_dialog.visible = false
	)
	hb.add_child(cancel_btn)

func build_delete_dialog() -> void:
	confirm_delete_dialog = PanelContainer.new()
	confirm_delete_dialog.visible = false
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.02, 0.03, 0.98)
	sb.border_color = Color(1.0, 0.25, 0.25)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	confirm_delete_dialog.add_theme_stylebox_override("panel", sb)
	confirm_delete_dialog.custom_minimum_size = Vector2(480, 200)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.add_child(confirm_delete_dialog)
	
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 24)
	m.add_theme_constant_override("margin_right", 24)
	m.add_theme_constant_override("margin_top", 20)
	m.add_theme_constant_override("margin_bottom", 20)
	confirm_delete_dialog.add_child(m)
	
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	m.add_child(vb)
	
	var title = Label.new()
	title.text = "KONFIRMASI PENGHAPUSAN SLOT"
	if font_orb: title.add_theme_font_override("font", font_orb)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	
	var warn = Label.new()
	warn.text = "Seluruh progres pada slot ini akan dimusnahkan secara permanen.\nLanjutkan?"
	if font_tech: warn.add_theme_font_override("font", font_tech)
	warn.add_theme_font_size_override("font_size", 13)
	warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(warn)
	
	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb)
	
	var ok_btn = create_custom_button("[ HAPUS PERMANEN ]", Color(1.0, 0.25, 0.25), Vector2(160, 38))
	ok_btn.pressed.connect(confirm_delete)
	hb.add_child(ok_btn)
	
	var cancel_btn = create_custom_button("[ BATAL ]", Color(0.7, 0.7, 0.7), Vector2(140, 38))
	cancel_btn.pressed.connect(func():
		play_sfx()
		confirm_delete_dialog.visible = false
	)
	hb.add_child(cancel_btn)

func refresh_slots_display() -> void:
	SaveManager.init_slots_meta()
	
	if active_slot_label:
		if SaveManager.active_slot_idx > 0 and SaveManager.slots_meta.has(SaveManager.active_slot_idx):
			var active_meta = SaveManager.slots_meta[SaveManager.active_slot_idx]
			active_slot_label.text = "SLOT AKTIF DALAM MEMORI: [ %s (SLOT %02d) ]" % [active_meta.get("name", "SLOT"), SaveManager.active_slot_idx]
			active_slot_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4))
		else:
			active_slot_label.text = "SLOT AKTIF DALAM MEMORI: [ BELUM DIMUAT / PROGRES SESI BERSIH ]"
			active_slot_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
			
	for r in slot_rows:
		var idx: int = r["index"]
		var meta: Dictionary = SaveManager.slots_meta.get(idx, {})
		var is_empty: bool = meta.get("empty", true)
		var slot_name: String = meta.get("name", "SLOT %02d" % idx)
		
		r["name_lbl"].text = "%02d. %s" % [idx, slot_name]
		if is_empty:
			r["details_lbl"].text = "● STATUS: [ KOSONG / BELUM ADA DATA ARSIP ]"
			r["details_lbl"].add_theme_color_override("font_color", Color(0.45, 0.5, 0.6))
			r["btn_load"].disabled = true
			r["btn_delete"].disabled = true
		else:
			var ts: String = meta.get("timestamp", "-")
			var stage: int = meta.get("stage_reached", 1)
			var cred: int = meta.get("credits", 0)
			var runes_cnt: int = meta.get("runes_count", 0)
			r["details_lbl"].text = "● TERSIMPAN: %s | KREDIT: %d NC | STAGE TERTINGGI: 0%d | RUNES: %d" % [ts, cred, stage, runes_cnt]
			r["details_lbl"].add_theme_color_override("font_color", Color(0.2, 0.85, 1.0))
			r["btn_load"].disabled = false
			r["btn_delete"].disabled = false

func on_save_clicked(slot_idx: int) -> void:
	play_sfx()
	var success = SaveManager.save_to_slot(slot_idx)
	if success:
		refresh_slots_display()
		show_feedback("BERHASIL MENYIMPAN DATA GAME KE %s!" % SaveManager.slots_meta[slot_idx]["name"])
	else:
		show_feedback("GAGAL MENYIMPAN DATA KE SLOT %02d!" % slot_idx, true)

func on_load_clicked(slot_idx: int) -> void:
	play_sfx()
	var success = SaveManager.load_from_slot(slot_idx)
	if success:
		refresh_slots_display()
		show_feedback("DATA %s BERHASIL DIMUAT KE SESI GAME!" % SaveManager.slots_meta[slot_idx]["name"])
	else:
		show_feedback("GAGAL MEMUAT DATA DARI SLOT %02d!" % slot_idx, true)

func on_rename_clicked(slot_idx: int) -> void:
	play_sfx()
	active_rename_slot = slot_idx
	var current_name = SaveManager.slots_meta.get(slot_idx, {}).get("name", "SLOT %02d" % slot_idx)
	rename_input.text = current_name
	rename_dialog.visible = true
	rename_input.grab_focus()
	rename_input.select_all()

func confirm_rename() -> void:
	if active_rename_slot <= 0: return
	play_sfx()
	var new_txt = rename_input.text.strip_edges()
	SaveManager.rename_slot(active_rename_slot, new_txt)
	rename_dialog.visible = false
	refresh_slots_display()
	show_feedback("NAMA SLOT %02d DIUBAH MENJADI: %s" % [active_rename_slot, new_txt])
	active_rename_slot = -1

func on_delete_clicked(slot_idx: int) -> void:
	play_sfx()
	delete_target_slot = slot_idx
	confirm_delete_dialog.visible = true

func confirm_delete() -> void:
	if delete_target_slot <= 0: return
	play_sfx()
	SaveManager.delete_slot(delete_target_slot)
	confirm_delete_dialog.visible = false
	refresh_slots_display()
	show_feedback("SLOT %02d BERHASIL DIHAPUS DAN DIKOSONGKAN." % delete_target_slot)
	delete_target_slot = -1

func on_wipe_all_clicked() -> void:
	play_sfx()
	SaveManager.wipe_all_save_data()
	refresh_slots_display()
	show_feedback("SELURUH DATA ARSIP LOKAL TELAH DIRESET BERSIH.")
