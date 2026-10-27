extends Node2D

@export var p1_node: CharacterBody2D
@export var p2_node: CharacterBody2D

var is_split: bool = false
var split_threshold: float = 480.0
var merge_threshold: float = 380.0

# Unified mode camera (single full screen when players are close)
var unified_cam: Camera2D = null

# Split screen layer & components
var split_layer: CanvasLayer = null
var split_container: HBoxContainer = null
var svc1: SubViewportContainer = null
var svp1: SubViewport = null
var cam_p1: Camera2D = null
var divider: ColorRect = null
var svc2: SubViewportContainer = null
var svp2: SubViewport = null
var cam_p2: Camera2D = null

# Screen shake parameters
var shake_intensity: float = 0.0
var shake_timer: float = 0.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("coop_camera")
	rng.randomize()
	
	_find_players()
	_setup_cameras()
	
	if has_node("/root/GameState"):
		var gs = get_node("/root/GameState")
		if gs.has_signal("screen_shake_requested"):
			gs.screen_shake_requested.connect(_on_screen_shake_requested)

func _find_players() -> void:
	if is_instance_valid(p1_node) and is_instance_valid(p2_node):
		return
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if not (p is CharacterBody2D):
			continue
		var idx: int = p.get("player_index") if "player_index" in p else 1
		if idx == 1:
			p1_node = p
		elif idx == 2:
			p2_node = p

func _setup_cameras() -> void:
	# 1. Disable built-in cameras on Player 1 and Player 2
	if is_instance_valid(p1_node):
		var p1_cam = p1_node.get_node_or_null("Camera2D") as Camera2D
		if p1_cam:
			p1_cam.enabled = false
	if is_instance_valid(p2_node):
		var p2_cam = p2_node.get_node_or_null("Camera2D") as Camera2D
		if p2_cam:
			p2_cam.enabled = false

	# 2. Setup Unified Camera in the main world
	unified_cam = Camera2D.new()
	unified_cam.name = "UnifiedCoopCamera"
	unified_cam.enabled = true
	unified_cam.position_smoothing_enabled = false
	add_child(unified_cam)
	unified_cam.make_current()

	# 3. Setup Split Screen CanvasLayer (layer = 1, below HUD at layer = 2)
	split_layer = CanvasLayer.new()
	split_layer.name = "CoopSplitLayer"
	split_layer.layer = 1
	split_layer.visible = false
	add_child(split_layer)

	split_container = HBoxContainer.new()
	split_container.name = "SplitContainer"
	split_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	split_container.anchor_right = 1.0
	split_container.anchor_bottom = 1.0
	split_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	split_container.grow_vertical = Control.GROW_DIRECTION_BOTH
	split_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	split_container.add_theme_constant_override("separation", 0)
	split_layer.add_child(split_container)

	var main_world_2d: World2D = get_viewport().find_world_2d()

	# Left SubViewport (Player 1)
	svc1 = SubViewportContainer.new()
	svc1.name = "SubViewportContainerP1"
	svc1.stretch = true
	svc1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	svc1.size_flags_vertical = Control.SIZE_EXPAND_FILL
	svc1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	svp1 = SubViewport.new()
	svp1.name = "SubViewportP1"
	svp1.handle_input_locally = false
	svp1.world_2d = main_world_2d
	svp1.render_target_update_mode = SubViewport.UPDATE_WHEN_PARENT_VISIBLE
	
	cam_p1 = Camera2D.new()
	cam_p1.name = "CameraP1"
	cam_p1.enabled = true
	cam_p1.zoom = Vector2(2.0, 2.0)
	svp1.add_child(cam_p1)
	
	svc1.add_child(svp1)
	split_container.add_child(svc1)

	# Divider line (3px glowing cyber cyan)
	divider = ColorRect.new()
	divider.name = "SplitDivider"
	divider.custom_minimum_size = Vector2(3.0, 0.0)
	divider.color = Color(0.0, 0.94, 1.0, 0.95)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	split_container.add_child(divider)

	# Right SubViewport (Player 2)
	svc2 = SubViewportContainer.new()
	svc2.name = "SubViewportContainerP2"
	svc2.stretch = true
	svc2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	svc2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	svc2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	svp2 = SubViewport.new()
	svp2.name = "SubViewportP2"
	svp2.handle_input_locally = false
	svp2.world_2d = main_world_2d
	svp2.render_target_update_mode = SubViewport.UPDATE_WHEN_PARENT_VISIBLE
	
	cam_p2 = Camera2D.new()
	cam_p2.name = "CameraP2"
	cam_p2.enabled = true
	cam_p2.zoom = Vector2(2.0, 2.0)
	svp2.add_child(cam_p2)
	
	svc2.add_child(svp2)
	split_container.add_child(svc2)

	# Initial positioning
	if is_instance_valid(p1_node) and is_instance_valid(p2_node):
		var mid: Vector2 = (p1_node.global_position + p2_node.global_position) * 0.5
		unified_cam.global_position = mid
		cam_p1.global_position = p1_node.global_position
		cam_p2.global_position = p2_node.global_position

func _on_screen_shake_requested(intensity: float, duration: float) -> void:
	var mult: float = 1.0
	if has_node("/root/SaveManager"):
		mult = get_node("/root/SaveManager").screen_shake_strength
	if mult <= 0.01:
		return
	shake_intensity = intensity * mult
	shake_timer = duration

func _process(delta: float) -> void:
	if not is_instance_valid(p1_node) or not is_instance_valid(p2_node):
		_find_players()
		if not is_instance_valid(p1_node) or not is_instance_valid(p2_node):
			# Single-player fallback if only one player is valid
			if is_instance_valid(p1_node) and is_instance_valid(unified_cam):
				unified_cam.global_position = unified_cam.global_position.lerp(p1_node.global_position, delta * 8.0)
				unified_cam.zoom = unified_cam.zoom.lerp(Vector2(2.0, 2.0), delta * 4.0)
				if is_instance_valid(split_layer):
					split_layer.visible = false
				is_split = false
			return

	var p1_pos: Vector2 = p1_node.global_position
	var p2_pos: Vector2 = p2_node.global_position
	var dist: float = p1_pos.distance_to(p2_pos)

	# State Transition with Hysteresis
	if not is_split:
		if dist >= split_threshold:
			_set_split_mode(true)
	else:
		if dist <= merge_threshold:
			_set_split_mode(false)

	# Calculate screen shake
	var shake_offset: Vector2 = Vector2.ZERO
	if shake_timer > 0.0:
		shake_timer -= delta
		shake_offset = Vector2(
			rng.randf_range(-shake_intensity, shake_intensity),
			rng.randf_range(-shake_intensity, shake_intensity)
		)

	# Update Cameras based on active state
	if is_split:
		# Player 1 Camera (Left Viewport) - Focuses squarely on Player 1
		if is_instance_valid(cam_p1):
			cam_p1.global_position = cam_p1.global_position.lerp(p1_pos, delta * 9.0)
			cam_p1.zoom = Vector2(2.0, 2.0)
			cam_p1.offset = shake_offset
		
		# Player 2 Camera (Right Viewport) - Focuses squarely on Player 2
		if is_instance_valid(cam_p2):
			cam_p2.global_position = cam_p2.global_position.lerp(p2_pos, delta * 9.0)
			cam_p2.zoom = Vector2(2.0, 2.0)
			cam_p2.offset = shake_offset
	else:
		# Unified Camera - Follows midpoint between both players with adaptive zoom
		if is_instance_valid(unified_cam):
			var midpoint: Vector2 = (p1_pos + p2_pos) * 0.5
			unified_cam.global_position = unified_cam.global_position.lerp(midpoint, delta * 7.0)
			
			var zoom_ratio: float = clampf(dist / split_threshold, 0.0, 1.0)
			var target_zoom_val: float = lerpf(2.2, 1.7, zoom_ratio)
			unified_cam.zoom = unified_cam.zoom.lerp(Vector2(target_zoom_val, target_zoom_val), delta * 4.0)
			unified_cam.offset = shake_offset

func _set_split_mode(enable: bool) -> void:
	if is_split == enable:
		return
	is_split = enable

	if is_split:
		# Enter Split Screen
		if is_instance_valid(split_layer):
			split_layer.visible = true
		if is_instance_valid(cam_p1) and is_instance_valid(p1_node):
			cam_p1.global_position = p1_node.global_position
		if is_instance_valid(cam_p2) and is_instance_valid(p2_node):
			cam_p2.global_position = p2_node.global_position
	else:
		# Return to Unified Camera
		if is_instance_valid(split_layer):
			split_layer.visible = false
		if is_instance_valid(unified_cam) and is_instance_valid(p1_node) and is_instance_valid(p2_node):
			unified_cam.global_position = (p1_node.global_position + p2_node.global_position) * 0.5

func get_p1_mouse_world_pos() -> Vector2:
	if is_split and is_instance_valid(svp1):
		var screen_mouse: Vector2 = get_viewport().get_mouse_position()
		return svp1.get_canvas_transform().affine_inverse() * screen_mouse
	return get_global_mouse_position()

func _exit_tree() -> void:
	# Restore Player 1's built-in camera when CoopCameraController is removed
	if is_instance_valid(p1_node):
		var p1_cam = p1_node.get_node_or_null("Camera2D") as Camera2D
		if is_instance_valid(p1_cam):
			p1_cam.enabled = true
			p1_cam.make_current()

