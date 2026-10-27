extends Node

signal scheme_changed(player_index: int, scheme_name: String)
signal input_device_disconnected(device_id: int, device_name: String, player_index: int)
signal input_device_reconnected(device_id: int, device_name: String, player_index: int)

var p1_scheme: String = "keyboard" # "keyboard", "xbox", "playstation", "nintendo"
var p2_scheme: String = "keyboard"

var p1_device_id: int = 0
var p2_device_id: int = 1

# Custom Action Bindings Store
const CONFIG_FILE_PATH := "user://custom_bindings.cfg"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	setup_numpad_ui_actions()
	setup_coop_actions()
	load_bindings()
	
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	call_deferred("refresh_device_assignments")

func setup_coop_actions() -> void:
	var p2_keys = [
		{"action": "p2_move_up", "keys": [KEY_UP, KEY_KP_8]},
		{"action": "p2_move_down", "keys": [KEY_DOWN, KEY_KP_2]},
		{"action": "p2_move_left", "keys": [KEY_LEFT, KEY_KP_4]},
		{"action": "p2_move_right", "keys": [KEY_RIGHT, KEY_KP_6]},
		{"action": "p2_attack", "keys": [KEY_KP_0, KEY_SLASH, KEY_ENTER]},
		{"action": "p2_melee", "keys": [KEY_KP_1, KEY_PERIOD]},
		{"action": "p2_reload", "keys": [KEY_KP_3]},
		{"action": "p2_swap", "keys": [KEY_KP_7]},
		{"action": "p2_skill", "keys": [KEY_KP_9]},
	]
	for item in p2_keys:
		var act: String = item["action"]
		if not InputMap.has_action(act):
			InputMap.add_action(act)
		for k in item["keys"]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			ev.keycode = k
			var found := false
			for existing in InputMap.action_get_events(act):
				if existing is InputEventKey and (existing.physical_keycode == k or existing.keycode == k):
					found = true
					break
			if not found:
				InputMap.action_add_event(act, ev)

func refresh_device_assignments() -> void:
	var pads = Input.get_connected_joypads()
	var is_coop = false
	var gm = get_node_or_null("/root/GameState")
	if gm and gm.get("is_coop_mode"):
		is_coop = gm.is_coop_mode
		
	if is_coop:
		if pads.size() >= 2:
			p1_device_id = pads[0]
			p2_device_id = pads[1]
			p1_scheme = identify_scheme(p1_device_id)
			p2_scheme = identify_scheme(p2_device_id)
		elif pads.size() == 1:
			# Player 1 takes Keyboard & Mouse, Player 2 takes the Gamepad
			p1_device_id = -1
			p1_scheme = "keyboard"
			p2_device_id = pads[0]
			p2_scheme = identify_scheme(p2_device_id)
		else:
			# Zero gamepads: both use keyboard (P1 WASD, P2 Numpad/Arrows)
			p1_device_id = -1
			p2_device_id = -1
			p1_scheme = "keyboard"
			p2_scheme = "keyboard"
	else:
		if pads.size() > 0:
			p1_device_id = pads[0]
			p1_scheme = identify_scheme(p1_device_id)
		else:
			p1_device_id = -1
			p1_scheme = "keyboard"
			
	scheme_changed.emit(1, p1_scheme)
	scheme_changed.emit(2, p2_scheme)

func _on_joy_connection_changed(device: int, connected: bool) -> void:
	var jname = Input.get_joy_name(device)
	if jname == "": jname = "Gamepad %d" % device
	
	var affected_p = 0
	if device == p1_device_id and p1_scheme != "keyboard":
		affected_p = 1
	elif device == p2_device_id and p2_scheme != "keyboard":
		affected_p = 2
	elif p2_device_id == -1 and connected:
		var gm = get_node_or_null("/root/GameState")
		if gm and gm.get("is_coop_mode"):
			affected_p = 2
			
	if not connected:
		input_device_disconnected.emit(device, jname, affected_p if affected_p > 0 else 1)
	else:
		input_device_reconnected.emit(device, jname, affected_p if affected_p > 0 else 1)
		
	refresh_device_assignments()

func setup_numpad_ui_actions() -> void:
	setup_universal_ui_actions()

func setup_universal_ui_actions() -> void:
	# 1. Keyboard mappings (Arrows, Numpad, WASD, Enter, Escape, Space, Tab)
	var key_mappings = [
		{"action": "ui_up", "key": KEY_UP},
		{"action": "ui_up", "key": KEY_KP_8},
		{"action": "ui_up", "key": KEY_W},
		{"action": "ui_down", "key": KEY_DOWN},
		{"action": "ui_down", "key": KEY_KP_2},
		{"action": "ui_down", "key": KEY_S},
		{"action": "ui_left", "key": KEY_LEFT},
		{"action": "ui_left", "key": KEY_KP_4},
		{"action": "ui_left", "key": KEY_A},
		{"action": "ui_right", "key": KEY_RIGHT},
		{"action": "ui_right", "key": KEY_KP_6},
		{"action": "ui_right", "key": KEY_D},
		{"action": "ui_accept", "key": KEY_ENTER},
		{"action": "ui_accept", "key": KEY_KP_ENTER},
		{"action": "ui_accept", "key": KEY_SPACE},
		{"action": "ui_accept", "key": KEY_KP_5},
		{"action": "ui_cancel", "key": KEY_ESCAPE},
		{"action": "ui_cancel", "key": KEY_KP_0},
		{"action": "ui_cancel", "key": KEY_KP_PERIOD},
		{"action": "ui_cancel", "key": KEY_BACKSPACE},
		{"action": "ui_focus_next", "key": KEY_TAB},
	]
	for m in key_mappings:
		_ensure_action_key(m["action"], m["key"])

	# 2. Gamepad Button mappings (Xbox A/B/X/Y, D-Pad, Start, LB, RB)
	var joy_button_mappings = [
		{"action": "ui_accept", "btn": JOY_BUTTON_A},
		{"action": "ui_accept", "btn": JOY_BUTTON_START},
		{"action": "ui_cancel", "btn": JOY_BUTTON_B},
		{"action": "ui_select", "btn": JOY_BUTTON_Y},
		{"action": "ui_select", "btn": JOY_BUTTON_X},
		{"action": "ui_up", "btn": JOY_BUTTON_DPAD_UP},
		{"action": "ui_down", "btn": JOY_BUTTON_DPAD_DOWN},
		{"action": "ui_left", "btn": JOY_BUTTON_DPAD_LEFT},
		{"action": "ui_right", "btn": JOY_BUTTON_DPAD_RIGHT},
		{"action": "ui_focus_next", "btn": JOY_BUTTON_RIGHT_SHOULDER},
		{"action": "ui_focus_prev", "btn": JOY_BUTTON_LEFT_SHOULDER},
	]
	for m in joy_button_mappings:
		_ensure_action_joybutton(m["action"], m["btn"])

	# 3. Gamepad Stick Motion mappings (Left Analog Stick for UI navigation)
	var joy_motion_mappings = [
		{"action": "ui_up", "axis": JOY_AXIS_LEFT_Y, "val": -1.0},
		{"action": "ui_down", "axis": JOY_AXIS_LEFT_Y, "val": 1.0},
		{"action": "ui_left", "axis": JOY_AXIS_LEFT_X, "val": -1.0},
		{"action": "ui_right", "axis": JOY_AXIS_LEFT_X, "val": 1.0},
	]
	for m in joy_motion_mappings:
		_ensure_action_joymotion(m["action"], m["axis"], m["val"])

func _ensure_action_key(action: String, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for existing in InputMap.action_get_events(action):
		if existing is InputEventKey and (existing.physical_keycode == keycode or existing.keycode == keycode):
			return
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	ev.keycode = keycode
	InputMap.action_add_event(action, ev)

func _ensure_action_joybutton(action: String, button: JoyButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for existing in InputMap.action_get_events(action):
		if existing is InputEventJoypadButton and existing.button_index == button:
			return
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)

func _ensure_action_joymotion(action: String, axis: JoyAxis, axis_value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for existing in InputMap.action_get_events(action):
		if existing is InputEventJoypadMotion and existing.axis == axis and signf(existing.axis_value) == signf(axis_value):
			return
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = axis_value
	InputMap.action_add_event(action, ev)

func identify_scheme(dev_id: int) -> String:
	var jname = Input.get_joy_name(dev_id).to_lower()
	if "sony" in jname or "ps4" in jname or "ps5" in jname or "dualshock" in jname or "dualsense" in jname or "playstation" in jname:
		return "playstation"
	elif "nintendo" in jname or "switch" in jname or "joy-con" in jname or "pro con" in jname:
		return "nintendo"
	else:
		return "xbox" # Standard default for XInput / Xbox / generic controllers

func _input(event: InputEvent) -> void:
	var gm = get_node_or_null("/root/GameState")
	var is_coop = gm and gm.get("is_coop_mode")
	
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.35):
		var dev = event.device
		var detected = identify_scheme(dev)
		if is_coop:
			if dev == p2_device_id:
				if p2_scheme != detected:
					p2_scheme = detected
					scheme_changed.emit(2, p2_scheme)
			elif dev == p1_device_id:
				if p1_scheme != detected:
					p1_scheme = detected
					scheme_changed.emit(1, p1_scheme)
		else:
			p1_device_id = dev
			if p1_scheme != detected:
				p1_scheme = detected
				scheme_changed.emit(1, p1_scheme)
				
	elif event is InputEventKey or event is InputEventMouseButton:
		if is_coop:
			if event is InputEventKey and (event.physical_keycode in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_KP_0, KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_ENTER, KEY_SLASH, KEY_PERIOD]):
				if p2_scheme != "keyboard":
					p2_scheme = "keyboard"
					scheme_changed.emit(2, "keyboard")
			else:
				if p1_scheme != "keyboard":
					p1_scheme = "keyboard"
					scheme_changed.emit(1, "keyboard")
		else:
			if p1_scheme != "keyboard":
				p1_scheme = "keyboard"
				scheme_changed.emit(1, "keyboard")

# ========================================================
# ACTION REBINDING UTILITIES
# ========================================================

func get_key_display_name(action: String) -> String:
	if not InputMap.has_action(action): return "---"
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			return OS.get_keycode_string(ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode)
		elif ev is InputEventMouseButton:
			match ev.button_index:
				MOUSE_BUTTON_LEFT: return "KLIK KIRI (LMB)"
				MOUSE_BUTTON_RIGHT: return "KLIK KANAN (RMB)"
				MOUSE_BUTTON_MIDDLE: return "KLIK TENGAH (MMB)"
				_: return "MOUSE BTN %d" % ev.button_index
	return "---"

func get_joybutton_display_name(action: String) -> String:
	if not InputMap.has_action(action): return "---"
	for ev in InputMap.action_get_events(action):
		if ev is InputEventJoypadButton:
			match ev.button_index:
				JOY_BUTTON_A: return "[A / ×]"
				JOY_BUTTON_B: return "[B / ○]"
				JOY_BUTTON_X: return "[X / □]"
				JOY_BUTTON_Y: return "[Y / △]"
				JOY_BUTTON_LEFT_SHOULDER: return "[LB / L1]"
				JOY_BUTTON_RIGHT_SHOULDER: return "[RB / R1]"
				JOY_BUTTON_START: return "[START / MENU]"
				JOY_BUTTON_BACK: return "[BACK / SELECT]"
				_: return "BTN %d" % ev.button_index
		elif ev is InputEventJoypadMotion:
			if ev.axis == JOY_AXIS_TRIGGER_RIGHT: return "[RT / R2]"
			elif ev.axis == JOY_AXIS_TRIGGER_LEFT: return "[LT / L2]"
	return "---"

func rebind_key(action: String, new_event: InputEvent) -> void:
	if not InputMap.has_action(action): return
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey or ev is InputEventMouseButton:
			InputMap.action_erase_event(action, ev)
	InputMap.action_add_event(action, new_event)
	save_bindings()

func rebind_joybutton(action: String, new_event: InputEvent) -> void:
	if not InputMap.has_action(action): return
	for ev in InputMap.action_get_events(action):
		if ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
			InputMap.action_erase_event(action, ev)
	InputMap.action_add_event(action, new_event)
	save_bindings()

func reset_bindings_to_defaults() -> void:
	var dir = DirAccess.open("user://")
	if dir and FileAccess.file_exists(CONFIG_FILE_PATH):
		dir.remove(CONFIG_FILE_PATH)
	InputMap.load_from_project_settings()
	setup_numpad_ui_actions()

func save_bindings() -> void:
	var cfg = ConfigFile.new()
	var actions = ["move_up", "move_down", "move_left", "move_right", "primary_attack", "melee_attack", "reload", "swap_weapon", "skill_action", "open_pause"]
	for act in actions:
		if not InputMap.has_action(act): continue
		for ev in InputMap.action_get_events(act):
			if ev is InputEventKey:
				cfg.set_value(act, "key_physical", ev.physical_keycode)
			elif ev is InputEventMouseButton:
				cfg.set_value(act, "mouse_btn", ev.button_index)
			elif ev is InputEventJoypadButton:
				cfg.set_value(act, "joy_btn", ev.button_index)
	cfg.save(CONFIG_FILE_PATH)

func load_bindings() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(CONFIG_FILE_PATH) != OK: return
	for act in cfg.get_sections():
		if not InputMap.has_action(act): continue
		if cfg.has_section_key(act, "key_physical"):
			var pk = cfg.get_value(act, "key_physical")
			var ev = InputEventKey.new()
			ev.physical_keycode = pk
			ev.keycode = pk
			rebind_key(act, ev)
		elif cfg.has_section_key(act, "mouse_btn"):
			var mb = cfg.get_value(act, "mouse_btn")
			var ev = InputEventMouseButton.new()
			ev.button_index = mb
			rebind_key(act, ev)
		if cfg.has_section_key(act, "joy_btn"):
			var jb = cfg.get_value(act, "joy_btn")
			var ev = InputEventJoypadButton.new()
			ev.button_index = jb
			rebind_joybutton(act, ev)

# ========================================================
# IMMERSIVE DUAL-MOTOR HAPTIC VIBRATION ENGINE
# Left Motor (Strong) = Low-frequency rumble, heavy impact, explosions, bass recoil
# Right Motor (Weak) = High-frequency buzz, sharp clicks, laser hum, card ticks
# ========================================================

func vibrate(weak: float, strong: float, duration: float, player_idx: int = 1) -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm and not sm.get("vib_master"): return
	var str_mult: float = sm.get("vib_strength") if (sm and sm.get("vib_strength")) else 1.0
	
	var dev_id = p1_device_id if player_idx == 1 else p2_device_id
	var pads = Input.get_connected_joypads()
	if not pads.has(dev_id): return
	Input.start_joy_vibration(dev_id, clampf(weak * str_mult, 0.0, 1.0), clampf(strong * str_mult, 0.0, 1.0), duration)

func vibrate_shot(weapon: String, player_idx: int = 1) -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm and not sm.get("vib_shooting"): return
	match weapon:
		"shotgun":
			# Heavy dual-motor buckshot kick!
			vibrate(0.60, 0.90, 0.22, player_idx)
		"railgun":
			# High-voltage laser beam thunderclap
			vibrate(0.85, 0.70, 0.26, player_idx)
		"smg":
			# Rapid snappy right-motor buzz per bullet
			vibrate(0.35, 0.15, 0.06, player_idx)
		_:
			# Revolver: sharp crisp magnum pop
			vibrate(0.50, 0.40, 0.12, player_idx)

func vibrate_melee(hero: String, player_idx: int = 1) -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm and not sm.get("vib_melee"): return
	match hero:
		"brutus":
			# Earth-shattering sledgehammer bash
			vibrate(0.40, 1.0, 0.35, player_idx)
		"kael":
			# Solid pipe wrench clank
			vibrate(0.45, 0.55, 0.16, player_idx)
		"vex":
			# Sharp kunai phase slice
			vibrate(0.70, 0.20, 0.10, player_idx)
		"nyx":
			# Resonant plasma scythe hum
			vibrate(0.75, 0.45, 0.20, player_idx)

func vibrate_damage(severity: float = 1.0, player_idx: int = 1) -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm and not sm.get("vib_damage"): return
	vibrate(0.75 * severity, 0.95 * severity, 0.25, player_idx)

func vibrate_reload(phase: String, player_idx: int = 1) -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm and not sm.get("vib_reload"): return
	if phase == "start":
		vibrate(0.30, 0.10, 0.08, player_idx)
	else:
		vibrate(0.50, 0.35, 0.12, player_idx)

func vibrate_skill(hero: String, player_idx: int = 1) -> void:
	match hero:
		"brutus":
			vibrate(0.50, 1.0, 0.50, player_idx)
		"nyx":
			vibrate(0.90, 0.70, 0.40, player_idx)
		"kael":
			vibrate(0.55, 0.60, 0.22, player_idx)
		"vex":
			vibrate(0.85, 0.25, 0.18, player_idx)

func vibrate_ui_card_deal() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm and not sm.get("vib_ui"): return
	vibrate(0.35, 0.08, 0.06, 1)

func vibrate_ui_card_select() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm and not sm.get("vib_ui"): return
	vibrate(0.28, 0.0, 0.04, 1)

func vibrate_ui_card_confirm(is_legendary: bool = false) -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm and not sm.get("vib_ui"): return
	if is_legendary:
		vibrate(0.90, 0.85, 0.50, 1)
	else:
		vibrate(0.60, 0.45, 0.22, 1)

func vibrate_tome_open() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm and not sm.get("vib_ui"): return
	vibrate(0.80, 0.65, 0.55, 1)

func vibrate_explosion(intensity: float = 1.0) -> void:
	vibrate(0.80 * intensity, 1.0 * intensity, 0.40, 1)

func vibrate_boss_roar() -> void:
	vibrate(0.65, 0.90, 0.75, 1)

func get_skill_button_icon(player_idx: int = 1) -> Texture2D:
	var scheme = p1_scheme if player_idx == 1 else p2_scheme
	match scheme:
		"playstation":
			return load("res://assets/ui/prompts/ps_l1.png")
		"nintendo":
			return load("res://assets/ui/prompts/nintendo_l.png")
		"xbox":
			return load("res://assets/ui/prompts/xbox_lb.png")
		_:
			return load("res://assets/ui/prompts/kbm_e.png")

func get_controls_summary(player_idx: int = 1) -> String:
	var scheme = p1_scheme if player_idx == 1 else p2_scheme
	match scheme:
		"playstation":
			return "[LS] JALAN | [R2] TEMBAK | [L2] MELEE | [L1/R1] SKILL | [▢] RELOAD | [△] SWAP"
		"nintendo":
			return "[L-STICK] JALAN | [ZR] TEMBAK | [ZL] MELEE | [L/R] SKILL | [Y] RELOAD | [X] SWAP"
		"xbox":
			return "[LS] JALAN | [RT] TEMBAK | [LT] MELEE | [LB/RB] SKILL | [X] RELOAD | [Y] SWAP"
		_:
			if player_idx == 1:
				return "[WASD] JALAN | [LMB] TEMBAK | [2] MELEE | [SPACE/E] SKILL | [R] RELOAD | [Q] SWAP"
			else:
				return "[NUMPAD] JALAN | [KP_0] TEMBAK | [KP_1] MELEE | [KP_9] SKILL | [KP_3] RELOAD | [KP_7] SWAP"
