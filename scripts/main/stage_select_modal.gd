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
	var font_pix = load("res://assets/fonts/PixelifySans-Regular.ttf")
	
	for s_id in range(1, 6):
		var cfg = GameState.stage_configs[s_id]
		var s_data = SaveManager.stages_data.get(s_id, {"unlocked": (s_id == 1), "high_rank": "-", "cleared": false})
		var is_unlocked: bool = s_data.get("unlocked", false) or (s_id == 1)
		
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(880, 100)
		
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.12, 0.18, 0.95) if is_unlocked else Color(0.04, 0.06, 0.09, 0.8)
		style.border_color = Color(0.18, 0.65, 0.92, 0.8) if is_unlocked else Color(0.3, 0.35, 0.45, 0.5)
		if s_id == 5 and is_unlocked:
			style.border_color = Color(1.0, 0.25, 0.35, 1.0) # Red border for Nightmare
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		panel.add_theme_stylebox_override("panel", style)
		
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 16)
		margin.add_theme_constant_override("margin_right", 16)
		margin.add_theme_constant_override("margin_top", 12)
		margin.add_theme_constant_override("margin_bottom", 12)
		
		var hbox := HBoxContainer.new()
		hbox.add_theme_constants_override("separation", 18)
		
		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 4)
		
		var title_lbl := Label.new()
		title_lbl.text = "[ STAGE %02d ] %s // %s" % [s_id, cfg["title"], cfg["difficulty"]]
		title_lbl.add_theme_font_override("font", font_orb)
		title_lbl.add_theme_font_size_override("font_size", 13)
		if s_id == 5:
			title_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.4))
		else:
			title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25) if is_unlocked else Color(0.5, 0.55, 0.65))
		info_vbox.add_child(title_lbl)
		
		var desc_lbl := Label.new()
		desc_lbl.text = "TARGET: %d DETIK  |  MISI: %s  |  BOSS: %s" % [int(cfg["target_time"]), cfg["objective"], cfg["boss_name"]]
		desc_lbl.add_theme_font_override("font", font_pix)
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0) if is_unlocked else Color(0.4, 0.45, 0.55))
		info_vbox.add_child(desc_lbl)
		
		var rank_lbl := Label.new()
		rank_lbl.text = "HIGHEST RANK: %s" % s_data.get("high_rank", "-")
		rank_lbl.add_theme_font_override("font", font_orb)
		rank_lbl.add_theme_font_size_override("font_size", 10)
		rank_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
		info_vbox.add_child(rank_lbl)
		
		hbox.add_child(info_vbox)
		
		var action_btn := Button.new()
		action_btn.custom_minimum_size = Vector2(200, 48)
		action_btn.add_theme_font_override("font", font_orb)
		action_btn.add_theme_font_size_override("font_size", 11)
		
		if is_unlocked:
			action_btn.text = "[ PILIH SEKTOR ]" if GameState.current_stage != s_id else "[ SEKTOR AKTIF ]"
			action_btn.disabled = (GameState.current_stage == s_id)
			action_btn.pressed.connect(func():
				GameState.current_stage = s_id
				stage_selected.emit(s_id)
				if sfx_click: sfx_click.play()
				visible = false
			)
		else:
			var req = "BUTUH RANK B DI STAGE %d" % (s_id - 1)
			if s_id == 4: req = "BUTUH RANK A DI STAGE 3"
			elif s_id == 5: req = "BUTUH RANK S DI STAGE 4"
			action_btn.text = "[ TERKUNCI ]\n%s" % req
			action_btn.add_theme_font_size_override("font_size", 8)
			action_btn.disabled = true
			
		hbox.add_child(action_btn)
		margin.add_child(hbox)
		panel.add_child(margin)
		stages_grid.add_child(panel)
