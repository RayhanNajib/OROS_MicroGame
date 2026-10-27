extends Control

@onready var center_box: VBoxContainer = $CenterBox
@onready var play_btn: Button = $CenterBox/VerticalMenuButtons/PlayBtn
@onready var coop_btn: Button = $CenterBox/VerticalMenuButtons/CoopBtn
@onready var shop_btn: Button = $CenterBox/VerticalMenuButtons/ShopBtn
@onready var save_load_btn: Button = $CenterBox/VerticalMenuButtons/SaveLoadBtn
@onready var settings_btn: Button = $CenterBox/VerticalMenuButtons/SettingsBtn
@onready var controls_btn: Button = $CenterBox/VerticalMenuButtons/ControlsBtn
@onready var quit_btn: Button = $CenterBox/VerticalMenuButtons/QuitBtn

@onready var stage_status_label: Label = $CenterBox/StageStatusLabel

@onready var campaign_wizard_modal = $CampaignWizardModal
@onready var marketplace_modal = $MarketplaceModal
@onready var settings_modal = $SettingsModal
@onready var controls_modal = $CreditsHoloModal
@onready var save_load_modal = $SaveLoadModal

@onready var pixel_bg: TextureRect = $PixelBG
@onready var logo_rect: TextureRect = $CenterBox/LogoRect

@onready var sfx_click: AudioStreamPlayer = $SFXClick
@onready var bgm_combat: AudioStreamPlayer = $BGMCombat

var _bg_time: float = 0.0
var menu_buttons: Array[Button] = []

func _process(delta: float) -> void:
	# Live animated home background: slow parallax pan + gentle logo float
	_bg_time += delta
	if pixel_bg:
		# Anchor-driven bg: animate scale drift (no position fight with full-rect anchors)
		pixel_bg.pivot_offset = Vector2(960, 540)
		var bg_scale_x := 1.10 + sin(_bg_time * 0.12) * 0.035
		var bg_scale_y := 1.10 + cos(_bg_time * 0.09) * 0.035
		pixel_bg.scale = Vector2(bg_scale_x, bg_scale_y)
		pixel_bg.rotation = sin(_bg_time * 0.05) * 0.006
	if logo_rect:
		# Scale pulse (container-managed position must not be overridden)
		logo_rect.pivot_offset = Vector2(260, 55)
		var pulse := 1.0 + sin(_bg_time * 1.6) * 0.012
		logo_rect.scale = Vector2(pulse, pulse)

func _ready() -> void:
	if get_tree().paused:
		get_tree().paused = false
	ensure_bgm_playing()
	Input.set_custom_mouse_cursor(null)
	setup_btn(play_btn, _on_play_pressed, Vector2(260, 34))
	setup_btn(coop_btn, _on_coop_pressed, Vector2(260, 32))
	setup_btn(shop_btn, _on_shop_pressed, Vector2(260, 32))
	setup_btn(save_load_btn, _on_save_load_pressed, Vector2(260, 32))
	setup_btn(settings_btn, _on_settings_pressed, Vector2(260, 32))
	setup_btn(controls_btn, _on_controls_pressed, Vector2(260, 32))
	setup_btn(quit_btn, _on_quit_pressed, Vector2(260, 32))

	# Establish seamless cyclic UI focus loop for D-Pad, Numpad, and Arrow navigation
	menu_buttons = [play_btn, coop_btn, shop_btn, save_load_btn, settings_btn, controls_btn, quit_btn]
	for i in range(menu_buttons.size()):
		var b = menu_buttons[i]
		if not b: continue
		b.focus_mode = Control.FOCUS_ALL
		var prev_btn = menu_buttons[(i - 1 + menu_buttons.size()) % menu_buttons.size()]
		var next_btn = menu_buttons[(i + 1) % menu_buttons.size()]
		if prev_btn: b.focus_neighbor_top = prev_btn.get_path()
		if next_btn: b.focus_neighbor_bottom = next_btn.get_path()

	# Live Animated Battle Backdrop
	var battle_script = load("res://scripts/ui/live_battle_backdrop.gd")
	if battle_script:
		var battle_node = Node2D.new()
		battle_node.name = "LiveBattleBackdrop"
		battle_node.set_script(battle_script)
		add_child(battle_node)
		move_child(battle_node, 0)
	if pixel_bg:
		pixel_bg.modulate = Color(1, 1, 1, 0.40) # Translucent grid over animated battle
		
	if play_btn:
		play_btn.grab_focus()

	if campaign_wizard_modal:
		campaign_wizard_modal.open_shop_requested.connect(_on_shop_pressed)
		campaign_wizard_modal.visibility_changed.connect(_check_modal_states)

	if marketplace_modal:
		marketplace_modal.visibility_changed.connect(_check_modal_states)

	if controls_modal:
		controls_modal.visibility_changed.connect(_check_modal_states)

	if settings_modal:
		settings_modal.visibility_changed.connect(_check_modal_states)
		if settings_modal.has_signal("settings_closed"):
			settings_modal.settings_closed.connect(func():
				_update_bgm_volume()
				ensure_bgm_playing()
				if settings_btn: settings_btn.grab_focus()
			)

	if save_load_modal:
		save_load_modal.visibility_changed.connect(_check_modal_states)
		if save_load_modal.has_signal("modal_closed"):
			save_load_modal.modal_closed.connect(func():
				update_stage_status()
				_update_bgm_volume()
				ensure_bgm_playing()
				if save_load_btn: save_load_btn.grab_focus()
			)

	update_stage_status()

var _last_pressed_btn: Button = null

func _check_modal_states() -> void:
	var any_modal_open = (
		(campaign_wizard_modal and campaign_wizard_modal.visible) or
		(marketplace_modal and marketplace_modal.visible) or
		(controls_modal and controls_modal.visible) or
		(settings_modal and settings_modal.visible) or
		(save_load_modal and save_load_modal.visible)
	)
	if center_box:
		center_box.visible = not any_modal_open
		if not any_modal_open:
			if _last_pressed_btn and is_instance_valid(_last_pressed_btn) and _last_pressed_btn.is_visible_in_tree():
				_last_pressed_btn.grab_focus()
			elif play_btn:
				play_btn.grab_focus()
	ensure_bgm_playing()

func ensure_bgm_playing() -> void:
	if not bgm_combat:
		bgm_combat = get_node_or_null("BGMCombat")
	if not bgm_combat:
		bgm_combat = AudioStreamPlayer.new()
		bgm_combat.name = "BGMCombat"
		add_child(bgm_combat)

	bgm_combat.process_mode = Node.PROCESS_MODE_ALWAYS

	if bgm_combat.stream == null:
		var stream_res = load("res://assets/audio/bgm_combat_loop.wav")
		if stream_res:
			bgm_combat.stream = stream_res

	if bgm_combat.stream and bgm_combat.stream is AudioStreamWAV:
		var wav: AudioStreamWAV = bgm_combat.stream
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		if wav.loop_end <= 0 or wav.loop_end <= wav.loop_begin:
			var total_samples: int = int(wav.get_length() * wav.mix_rate)
			if total_samples > 1:
				wav.loop_end = total_samples - 1
			else:
				wav.loop_end = 352799

	if not bgm_combat.finished.is_connected(_on_bgm_finished):
		bgm_combat.finished.connect(_on_bgm_finished)

	_update_bgm_volume()

	if not bgm_combat.playing:
		bgm_combat.play()

func _on_bgm_finished() -> void:
	if is_inside_tree() and bgm_combat:
		bgm_combat.play()

func _update_bgm_volume() -> void:
	if not bgm_combat:
		return
	var master_vol: float = 1.0
	var bgm_vol: float = 0.8
	var sm = get_node_or_null("/root/SaveManager")
	if sm:
		if "volume_master" in sm:
			master_vol = float(sm.volume_master)
		if "volume_bgm" in sm:
			bgm_vol = float(sm.volume_bgm)
		elif "audio_bgm" in sm:
			bgm_vol = float(sm.audio_bgm)
	var combined: float = clampf(master_vol * bgm_vol, 0.0, 1.0)
	if combined <= 0.01:
		bgm_combat.volume_db = -80.0
	else:
		bgm_combat.volume_db = linear_to_db(combined)

func _on_controls_pressed() -> void:
	_last_pressed_btn = controls_btn
	if controls_modal:
		controls_modal.open_credits()

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
	btn.focus_entered.connect(func():
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.focus_exited.connect(func():
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)

func update_stage_status() -> void:
	if not stage_status_label: return
	var s_data = SaveManager.stages_data.get(GameState.current_stage, {"unlocked": true, "high_rank": "-"})
	var cfg = GameState.stage_configs.get(GameState.current_stage, GameState.stage_configs[1])
	stage_status_label.text = "SEKTOR MISI: [ STAGE %02d // %s ]  •  EVALUASI RANK TERTINGGI: %s" % [
		GameState.current_stage, cfg["title"], s_data.get("high_rank", "-")
	]

func _on_play_pressed() -> void:
	_last_pressed_btn = play_btn
	GameState.is_coop_mode = false
	if campaign_wizard_modal:
		campaign_wizard_modal.open_wizard()

func _on_coop_pressed() -> void:
	_last_pressed_btn = coop_btn
	GameState.is_coop_mode = true
	if campaign_wizard_modal:
		campaign_wizard_modal.open_wizard()

func _on_shop_pressed() -> void:
	_last_pressed_btn = shop_btn
	if marketplace_modal:
		marketplace_modal.open_marketplace()

func _on_save_load_pressed() -> void:
	_last_pressed_btn = save_load_btn
	if save_load_modal:
		if save_load_modal.has_method("open_modal"):
			save_load_modal.open_modal()
		else:
			save_load_modal.visible = true

func _on_settings_pressed() -> void:
	_last_pressed_btn = settings_btn
	if settings_modal:
		if settings_modal.has_method("open_modal"):
			settings_modal.open_modal()
		else:
			settings_modal.visible = true

func _on_quit_pressed() -> void:
	get_tree().quit()

func _input(event: InputEvent) -> void:
	var is_cancel = event.is_action_pressed("ui_cancel")
	if not is_cancel and event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_KP_0:
			is_cancel = true
	elif not is_cancel and event is InputEventJoypadButton and event.is_pressed() and event.button_index == JOY_BUTTON_B:
		is_cancel = true

	if is_cancel:
		var handled_modal = false
		if controls_modal and controls_modal.visible:
			controls_modal.visible = false
			handled_modal = true
		elif settings_modal and settings_modal.visible:
			if settings_modal.has_method("close_modal"):
				settings_modal.close_modal()
			else:
				settings_modal.visible = false
			handled_modal = true
		elif save_load_modal and save_load_modal.visible:
			if save_load_modal.has_method("close_modal"):
				save_load_modal.close_modal()
			else:
				save_load_modal.visible = false
			handled_modal = true
		elif marketplace_modal and marketplace_modal.visible:
			marketplace_modal.visible = false
			handled_modal = true
		elif campaign_wizard_modal and campaign_wizard_modal.visible:
			campaign_wizard_modal._on_back_pressed()
			handled_modal = true

		if handled_modal:
			_check_modal_states()
			get_viewport().set_input_as_handled()
	elif center_box and center_box.visible and get_viewport().gui_get_focus_owner() == null:
		if _last_pressed_btn and is_instance_valid(_last_pressed_btn) and _last_pressed_btn.is_visible_in_tree():
			_last_pressed_btn.grab_focus()
		elif play_btn:
			play_btn.grab_focus()