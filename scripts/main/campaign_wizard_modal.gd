extends ColorRect

@onready var step1_stage_select: Control = $CenterContainer/Panel/Margin/VBox/Step1StageSelect
@onready var step2_loadout_prep: Control = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep

@onready var wizard_title: Label = $CenterContainer/Panel/Margin/VBox/HeaderBox/WizardTitle
@onready var wizard_step_label: Label = $CenterContainer/Panel/Margin/VBox/HeaderBox/StepIndicator

# Step 1: Stages
@onready var stages_vbox: VBoxContainer = $CenterContainer/Panel/Margin/VBox/Step1StageSelect/Scroll/StagesVBox

# Step 2: Loadout
@onready var btn_kael: Button = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/HBox/HeroPanel/Margin/VBox/HeroBtns/BtnKael
@onready var btn_vex: Button = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/HBox/HeroPanel/Margin/VBox/HeroBtns/BtnVex
@onready var btn_brutus: Button = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/HBox/HeroPanel/Margin/VBox/HeroBtns/BtnBrutus
@onready var hero_desc: Label = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/HBox/HeroPanel/Margin/VBox/HeroDesc

@onready var btn_revolver: Button = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/HBox/WeaponPanel/Margin/VBox/WeaponBtns/BtnRevolver
@onready var btn_shotgun: Button = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/HBox/WeaponPanel/Margin/VBox/WeaponBtns/BtnShotgun
@onready var btn_smg: Button = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/HBox/WeaponPanel/Margin/VBox/WeaponBtns/BtnSMG
@onready var weapon_desc: Label = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/HBox/WeaponPanel/Margin/VBox/WeaponDesc

@onready var preview_hero: Sprite2D = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/HBox/PreviewPanel/Margin/VBox/StageControl/PreviewHero
@onready var preview_weapon: Sprite2D = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/HBox/PreviewPanel/Margin/VBox/StageControl/PreviewHero/PreviewWeapon
@onready var prep_stage_banner: Label = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/HBox/PreviewPanel/Margin/VBox/PrepStageBanner
@onready var synergy_banner: Label = $CenterContainer/Panel/Margin/VBox/Step2LoadoutPrep/HBox/PreviewPanel/Margin/VBox/SynergyBanner

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
		wizard_step_label.text = "PILIH SEKTOR OPERASI YANG AKAN DIINFILTRASI"
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
		update_prep_stage_banner()

func _process(_delta: float) -> void:
	if preview_hero and step2_loadout_prep.visible:
		var breath := sin(Time.get_ticks_msec() * 0.005) * 0.04
		preview_hero.scale = Vector2(5.5 * (1.0 + breath), 5.5 * (1.0 - breath))

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
		style.bg_color = Color(0.08, 0.12, 0.18, 0.96) if is_unlocked else Color(0.04, 0.05, 0.08, 0.85)
		style.border_color = Color(1.0, 0.85, 0.25, 1.0) if is_current else (Color(0.2, 0.65, 0.9, 0.7) if is_unlocked else Color(0.3, 0.35, 0.45, 0.4))
		if s_id == 5 and is_unlocked:
			style.border_color = Color(1.0, 0.25, 0.35, 1.0) # Nightmare Red
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
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25) if is_unlocked else Color(0.5, 0.55, 0.65))
		info_vbox.add_child(title_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = "TARGET SURVIVE: %d DETIK  |  MISI: %s  |  APEX BOSS: %s" % [int(cfg["target_time"]), cfg["objective"], cfg["boss_name"]]
		desc_lbl.add_theme_font_override("font", font_tech)
		desc_lbl.add_theme_font_size_override("font_size", 15)
		desc_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0) if is_unlocked else Color(0.45, 0.5, 0.6))
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
	if btn_kael: btn_kael.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	if btn_vex: btn_vex.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	if btn_brutus: btn_brutus.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))

	match hero_id:
		"kael":
			if btn_kael: btn_kael.add_theme_color_override("font_color", Color(0.2, 0.9, 1.0))
			if preview_hero:
				var skin_path = "res://assets/sprites/skins/player_kael_crimson.png" if SaveManager.equipped_hero_skin == "crimson" else "res://assets/sprites/player_kael_run.png"
				preview_hero.texture = load(skin_path)
			if hero_desc:
				hero_desc.text = "> KAEL (The CyberSmith) [BALANCED]\n\nHP        : 4 HEALTH\nSPEED     : 160 PX/S\n\nSKILL AKTIF [SPACE/E]: EMP CRYO DASH\nMeluncur 260px ke depan dengan kekebalan dan melepaskan gelombang es yang membekukan musuh 3 detik.\n\nSENJATA NATIVE : DUAL REVOLVER (+25% Damage Buff)"
		"vex":
			if btn_vex: btn_vex.add_theme_color_override("font_color", Color(1.0, 0.3, 0.4))
			if preview_hero:
				var skin_path = "res://assets/sprites/skins/player_vex_toxic.png" if SaveManager.equipped_hero_skin == "toxic" else "res://assets/sprites/player_vex_run.png"
				preview_hero.texture = load(skin_path)
			if hero_desc:
				hero_desc.text = "> VEX (Phase Assassin) [AGILITY]\n\nHP        : 3 HEALTH (Tipis)\nSPEED     : 205 PX/S (Sangat Lincah)\n\nSKILL AKTIF [SPACE/E]: PHASE BLINK\nTeleportasi seketika 320px menembus rintangan dan meninggalkan decoy pemancing yang meledak 80 DMG.\n\nSENJATA NATIVE : CYBER SMG (+25% Laju Tembak Buff)"
		"brutus":
			if btn_brutus: btn_brutus.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
			if preview_hero:
				var skin_path = "res://assets/sprites/skins/player_brutus_gold.png" if SaveManager.equipped_hero_skin == "gold" else "res://assets/sprites/player_brutus_run.png"
				preview_hero.texture = load(skin_path)
			if hero_desc:
				hero_desc.text = "> BRUTUS (The Juggernaut) [TANK]\n\nHP        : 6 HEALTH (Sangat Tebal)\nSPEED     : 130 PX/S (Lambat)\n\nSKILL AKTIF [SPACE/E]: TITAN SEISMIC SLAM\nMenghentak tanah memicu gempa 70 DMG + hempasan 350px dan memberikan perisai kinetik 2.0s.\n\nSENJATA NATIVE : SCRAP SHOTGUN (+3 Pellets & +20% Knockback)"

func setup_weapon_btn(btn: Button, wep_id: String) -> void:
	if not btn: return
	btn.pressed.connect(func():
		if sfx_click: sfx_click.play()
		GameState.selected_weapon = wep_id
		update_weapon_ui(wep_id)
		check_synergy()
	)

func update_weapon_ui(wep_id: String) -> void:
	if btn_revolver: btn_revolver.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	if btn_shotgun: btn_shotgun.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	if btn_smg: btn_smg.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))

	match wep_id:
		"revolver":
			if btn_revolver: btn_revolver.add_theme_color_override("font_color", Color(0.2, 0.9, 1.0))
			if preview_weapon:
				var wep_path = "res://assets/sprites/skins/spr_revolver_gold.png" if SaveManager.equipped_weapon_skin == "gold" else "res://assets/sprites/spr_revolver.png"
				preview_weapon.texture = load(wep_path)
				preview_weapon.position = Vector2(10, 0)
			if weapon_desc:
				weapon_desc.text = "> DUAL PLASMA REVOLVER [MID-LONG]\n\nMAGASIN   : 6 PELURU\nDAMAGE    : 24 PER HIT\nRELOAD    : 0.95 DETIK\n\nKARAKTERISTIK:\nPresisi tinggi tembakan berdaya tembus tajam. Ideal untuk eliminasi musuh dari jarak aman."
		"shotgun":
			if btn_shotgun: btn_shotgun.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
			if preview_weapon:
				var wep_path = "res://assets/sprites/skins/spr_shotgun_cyber.png" if SaveManager.equipped_weapon_skin == "cyber" else "res://assets/sprites/spr_shotgun.png"
				preview_weapon.texture = load(wep_path)
				preview_weapon.position = Vector2(14, 0)
			if weapon_desc:
				weapon_desc.text = "> SCRAP SHOTGUN [CLOSE QUARTERS]\n\nMAGASIN   : 4 PELURU (Sangat Terbatas)\nDAMAGE    : 8x8 PELLETS (64 POINT-BLANK)\nRELOAD    : 1.25 DETIK (Lambat)\n\nKARAKTERISTIK:\nJarak sangat pendek! Peluru menguap di 170px. Mematikan jika ditembakkan langsung di depan robot musuh."
		"smg":
			if btn_smg: btn_smg.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
			if preview_weapon:
				var wep_path = "res://assets/sprites/skins/spr_smg_violet.png" if SaveManager.equipped_weapon_skin == "violet" else "res://assets/sprites/spr_smg.png"
				preview_weapon.texture = load(wep_path)
				preview_weapon.position = Vector2(10, 0)
			if weapon_desc:
				weapon_desc.text = "> CYBER SMG [RAPID SPRAY]\n\nMAGASIN   : 28 PELURU (Sangat Banyak)\nDAMAGE    : 7 PER HIT\nLAJU TEMBAK: 0.075S (Sangat Cepat)\nRELOAD    : 0.80 DETIK\n\nKARAKTERISTIK:\nLaju semburan peluru cepat untuk memotong kerumunan musuh banyak seketika."

func check_synergy() -> void:
	if not synergy_banner: return
	var is_syn := false
	if GameState.selected_hero == "kael" and GameState.selected_weapon == "revolver":
		is_syn = true
		synergy_banner.text = "[ NATIVE SYNERGY AKTIF: KAEL + REVOLVER -> +25% DMG ]"
	elif GameState.selected_hero == "vex" and GameState.selected_weapon == "smg":
		is_syn = true
		synergy_banner.text = "[ NATIVE SYNERGY AKTIF: VEX + SMG -> +25% LAJU TEMBAK ]"
	elif GameState.selected_hero == "brutus" and GameState.selected_weapon == "shotgun":
		is_syn = true
		synergy_banner.text = "[ NATIVE SYNERGY AKTIF: BRUTUS + SHOTGUN -> +3 PELLETS ]"
	else:
		synergy_banner.text = "[ NON-NATIVE: BUFF SENJATA PASIF NONAKTIF (DAPAT DIUPGRADE DI SHOP) ]"
		synergy_banner.add_theme_color_override("font_color", Color(0.85, 0.6, 0.35))
		return
	synergy_banner.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))

func update_prep_stage_banner() -> void:
	if prep_stage_banner:
		var cfg = GameState.stage_configs.get(GameState.current_stage, GameState.stage_configs[1])
		prep_stage_banner.text = "[ TARGET: %s // %d DETIK ]" % [cfg["title"], int(cfg["target_time"])]
	check_synergy()

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