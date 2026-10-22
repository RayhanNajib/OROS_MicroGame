extends CanvasLayer

@onready var status_label: Label = $TopBar/HBox/StatusLabel
@onready var led_najib: ColorRect = $TopBar/HBox/LEDContainer/LEDNajib
@onready var led_luigy: ColorRect = $TopBar/HBox/LEDContainer/LEDLuigy
@onready var led_faizun: ColorRect = $TopBar/HBox/LEDContainer/LEDFaizun

# Popup Single Member Card
@onready var member_card: PanelContainer = $MemberCard
@onready var card_avatar: TextureRect = $MemberCard/MarginContainer/HBox/AvatarRect
@onready var card_name: Label = $MemberCard/MarginContainer/HBox/VBox/NameLabel
@onready var card_nim: Label = $MemberCard/MarginContainer/HBox/VBox/NimLabel
@onready var card_role: Label = $MemberCard/MarginContainer/HBox/VBox/RoleLabel
@onready var card_desc: Label = $MemberCard/MarginContainer/HBox/VBox/DescLabel
@onready var card_timer: Timer = $MemberCard/CardTimer

# Victory Panel
@onready var victory_panel: PanelContainer = $VictoryPanel
@onready var sfx_popup: AudioStreamPlayer = $SFXPopup

var activated_count: int = 0

func _ready() -> void:
	if member_card:
		member_card.visible = false
	if victory_panel:
		victory_panel.visible = false
	if card_timer:
		card_timer.timeout.connect(_on_card_timer_timeout)
		
	update_status_bar()

func update_status_bar() -> void:
	if status_label:
		status_label.text = "O.R.O.S. DIAGNOSTIC: [ %d / 3 ] TERMINALS ONLINE" % activated_count
		if activated_count == 3:
			status_label.modulate = Color(0.2, 1.0, 0.4)
		else:
			status_label.modulate = Color(0.9, 0.9, 1.0)

func show_member_popup(info: Dictionary) -> void:
	activated_count += 1
	update_status_bar()
	
	# Update LED indicator
	match info["id"]:
		"najib":
			if led_najib: led_najib.color = Color(0.0, 0.9, 1.0) # Cyan
		"luigy":
			if led_luigy: led_luigy.color = Color(0.8, 0.3, 1.0) # Purple
		"faizun":
			if led_faizun: led_faizun.color = Color(0.2, 0.95, 0.5) # Emerald green
			
	# Update popup card
	if member_card:
		card_name.text = info.get("name", "")
		card_nim.text = "NIM: " + str(info.get("nim", ""))
		card_role.text = info.get("role", "")
		card_desc.text = info.get("desc", "")
		if info.get("avatar") and card_avatar:
			card_avatar.texture = info["avatar"]
			
		member_card.visible = true
		if sfx_popup: sfx_popup.play()
		card_timer.start(4.0)

func _on_card_timer_timeout() -> void:
	if member_card:
		member_card.visible = false

func show_victory_screen() -> void:
	if member_card:
		member_card.visible = false
	if victory_panel:
		victory_panel.visible = true
