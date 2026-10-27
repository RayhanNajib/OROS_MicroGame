extends CanvasLayer

var cursor_sprite: Sprite2D
var virtual_pos: Vector2 = Vector2(960, 540)
var velocity: Vector2 = Vector2.ZERO
var active: bool = false
var cursor_speed: float = 950.0

func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	cursor_sprite = Sprite2D.new()
	var tex = load("res://assets/ui/cursor_gamepad_circle.png")
	if tex:
		cursor_sprite.texture = tex
	cursor_sprite.offset = Vector2.ZERO # Centered circular reticle
	cursor_sprite.visible = false
	add_child(cursor_sprite)

func is_in_menu_mode() -> bool:
	if get_tree().paused: return true
	var current_scene = get_tree().current_scene
	if current_scene and ("MainMenu" in current_scene.name or "Splash" in current_scene.name):
		return true
	# Check if any modal is currently visible
	for modal_name in ["CampaignWizardModal", "MarketplaceModal", "SettingsModal", "LevelUpModal", "TomeModal", "PauseModal", "GameOverModal", "CreditsHoloModal", "DisconnectModal"]:
		var m = get_tree().root.find_child(modal_name, true, false)
		if m and m.visible:
			return true
	return false

func _process(delta: float) -> void:
	var pads = Input.get_connected_joypads()
	var im = get_node_or_null("/root/InputManager")
	var is_pad_active = (pads.size() > 0) or (im and im.p1_scheme != "keyboard") or active
	if not is_pad_active:
		if cursor_sprite.visible: cursor_sprite.visible = false
		return

	# Only operate virtual cursor when in menus/modals or paused
	if not is_in_menu_mode():
		if cursor_sprite.visible:
			cursor_sprite.visible = false
			active = false
		return

	var dev_id := 0
	# Right stick drives virtual pointer in menus. Left Stick & D-Pad are reserved for discrete UI focus.
	var rx := Input.get_joy_axis(dev_id, JOY_AXIS_RIGHT_X)
	var ry := Input.get_joy_axis(dev_id, JOY_AXIS_RIGHT_Y)
	var stick := Vector2(rx, ry)

	var mult: float = 1.0
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.get("gamepad_sensitivity"):
		mult = sm.get("gamepad_sensitivity")

	if stick.length() > 0.18:
		if not active:
			active = true
			cursor_sprite.visible = true
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			var vp = get_viewport()
			if vp: virtual_pos = vp.get_mouse_position()
			
		var target_vel = stick.normalized() * (cursor_speed * mult * minf(1.0, stick.length()))
		velocity = velocity.move_toward(target_vel, 4200.0 * delta)
		virtual_pos += velocity * delta
		
		var vp_rect = get_viewport().get_visible_rect()
		virtual_pos.x = clampf(virtual_pos.x, 4.0, vp_rect.size.x - 4.0)
		virtual_pos.y = clampf(virtual_pos.y, 4.0, vp_rect.size.y - 4.0)
		cursor_sprite.global_position = virtual_pos
		cursor_sprite.rotation += delta * 2.5
		
		# Send MouseMotion event to trigger UI hover states
		var motion := InputEventMouseMotion.new()
		motion.position = virtual_pos
		motion.global_position = virtual_pos
		motion.relative = velocity * delta
		motion.device = -1
		Input.parse_input_event(motion)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 3800.0 * delta)

func _input(event: InputEvent) -> void:
	if not is_in_menu_mode():
		return

	# 1. PHYSICAL MOUSE DETECTION: Hide virtual cursor if real mouse moves
	if event is InputEventMouseMotion and not (event.device == -1):
		if active and event.relative.length() > 4.0:
			active = false
			cursor_sprite.visible = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# 2. VIRTUAL CURSOR CLICKING:
	# When virtual cursor is actively pointing, A button or RT clicks at the virtual cursor position
	elif active and event is InputEventJoypadButton and event.device == 0 and event.is_pressed():
		if event.button_index == JOY_BUTTON_A or event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			_simulate_mouse_click(virtual_pos)
			get_viewport().set_input_as_handled()

	# 3. DISCRETE UI FOCUS NAVIGATION:
	# When user navigates with D-Pad, Left Stick, Numpad, or Arrow keys,
	# deactivate virtual pointer so Godot native UI focus handles everything smoothly without double-jumping.
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down") \
	  or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		if active:
			active = false
			cursor_sprite.visible = false
		_ensure_focus_exists()

	elif event.is_action_pressed("ui_accept"):
		# If user pressed accept without a focused element, safely focus the primary button
		if not active:
			_ensure_focus_exists()

func _ensure_focus_exists() -> void:
	var cur = get_viewport().gui_get_focus_owner()
	if cur and is_instance_valid(cur) and cur.is_visible_in_tree() and cur.focus_mode != Control.FOCUS_NONE:
		return
	
	# Check topmost visible modal first
	for modal_name in ["CampaignWizardModal", "MarketplaceModal", "SettingsModal", "LevelUpModal", "TomeModal", "PauseModal", "GameOverModal", "CreditsHoloModal", "DisconnectModal"]:
		var m = get_tree().root.find_child(modal_name, true, false)
		if m and m.visible:
			var btn = _find_first_focusable(m)
			if btn:
				btn.grab_focus()
				return
	
	var root = get_tree().current_scene
	if root:
		var btn = _find_first_focusable(root)
		if btn:
			btn.grab_focus()

func _find_first_focusable(node: Node) -> Control:
	if not node: return null
	if node is Control and node.is_visible_in_tree() and node.focus_mode != Control.FOCUS_NONE:
		if (node is BaseButton and not node.disabled) or node is Slider:
			return node
	for child in node.get_children():
		var found = _find_first_focusable(child)
		if found: return found
	return null

func _simulate_mouse_click(pos: Vector2) -> void:
	var mb_down := InputEventMouseButton.new()
	mb_down.button_index = MOUSE_BUTTON_LEFT
	mb_down.pressed = true
	mb_down.position = pos
	mb_down.global_position = pos
	mb_down.device = -1
	Input.parse_input_event(mb_down)
	
	await get_tree().process_frame
	
	var mb_up := InputEventMouseButton.new()
	mb_up.button_index = MOUSE_BUTTON_LEFT
	mb_up.pressed = false
	mb_up.position = pos
	mb_up.global_position = pos
	mb_up.device = -1
	Input.parse_input_event(mb_up)
