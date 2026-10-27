extends ColorRect

@onready var sub_viewport: SubViewport = $HoloViewportContainer/SubViewport
@onready var camera: Camera3D = $HoloViewportContainer/SubViewport/World3D/Camera3D
@onready var world_pivot: Node3D = $HoloViewportContainer/SubViewport/World3D/WorldPivot

@onready var card_rayhan: MeshInstance3D = $HoloViewportContainer/SubViewport/World3D/WorldPivot/CardRayhan
@onready var card_faizun: MeshInstance3D = $HoloViewportContainer/SubViewport/World3D/WorldPivot/CardFaizun
@onready var card_luigy: MeshInstance3D = $HoloViewportContainer/SubViewport/World3D/WorldPivot/CardLuigy

# UI elements
@onready var btn_rayhan: Button = $UIOverlay/Margin/VBox/TopControls/MemberButtons/BtnRayhan
@onready var btn_faizun: Button = $UIOverlay/Margin/VBox/TopControls/MemberButtons/BtnFaizun
@onready var btn_luigy: Button = $UIOverlay/Margin/VBox/TopControls/MemberButtons/BtnLuigy
@onready var btn_reset_cam: Button = $UIOverlay/Margin/VBox/TopControls/MemberButtons/BtnResetCam
@onready var btn_auto_rotate: Button = $UIOverlay/Margin/VBox/TopControls/MemberButtons/BtnAutoRotate

@onready var btn_tab_holo: Button = $UIOverlay/Margin/VBox/HeaderBox/TabHoloBtn
@onready var btn_tab_controls: Button = $UIOverlay/Margin/VBox/HeaderBox/TabControlsBtn

@onready var holo_view_container: Control = $HoloViewportContainer
@onready var controls_guide_box: Control = $UIOverlay/Margin/VBox/ControlsGuideBox
@onready var dossier_box: PanelContainer = $UIOverlay/Margin/VBox/MiddleArea/DossierBox
@onready var dossier_name: Label = $UIOverlay/Margin/VBox/MiddleArea/DossierBox/Margin/VBox/DossierName
@onready var dossier_role: Label = $UIOverlay/Margin/VBox/MiddleArea/DossierBox/Margin/VBox/DossierRole
@onready var dossier_desc: Label = $UIOverlay/Margin/VBox/MiddleArea/DossierBox/Margin/VBox/DossierDesc

@onready var close_btn: Button = $UIOverlay/Margin/VBox/BottomBar/CloseBtn
@onready var sfx_click: AudioStreamPlayer = $SFXClick

# 3D Orbit / Pan / Zoom State
var is_dragging: bool = false
var last_mouse_pos: Vector2 = Vector2.ZERO
var rot_x: float = 0.0
var rot_y: float = 0.0
var target_rot_x: float = 0.0
var target_rot_y: float = 0.0

var cam_zoom: float = 3.6
var target_zoom: float = 3.6
var cam_pan: Vector2 = Vector2.ZERO
var target_pan: Vector2 = Vector2.ZERO

var auto_rotate: bool = true
var time_elapsed: float = 0.0

# Current active focused member ("none", "rayhan", "faizun", "luigy")
var focused_member: String = "none"

func _ready() -> void:
	visible = false
	
	if close_btn:
		close_btn.pressed.connect(func():
			if sfx_click: sfx_click.play()
			visible = false
		)
		
	if btn_rayhan: btn_rayhan.pressed.connect(func(): focus_member("rayhan"))
	if btn_faizun: btn_faizun.pressed.connect(func(): focus_member("faizun"))
	if btn_luigy: btn_luigy.pressed.connect(func(): focus_member("luigy"))
	if btn_reset_cam: btn_reset_cam.pressed.connect(reset_camera)
	
	if btn_auto_rotate:
		btn_auto_rotate.pressed.connect(func():
			if sfx_click: sfx_click.play()
			auto_rotate = not auto_rotate
			btn_auto_rotate.text = "AUTO-ROTATE: ON" if auto_rotate else "AUTO-ROTATE: OFF"
		)
		
	if btn_tab_holo:
		btn_tab_holo.pressed.connect(func(): switch_mode(true))
	if btn_tab_controls:
		btn_tab_controls.pressed.connect(func(): switch_mode(false))
		
	setup_3d_materials()
	reset_camera()

func open_credits() -> void:
	visible = true
	if sfx_click: sfx_click.play()
	switch_mode(true)
	reset_camera()

func switch_mode(show_holo: bool) -> void:
	if sfx_click: sfx_click.play()
	if holo_view_container: holo_view_container.visible = show_holo
	if dossier_box: dossier_box.visible = show_holo
	if controls_guide_box: controls_guide_box.visible = not show_holo
	
	if btn_tab_holo:
		btn_tab_holo.add_theme_color_override("font_color", Color(1.0, 0.95, 0.15) if show_holo else Color(0, 0.94, 1.0))
	if btn_tab_controls:
		btn_tab_controls.add_theme_color_override("font_color", Color(1.0, 0.95, 0.15) if not show_holo else Color(0, 0.94, 1.0))

func setup_3d_materials() -> void:
	var tex_r = load("res://assets/credits/card_rayhan_holo.png")
	var tex_f = load("res://assets/credits/card_faizun_holo.png")
	var tex_l = load("res://assets/credits/card_luigy_holo.png")
	
	apply_card_mat(card_rayhan, tex_r, Color(0, 0.94, 1.0))
	apply_card_mat(card_faizun, tex_f, Color(0.98, 0.8, 0.08))
	apply_card_mat(card_luigy, tex_l, Color(0.13, 0.95, 0.4))

func apply_card_mat(mesh_inst: MeshInstance3D, tex: Texture2D, glow_col: Color) -> void:
	if not mesh_inst or not tex: return
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.emission_enabled = true
	mat.emission = glow_col
	mat.emission_energy_multiplier = 0.28
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.material_override = mat

func _process(delta: float) -> void:
	if not visible: return
	time_elapsed += delta
	
	# Gamepad Analog 3D Rotation & Zoom
	var rx := Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var ry := Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	if absf(rx) > 0.18: target_rot_y += rx * 2.8 * delta; auto_rotate = false
	if absf(ry) > 0.18: target_rot_x = clampf(target_rot_x + ry * 2.2 * delta, -0.65, 0.65); auto_rotate = false
	
	var lt := Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT)
	var rt := Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT)
	if lt > 0.2: target_zoom = clampf(target_zoom + lt * 3.5 * delta, 1.8, 6.0)
	if rt > 0.2: target_zoom = clampf(target_zoom - rt * 3.5 * delta, 1.8, 6.0)

	rot_x = lerpf(rot_x, target_rot_x, 8.0 * delta)
	rot_y = lerpf(rot_y, target_rot_y, 8.0 * delta)
	cam_zoom = lerpf(cam_zoom, target_zoom, 8.0 * delta)
	cam_pan = cam_pan.lerp(target_pan, 8.0 * delta)
	
	if auto_rotate and not is_dragging and focused_member == "none":
		target_rot_y += 0.25 * delta
		
	if world_pivot:
		world_pivot.rotation.x = rot_x
		world_pivot.rotation.y = rot_y
		
	if camera:
		camera.position.x = cam_pan.x
		camera.position.y = 0.35 + cam_pan.y
		camera.position.z = cam_zoom
		camera.look_at(Vector3(cam_pan.x, 0.2, 0))
		
	var float_y := sin(time_elapsed * 2.2) * 0.05
	if card_rayhan: card_rayhan.position.y = 0.2 + float_y
	if card_faizun: card_faizun.position.y = 0.15 + sin(time_elapsed * 2.2 + 1.2) * 0.05
	if card_luigy: card_luigy.position.y = 0.15 + sin(time_elapsed * 2.2 + 2.4) * 0.05

func _gui_input(event: InputEvent) -> void:
	handle_hologram_input(event)

func _safe_handle_input() -> void:
	if is_inside_tree() and get_viewport():
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if not visible: return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_KP_0:
			if sfx_click: sfx_click.play()
			visible = false
			_safe_handle_input()
		elif event.keycode == KEY_1:
			focus_member("rayhan")
			_safe_handle_input()
		elif event.keycode == KEY_2:
			focus_member("faizun")
			_safe_handle_input()
		elif event.keycode == KEY_3:
			focus_member("luigy")
			_safe_handle_input()
		elif event.keycode == KEY_SPACE or event.keycode == KEY_R:
			reset_camera()
			_safe_handle_input()
	elif event is InputEventJoypadButton and event.is_pressed():
		if event.button_index == JOY_BUTTON_B:
			if sfx_click: sfx_click.play()
			visible = false
			_safe_handle_input()
		elif event.button_index == JOY_BUTTON_A:
			reset_camera()
			_safe_handle_input()
		elif event.button_index == JOY_BUTTON_X or event.button_index == JOY_BUTTON_Y:
			auto_rotate = not auto_rotate
			if btn_auto_rotate: btn_auto_rotate.text = "AUTO-ROTATE"
			_safe_handle_input()
		elif event.button_index == JOY_BUTTON_LEFT_SHOULDER or event.button_index == JOY_BUTTON_DPAD_LEFT:
			cycle_member(-1)
			_safe_handle_input()
		elif event.button_index == JOY_BUTTON_RIGHT_SHOULDER or event.button_index == JOY_BUTTON_DPAD_RIGHT:
			cycle_member(1)
			_safe_handle_input()

func cycle_member(dir: int) -> void:
	var members = ["rayhan", "faizun", "luigy"]
	var cur_idx = members.find(focused_member)
	var next_idx = (cur_idx + dir + members.size()) % members.size()
	focus_member(members[next_idx])

var is_panning: bool = false

func handle_hologram_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				last_mouse_pos = event.position
			else:
				is_dragging = false
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				is_panning = true
				last_mouse_pos = event.position
			else:
				is_panning = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom = clampf(target_zoom - 0.35, 1.8, 5.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom = clampf(target_zoom + 0.35, 1.8, 5.5)
			
	elif event is InputEventMouseMotion:
		var diff = event.position - last_mouse_pos
		last_mouse_pos = event.position
		
		if is_dragging:
			# Orbit rotation
			target_rot_y -= diff.x * 0.005
			target_rot_x = clampf(target_rot_x - diff.y * 0.004, -0.4, 0.4)
			if focused_member != "none":
				focused_member = "none"
		elif is_panning:
			# Pan horizontal & vertical
			target_pan.x -= diff.x * 0.003
			target_pan.y += diff.y * 0.003
			if focused_member != "none":
				focused_member = "none"

func focus_member(member: String) -> void:
	if sfx_click: sfx_click.play()
	focused_member = member
	auto_rotate = false
	if btn_auto_rotate: btn_auto_rotate.text = "AUTO-ROTATE: OFF"
	
	match member:
		"rayhan":
			target_pan = Vector2(0.7, 0.05)
			target_rot_y = 0.0
			target_rot_x = 0.02
			target_zoom = 2.4
			update_dossier("MUHAMMAD RAYHAN NAJIB", "PROGRAMMER // NIM: 240533600012", 
				"• Arsitektur Core State Machine & Twin-Stick Gameplay\n• Sistem 5 Stage Nightmare & Logika 5 Boss Unik\n• Algoritma Level-up Draft Card & Adaptive Drop Rate\n• Sistem Dual-Weapon Swap & Melee-Gated Heal Balancing\n• Integrasi Autoload SaveManager & Engine Godot 4.7.2")
		"faizun":
			target_pan = Vector2(-1.05, 0.05)
			target_rot_y = 0.28
			target_rot_x = 0.02
			target_zoom = 2.4
			update_dossier("M. FAIZUN NI'AM", "ARTIST // NIM: 240533600539",
				"• Produksi 100% 2D Retro Pixel Art & Animasi Walk Cycles\n• Desain Visual 7 Varian Musuh & 5 Karakter Boss\n• Komposisi Audio 16-Bit Chiptune Foley & Sound FX\n• Aset Senjata Close-up, Projectile Sprites & Loot Cores\n• Estetika Retro Synthwave & Konsistensi Palet Neon")
		"luigy":
			target_pan = Vector2(2.45, 0.05)
			target_rot_y = -0.28
			target_rot_x = 0.02
			target_zoom = 2.4
			update_dossier("LUIGY M. C. LIEM SAUNOAH", "PROJECT + LEVEL MANAGER // NIM: 240533605298",
				"• Manajemen Produksi & QA Balance Testing 5 Sektor\n• Desain Sistem Navigasi UI/UX & Layout Campaign Wizard\n• Perancangan Toko Siber (Marketplace) & Rune Skill Tree\n• Penyusunan Dokumen Desain Gim (GDD) Standar Industri\n• Pengujian Keseimbangan Tingkat Kesulitan Sektor 1-5")

func reset_camera() -> void:
	if sfx_click: sfx_click.play()
	focused_member = "none"
	target_pan = Vector2(0.9, 0.0)
	target_rot_x = 0.04
	target_rot_y = 0.0
	target_zoom = 4.3
	update_dossier("TIM PENGEMBANG O.R.O.S. (KELOMPOK 3)", "FAKULTAS TEKNIK • PENDIDIKAN TEKNIK INFORMATIKA 2026",
		"Klik pada tombol anggota di atas atau klik-tahan mouse untuk memutar hologram 3D 360 derajat. Klik kanan drag untuk menggeser posisi (pan), dan scroll mouse untuk memperbesar (zoom in/out).")

func update_dossier(p_name: String, p_role: String, p_desc: String) -> void:
	if dossier_name: dossier_name.text = p_name
	if dossier_role: dossier_role.text = p_role
	if dossier_desc: dossier_desc.text = p_desc
