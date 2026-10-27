extends ColorRect

@onready var step1_stage_select: Control = $CenterContainer/Panel/Margin/VBox/Step1StageSelect
@onready var step2_loadout_prep: Control = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep

@onready var wizard_title: Label = $CenterContainer/Panel/Margin/VBox/HeaderBox/WizardTitle
@onready var wizard_step_label: Label = $CenterContainer/Panel/Margin/VBox/HeaderBox/StepIndicator

# Step 1: Stages
@onready var stages_hbox: HBoxContainer = $CenterContainer/Panel/Margin/VBox/Step1StageSelect/StagesHBox

# Step 2: Loadout
@onready var hero_name_lbl: Label = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/HeroSection/HeroHeader/HeroName
@onready var hero_hp_lbl: Label = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/HeroSection/HeroHeader/HeroHP
@onready var hero_desc_lbl: Label = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/HeroSection/HeroDesc

@onready var btn_kael: Button = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/HeroSection/HeroGrid/BtnKael
@onready var btn_vex: Button = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/HeroSection/HeroGrid/BtnVex
@onready var btn_brutus: Button = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/HeroSection/HeroGrid/BtnBrutus
@onready var btn_nyx: Button = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/HeroSection/HeroGrid/BtnNyx

@onready var skin_default_btn: Button = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/HeroSection/SkinSwitcherHBox/SkinDefaultBtn
@onready var skin_custom_btn: Button = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/HeroSection/SkinSwitcherHBox/SkinCustomBtn

@onready var wep_name_lbl: Label = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/WeaponSection/WepHeader/WepName
@onready var wep_closeup: TextureRect = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/WeaponSection/WepHeader/WepCloseUp
@onready var wep_stats_lbl: Label = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/WeaponSection/WepStats

@onready var wep_skin_default_btn: Button = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/WeaponSection/WepSkinSwitcherHBox/WepSkinDefaultBtn
@onready var wep_skin_custom_btn: Button = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/WeaponSection/WepSkinSwitcherHBox/WepSkinCustomBtn

@onready var btn_revolver: Button = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/WeaponSection/WeaponGrid/BtnRevolver
@onready var btn_shotgun: Button = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/WeaponSection/WeaponGrid/BtnShotgun
@onready var btn_smg: Button = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/WeaponSection/WeaponGrid/BtnSMG
@onready var btn_railgun: Button = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/WeaponSection/WeaponGrid/BtnRailgun

@onready var synergy_banner: Label = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/SynergyBanner
@onready var right_side_portrait: TextureRect = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/RightSidePortrait
@onready var portrait_glint: ColorRect = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/RightSidePortrait/PortraitGlint

# Navigation buttons
@onready var back_btn: Button = $CenterContainer/Panel/Margin/VBox/BottomNav/BackBtn
@onready var shop_shortcut_btn: Button = $CenterContainer/Panel/Margin/VBox/BottomNav/ShopShortcutBtn
@onready var launch_btn: Button = $CenterContainer/Panel/Margin/VBox/BottomNav/LaunchBtn

@onready var sfx_click: AudioStreamPlayer = $SFXClick

signal open_shop_requested()

var current_step: int = 1
var vo_player: AudioStreamPlayer = null
var equip_sfx_player: AudioStreamPlayer = null

func _ready() -> void:
	visible = false
	if back_btn: back_btn.pressed.connect(_on_back_pressed)
	if shop_shortcut_btn: shop_shortcut_btn.pressed.connect(_on_shop_shortcut_pressed)
	if launch_btn: launch_btn.pressed.connect(_on_launch_pressed)

	vo_player = AudioStreamPlayer.new()
	vo_player.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
	add_child(vo_player)

	equip_sfx_player = AudioStreamPlayer.new()
	equip_sfx_player.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
	add_child(equip_sfx_player)

	setup_hero_btn(btn_kael, "kael")
	setup_hero_btn(btn_vex, "vex")
	setup_hero_btn(btn_brutus, "brutus")
	setup_hero_btn(btn_nyx, "nyx")

	setup_skin_buttons()
	setup_weapon_skin_buttons()

	setup_weapon_btn(btn_revolver, "revolver")
	setup_weapon_btn(btn_shotgun, "shotgun")
	setup_weapon_btn(btn_smg, "smg")
	setup_weapon_btn(btn_railgun, "railgun")

func play_hero_vo(hero_id: String) -> void:
	var path = "res://assets/audio/vo_%s_select.wav" % hero_id
	if ResourceLoader.exists(path):
		var st = load(path)
		if st and vo_player:
			vo_player.stream = st
			vo_player.play()

func play_weapon_sfx(wep_id: String) -> void:
	var path = "res://assets/audio/sfx_equip_%s.wav" % wep_id
	if ResourceLoader.exists(path):
		var st = load(path)
		if st and equip_sfx_player:
			equip_sfx_player.stream = st
			equip_sfx_player.play()

func open_wizard() -> void:
	visible = true
	if sfx_click: sfx_click.play()
	go_to_step(1)

func go_to_step(step: int) -> void:
	current_step = step
	if step == 1:
		wizard_title.text = "[ MODE LOCAL CO-OP (2P) // PILIH SEKTOR ]" if GameState.is_coop_mode else "[ LANGKAH 1: PILIH SEKTOR MISI ]"
		wizard_step_label.text = "PILIH SEKTOR OPERASI SEBELUM MEMILIH OPERATIVE"
		step1_stage_select.visible = true
		step2_loadout_prep.visible = false
		launch_btn.visible = false
		shop_shortcut_btn.visible = true
		back_btn.text = "[ KEMBALI KE MENU UTAMA ]"
		build_stage_list()
	elif step == 2:
		var cfg = GameState.stage_configs.get(GameState.current_stage, GameState.stage_configs[1])
		if GameState.is_coop_mode:
			wizard_title.text = "[ CO-OP 2P // SELEKSI OPERATIVE: PLAYER 1 ]"
			wizard_step_label.text = "PLAYER 1: PILIH HERO & SENJATA ANDA LALU KONFIRMASI SIAP"
			launch_btn.text = "[ > KONFIRMASI P1 SIAP -> LANJUT SELEKSI P2 < ]"
		else:
			wizard_title.text = "[ LANGKAH 2: PERSIAPAN OPERATIVE & ARSENAL ]"
			wizard_step_label.text = "SEKTOR: STAGE %02d // %s (%s)" % [GameState.current_stage, cfg["title"], cfg["difficulty"]]
			launch_btn.text = "[ > LUNCURKAN MISI SEKTOR < ]"
		step1_stage_select.visible = false
		step2_loadout_prep.visible = true
		launch_btn.visible = true
		shop_shortcut_btn.visible = true
		back_btn.text = "[ < GANTI SEKTOR STAGE ]"
		update_hero_ui(GameState.selected_hero)
		update_weapon_ui(GameState.primary_weapon)
		call_deferred("_focus_launch_btn")
	elif step == 3:
		# Step 3: Player 2 selection in Co-op mode
		wizard_title.text = "[ CO-OP 2P // SELEKSI OPERATIVE: PLAYER 2 ]"
		wizard_step_label.text = "PLAYER 2: PILIH HERO & SENJATA ANDA LALU LUNCURKAN"
		launch_btn.text = "[ > SEMUA OPERATIVE SIAP // LUNCURKAN CO-OP < ]"
		step1_stage_select.visible = false
		step2_loadout_prep.visible = true
		launch_btn.visible = true
		shop_shortcut_btn.visible = false
		back_btn.text = "[ < KEMBALI KE PLAYER 1 ]"
		update_hero_ui(GameState.coop_p2_hero)
		update_weapon_ui(GameState.coop_p2_weapon)
		call_deferred("_focus_launch_btn")

func _focus_launch_btn() -> void:
	if launch_btn and launch_btn.is_visible_in_tree():
		launch_btn.grab_focus()

func _input(event: InputEvent) -> void:
	if not visible: return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_KP_0:
			if is_inside_tree() and get_viewport():
				get_viewport().set_input_as_handled()
			_on_back_pressed()
	elif event is InputEventJoypadButton and event.is_pressed():
		match event.button_index:
			JOY_BUTTON_B:
				if is_inside_tree() and get_viewport():
					get_viewport().set_input_as_handled()
				_on_back_pressed()
			JOY_BUTTON_START:
				if is_inside_tree() and get_viewport():
					get_viewport().set_input_as_handled()
				if current_step == 2:
					_on_launch_pressed()
			JOY_BUTTON_BACK:
				if is_inside_tree() and get_viewport():
					get_viewport().set_input_as_handled()
				_on_shop_shortcut_pressed()

func build_stage_list() -> void:
	if not stages_hbox: return
	for child in stages_hbox.get_children():
		child.queue_free()

	var font_orb = load("res://assets/fonts/Orbitron-Bold.ttf")
	var font_silk = load("res://assets/fonts/Silkscreen-Bold.ttf")
	var font_tech = load("res://assets/fonts/tech_font.ttf")

	var tex_conf_n = load("res://assets/ui/btn_confirm_normal.png")
	var tex_conf_h = load("res://assets/ui/btn_confirm_hover.png")
	var tex_sci_n = load("res://assets/ui/btn_sci_normal.png")
	var tex_sci_h = load("res://assets/ui/btn_sci_hover.png")

	var sb_conf_n = StyleBoxTexture.new(); sb_conf_n.texture = tex_conf_n; sb_conf_n.set_texture_margin_all(8)
	var sb_conf_h = StyleBoxTexture.new(); sb_conf_h.texture = tex_conf_h; sb_conf_h.set_texture_margin_all(8)
	var sb_sci_n = StyleBoxTexture.new(); sb_sci_n.texture = tex_sci_n; sb_sci_n.set_texture_margin_all(8)
	var sb_sci_h = StyleBoxTexture.new(); sb_sci_h.texture = tex_sci_h; sb_sci_h.set_texture_margin_all(8)

	for s_id in range(1, 6):
		var cfg = GameState.stage_configs[s_id]
		var s_data = SaveManager.stages_data.get(s_id, {"unlocked": (s_id == 1), "high_rank": "-", "cleared": false})
		var is_unlocked: bool = SaveManager.is_stage_unlocked(s_id)
		var is_current: bool = (GameState.current_stage == s_id)

		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(336, 680)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.06, 0.09, 0.14, 0.96) if is_unlocked else Color(0.03, 0.05, 0.08, 0.88)
		style.border_color = Color(1.0, 0.95, 0.15, 1.0) if is_current else (Color(0, 0.94, 1, 0.8) if is_unlocked else Color(0.2, 0.3, 0.45, 0.4))
		style.set_border_width_all(3 if is_current else 2)
		style.set_corner_radius_all(6)
		card.add_theme_stylebox_override("panel", style)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 14)
		margin.add_theme_constant_override("margin_right", 14)
		margin.add_theme_constant_override("margin_top", 14)
		margin.add_theme_constant_override("margin_bottom", 14)

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 10)

		# 1. Header Row: [ STAGE %02d ] + Difficulty Badge
		var hd_row := HBoxContainer.new()
		var s_num_lbl := Label.new()
		s_num_lbl.text = "[ STAGE %02d ]" % s_id
		s_num_lbl.add_theme_font_override("font", font_orb)
		s_num_lbl.add_theme_font_size_override("font_size", 15)
		s_num_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.15) if is_current else (Color(0, 0.94, 1) if is_unlocked else Color(0.5, 0.55, 0.65)))
		hd_row.add_child(s_num_lbl)

		var spacer_hd := Control.new()
		spacer_hd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hd_row.add_child(spacer_hd)

		var diff_lbl := Label.new()
		diff_lbl.text = cfg["difficulty"]
		diff_lbl.add_theme_font_override("font", font_silk)
		diff_lbl.add_theme_font_size_override("font_size", 10)
		match s_id:
			1: diff_lbl.add_theme_color_override("font_color", Color(0, 0.94, 1))
			2: diff_lbl.add_theme_color_override("font_color", Color(0.13, 0.95, 0.4))
			3: diff_lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.2))
			4: diff_lbl.add_theme_color_override("font_color", Color(0.82, 0.24, 1.0))
			5: diff_lbl.add_theme_color_override("font_color", Color(1.0, 0.24, 0.66))
		hd_row.add_child(diff_lbl)
		vbox.add_child(hd_row)

		# 2. Scenic Thumbnail (308x160)
		var thumb_rect := TextureRect.new()
		var thumb_path = "res://assets/sprites/stage_preview_%d.png" % s_id
		if ResourceLoader.exists(thumb_path):
			thumb_rect.texture = load(thumb_path)
		thumb_rect.custom_minimum_size = Vector2(308, 160)
		thumb_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		if not is_unlocked:
			thumb_rect.modulate = Color(0.4, 0.45, 0.55, 0.7)
		vbox.add_child(thumb_rect)

		# 3. Stage Title
		var title_lbl := Label.new()
		title_lbl.text = cfg["title"]
		title_lbl.add_theme_font_override("font", font_orb)
		title_lbl.add_theme_font_size_override("font_size", 16)
		title_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0) if is_unlocked else Color(0.5, 0.55, 0.65))
		title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(title_lbl)

		# 4. Quick Specs (Boss & Target)
		var boss_lbl := Label.new()
		boss_lbl.text = "BOSS: %s" % cfg["boss_name"]
		boss_lbl.add_theme_font_override("font", font_tech)
		boss_lbl.add_theme_font_size_override("font_size", 13)
		boss_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0) if is_unlocked else Color(0.4, 0.45, 0.55))
		vbox.add_child(boss_lbl)

		var target_lbl := Label.new()
		target_lbl.text = "TARGET: SURVIVE %d:00" % int(cfg["target_time"] / 60.0)
		target_lbl.add_theme_font_override("font", font_tech)
		target_lbl.add_theme_font_size_override("font_size", 13)
		target_lbl.add_theme_color_override("font_color", Color(0, 0.94, 1) if is_unlocked else Color(0.4, 0.45, 0.55))
		vbox.add_child(target_lbl)

		# 5. Concise Requirement Badge
		var req_lbl := Label.new()
		req_lbl.add_theme_font_override("font", font_silk)
		req_lbl.add_theme_font_size_override("font_size", 11)
		req_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if is_unlocked:
			req_lbl.text = "[ STATUS: SEKTOR TERBUKA ]"
			req_lbl.add_theme_color_override("font_color", Color(0.13, 0.95, 0.4))
		else:
			match s_id:
				2: req_lbl.text = "[ SYARAT: CLEAR 3:00 RANK B ]"
				3: req_lbl.text = "[ SYARAT: CLEAR 3:00 RANK B ]"
				4: req_lbl.text = "[ SYARAT: CLEAR 4:00 RANK A ]"
				5: req_lbl.text = "[ SYARAT: CLEAR 4:00 RANK S ]"
				_: req_lbl.text = "[ SYARAT: TERKUNCI ]"
			req_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.12))
		vbox.add_child(req_lbl)

		# 6. Record Badge
		var rank_lbl := Label.new()
		var hr = s_data.get("high_rank", "-")
		var bt = s_data.get("best_time", 0.0)
		rank_lbl.add_theme_font_override("font", font_silk)
		rank_lbl.add_theme_font_size_override("font_size", 11)
		if hr != "-":
			var b_min = floori(bt / 60.0)
			var b_sec = int(bt) % 60
			rank_lbl.text = "REKOR: RANK %s (%02d:%02d)" % [hr, b_min, b_sec]
			rank_lbl.add_theme_color_override("font_color", Color(0.13, 0.95, 0.4))
		else:
			rank_lbl.text = "REKOR: BELUM CLEAR"
			rank_lbl.add_theme_color_override("font_color", Color(0.4, 0.5, 0.6))
		vbox.add_child(rank_lbl)

		# 7. Spacer
		var spacer := Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(spacer)

		# 8. Action Button
		var pick_btn := Button.new()
		pick_btn.custom_minimum_size = Vector2(0, 52)
		pick_btn.add_theme_font_override("font", font_orb)
		pick_btn.add_theme_font_size_override("font_size", 14)

		if is_current:
			pick_btn.text = "[ > SEKTOR AKTIF < ]"
			pick_btn.add_theme_stylebox_override("normal", sb_conf_n)
			pick_btn.add_theme_stylebox_override("hover", sb_conf_h)
			pick_btn.add_theme_stylebox_override("focus", sb_conf_h)
			pick_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.15))
			pick_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
			pick_btn.pressed.connect(func():
				if sfx_click: sfx_click.play()
				go_to_step(2)
			)
			pick_btn.call_deferred("grab_focus")
		elif is_unlocked:
			pick_btn.text = "[ PILIH SEKTOR ]"
			pick_btn.add_theme_stylebox_override("normal", sb_sci_n)
			pick_btn.add_theme_stylebox_override("hover", sb_sci_h)
			pick_btn.add_theme_stylebox_override("focus", sb_sci_h)
			pick_btn.add_theme_color_override("font_color", Color(0.5, 0.94, 1.0))
			pick_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
			pick_btn.pressed.connect(func():
				GameState.current_stage = s_id
				if sfx_click: sfx_click.play()
				go_to_step(2)
			)
		else:
			pick_btn.text = "[ TERKUNCI ]"
			pick_btn.disabled = true
			pick_btn.add_theme_stylebox_override("normal", sb_sci_n)
			pick_btn.add_theme_color_override("font_disabled_color", Color(0.45, 0.5, 0.6, 0.7))

		vbox.add_child(pick_btn)

		margin.add_child(vbox)
		card.add_child(margin)
		stages_hbox.add_child(card)

func setup_hero_btn(btn: Button, hero_id: String) -> void:
	if not btn: return
	btn.pressed.connect(func():
		if sfx_click: sfx_click.play()
		play_hero_vo(hero_id)
		if GameState.is_coop_mode and current_step == 3:
			GameState.coop_p2_hero = hero_id
		else:
			GameState.selected_hero = hero_id
		update_hero_ui(hero_id, true)
		check_synergy()
	)

func setup_skin_buttons() -> void:
	if skin_default_btn:
		skin_default_btn.pressed.connect(func():
			if sfx_click: sfx_click.play()
			SaveManager.set_hero_skin(GameState.selected_hero, "default")
			SaveManager.save_game()
			update_hero_ui(GameState.selected_hero, true)
		)
	if skin_custom_btn:
		skin_custom_btn.pressed.connect(func():
			var hero_id = GameState.selected_hero
			var cur_skin = SaveManager.get_hero_skin(hero_id)
			var target_skin = "default"
			var target_skin_id = ""
			
			if hero_id == "kael":
				var has_cobalt = SaveManager.unlocked_items.has("skin_kael_cobalt")
				var has_crimson = SaveManager.unlocked_items.has("skin_kael_crimson")
				if cur_skin == "cobalt" and has_crimson:
					target_skin = "crimson"
					target_skin_id = "skin_kael_crimson"
				elif cur_skin == "crimson" and has_cobalt:
					target_skin = "cobalt"
					target_skin_id = "skin_kael_cobalt"
				elif has_cobalt:
					target_skin = "cobalt"
					target_skin_id = "skin_kael_cobalt"
				elif has_crimson:
					target_skin = "crimson"
					target_skin_id = "skin_kael_crimson"
			elif hero_id == "vex":
				target_skin_id = "skin_vex_toxic"
				target_skin = "toxic"
			elif hero_id == "brutus":
				target_skin_id = "skin_brutus_gold"
				target_skin = "gold"
			elif hero_id == "nyx":
				target_skin_id = "skin_nyx_void"
				target_skin = "void"
			
			if SaveManager.unlocked_items.has(target_skin_id):
				if sfx_click: sfx_click.play()
				SaveManager.set_hero_skin(hero_id, target_skin)
				SaveManager.save_game()
				update_hero_ui(hero_id, true)
		)

func _get_skin_accent(hero_id: String, skin: String) -> Color:
	match hero_id:
		"kael":
			return Color(0.16, 0.83, 1.0) if skin == "default" else Color(0.0, 0.55, 1.0)
		"vex":
			return Color(0.22, 1.0, 0.53) if skin == "default" else Color(0.55, 1.0, 0.2)
		"brutus":
			return Color(1.0, 0.71, 0.16) if skin == "default" else Color(1.0, 0.88, 0.29)
		"nyx":
			return Color(1.0, 0.24, 0.66) if skin == "default" else Color(0.71, 0.2, 1.0)
	return Color(0.16, 0.83, 1.0)

# Live Holo Flip: portrait spins on Y-axis (simulated via horizontal squeeze),
# texture swaps at edge-on moment, then spins back + glint scan + aura pulse.
func animate_portrait_skin_flip(new_tex: Texture2D, accent: Color) -> void:
	if not right_side_portrait: return
	
	# Kill any running flip tweens to avoid overlap
	if right_side_portrait.has_meta("flip_tween"):
		var old_tw = right_side_portrait.get_meta("flip_tween")
		if old_tw and old_tw.is_valid():
			old_tw.kill()
	
	var pivot_x = right_side_portrait.size.x * 0.5
	right_side_portrait.pivot_offset = Vector2(pivot_x, right_side_portrait.size.y * 0.5)
	
	var tw := right_side_portrait.create_tween()
	right_side_portrait.set_meta("flip_tween", tw)
	
	# PHASE 1 — Spin away (X scale 1.0 -> 0.06, edge-on) + slight darken
	tw.set_parallel(true)
	tw.tween_property(right_side_portrait, "scale:x", 0.06, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(right_side_portrait, "modulate", Color(0.55, 0.65, 0.9, 1.0), 0.16)
	
	# PHASE 2 — Edge-on: swap texture + flash aura accent
	tw.chain().tween_callback(func():
		if new_tex:
			right_side_portrait.texture = new_tex
		# Aura flash at swap instant
		if portrait_glint:
			portrait_glint.color = Color(accent.r, accent.g, accent.b, 0.35)
	)
	
	# PHASE 3 — Spin back with overshoot bounce (0.06 -> 1.0 TRANS_BACK)
	tw.chain().set_parallel(true)
	tw.tween_property(right_side_portrait, "scale:x", 1.0, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(right_side_portrait, "modulate", Color(1.05, 1.05, 1.1, 1.0), 0.1)
	
	# PHASE 4 — Glint scanline sweep (top->bottom) while settling
	tw.chain().tween_property(right_side_portrait, "modulate", Color(1, 1, 1, 1), 0.12)
	if portrait_glint:
		var gt := portrait_glint.create_tween()
		gt.tween_property(portrait_glint, "color:a", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func update_hero_ui(hero_id: String, animate_flip: bool = false) -> void:
	var skin = SaveManager.equipped_hero_skin
	var port_path = "res://assets/sprites/portrait_%s.png" % hero_id
	if skin != "default":
		var skin_port = "res://assets/sprites/portrait_%s_%s.png" % [hero_id, skin]
		if ResourceLoader.exists(skin_port):
			port_path = skin_port
	if ResourceLoader.exists(port_path):
		var new_tex: Texture2D = load(port_path)
		if right_side_portrait and (animate_flip or right_side_portrait.texture != new_tex):
			if animate_flip:
				animate_portrait_skin_flip(new_tex, _get_skin_accent(hero_id, skin))
			else:
				right_side_portrait.texture = new_tex

	var target_skin_id = "skin_kael_cobalt"
	var skin_label = "COBALT ANVIL (CYAN)"
	if hero_id == "kael":
		if skin == "crimson" or (not SaveManager.unlocked_items.has("skin_kael_cobalt") and SaveManager.unlocked_items.has("skin_kael_crimson")):
			target_skin_id = "skin_kael_crimson"
			skin_label = "CRIMSON FURY (RUBY)"
		else:
			target_skin_id = "skin_kael_cobalt"
			skin_label = "COBALT ANVIL (CYAN)"
	elif hero_id == "vex":
		target_skin_id = "skin_vex_toxic"
		skin_label = "ACID MANTIS (EMERALD)"
	elif hero_id == "brutus":
		target_skin_id = "skin_brutus_gold"
		skin_label = "TITAN GOLD (ELECTRIC)"
	elif hero_id == "nyx":
		target_skin_id = "skin_nyx_void"
		skin_label = "VOID NYX (NEON)"

	var is_unlocked = SaveManager.unlocked_items.has(target_skin_id)
	if skin_custom_btn:
		if is_unlocked:
			skin_custom_btn.disabled = false
			if skin != "default":
				skin_custom_btn.text = "[ SKIN: %s (AKTIF) ]" % skin_label
				skin_custom_btn.add_theme_color_override("font_color", Color(0.13, 0.95, 0.4, 1))
			else:
				skin_custom_btn.text = "[ PASANG: %s ]" % skin_label
				skin_custom_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.15, 1))
			skin_custom_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
			skin_custom_btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.95, 0.15, 1))
			skin_custom_btn.add_theme_color_override("font_focus_color", Color(1, 1, 1, 1))
		else:
			skin_custom_btn.disabled = true
			skin_custom_btn.text = "[ TERKUNCI: %s (SHOP) ]" % skin_label
			skin_custom_btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.55, 0.65, 0.8))

	if skin_default_btn:
		if skin == "default":
			skin_default_btn.text = "[ > SKIN DEFAULT (AKTIF) < ]"
			skin_default_btn.add_theme_color_override("font_color", Color(0.13, 0.95, 0.4))
		else:
			skin_default_btn.text = "[ GANTI KE DEFAULT ]"
			skin_default_btn.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))

	match hero_id:
		"kael":
			if hero_name_lbl: hero_name_lbl.text = "KAEL (THE CYBERSMITH)"
			if hero_hp_lbl: hero_hp_lbl.text = "HP: 04"
			if hero_desc_lbl:
				hero_desc_lbl.text = "SKILL AKTIF [TAHAN E]: EMP CRYO DASH - Meluncur ke arah mouse dengan kekebalan dan membekukan musuh 3 detik tanpa wipe kill.\nSenjata Native: Dual Revolver (+25% Damage)."
		"vex":
			if hero_name_lbl: hero_name_lbl.text = "VEX (PHASE ASSASSIN)"
			if hero_hp_lbl: hero_hp_lbl.text = "HP: 03"
			if hero_desc_lbl:
				hero_desc_lbl.text = "SKILL AKTIF [TAHAN E]: SHADOW DASH - Meluncur 200px dan memunculkan bayangan kloning (Decoy) yang memancing dan meledak 35 DMG.\nSenjata Native: Cyber SMG (+25% Laju Tembak)."
		"brutus":
			if hero_name_lbl: hero_name_lbl.text = "BRUTUS (THE JUGGERNAUT)"
			if hero_hp_lbl: hero_hp_lbl.text = "HP: 06"
			if hero_desc_lbl:
				hero_desc_lbl.text = "SKILL AKTIF [TAHAN E]: TITAN SLAM - Menghentak tanah memicu gempa radius 114px (+30% area) + 26 DMG, hempasan knockback, dan perisai kinetik 2.0s.\nSenjata Native: Scrap Shotgun (+3 Pellets)."
		"nyx":
			if hero_name_lbl: hero_name_lbl.text = "NYX (THE PLASMA WITCH)"
			if hero_hp_lbl: hero_hp_lbl.text = "HP: 03"
			if hero_desc_lbl:
				hero_desc_lbl.text = "SKILL AKTIF [TAHAN E]: VOID SINGULARITY - Menghisap musuh ke titik kursor radius 117px + 6-22 DMG plasma (Nerfed 55%).\nSenjata Native: Plasma Railgun (+20% Damage & Pierce)."

func setup_weapon_skin_buttons() -> void:
	if wep_skin_default_btn:
		wep_skin_default_btn.pressed.connect(func():
			if sfx_click: sfx_click.play()
			SaveManager.set_weapon_skin(GameState.primary_weapon, "default")
			SaveManager.save_game()
			update_weapon_ui(GameState.primary_weapon)
		)
	if wep_skin_custom_btn:
		wep_skin_custom_btn.pressed.connect(func():
			var wep_id = GameState.primary_weapon
			var target_skin_id = "wep_revolver_gold"
			var target_variant = "gold"
			if wep_id == "shotgun":
				target_skin_id = "wep_shotgun_cyber"
				target_variant = "cyber"
			elif wep_id == "smg":
				target_skin_id = "wep_smg_violet"
				target_variant = "violet"
			elif wep_id == "railgun":
				target_skin_id = "wep_railgun_cryo"
				target_variant = "cryo"
				
			if SaveManager.unlocked_items.has(target_skin_id):
				if sfx_click: sfx_click.play()
				SaveManager.set_weapon_skin(wep_id, target_variant)
				SaveManager.save_game()
				update_weapon_ui(GameState.primary_weapon)
		)

func setup_weapon_btn(btn: Button, wep_id: String) -> void:
	if not btn: return
	btn.pressed.connect(func():
		if sfx_click: sfx_click.play()
		play_weapon_sfx(wep_id)
		if GameState.is_coop_mode and current_step == 3:
			GameState.coop_p2_weapon = wep_id
		else:
			GameState.primary_weapon = wep_id
			GameState.selected_weapon = wep_id
		update_weapon_ui(wep_id)
		check_synergy()
		
		if wep_closeup:
			var tw := wep_closeup.create_tween()
			tw.tween_property(wep_closeup, "scale", Vector2(1.08, 1.08), 0.08)
			tw.tween_property(wep_closeup, "scale", Vector2.ONE, 0.12)
	)

func update_weapon_ui(wep_id: String) -> void:
	var target_skin_id = "wep_revolver_gold"
	var skin_label = "SOVEREIGN GOLD"
	var target_variant = "gold"
	if wep_id == "shotgun":
		target_skin_id = "wep_shotgun_cyber"
		skin_label = "CYBER BLAST"
		target_variant = "cyber"
	elif wep_id == "smg":
		target_skin_id = "wep_smg_violet"
		skin_label = "MATRIX SPRAY"
		target_variant = "violet"
	elif wep_id == "railgun":
		target_skin_id = "wep_railgun_cryo"
		skin_label = "CRYO BEAM"
		target_variant = "cryo"

	var is_unlocked = SaveManager.unlocked_items.has(target_skin_id)
	var active_wep_skin = SaveManager.get_weapon_skin(wep_id)
	if wep_skin_custom_btn:
		if is_unlocked:
			wep_skin_custom_btn.disabled = false
			if active_wep_skin == target_variant:
				wep_skin_custom_btn.text = "[ SKIN: %s (AKTIF) ]" % skin_label
				wep_skin_custom_btn.add_theme_color_override("font_color", Color(0.13, 0.95, 0.4))
			else:
				wep_skin_custom_btn.text = "[ PASANG: %s ]" % skin_label
				wep_skin_custom_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.15))
		else:
			wep_skin_custom_btn.disabled = true
			wep_skin_custom_btn.text = "[ TERKUNCI: %s (SHOP) ]" % skin_label
			wep_skin_custom_btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.55, 0.65, 0.8))

	if wep_skin_default_btn:
		if active_wep_skin == "default":
			wep_skin_default_btn.text = "[ > SKIN DEFAULT (AKTIF) < ]"
			wep_skin_default_btn.add_theme_color_override("font_color", Color(0.13, 0.95, 0.4))
		else:
			wep_skin_default_btn.text = "[ GANTI KE DEFAULT ]"
			wep_skin_default_btn.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))

	var close_path = "res://assets/sprites/closeup_%s.png" % wep_id
	if ResourceLoader.exists(close_path) and wep_closeup:
		wep_closeup.texture = load(close_path)

	match wep_id:
		"revolver":
			if wep_name_lbl: wep_name_lbl.text = "DUAL REVOLVER [BALANCED]"
			if wep_stats_lbl:
				wep_stats_lbl.text = "DAMAGE: 18 (2-Hit Kill) | PROYEKTIL: 1 | RELOAD: 0.95s | FIRE RATE: 0.22s | AMMO: 06\nSEKUNDER: CYBER KATANA TERPASANG (TEBASAN MELEE MEMICU HEAL DROP)"
		"shotgun":
			if wep_name_lbl: wep_name_lbl.text = "SCRAP SHOTGUN [POINT-BLANK]"
			if wep_stats_lbl:
				wep_stats_lbl.text = "DAMAGE: 8x10 PELLETS (80 POINT-BLANK) | RELOAD: 1.25s | AMMO: 04 (Jarak < 110px)\nSEKUNDER: CYBER KATANA TERPASANG (TEBASAN MELEE MEMICU HEAL DROP)"
		"smg":
			if wep_name_lbl: wep_name_lbl.text = "CYBER SMG [RAPID SPRAY]"
			if wep_stats_lbl:
				wep_stats_lbl.text = "DAMAGE: 6 | PROYEKTIL: 1 | RELOAD: 0.80s | FIRE RATE: 0.08s | AMMO: 28\nSEKUNDER: CYBER KATANA TERPASANG (TEBASAN MELEE MEMICU HEAL DROP)"
		"railgun":
			if wep_name_lbl: wep_name_lbl.text = "PLASMA RAILGUN [SNIPER BEAM]"
			if wep_stats_lbl:
				wep_stats_lbl.text = "DAMAGE: 38 | PROYEKTIL: 1 | TEMBUS: 3 MUSUH | RELOAD: 1.35s | AMMO: 03\nSEKUNDER: CYBER KATANA TERPASANG (TEBASAN MELEE MEMICU HEAL DROP)"

func check_synergy() -> void:
	if not synergy_banner: return
	if GameState.selected_hero == "kael" and GameState.primary_weapon == "revolver":
		synergy_banner.text = "[ NATIVE SYNERGY AKTIF: KAEL + REVOLVER -> +25% DMG ]"
		synergy_banner.add_theme_color_override("font_color", Color(0.13, 0.95, 0.4))
	elif GameState.selected_hero == "vex" and GameState.primary_weapon == "smg":
		synergy_banner.text = "[ NATIVE SYNERGY AKTIF: VEX + SMG -> +25% LAJU TEMBAK ]"
		synergy_banner.add_theme_color_override("font_color", Color(0.13, 0.95, 0.4))
	elif GameState.selected_hero == "brutus" and GameState.primary_weapon == "shotgun":
		synergy_banner.text = "[ NATIVE SYNERGY AKTIF: BRUTUS + SHOTGUN -> +3 PELLETS ]"
		synergy_banner.add_theme_color_override("font_color", Color(0.13, 0.95, 0.4))
	elif GameState.selected_hero == "nyx" and GameState.primary_weapon == "railgun":
		synergy_banner.text = "[ NATIVE SYNERGY AKTIF: NYX + RAILGUN -> +20% DMG & SPEED ]"
		synergy_banner.add_theme_color_override("font_color", Color(0.13, 0.95, 0.4))
	else:
		synergy_banner.text = "[ NON-NATIVE: BUFF SENJATA PASIF NONAKTIF (DAPAT DIUPGRADE DI RUNE SKILL TREE) ]"
		synergy_banner.add_theme_color_override("font_color", Color(0.98, 0.8, 0.08))

func _on_back_pressed() -> void:
	if sfx_click: sfx_click.play()
	if current_step == 3:
		go_to_step(2)
	elif current_step == 2:
		go_to_step(1)
	else:
		visible = false

func _on_shop_shortcut_pressed() -> void:
	if sfx_click: sfx_click.play()
	visible = false
	open_shop_requested.emit()

func _on_launch_pressed() -> void:
	if sfx_click: sfx_click.play()
	if GameState.is_coop_mode and current_step == 2:
		# P1 choice confirmed, advance to P2 selection!
		go_to_step(3)
		return
	
	visible = false
	GameState.reset_run()
	get_tree().change_scene_to_file("res://scenes/main/GameArena.tscn")
