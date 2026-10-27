extends Node2D

@export var player_node: CharacterBody2D

var anim_time: float = 0.0

func _process(delta: float) -> void:
	if not player_node:
		visible = false
		return
		
	if player_node.is_reloading:
		visible = true
		anim_time += delta
		queue_redraw()
	else:
		visible = false
		anim_time = 0.0

func _draw() -> void:
	if not player_node or not player_node.is_reloading: return
	
	var pct: float = clampf(player_node.reload_timer / GameState.reload_duration, 0.0, 1.0)
	var wep: String = GameState.primary_weapon
	if player_node and player_node.get("player_index") == 2 and GameState.is_coop_mode:
		wep = GameState.coop_p2_weapon if GameState.coop_p2_weapon != "" else GameState.primary_weapon
	
	# 1. Clean Reload Visual: Revolver rotating cylinder / weapon mechanism only (no redundant bottom bars)
	match wep:
		"revolver":
			draw_revolver_cylinder(Vector2(0, 0), pct)
		"shotgun":
			draw_shotgun_shells(Vector2(0, 0), pct)
		"smg":
			draw_smg_magazine(Vector2(0, 0), pct)
		"railgun":
			draw_railgun_capacitor(Vector2(0, 0), pct)
		_:
			draw_revolver_cylinder(Vector2(0, 0), pct)

func draw_revolver_cylinder(pos: Vector2, pct: float) -> void:
	# Revolving cylinder icon (perlambat animasi putaran silinder)
	var rot := anim_time * 3.5
	var r := 9.0
	draw_circle(pos, r, Color(0.08, 0.12, 0.18, 0.95))
	draw_arc(pos, r, 0, TAU, 16, Color(1.0, 0.85, 0.12, 1.0), 1.5)
	draw_circle(pos, 2.5, Color(0.04, 0.06, 0.09, 1.0))
	
	var filled_chambers := int(pct * 6.0)
	for i in range(6):
		var ang := rot + (TAU / 6.0) * i
		var ch_pos := pos + Vector2(cos(ang), sin(ang)) * 5.2
		if i < filled_chambers:
			draw_circle(ch_pos, 1.8, Color(1.0, 0.95, 0.15, 1.0)) # Loaded brass
		else:
			draw_circle(ch_pos, 1.8, Color(0.2, 0.25, 0.35, 1.0)) # Empty chamber

func draw_shotgun_shells(pos: Vector2, pct: float) -> void:
	# 4 Shotgun shells loading in sequence with pump action slide
	var total_shells := 4
	var loaded := int(pct * 4.0)
	var shell_w := 6.0
	var start_x := pos.x - 14.0
	
	# Pump breach frame
	draw_rect(Rect2(pos.x - 17.0, pos.y - 6.0, 34.0, 12.0), Color(0.08, 0.10, 0.15, 0.9), true)
	draw_rect(Rect2(pos.x - 17.0, pos.y - 6.0, 34.0, 12.0), Color(0.98, 0.8, 0.08, 0.8), false, 1.0)
	
	for i in range(total_shells):
		var sx := start_x + (i * 8.0)
		var sy := pos.y - 4.5
		if i < loaded:
			# Red hull + brass gold cap
			draw_rect(Rect2(sx, sy, shell_w, 6.0), Color(0.9, 0.2, 0.2, 1.0))
			draw_rect(Rect2(sx, sy + 6.0, shell_w, 3.0), Color(1.0, 0.85, 0.12, 1.0))
		else:
			draw_rect(Rect2(sx, sy, shell_w, 9.0), Color(0.25, 0.3, 0.4, 0.6), false, 1.0)

func draw_smg_magazine(pos: Vector2, pct: float) -> void:
	# Curved tactical mag inserting upwards
	var mag_y_offset := (1.0 - pct) * 8.0
	var mag_w := 9.0
	var mag_h := 14.0
	var mag_rect := Rect2(pos.x - mag_w * 0.5, pos.y - mag_h * 0.5 + mag_y_offset, mag_w, mag_h)
	
	# Mag casing
	draw_rect(mag_rect, Color(0.12, 0.16, 0.22, 0.95))
	draw_rect(mag_rect, Color(0.13, 0.95, 0.4, 0.9), false, 1.0)
	
	# LED capacity bars
	var bars := 4
	var active_bars := int(pct * 4.0)
	for i in range(bars):
		var by := mag_rect.position.y + mag_h - 3.5 - (i * 3.0)
		var b_col := Color(0.13, 0.95, 0.4, 1.0) if i < active_bars else Color(0.2, 0.3, 0.25, 0.5)
		draw_line(Vector2(mag_rect.position.x + 2.0, by), Vector2(mag_rect.position.x + mag_w - 2.0, by), b_col, 1.5)

func draw_railgun_capacitor(pos: Vector2, pct: float) -> void:
	# Dual plasma electrodes with high-voltage electric arc bridging
	var coil_w := 26.0
	var coil_h := 10.0
	var c_rect := Rect2(pos.x - coil_w * 0.5, pos.y - coil_h * 0.5, coil_w, coil_h)
	
	draw_rect(c_rect, Color(0.06, 0.09, 0.16, 0.9))
	draw_rect(c_rect, Color(0, 0.94, 1.0, 0.9), false, 1.0)
	
	# Capacitor core nodes
	draw_circle(Vector2(pos.x - 9.0, pos.y), 3.0, Color(0, 0.94, 1.0, 1.0))
	draw_circle(Vector2(pos.x + 9.0, pos.y), 3.0, Color(0, 0.94, 1.0, 1.0))
	
	# Electric spark discharge across nodes
	if pct > 0.15:
		var jitter_y1 = randf_range(-3.0, 3.0)
		var jitter_y2 = randf_range(-3.0, 3.0)
		var p1 = Vector2(pos.x - 7.0, pos.y)
		var p2 = Vector2(pos.x - 2.0, pos.y + jitter_y1)
		var p3 = Vector2(pos.x + 2.0, pos.y + jitter_y2)
		var p4 = Vector2(pos.x + 7.0, pos.y)
		
		var arc_col := Color(1.0, 1.0, 1.0, 1.0) if pct >= 0.85 else Color(0.3, 2.2, 2.5, 1.0)
		draw_line(p1, p2, arc_col, 1.5)
		draw_line(p2, p3, arc_col, 1.5)
		draw_line(p3, p4, arc_col, 1.5)
