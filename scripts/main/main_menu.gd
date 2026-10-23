extends Control

# Bottom Action Buttons
@onready var start_btn: Button = $BottomActions/StartBtn
@onready var stage_btn: Button = $BottomActions/StageBtn
@onready var shop_btn: Button = $BottomActions/ShopBtn
@onready var controls_btn: Button = $BottomActions/ControlsBtn
@onready var credits_btn: Button = $BottomActions/CreditsBtn
@onready var quit_btn: Button = $BottomActions/QuitBtn

@onready var active_stage_label: Label = $TopGroup/ActiveStageIndicator

# Hero Selection
@onready var btn_kael: Button = $SelectionHBox/HeroPanel/Margin/VBox/HeroBtns/BtnKael
@onready var btn_vex: Button = $SelectionHBox/HeroPanel/Margin/VBox/HeroBtns/BtnVex
@onready var btn_brutus: Button = $SelectionHBox/HeroPanel/Margin/VBox/HeroBtns/BtnBrutus
@onready var hero_desc: Label = $SelectionHBox/HeroPanel/Margin/VBox/HeroDesc

# Weapon Selection
@onready var btn_revolver: Button = $SelectionHBox/WeaponPanel/Margin/VBox/WeaponBtns/BtnRevolver
@onready var btn_shotgun: Button = $SelectionHBox/WeaponPanel/Margin/VBox/WeaponBtns/BtnShotgun
@onready var btn_smg: Button = $SelectionHBox/WeaponPanel/Margin/VBox/WeaponBtns/BtnSMG
@onready var weapon_desc: Label = $SelectionHBox/WeaponPanel/Margin/VBox/WeaponDesc

# Live Preview Stage
@onready var preview_hero: Sprite2D = $SelectionHBox/PreviewPanel/Margin/VBox/StageControl/PreviewHero
@onready var preview_weapon: Sprite2D = $SelectionHBox/PreviewPanel/Margin/VBox/StageControl/PreviewHero/PreviewWeapon

# Modals
@onready var stage_select_modal = $StageSelectModal
@onready var marketplace_modal = $MarketplaceModal
@onready var controls_modal: ColorRect = $ControlsModal
@onready var close_controls_btn: Button = $ControlsModal/Center/Panel/Margin/VBox/CloseControlsBtn

@onready var credits_modal: ColorRect = $CreditsModal
@onready var close_credits_btn: Button = $CreditsModal/Center/Panel/Margin/VBox/CloseCreditsBtn

@onready var sfx_click: AudioStreamPlayer = $SFXClick

func _ready() -> void:
	setup_btn(start_btn, _on_start_pressed, Vector2(170, 28))
	setup_btn(stage_btn, _on_stage_pressed, Vector2(150, 28))
	setup_btn(shop_btn, _on_shop_pressed, Vector2(150, 28))
	setup_btn(controls_btn, _on_controls_pressed, Vector2(140, 28))
	setup_btn(credits_btn, _on_credits_pressed, Vector2(140, 28))
	setup_btn(quit_btn, _on_quit_pressed, Vector2(65, 28))
	
	if close_controls_btn:
		setup_btn(close_controls_btn, func(): controls_modal.visible = false, Vector2(130, 24))
	if close_credits_btn:
		setup_btn(close_credits_btn, func(): credits_modal.visible = false, Vector2(140, 24))

	setup_hero_btn(btn_kael, "kael")
	setup_hero_btn(btn_vex, "vex")
	setup_hero_btn(btn_brutus, "brutus")
	update_hero_ui("kael")

	setup_weapon_btn(btn_revolver, "revolver")
	setup_weapon_btn(btn_shotgun, "shotgun")
	setup_weapon_btn(btn_smg, "smg")
	update_weapon_ui("revolver")
	
	if stage_select_modal:
		stage_select_modal.stage_selected.connect(_on_stage_selected)
		
	update_stage_indicator()

func setup_btn(btn: Button, callback: Callable, pivot: Vector2) -> void:
	if not btn: return
	btn.pivot_offset = pivot
	btn.pressed.connect(func():
		if sfx_click: sfx_click.play()
		callback.call()
	)
	btn.mouse_entered.connect(func():
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func():
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)

func _process(_delta: float) -> void:
	if preview_hero:
		var breath := sin(Time.get_ticks_msec() * 0.005) * 0.04
		preview_hero.scale = Vector2(5.5 * (1.0 + breath), 5.5 * (1.0 - breath))

func update_stage_indicator() -> void:
	var cfg = GameState.stage_configs.get(GameState.current_stage, GameState.stage_configs[1])
	if active_stage_label:
		active_stage_label.text = "SEKTOR AKTIF: [ STAGE %02d: %s // %s ]" % [GameState.current_stage, cfg["title"], cfg["difficulty"]]

func _on_stage_selected(_s_id: int) -> void:
	update_stage_indicator()

func setup_hero_btn(btn: Button, hero_id: String) -> void:
	if not btn: return
	btn.pressed.connect(func():
		if sfx_click: sfx_click.play()
		GameState.selected_hero = hero_id
		update_hero_ui(hero_id)
	)

func update_hero_ui(hero_id: String) -> void:
	if btn_kael: btn_kael.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	if btn_vex: btn_vex.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	if btn_brutus: btn_brutus.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))

	if preview_hero:
		var tw := preview_hero.create_tween()
		tw.tween_property(preview_hero, "position:y", 215.0, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(preview_hero, "position:y", 240.0, 0.14).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	match hero_id:
		"kael":
			if btn_kael: btn_kael.add_theme_color_override("font_color", Color(0.2, 0.9, 1.0))
			if preview_hero:
				var skin_path = "res://assets/sprites/skins/player_kael_crimson.png" if SaveManager.equipped_hero_skin == "crimson" else "res://assets/sprites/player_kael_run.png"
				preview_hero.texture = load(skin_path)
			if hero_desc:
				hero_desc.text = "> KAEL (The CyberSmith) [BALANCED]\n\nHP        : 4 HEALTH\nSPEED     : 160 PX/S\n\nKELEBIHAN : Adaptif di segala situasi.\nPASIF     : Overclock Core (+20% Bullet Damage & Pulsa Energi 360 Derajat Berkala)."
		"vex":
			if btn_vex: btn_vex.add_theme_color_override("font_color", Color(1.0, 0.3, 0.4))
			if preview_hero:
				var skin_path = "res://assets/sprites/skins/player_vex_toxic.png" if SaveManager.equipped_hero_skin == "toxic" else "res://assets/sprites/player_vex_run.png"
				preview_hero.texture = load(skin_path)
			if hero_desc:
				hero_desc.text = "> VEX (Phase Assassin) [AGILITY]\n\nHP        : 3 HEALTH (Rentan)\nSPEED     : 205 PX/S (Sangat Lincah)\n\nKELEMAHAN : HP tipis (3 hit mati).\nPASIF     : Phase Step (15% Peluang Menghindar/Dodge dari Hit Musuh)."
		"brutus":
			if btn_brutus: btn_brutus.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
			if preview_hero:
				var skin_path = "res://assets/sprites/skins/player_brutus_gold.png" if SaveManager.equipped_hero_skin == "gold" else "res://assets/sprites/player_brutus_run.png"
				preview_hero.texture = load(skin_path)
			if hero_desc:
				hero_desc.text = "> BRUTUS (The Juggernaut) [TANK]\n\nHP        : 6 HEALTH (Sangat Tebal)\nSPEED     : 130 PX/S (Lambat)\n\nKELEBIHAN : Reduksi -1 damage kontak musuh.\nPASIF     : Nano-Armor (Regenerasi 1 HP Otomatis Setiap 50 Eliminasi Robot)."

func setup_weapon_btn(btn: Button, wep_id: String) -> void:
	if not btn: return
	btn.pressed.connect(func():
		if sfx_click: sfx_click.play()
		GameState.selected_weapon = wep_id
		update_weapon_ui(wep_id)
	)

func update_weapon_ui(wep_id: String) -> void:
	if btn_revolver: btn_revolver.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	if btn_shotgun: btn_shotgun.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	if btn_smg: btn_smg.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))

	if preview_weapon:
		var tw := preview_weapon.create_tween()
		tw.tween_property(preview_weapon, "scale", Vector2(1.3, 1.3), 0.08)
		tw.tween_property(preview_weapon, "scale", Vector2.ONE, 0.1)

	match wep_id:
		"revolver":
			if btn_revolver: btn_revolver.add_theme_color_override("font_color", Color(0.2, 0.9, 1.0))
			if preview_weapon:
				var wep_path = "res://assets/sprites/skins/spr_revolver_gold.png" if SaveManager.equipped_weapon_skin == "gold" else "res://assets/sprites/spr_revolver.png"
				preview_weapon.texture = load(wep_path)
				preview_weapon.position = Vector2(10, 0)
			if weapon_desc:
				weapon_desc.text = "> DUAL PLASMA REVOLVER\n\nMAGASIN   : 6 PELURU\nDAMAGE    : 22 PER HIT\nRELOAD    : 1.0 DETIK\n\nKARAKTER  : Presisi tinggi jarak menengah, konsumsi magasin seimbang untuk pertempuran stabil."
		"shotgun":
			if btn_shotgun: btn_shotgun.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
			if preview_weapon:
				var wep_path = "res://assets/sprites/skins/spr_shotgun_cyber.png" if SaveManager.equipped_weapon_skin == "cyber" else "res://assets/sprites/spr_shotgun.png"
				preview_weapon.texture = load(wep_path)
				preview_weapon.position = Vector2(14, 0)
			if weapon_desc:
				weapon_desc.text = "> SCRAP SHOTGUN\n\nMAGASIN   : 4 PELURU\nDAMAGE    : 5x9 PELLETS (45 TOTAL)\nRELOAD    : 1.2 DETIK\n\nKARAKTER  : Semburan peluru sebar jarak dekat dengan daya tolak (knockback 150) sangat tinggi."
		"smg":
			if btn_smg: btn_smg.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
			if preview_weapon:
				var wep_path = "res://assets/sprites/skins/spr_smg_violet.png" if SaveManager.equipped_weapon_skin == "violet" else "res://assets/sprites/spr_smg.png"
				preview_weapon.texture = load(wep_path)
				preview_weapon.position = Vector2(10, 0)
			if weapon_desc:
				weapon_desc.text = "> CYBER SMG (RAPID FIRE)\n\nMAGASIN   : 24 PELURU\nDAMAGE    : 8 PER HIT\nLAJU TEMBAK: 0.08S (EKSTREM)\nRELOAD    : 0.85 DETIK\n\nKARAKTER  : Laju tembak super cepat untuk merobek gerombolan musuh rapat seketika."

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ESCAPE:
			if controls_modal and controls_modal.visible:
				controls_modal.visible = false
			elif credits_modal and credits_modal.visible:
				credits_modal.visible = false
			elif stage_select_modal and stage_select_modal.visible:
				stage_select_modal.visible = false
			elif marketplace_modal and marketplace_modal.visible:
				marketplace_modal.visible = false
		elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			if not is_any_modal_open():
				_on_start_pressed()

func is_any_modal_open() -> bool:
	return (controls_modal and controls_modal.visible) or \
		(credits_modal and credits_modal.visible) or \
		(stage_select_modal and stage_select_modal.visible) or \
		(marketplace_modal and marketplace_modal.visible)

func _on_start_pressed() -> void:
	if stage_select_modal:
		stage_select_modal.open_stage_select()
	else:
		GameState.reset_run()
		get_tree().change_scene_to_file("res://scenes/main/GameArena.tscn")

func _on_stage_pressed() -> void:
	if stage_select_modal:
		stage_select_modal.open_stage_select()

func _on_shop_pressed() -> void:
	if marketplace_modal:
		marketplace_modal.open_marketplace()

func _on_controls_pressed() -> void:
	if controls_modal:
		controls_modal.visible = true

func _on_credits_pressed() -> void:
	if credits_modal:
		credits_modal.visible = true

func _on_quit_pressed() -> void:
	get_tree().quit()