extends ColorRect

@onready var step1_stage_select: Control = $CenterContainer/Panel/Margin/VBox/Step1StageSelect
@onready var step2_loadout_prep: Control = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep

@onready var wizard_title: Label = $CenterContainer/Panel/Margin/VBox/HeaderBox/WizardTitle
@onready var wizard_step_label: Label = $CenterContainer/Panel/Margin/VBox/HeaderBox/StepIndicator

# Step 1: Stages
@onready var stages_vbox: VBoxContainer = $CenterContainer/Panel/Margin/VBox/Step1StageSelect/Scroll/StagesVBox

# Step 2: Loadout
@onready var hero_name_lbl: Label = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/HeroSection/HeroHeader/HeroName
@onready var hero_hp_lbl: Label = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/HeroSection/HeroHeader/HeroHP
@onready var hero_desc_lbl: Label = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/HeroSection/HeroDesc

@onready var btn_kael: Button = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/HeroSection/HeroGrid/BtnKael
@onready var btn_vex: Button = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/HeroSection/HeroGrid/BtnVex
@onready var btn_brutus: Button = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/HeroSection/HeroGrid/BtnBrutus

@onready var wep_name_lbl: Label = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/WeaponSection/WepHeader/WepName
@onready var wep_closeup: TextureRect = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/WeaponSection/WepHeader/WepCloseUp
@onready var wep_stats_lbl: Label = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/WeaponSection/WepStats

@onready var btn_revolver: Button = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/WeaponSection/WeaponGrid/BtnRevolver
@onready var btn_shotgun: Button = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/WeaponSection/WeaponGrid/BtnShotgun
@onready var btn_smg: Button = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/WeaponSection/WeaponGrid/BtnSMG

@onready var synergy_banner: Label = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/LeftLoadout/SynergyBanner
@onready var right_side_portrait: TextureRect = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/MainLayout/RightSidePortrait

# Navigation buttons
@onready var back_btn: Button = $CenterContainer/Panel/Margin/VBox/BottomNav/BackBtn
@onready var shop_shortcut_btn: Button = $CenterContainer/Panel/Margin/VBox/BottomNav/ShopShortcutBtn
@onready var launch_btn: Button = $CenterContainer/Panel/Margin/VBox/BottomNav/LaunchBtn

@onready var sfx_click: AudioStreamPlayer = $SFXClick

signal open_shop_requested()

var current_step: int = 1

func _ready() -> void:
	visible = false
	if back_btn: back_btn.pressed.connect(_on_back_pressed)
	if shop_shortcut_btn: shop_shortcut_btn.pressed.connect(_on_shop_shortcut_pressed)
	if launch_btn: launch_btn.pressed.connect(_on_launch_pressed)

	setup_hero_btn(btn_kael, "kael")
	setup_hero_btn(btn_vex, "vex")
	setup_hero_btn(btn_brutus, "brutus")

	setup_weapon_btn(btn_revolver, "revolver")
	setup_weapon_btn(btn_shotgun, "shotgun")
	setup_weapon_btn(btn_smg, "smg")

func open_wizard() -> void:
	visible = true
	if sfx_click: sfx_click.play()
	go_to_step(1)

func go_to_step(step: int) -> void:
	current_step = step
	if step == 1:
		wizard_title.text = "[ LANGKAH 1: PILIH SEKTOR MISI ]"
		wizard_step_label.text = "PILIH SEKTOR OPERASI SEBELUM MEMILIH OPERATIVE"
		step1_stage_select.visible = true
		step2_loadout_prep.visible = false
		launch_btn.visible = false
		shop_shortcut_btn.visible = true
		back_btn.text = "[ KEMBALI KE MENU UTAMA ]"
		build_stage_list()
	else:
		var cfg = GameState.stage_configs.get(GameState.current_stage, GameState.stage_configs[1])
		wizard_title.text = "[ LANGKAH 2: PERSIAPAN OPERATIVE & ARSENAL ]"
		wizard_step_label.text = "SEKTOR: STAGE %02d // %s (%s)" % [GameState.current_stage, cfg["title"], cfg["difficulty"]]
		step1_stage_select.visible = false
		step2_loadout_prep.visible = true
		launch_btn.visible = true
		shop_shortcut_btn.visible = true
		back_btn.text = "[ < GANTI SEKTOR STAGE ]"
		update_hero_ui(GameState.selected_hero)
		update_weapon_ui(GameState.selected_weapon)

func build_stage_list() -> void:
	if not stages_vbox: return
	for child in stages_vbox.get_children():
		child.queue_free()

	var font_orb = load("res://assets/fonts/Orbitron-Bold.ttf")
	var font_tech = load("res://assets/fonts/tech_font.ttf")

	for s_id in range(1, 6):
		var cfg = GameState.stage_configs[s_id]
		var s_data = SaveManager.stages_data.get(s_id, {"unlocked": (s_id == 1), "high_rank": "-", "cleared": false})
		var is_unlocked: bool = s_data.get("unlocked", false) or (s_id == 1)
		var is_current: bool = (GameState.current_stage == s_id)

		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(1100, 105)

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.09, 0.15, 0.95) if is_unlocked else Color(0.08, 0.06, 0.1, 0.85)
		style.border_color = Color(0.95, 0.76, 0.28, 1.0) if is_current else (Color(0.2, 0.65, 0.9, 0.7) if is_unlocked else Color(0.3, 0.35, 0.45, 0.4))
		if s_id == 5 and is_unlocked:
			style.border_color = Color(0.92, 0.36, 0.42, 1.0) # Nightmare Red
		style.set_border_width_all(3 if is_current else 2)
		style.set_corner_radius_all(6)
		panel.add_theme_stylebox_override("panel", style)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 24)
		margin.add_theme_constant_override("margin_right", 24)
		margin.add_theme_constant_override("margin_top", 14)
		margin.add_theme_constant_override("margin_bottom", 14)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 24)

		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 6)

		var title_lbl := Label.new()
		title_lbl.text = "[ STAGE %02d ] %s // TINGKAT: %s" % [s_id, cfg["title"], cfg["difficulty"]]
		title_lbl.add_theme_font_override("font", font_orb)
		title_lbl.add_theme_font_size_override("font_size", 18)
		title_lbl.add_theme_color_override("font_color", Color(0.92, 0.36, 0.42) if is_unlocked else Color(0.5, 0.55, 0.65))
		info_vbox.add_child(title_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = "TARGET SURVIVE: %d DETIK  |  MISI: %s  |  APEX BOSS: %s" % [int(cfg["target_time"]), cfg["objective"], cfg["boss_name"]]
		desc_lbl.add_theme_font_override("font", font_tech)
		desc_lbl.add_theme_font_size_override("font_size", 15)
		desc_lbl.add_theme_color_override("font_color", Color(0.93, 0.89, 0.85) if is_unlocked else Color(0.45, 0.5, 0.6))
		info_vbox.add_child(desc_lbl)

		var rank_lbl := Label.new()
		rank_lbl.text = "EVALUASI RANK TERTINGGI: %s" % s_data.get("high_rank", "-")
		rank_lbl.add_theme_font_override("font", font_orb)
		rank_lbl.add_theme_font_size_override("font_size", 14)
		rank_lbl.add_theme_color_override("font_color", Color(0.2, 0.9, 1.0))
		info_vbox.add_child(rank_lbl)

		hbox.add_child(info_vbox)

		if is_unlocked:
			var pick_btn := Button.new()
			pick_btn.custom_minimum_size = Vector2(240, 50)
			pick_btn.add_theme_font_override("font", font_orb)
			pick_btn.add_theme_font_size_override("font_size", 15)
			pick_btn.text = "[ > PILIH SEKTOR INI < ]"
			pick_btn.pressed.connect(func():
				GameState.current_stage = s_id
				if sfx_click: sfx_click.play()
				go_to_step(2)
			)
			hbox.add_child(pick_btn)
		else:
			var req = "BUTUH RANK B DI STAGE %d" % (s_id - 1)
			if s_id == 4: req = "BUTUH RANK A DI STAGE 3"
			elif s_id == 5: req = "BUTUH RANK S DI STAGE 4"
			var lock_lbl := Label.new()
			lock_lbl.custom_minimum_size = Vector2(240, 50)
			lock_lbl.text = "[ TERKUNCI ]\n%s" % req
			lock_lbl.add_theme_font_override("font", font_tech)
			lock_lbl.add_theme_font_size_override("font_size", 13)
			lock_lbl.add_theme_color_override("font_color", Color(0.8, 0.35, 0.4))
			lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lock_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			hbox.add_child(lock_lbl)

		margin.add_child(hbox)
		panel.add_child(margin)
		stages_vbox.add_child(panel)

func setup_hero_btn(btn: Button, hero_id: String) -> void:
	if not btn: return
	btn.pressed.connect(func():
		if sfx_click: sfx_click.play()
		GameState.selected_hero = hero_id
		update_hero_ui(hero_id)
		check_synergy()
	)

func update_hero_ui(hero_id: String) -> void:
	var port_path = "res://assets/sprites/portrait_%s.png" % hero_id
	if ResourceLoader.exists(port_path) and right_side_portrait:
		right_side_portrait.texture = load(port_path)

	match hero_id:
		"kael":
			if hero_name_lbl: hero_name_lbl.text = "KAEL (THE CYBERSMITH)"
			if hero_hp_lbl: hero_hp_lbl.text = "HP: 04"
			if hero_desc_lbl:
				hero_desc_lbl.text = "SKILL AKTIF [SPACE/E]: EMP CRYO DASH\nMeluncur 260px ke depan dengan kekebalan dan gelombang es membekukan seluruh robot musuh 3 detik.\nDapat ditingkatkan lewat Skill Core drops! Senjata Native: Dual Revolver (+25% Damage)."
		"vex":
			if hero_name_lbl: hero_name_lbl.text = "VEX (PHASE ASSASSIN)"
			if hero_hp_lbl: hero_hp_lbl.text = "HP: 03"
			if hero_desc_lbl:
				hero_desc_lbl.text = "SKILL AKTIF [SPACE/E]: PHASE BLINK\nTeleportasi seketika 320px menembus rintangan dan meninggalkan decoy pemancing yang meledak 80 DMG.\nDapat ditingkatkan lewat Skill Core drops! Senjata Native: Cyber SMG (+25% Laju Tembak)."
		"brutus":
			if hero_name_lbl: hero_name_lbl.text = "BRUTUS (THE JUGGERNAUT)"
			if hero_hp_lbl: hero_hp_lbl.text = "HP: 06"
			if hero_desc_lbl:
				hero_desc_lbl.text = "SKILL AKTIF [SPACE/E]: TITAN SEISMIC SLAM\nMenghentak tanah memicu gempa 70 DMG + hempasan 350px dan memberikan perisai kinetik 2.0s.\nDapat ditingkatkan lewat Skill Core drops! Senjata Native: Scrap Shotgun (+3 Pellets & +20% Knockback)."

func setup_weapon_btn(btn: Button, wep_id: String) -> void:
	if not btn: return
	btn.pressed.connect(func():
		if sfx_click: sfx_click.play()
		GameState.primary_weapon = wep_id
		GameState.selected_weapon = wep_id
		update_weapon_ui(wep_id)
		check_synergy()
	)

func update_weapon_ui(wep_id: String) -> void:
	var close_path = "res://assets/sprites/closeup_%s.png" % wep_id
	if ResourceLoader.exists(close_path) and wep_closeup:
		wep_closeup.texture = load(close_path)

	match wep_id:
		"revolver":
			if wep_name_lbl: wep_name_lbl.text = "DUAL REVOLVER [BALANCED]"
			if wep_stats_lbl:
				wep_stats_lbl.text = "DAMAGE: 18 (2-Hit Kill) | PROYEKTIL: 1 | RELOAD: 0.95s | FIRE RATE: 0.22s | AMMO: 06\\nSEKUNDER: CYBER KATANA TERPASANG (TEBASAN MELEE MEMICU 100% HEAL DROP)"
		"shotgun":
			if wep_name_lbl: wep_name_lbl.text = "SCRAP SHOTGUN [POINT-BLANK]"
			if wep_stats_lbl:
				wep_stats_lbl.text = "DAMAGE: 8x10 PELLETS (80 POINT-BLANK) | RELOAD: 1.25s | AMMO: 04 (Jarak < 110px)\\nSEKUNDER: CYBER KATANA TERPASANG (TEBASAN MELEE MEMICU 100% HEAL DROP)"
		"smg":
			if wep_name_lbl: wep_name_lbl.text = "CYBER SMG [RAPID SPRAY]"
			if wep_stats_lbl:
				wep_stats_lbl.text = "DAMAGE: 6 | PROYEKTIL: 1 | RELOAD: 0.80s | FIRE RATE: 0.08s | AMMO: 28\\nSEKUNDER: CYBER KATANA TERPASANG (TEBASAN MELEE MEMICU 100% HEAL DROP)"

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
	else:
		synergy_banner.text = "[ NON-NATIVE: BUFF SENJATA PASIF NONAKTIF (DAPAT DIUPGRADE DI RUNE SKILL TREE) ]"
		synergy_banner.add_theme_color_override("font_color", Color(0.98, 0.8, 0.08))

func _on_back_pressed() -> void:
	if sfx_click: sfx_click.play()
	if current_step == 2:
		go_to_step(1)
	else:
		visible = false

func _on_shop_shortcut_pressed() -> void:
	if sfx_click: sfx_click.play()
	open_shop_requested.emit()

func _on_launch_pressed() -> void:
	if sfx_click: sfx_click.play()
	visible = false
	GameState.reset_run()
	get_tree().change_scene_to_file("res://scenes/main/GameArena.tscn")