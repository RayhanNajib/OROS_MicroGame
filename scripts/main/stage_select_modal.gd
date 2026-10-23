extends ColorRect

@onready var stages_grid: VBoxContainer = $CenterContainer/Panel/Margin/VBox/Scroll/StagesVBox
@onready var close_btn: Button = $CenterContainer/Panel/Margin/VBox/CloseBtn
@onready var sfx_click: AudioStreamPlayer = $SFXClick

signal stage_selected(stage_id: int)

func _ready() -> void:
	visible = false
	if close_btn:
		close_btn.pressed.connect(func():
			if sfx_click: sfx_click.play()
			visible = false
		)

func open_stage_select() -> void:
	visible = true
	if sfx_click: sfx_click.play()
	build_stage_list()

func build_stage_list() -> void:
	if not stages_grid: return
	for child in stages_grid.get_children():
		child.queue_free()
		
	var font_orb = load("res://assets/fonts/Orbitron-Bold.ttf")
	var font_silk = load("res://assets/fonts/Silkscreen-Bold.ttf")
	var font_tech = load("res://assets/fonts/tech_font.ttf")
	
	for s_id in range(1, 6):
		var cfg = GameState.stage_configs[s_id]
		var s_data = SaveManager.stages_data.get(s_id, {"unlocked": (s_id == 1), "high_rank": "-", "cleared": false})
		var is_unlocked: bool = s_data.get("unlocked", false) or (s_id == 1)
		var is_current: bool = (GameState.current_stage == s_id)
		
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(900, 110)
		
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.12, 0.18, 0.96) if is_unlocked else Color(0.04, 0.05, 0.08, 0.85)
		style.border_color = Color(0.0, 0.9, 1.0, 0.9) if is_current else (Color(0.2, 0.6, 0.85, 0.7) if is_unlocked else Color(0.3, 0.35, 0.45, 0.4))
		if s_id == 5 and is_unlocked:
			style.border_color = Color(1.0, 0.9, 0.1, 1.0) # High-voltage yellow for Nightmare
		style.set_border_width_all(3 if is_current else 2)
		style.set_corner_radius_all(6)
		panel.add_theme_stylebox_override("panel", style)
		
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 20)
		margin.add_theme_constant_override("margin_right", 20)
		margin.add_theme_constant_override("margin_top", 14)
		margin.add_theme_constant_override("margin_bottom", 14)
		
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 20)
		
		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 4)
		
		var title_lbl := Label.new()
		title_lbl.text = "[ STAGE %02d ] %s // TINGKAT: %s" % [s_id, cfg["title"], cfg["difficulty"]]
		title_lbl.add_theme_font_override("font", font_orb)
		title_lbl.add_theme_font_size_override("font_size", 18)
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.1) if (s_id == 5 and is_unlocked) else (Color(0.0, 0.94, 1.0) if is_unlocked else Color(0.5, 0.55, 0.65)))
		info_vbox.add_child(title_lbl)
		
		var desc_lbl := Label.new()
		desc_lbl.text = "TARGET SURVIVE: %d DETIK  |  MISI: %s  |  APEX BOSS: %s" % [int(cfg["target_time"]), cfg["objective"], cfg["boss_name"]]
		desc_lbl.add_theme_font_override("font", font_tech)
		desc_lbl.add_theme_font_size_override("font_size", 15)
		desc_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0) if is_unlocked else Color(0.45, 0.5, 0.6))
		info_vbox.add_child(desc_lbl)
		
		var rank_lbl := Label.new()
		rank_lbl.text = "EVALUASI RANK TERTINGGI: %s" % s_data.get("high_rank", "-")
		rank_lbl.add_theme_font_override("font", font_silk)
		rank_lbl.add_theme_font_size_override("font_size", 13)
		rank_lbl.add_theme_color_override("font_color", Color(0.13, 0.95, 0.4))
		info_vbox.add_child(rank_lbl)
		
		hbox.add_child(info_vbox)
		
		# Action Buttons Container
		var btn_vbox := VBoxContainer.new()
		btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		btn_vbox.add_theme_constant_override("separation", 6)
		
		if is_unlocked:
			var launch_btn := Button.new()
			launch_btn.custom_minimum_size = Vector2(240, 48)
			launch_btn.add_theme_font_override("font", font_orb)
			launch_btn.add_theme_font_size_override("font_size", 15)
			launch_btn.text = "[ > LUNCURKAN MISI < ]" if is_current else "[ PILIH & LUNCURKAN ]"
			launch_btn.pressed.connect(func():
				GameState.current_stage = s_id
				stage_selected.emit(s_id)
				if sfx_click: sfx_click.play()
				visible = false
				GameState.reset_run()
				get_tree().change_scene_to_file("res://scenes/main/GameArena.tscn")
			)
			btn_vbox.add_child(launch_btn)
		else:
			var req = "BUTUH RANK B DI STAGE %d" % (s_id - 1)
			if s_id == 4: req = "BUTUH RANK A DI STAGE 3"
			elif s_id == 5: req = "BUTUH RANK S DI STAGE 4"
			var lock_btn := Button.new()
			lock_btn.custom_minimum_size = Vector2(240, 48)
			lock_btn.add_theme_font_override("font", font_tech)
			lock_btn.add_theme_font_size_override("font_size", 12)
			lock_btn.text = "[ TERKUNCI ]\n%s" % req
			lock_btn.disabled = true
			btn_vbox.add_child(lock_btn)
			
		hbox.add_child(btn_vbox)
		margin.add_child(hbox)
		panel.add_child(margin)
		stages_grid.add_child(panel)
