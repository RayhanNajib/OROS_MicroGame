extends Area2D

@export var base_exp_value: int = 50
var player: Node2D = null
var is_picked: bool = false

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("loot")
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	# Hover float & spin
	var hover := sin(Time.get_ticks_msec() * 0.006) * 3.0
	if sprite:
		sprite.position.y = hover
		sprite.rotation += delta * 2.5
		
	# Magnet pull to nearest active player (supports single player and co-op)
	if not is_picked:
		var target_player: Node2D = null
		var min_dist := 999999.0
		for p in get_tree().get_nodes_in_group("player"):
			if is_instance_valid(p) and not p.get("is_downed"):
				var d = global_position.distance_to(p.global_position)
				if d < min_dist:
					min_dist = d
					target_player = p
		
		if target_player:
			var pull_radius = GameState.pickup_radius * 1.5
			if target_player.get("has_magnetic_vacuum"):
				pull_radius *= 2.5
			if min_dist < pull_radius:
				var dir = (target_player.global_position - global_position).normalized()
				global_position += dir * (340.0 * delta)
				if min_dist < 24.0:
					collect(target_player)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collect(body)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		collect(area)
	elif area.get_parent() and area.get_parent().is_in_group("player"):
		collect(area.get_parent())

func collect(collector: Node2D = null) -> void:
	if is_picked: return
	is_picked = true
	
	var p_idx := 1
	var target_p = collector
	if not is_instance_valid(target_p):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target_p = players[0]
			
	if is_instance_valid(target_p) and "player_index" in target_p:
		p_idx = target_p.player_index
		
	var cur_lvl := GameState.skill_level if p_idx == 1 else GameState.p2_skill_level
	
	if cur_lvl >= GameState.MAX_SKILL_LEVEL:
		# Max skill cap reached (Level 15)!
		# Dialihkan ke level EXP sebesar 50% poin dari pendapatan EXP aslinya.
		# Berlaku juga untuk co-op; akumulasi exp 2 orang tetap berjalan normal via GameState.add_xp() / add_exp()
		var exp_gain: int = maxi(1, int(round(float(base_exp_value) * 0.50)))
		if GameState.has_method("add_xp"):
			GameState.add_xp(exp_gain)
		elif GameState.has_method("add_exp"):
			GameState.add_exp(exp_gain)
		
		if is_instance_valid(target_p) and target_p.has_node("SFXPickupPearl"):
			target_p.get_node("SFXPickupPearl").play()
		elif is_instance_valid(target_p) and target_p.has_node("SFXPickupCore"):
			target_p.get_node("SFXPickupCore").play()
			
		var popup_scene = load("res://scenes/entities/DamagePopup.tscn")
		if popup_scene:
			var popup = popup_scene.instantiate()
			popup.global_position = global_position + Vector2(0, -30)
			if popup.has_method("setup_text"):
				popup.setup_text("+%d EXP (LVL 15 CAP)" % exp_gain, Color(0.0, 1.0, 0.75, 1.0))
			else:
				popup.setup(exp_gain, true)
			get_parent().add_child(popup)
	else:
		# Upgrade level skill hero sampai mentok level 15
		GameState.upgrade_skill(p_idx)
		var new_lvl := GameState.skill_level if p_idx == 1 else GameState.p2_skill_level
		
		if is_instance_valid(target_p) and target_p.has_node("SFXPickupCore"):
			target_p.get_node("SFXPickupCore").play()
			
		var popup_scene = load("res://scenes/entities/DamagePopup.tscn")
		if popup_scene:
			var popup = popup_scene.instantiate()
			popup.global_position = global_position + Vector2(0, -30)
			if popup.has_method("setup_text"):
				if new_lvl >= GameState.MAX_SKILL_LEVEL:
					popup.setup_text("SKILL LVL 15 (MAX)!", Color(1.0, 0.35, 0.1, 1.0))
				else:
					popup.setup_text("SKILL LVL %d" % new_lvl, Color(1.0, 0.85, 0.1, 1.0))
			else:
				popup.setup(new_lvl, false)
			get_parent().add_child(popup)
			
	queue_free()
