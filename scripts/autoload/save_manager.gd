extends Node

signal slot_saved(slot_idx: int)
signal slot_loaded(slot_idx: int)
signal slot_deleted(slot_idx: int)
signal slot_renamed(slot_idx: int, new_name: String)

const MAX_SLOTS: int = 5
const META_PATH: String = "user://save_slots_meta.json"
const OLD_SAVE_PATH: String = "user://oros_save.json"

var slots_meta: Dictionary = {}
var active_slot_idx: int = -1
var last_active_slot: int = -1

var nano_credits: int = 0

var stages_data: Dictionary = {
	1: {"unlocked": true, "high_rank": "-", "best_time": 0.0, "cleared": false},
	2: {"unlocked": false, "high_rank": "-", "best_time": 0.0, "cleared": false},
	3: {"unlocked": false, "high_rank": "-", "best_time": 0.0, "cleared": false},
	4: {"unlocked": false, "high_rank": "-", "best_time": 0.0, "cleared": false},
	5: {"unlocked": false, "high_rank": "-", "best_time": 0.0, "cleared": false}
}

var unlocked_items: Array = [
	"skin_kael_default", "skin_vex_default", "skin_brutus_default", "skin_nyx_default",
	"wep_revolver_default", "wep_shotgun_default", "wep_smg_default", "wep_railgun_default",
	"hud_cyan", "gem_core"
]

var equipped_hero_skin: String = "default"
var equipped_weapon_skin: String = "default"
var equipped_hud_theme: String = "cyan"
var equipped_gem_skin: String = "core"

var equipped_hero_skins: Dictionary = {
	"kael": "default",
	"vex": "default",
	"brutus": "default",
	"nyx": "default"
}

var equipped_weapon_skins: Dictionary = {
	"revolver": "default",
	"shotgun": "default",
	"smg": "default",
	"railgun": "default"
}

func get_hero_skin(hero_id: String) -> String:
	if equipped_hero_skins.has(hero_id) and equipped_hero_skins[hero_id] != "default":
		return equipped_hero_skins[hero_id]
	match hero_id:
		"kael":
			if equipped_hero_skin in ["cobalt", "crimson"]: return equipped_hero_skin
		"vex":
			if equipped_hero_skin == "toxic": return equipped_hero_skin
		"brutus":
			if equipped_hero_skin == "gold": return equipped_hero_skin
		"nyx":
			if equipped_hero_skin == "void": return equipped_hero_skin
	return "default"

func set_hero_skin(hero_id: String, variant: String) -> void:
	equipped_hero_skins[hero_id] = variant
	equipped_hero_skin = variant

func get_weapon_skin(wep_id: String) -> String:
	if equipped_weapon_skins.has(wep_id) and equipped_weapon_skins[wep_id] != "default":
		return equipped_weapon_skins[wep_id]
	match wep_id:
		"revolver":
			if equipped_weapon_skin == "gold": return equipped_weapon_skin
		"shotgun":
			if equipped_weapon_skin == "cyber": return equipped_weapon_skin
		"smg":
			if equipped_weapon_skin == "violet": return equipped_weapon_skin
		"railgun":
			if equipped_weapon_skin == "cryo": return equipped_weapon_skin
	return "default"

func set_weapon_skin(wep_id: String, variant: String) -> void:
	equipped_weapon_skins[wep_id] = variant
	equipped_weapon_skin = variant

var audio_bgm: float = 0.8
var audio_sfx: float = 0.9
var language: String = "id"

# Settings parameters
var gamepad_sensitivity: float = 1.0
var mouse_sensitivity: float = 1.0
var gamepad_deadzone: float = 0.15
var aim_assist: bool = true

var vib_master: bool = true
var vib_shooting: bool = false
var vib_melee: bool = true
var vib_damage: bool = true
var vib_reload: bool = true
var vib_ui: bool = true
var vib_strength: float = 1.0

var volume_master: float = 1.0
var volume_bgm: float = 0.8
var volume_sfx: float = 1.0
var volume_reload: float = 1.0

var screen_shake_strength: float = 1.0
var crt_scanlines: bool = true
var damage_popups: bool = true

var fullscreen: bool = false
var camera_shake: bool = true
var auto_reload: bool = true
var outline_vfx: bool = false

var runes: Dictionary = {
	"cyber_caliber": 0,
	"rapid_vent": 0,
	"heavy_impulse": 0,
	"plasma_pierce": 0,
	"titan_alloy": 0,
	"ion_stride": 0,
	"melee_leech": 0,
	"overclock_core": 0
}

func _ready() -> void:
	init_slots_meta()
	var loaded := false
	if last_active_slot > 0 and slots_meta.has(last_active_slot) and not slots_meta[last_active_slot].get("empty", true) and FileAccess.file_exists(get_slot_path(last_active_slot)):
		loaded = load_from_slot(last_active_slot)
	if not loaded:
		for i in range(1, MAX_SLOTS + 1):
			if not slots_meta[i].get("empty", true) and FileAccess.file_exists(get_slot_path(i)):
				loaded = load_from_slot(i)
				break
	if not loaded:
		if FileAccess.file_exists(OLD_SAVE_PATH):
			var f := FileAccess.open(OLD_SAVE_PATH, FileAccess.READ)
			if f:
				var txt := f.get_as_text()
				f.close()
				var p = JSON.parse_string(txt)
				if p is Dictionary:
					apply_save_dict(p)
					save_to_slot(1, "ARSIP MIGRASI")
					loaded = true
		if not loaded:
			reset_all_data()

func get_slot_path(slot_idx: int) -> String:
	return "user://save_slot_%d.json" % slot_idx

func init_slots_meta() -> void:
	slots_meta.clear()
	for i in range(1, MAX_SLOTS + 1):
		slots_meta[i] = {
			"id": i,
			"name": "SLOT %02d" % i,
			"empty": true,
			"timestamp": "-",
			"stage_reached": 1,
			"credits": 0,
			"runes_count": 0
		}
	
	if FileAccess.file_exists(META_PATH):
		var f := FileAccess.open(META_PATH, FileAccess.READ)
		if f:
			var txt := f.get_as_text()
			f.close()
			var parsed = JSON.parse_string(txt)
			if parsed is Dictionary:
				if parsed.has("last_active_slot"):
					last_active_slot = int(parsed.get("last_active_slot", -1))
				var s_map: Dictionary = parsed.get("slots", parsed)
				for k in s_map:
					var idx = int(k)
					if slots_meta.has(idx) and s_map[k] is Dictionary:
						var d = s_map[k]
						slots_meta[idx]["name"] = d.get("name", "SLOT %02d" % idx)
						slots_meta[idx]["empty"] = d.get("empty", true)
						slots_meta[idx]["timestamp"] = d.get("timestamp", "-")
						slots_meta[idx]["stage_reached"] = d.get("stage_reached", 1)
						slots_meta[idx]["credits"] = d.get("credits", 0)
						slots_meta[idx]["runes_count"] = d.get("runes_count", 0)
						if not slots_meta[idx]["empty"] and not FileAccess.file_exists(get_slot_path(idx)):
							slots_meta[idx]["empty"] = true

func save_slots_meta() -> void:
	var payload := {
		"last_active_slot": active_slot_idx if active_slot_idx > 0 else last_active_slot,
		"slots": slots_meta
	}
	var f := FileAccess.open(META_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "	"))
		f.flush()
		f.close()

func get_save_dict() -> Dictionary:
	return {
		"nano_credits": nano_credits,
		"stages_data": stages_data,
		"unlocked_items": unlocked_items,
		"equipped_hero_skin": equipped_hero_skin,
		"equipped_weapon_skin": equipped_weapon_skin,
		"equipped_hero_skins": equipped_hero_skins,
		"equipped_weapon_skins": equipped_weapon_skins,
		"equipped_hud_theme": equipped_hud_theme,
		"equipped_gem_skin": equipped_gem_skin,
		"audio_bgm": audio_bgm,
		"audio_sfx": audio_sfx,
		"language": language,
		"runes": runes,
		"gamepad_sensitivity": gamepad_sensitivity,
		"mouse_sensitivity": mouse_sensitivity,
		"gamepad_deadzone": gamepad_deadzone,
		"aim_assist": aim_assist,
		"vib_master": vib_master,
		"vib_shooting": vib_shooting,
		"vib_melee": vib_melee,
		"vib_damage": vib_damage,
		"vib_reload": vib_reload,
		"vib_ui": vib_ui,
		"vib_strength": vib_strength,
		"volume_master": volume_master,
		"volume_bgm": volume_bgm,
		"volume_sfx": volume_sfx,
		"volume_reload": volume_reload,
		"screen_shake_strength": screen_shake_strength,
		"crt_scanlines": crt_scanlines,
		"damage_popups": damage_popups,
		"fullscreen": fullscreen
	}

func apply_save_dict(parsed: Dictionary) -> void:
	nano_credits = parsed.get("nano_credits", 0)
	var raw_stages = parsed.get("stages_data", {})
	for k in raw_stages:
		var s_int = int(k)
		if stages_data.has(s_int):
			var s_dict = raw_stages[k]
			stages_data[s_int]["unlocked"] = s_dict.get("unlocked", stages_data[s_int]["unlocked"])
			stages_data[s_int]["high_rank"] = s_dict.get("high_rank", stages_data[s_int]["high_rank"])
			stages_data[s_int]["best_time"] = s_dict.get("best_time", stages_data[s_int]["best_time"])
			stages_data[s_int]["cleared"] = s_dict.get("cleared", stages_data[s_int]["cleared"])
	unlocked_items = parsed.get("unlocked_items", unlocked_items)
	equipped_hero_skin = parsed.get("equipped_hero_skin", "default")
	equipped_weapon_skin = parsed.get("equipped_weapon_skin", "default")
	if parsed.has("equipped_hero_skins"):
		equipped_hero_skins = parsed.get("equipped_hero_skins", equipped_hero_skins)
	else:
		if equipped_hero_skin in ["cobalt", "crimson"]: equipped_hero_skins["kael"] = equipped_hero_skin
		elif equipped_hero_skin == "toxic": equipped_hero_skins["vex"] = equipped_hero_skin
		elif equipped_hero_skin == "gold": equipped_hero_skins["brutus"] = equipped_hero_skin
		elif equipped_hero_skin == "void": equipped_hero_skins["nyx"] = equipped_hero_skin
	if parsed.has("equipped_weapon_skins"):
		equipped_weapon_skins = parsed.get("equipped_weapon_skins", equipped_weapon_skins)
	else:
		if equipped_weapon_skin == "gold": equipped_weapon_skins["revolver"] = equipped_weapon_skin
		elif equipped_weapon_skin == "cyber": equipped_weapon_skins["shotgun"] = equipped_weapon_skin
		elif equipped_weapon_skin == "violet": equipped_weapon_skins["smg"] = equipped_weapon_skin
		elif equipped_weapon_skin == "cryo": equipped_weapon_skins["railgun"] = equipped_weapon_skin
	equipped_hud_theme = parsed.get("equipped_hud_theme", "cyan")
	equipped_gem_skin = parsed.get("equipped_gem_skin", "core")
	audio_bgm = parsed.get("audio_bgm", 0.8)
	audio_sfx = parsed.get("audio_sfx", 0.9)
	language = parsed.get("language", "id")
	runes = parsed.get("runes", runes)
	gamepad_sensitivity = parsed.get("gamepad_sensitivity", 1.0)
	mouse_sensitivity = parsed.get("mouse_sensitivity", 1.0)
	gamepad_deadzone = parsed.get("gamepad_deadzone", 0.15)
	aim_assist = parsed.get("aim_assist", true)
	vib_master = parsed.get("vib_master", true)
	vib_shooting = parsed.get("vib_shooting", false)
	vib_melee = parsed.get("vib_melee", true)
	vib_damage = parsed.get("vib_damage", true)
	vib_reload = parsed.get("vib_reload", true)
	vib_ui = parsed.get("vib_ui", true)
	vib_strength = parsed.get("vib_strength", 1.0)
	volume_master = parsed.get("volume_master", 1.0)
	volume_bgm = parsed.get("volume_bgm", 0.8)
	volume_sfx = parsed.get("volume_sfx", 1.0)
	volume_reload = parsed.get("volume_reload", 1.0)
	screen_shake_strength = parsed.get("screen_shake_strength", 1.0)
	crt_scanlines = parsed.get("crt_scanlines", true)
	damage_popups = parsed.get("damage_popups", true)
	fullscreen = parsed.get("fullscreen", false)

func save_to_slot(slot_idx: int, custom_name: String = "") -> bool:
	if slot_idx < 1 or slot_idx > MAX_SLOTS: return false
	var path := get_slot_path(slot_idx)
	var data := get_save_dict()
	var f := FileAccess.open(path, FileAccess.WRITE)
	if not f: return false
	f.store_string(JSON.stringify(data, "	"))
	f.flush()
	f.close()
	
	var dt := Time.get_datetime_dict_from_system()
	var dt_str := "%04d-%02d-%02d %02d:%02d" % [dt.year, dt.month, dt.day, dt.hour, dt.minute]
	var max_stage := 1
	for s_id in stages_data:
		if stages_data[s_id].get("unlocked", false):
			max_stage = maxi(max_stage, s_id)
			
	var total_runes := 0
	for r in runes:
		total_runes += runes[r]
		
	slots_meta[slot_idx]["empty"] = false
	if custom_name.strip_edges() != "":
		slots_meta[slot_idx]["name"] = custom_name.strip_edges()
	slots_meta[slot_idx]["timestamp"] = dt_str
	slots_meta[slot_idx]["stage_reached"] = max_stage
	slots_meta[slot_idx]["credits"] = nano_credits
	slots_meta[slot_idx]["runes_count"] = total_runes
	active_slot_idx = slot_idx
	last_active_slot = slot_idx
	save_slots_meta()
	slot_saved.emit(slot_idx)
	return true

func load_from_slot(slot_idx: int) -> bool:
	if slot_idx < 1 or slot_idx > MAX_SLOTS: return false
	var path := get_slot_path(slot_idx)
	if not FileAccess.file_exists(path): return false
	var f := FileAccess.open(path, FileAccess.READ)
	if not f: return false
	var txt := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(txt)
	if parsed is Dictionary:
		apply_save_dict(parsed)
		active_slot_idx = slot_idx
		last_active_slot = slot_idx
		save_slots_meta()
		slot_loaded.emit(slot_idx)
		return true
	return false

func delete_slot(slot_idx: int) -> bool:
	if slot_idx < 1 or slot_idx > MAX_SLOTS: return false
	var path := get_slot_path(slot_idx)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	slots_meta[slot_idx] = {
		"id": slot_idx,
		"name": "SLOT %02d" % slot_idx,
		"empty": true,
		"timestamp": "-",
		"stage_reached": 1,
		"credits": 0,
		"runes_count": 0
	}
	if active_slot_idx == slot_idx:
		active_slot_idx = -1
	if last_active_slot == slot_idx:
		last_active_slot = -1
	save_slots_meta()
	slot_deleted.emit(slot_idx)
	return true

func rename_slot(slot_idx: int, new_name: String) -> bool:
	if slot_idx < 1 or slot_idx > MAX_SLOTS: return false
	var clean_name = new_name.strip_edges()
	if clean_name.is_empty():
		clean_name = "SLOT %02d" % slot_idx
	slots_meta[slot_idx]["name"] = clean_name
	save_slots_meta()
	slot_renamed.emit(slot_idx, clean_name)
	return true

func reset_all_data() -> void:
	nano_credits = 0
	stages_data = {
		1: {"unlocked": true, "high_rank": "-", "best_time": 0.0, "cleared": false},
		2: {"unlocked": false, "high_rank": "-", "best_time": 0.0, "cleared": false},
		3: {"unlocked": false, "high_rank": "-", "best_time": 0.0, "cleared": false},
		4: {"unlocked": false, "high_rank": "-", "best_time": 0.0, "cleared": false},
		5: {"unlocked": false, "high_rank": "-", "best_time": 0.0, "cleared": false}
	}
	unlocked_items = [
		"skin_kael_default", "skin_vex_default", "skin_brutus_default", "skin_nyx_default",
		"wep_revolver_default", "wep_shotgun_default", "wep_smg_default", "wep_railgun_default",
		"hud_cyan", "gem_core"
	]
	equipped_hero_skin = "default"
	equipped_weapon_skin = "default"
	equipped_hero_skins = {
		"kael": "default",
		"vex": "default",
		"brutus": "default",
		"nyx": "default"
	}
	equipped_weapon_skins = {
		"revolver": "default",
		"shotgun": "default",
		"smg": "default",
		"railgun": "default"
	}
	equipped_hud_theme = "cyan"
	equipped_gem_skin = "core"
	for k in runes.keys():
		runes[k] = 0
	active_slot_idx = -1
	last_active_slot = -1

func wipe_all_save_data() -> void:
	for i in range(1, MAX_SLOTS + 1):
		var p := get_slot_path(i)
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
	if FileAccess.file_exists(META_PATH):
		DirAccess.remove_absolute(META_PATH)
	if FileAccess.file_exists(OLD_SAVE_PATH):
		DirAccess.remove_absolute(OLD_SAVE_PATH)
	init_slots_meta()
	reset_all_data()

func save_game() -> void:
	# Jika ada slot aktif (pernah disimpan atau dimuat), persistensi data langsung ke slot
	if active_slot_idx > 0 and active_slot_idx <= MAX_SLOTS:
		save_to_slot(active_slot_idx)
	elif last_active_slot > 0 and last_active_slot <= MAX_SLOTS and not slots_meta.get(last_active_slot, {}).get("empty", true):
		save_to_slot(last_active_slot)
	else:
		if slots_meta.has(1) and not slots_meta[1].get("empty", true):
			save_to_slot(1)

func load_game() -> void:
	if active_slot_idx > 0 and active_slot_idx <= MAX_SLOTS:
		load_from_slot(active_slot_idx)
	elif last_active_slot > 0 and last_active_slot <= MAX_SLOTS and not slots_meta.get(last_active_slot, {}).get("empty", true):
		load_from_slot(last_active_slot)
	else:
		for i in range(1, MAX_SLOTS + 1):
			if not slots_meta[i].get("empty", true) and FileAccess.file_exists(get_slot_path(i)):
				load_from_slot(i)
				break

func add_credits(amount: int) -> void:
	nano_credits += amount

func is_stage_unlocked(stage_id: int) -> bool:
	if stage_id == 1: return true
	if stages_data.has(stage_id):
		return stages_data[stage_id].get("unlocked", false)
	return false

func record_stage_result(stage_id: int, time_survived: float, rank: String) -> void:
	if not stages_data.has(stage_id):
		return
	var s: Dictionary = stages_data[stage_id]
	s["cleared"] = true
	s["best_time"] = maxf(s.get("best_time", 0.0), time_survived)
	
	var rank_val = {"S": 4, "A": 3, "B": 2, "C": 1, "-": 0}
	var old_rank = s.get("high_rank", "-")
	if rank_val.get(rank, 0) > rank_val.get(old_rank, 0):
		s["high_rank"] = rank
		
	if stage_id == 1 and time_survived >= 300.0:
		stages_data[2]["unlocked"] = true
	elif stage_id == 2 and time_survived >= 600.0:
		stages_data[3]["unlocked"] = true
	elif stage_id == 3 and time_survived >= 900.0:
		stages_data[4]["unlocked"] = true
	elif stage_id == 4 and time_survived >= 1200.0:
		stages_data[5]["unlocked"] = true

func buy_rune(rune_id: String, max_rank: int = 5, cost: int = 150) -> bool:
	var cur = runes.get(rune_id, 0)
	if cur >= max_rank: return false
	if nano_credits < cost: return false
	nano_credits -= cost
	runes[rune_id] = cur + 1
	return true

func respec_runes() -> void:
	var refund := 0
	var rune_costs = {
		"cyber_caliber": 150,
		"rapid_vent": 225,
		"heavy_impulse": 300,
		"plasma_pierce": 450,
		"titan_alloy": 150,
		"ion_stride": 225,
		"melee_leech": 300,
		"overclock_core": 450
	}
	for k in runes.keys():
		var cost_per_rank = rune_costs.get(k, 150)
		refund += runes[k] * cost_per_rank
		runes[k] = 0
	nano_credits += refund
