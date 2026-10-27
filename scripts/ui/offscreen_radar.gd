extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	if not visible: return
	queue_redraw()

func _draw() -> void:
	var viewport = get_viewport()
	if not viewport: return
	var vp_size := viewport.get_visible_rect().size
	if vp_size.x <= 0 or vp_size.y <= 0: return

	var cam_ctrl = get_tree().get_first_node_in_group("coop_camera")
	var is_split: bool = false
	if cam_ctrl and is_instance_valid(cam_ctrl) and cam_ctrl.get("is_split"):
		if is_instance_valid(cam_ctrl.get("p1_node")) and is_instance_valid(cam_ctrl.get("p2_node")):
			is_split = true

	if is_split:
		# SPLIT-SCREEN COOP: Left screen = P1, Right screen = P2
		var half_w := vp_size.x * 0.5
		var rect_p1 := Rect2(0.0, 0.0, half_w, vp_size.y)
		var rect_p2 := Rect2(half_w, 0.0, half_w, vp_size.y)
		
		var p1: Node2D = cam_ctrl.get("p1_node")
		var p2: Node2D = cam_ctrl.get("p2_node")
		
		var cam_p1_pos: Vector2 = p1.global_position
		var cam_p1_zoom: Vector2 = Vector2(2.0, 2.0)
		if is_instance_valid(cam_ctrl.get("cam_p1")):
			cam_p1_zoom = cam_ctrl.cam_p1.zoom
			
		var cam_p2_pos: Vector2 = p2.global_position
		var cam_p2_zoom: Vector2 = Vector2(2.0, 2.0)
		if is_instance_valid(cam_ctrl.get("cam_p2")):
			cam_p2_zoom = cam_ctrl.cam_p2.zoom

		# P1 view targets (P1 sees P2, Reactor, Bosses)
		var targets_p1: Array[Dictionary] = []
		if is_instance_valid(p2):
			var is_downed: bool = bool(p2.get("is_downed"))
			targets_p1.append({
				"node": p2,
				"label": "! SOS P2 DOWN !" if is_downed else "REKAN P2",
				"col": Color(1.0, 0.25, 0.25) if is_downed else Color(0.0, 0.95, 1.0),
				"emergency": is_downed
			})
		_append_common_targets(targets_p1)
		_draw_view_radar(rect_p1, cam_p1_pos, cam_p1_zoom, targets_p1)

		# P2 view targets (P2 sees P1, Reactor, Bosses)
		var targets_p2: Array[Dictionary] = []
		if is_instance_valid(p1):
			var is_downed: bool = bool(p1.get("is_downed"))
			targets_p2.append({
				"node": p1,
				"label": "! SOS P1 DOWN !" if is_downed else "REKAN P1",
				"col": Color(1.0, 0.25, 0.25) if is_downed else Color(0.2, 1.0, 0.5),
				"emergency": is_downed
			})
		_append_common_targets(targets_p2)
		_draw_view_radar(rect_p2, cam_p2_pos, cam_p2_zoom, targets_p2)

	else:
		# UNIFIED SCREEN OR SINGLE PLAYER
		var cam: Camera2D = null
		if cam_ctrl and is_instance_valid(cam_ctrl.get("unified_cam")):
			cam = cam_ctrl.unified_cam
		else:
			cam = viewport.get_camera_2d()
			
		if not cam: return
		
		var cam_center: Vector2 = cam.get_screen_center_position()
		var cam_zoom: Vector2 = cam.zoom
		var full_rect := Rect2(Vector2.ZERO, vp_size)
		
		var targets: Array[Dictionary] = []
		var players = get_tree().get_nodes_in_group("player")
		if players.size() >= 2:
			var p1 = players[0]
			var p2 = players[1]
			if is_instance_valid(p1) and is_instance_valid(p2):
				var p1_downed: bool = bool(p1.get("is_downed"))
				var p2_downed: bool = bool(p2.get("is_downed"))
				targets.append({
					"node": p1,
					"label": "! SOS P1 DOWN !" if p1_downed else "REKAN P1",
					"col": Color(1.0, 0.25, 0.25) if p1_downed else Color(0.2, 1.0, 0.5),
					"emergency": p1_downed
				})
				targets.append({
					"node": p2,
					"label": "! SOS P2 DOWN !" if p2_downed else "REKAN P2",
					"col": Color(1.0, 0.25, 0.25) if p2_downed else Color(0.0, 0.95, 1.0),
					"emergency": p2_downed
				})
				
		_append_common_targets(targets)
		_draw_view_radar(full_rect, cam_center, cam_zoom, targets)

func _append_common_targets(target_list: Array[Dictionary]) -> void:
	if not is_inside_tree(): return
	var tree = get_tree()
	if not tree: return
	
	# Defense Tower / Reaktor Inti
	for tower in tree.get_nodes_in_group("defense_tower"):
		if is_instance_valid(tower):
			var t_hp: int = int(tower.get("current_hp")) if "current_hp" in tower else 1500
			var t_max: int = int(tower.get("max_hp")) if "max_hp" in tower else 1500
			var pct: int = int(clampf(float(t_hp) / float(maxi(1, t_max)) * 100.0, 0.0, 100.0))
			var is_crit: bool = (pct <= 35)
			var lbl := ("! REAKTOR KRITIS (%d%%) !" % pct) if is_crit else ("REAKTOR (%d%%)" % pct)
			var col := Color(1.0, 0.25, 0.25) if is_crit else Color(1.0, 0.84, 0.15)
			target_list.append({
				"node": tower,
				"label": lbl,
				"col": col,
				"emergency": is_crit
			})

	# Sector Boss
	for b in tree.get_nodes_in_group("boss"):
		if is_instance_valid(b):
			target_list.append({"node": b, "label": "SECTOR BOSS", "col": Color(1.0, 0.25, 0.25), "emergency": true})
			
	# Mini-Boss
	for mb in tree.get_nodes_in_group("mini_boss"):
		if is_instance_valid(mb):
			target_list.append({"node": mb, "label": "MINI-BOSS", "col": Color(1.0, 0.85, 0.12), "emergency": false})
			
	# Cyber Tome
	for t in tree.get_nodes_in_group("tome_pickup"):
		if is_instance_valid(t):
			target_list.append({"node": t, "label": "CYBER TOME", "col": Color(0.85, 0.35, 1.0), "emergency": false})

func _draw_view_radar(rect: Rect2, cam_center: Vector2, cam_zoom: Vector2, targets: Array[Dictionary]) -> void:
	var margin := 45.0
	var min_bound := rect.position + Vector2(margin, margin)
	var max_bound := rect.position + rect.size - Vector2(margin, margin)
	var rect_center := rect.position + rect.size * 0.5
	var half_vp := (rect.size * 0.5) / cam_zoom
	var font: Font = ThemeDB.fallback_font

	for tgt in targets:
		var target: Node2D = tgt.get("node")
		if not is_instance_valid(target): continue
		
		var diff: Vector2 = target.global_position - cam_center
		var dist: float = diff.length()
		
		# Check if off-screen relative to this view rect
		if absf(diff.x) > (half_vp.x - 30.0) or absf(diff.y) > (half_vp.y - 30.0):
			var dir: Vector2 = diff.normalized()
			
			# Precision ray-box border clamping
			var avail_x: float = maxf(1.0, rect.size.x * 0.5 - margin)
			var avail_y: float = maxf(1.0, rect.size.y * 0.5 - margin)
			var scale_x: float = absf(avail_x / dir.x) if absf(dir.x) > 0.0001 else 999999.0
			var scale_y: float = absf(avail_y / dir.y) if absf(dir.y) > 0.0001 else 999999.0
			var t: float = minf(scale_x, scale_y)
			var edge_pos: Vector2 = rect_center + dir * t
			edge_pos.x = clampf(edge_pos.x, min_bound.x, max_bound.x)
			edge_pos.y = clampf(edge_pos.y, min_bound.y, max_bound.y)
			
			var col: Color = tgt.get("col", Color.WHITE)
			var is_emergency: bool = tgt.get("emergency", false)
			if is_emergency:
				var pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.009)
				col = col.lerp(Color(1.0, 0.2, 0.2), pulse)
				
			var angle: float = dir.angle()
			
			# Draw Chevron Arrow pointing in target direction
			var p_tip: Vector2 = edge_pos + Vector2.RIGHT.rotated(angle) * 16.0
			var p_left: Vector2 = edge_pos + Vector2.RIGHT.rotated(angle + 2.4) * 13.0
			var p_right: Vector2 = edge_pos + Vector2.RIGHT.rotated(angle - 2.4) * 13.0
			var p_notch: Vector2 = edge_pos + Vector2.RIGHT.rotated(angle) * 3.0
			
			# Shadow / Glow
			draw_colored_polygon(PackedVector2Array([
				p_tip + Vector2.RIGHT.rotated(angle) * 3.0,
				p_left + Vector2.RIGHT.rotated(angle + 2.4) * 3.0,
				p_notch - Vector2.RIGHT.rotated(angle) * 2.0,
				p_right + Vector2.RIGHT.rotated(angle - 2.4) * 3.0
			]), Color(0.0, 0.0, 0.0, 0.75))
			
			# Arrow body
			draw_colored_polygon(PackedVector2Array([p_tip, p_left, p_notch, p_right]), col)
			
			# Distance in meters (50px = 1 meter)
			var dist_m: int = int(dist / 50.0)
			var label_str: String = tgt.get("label", "")
			var full_text: String = "%s [%dm]" % [label_str, dist_m]
			
			if font:
				var str_w: float = font.get_string_size(full_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 11).x
				var box_pos: Vector2 = edge_pos + Vector2(-str_w * 0.5 - 6.0, 18.0)
				if edge_pos.y > max_bound.y - 25.0:
					box_pos.y = edge_pos.y - 32.0
				box_pos.x = clampf(box_pos.x, rect.position.x + 6.0, rect.position.x + rect.size.x - str_w - 18.0)
				
				var bg_rect: Rect2 = Rect2(box_pos.x, box_pos.y, str_w + 12.0, 18.0)
				draw_rect(bg_rect, Color(0.03, 0.07, 0.12, 0.88), true)
				draw_rect(bg_rect, col * 0.85, false, 1.2)
				draw_string(font, Vector2(box_pos.x + 6.0, box_pos.y + 13.0), full_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
