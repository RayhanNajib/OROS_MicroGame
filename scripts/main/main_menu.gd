extends Control

@onready var play_btn: Button = $CenterBox/VerticalMenuButtons/PlayBtn
@onready var shop_btn: Button = $CenterBox/VerticalMenuButtons/ShopBtn
@onready var settings_btn: Button = $CenterBox/VerticalMenuButtons/SettingsBtn
@onready var controls_btn: Button = $CenterBox/VerticalMenuButtons/ControlsBtn
@onready var quit_btn: Button = $CenterBox/VerticalMenuButtons/QuitBtn

@onready var stage_status_label: Label = $CenterBox/StageStatusLabel

@onready var campaign_wizard_modal = $CampaignWizardModal
@onready var marketplace_modal = $MarketplaceModal
@onready var settings_modal = $SettingsModal
@onready var controls_modal = $ControlsModal
@onready var close_controls_btn: Button = $ControlsModal/Center/Panel/Margin/VBox/CloseControlsBtn

@onready var sfx_click: AudioStreamPlayer = $SFXClick

func _ready() -> void:
	setup_btn(play_btn, _on_play_pressed, Vector2(260, 34))
	setup_btn(shop_btn, _on_shop_pressed, Vector2(260, 32))
	setup_btn(settings_btn, _on_settings_pressed, Vector2(260, 32))
	setup_btn(controls_btn, _on_controls_pressed, Vector2(260, 32))
	setup_btn(quit_btn, _on_quit_pressed, Vector2(260, 32))

	if close_controls_btn:
		setup_btn(close_controls_btn, func(): controls_modal.visible = false, Vector2(140, 26))

	if campaign_wizard_modal:
		campaign_wizard_modal.open_shop_requested.connect(_on_shop_pressed)

	update_stage_status()

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

func update_stage_status() -> void:
	if not stage_status_label: return
	var s_data = SaveManager.stages_data.get(GameState.current_stage, {"unlocked": true, "high_rank": "-"})
	var cfg = GameState.stage_configs.get(GameState.current_stage, GameState.stage_configs[1])
	stage_status_label.text = "SEKTOR MISI: [ STAGE %02d // %s ]  •  EVALUASI RANK TERTINGGI: %s" % [
		GameState.current_stage, cfg["title"], s_data.get("high_rank", "-")
	]

func _on_play_pressed() -> void:
	if campaign_wizard_modal:
		campaign_wizard_modal.open_wizard()

func _on_shop_pressed() -> void:
	if marketplace_modal:
		marketplace_modal.open_marketplace()

func _on_settings_pressed() -> void:
	if settings_modal:
		settings_modal.visible = true

func _on_controls_pressed() -> void:
	if controls_modal:
		controls_modal.visible = true

func _on_quit_pressed() -> void:
	get_tree().quit()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ESCAPE:
			if controls_modal and controls_modal.visible:
				controls_modal.visible = false
			elif settings_modal and settings_modal.visible:
				settings_modal.visible = false
			elif marketplace_modal and marketplace_modal.visible:
				marketplace_modal.visible = false
			elif campaign_wizard_modal and campaign_wizard_modal.visible:
				campaign_wizard_modal._on_back_pressed()