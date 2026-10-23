extends Node

const SAVE_PATH = "user://oros_save.json"

var nano_credits: int = 0 # Starting Nano-Credits (Grind to unlock!)

var stages_data: Dictionary = {
	1: {"unlocked": true, "high_rank": "-", "best_time": 0.0, "cleared": false},
	2: {"unlocked": false, "high_rank": "-", "best_time": 0.0, "cleared": false}, # Requires Rank B in Stage 1
	3: {"unlocked": false, "high_rank": "-", "best_time": 0.0, "cleared": false}, # Requires Rank B in Stage 2
	4: {"unlocked": false, "high_rank": "-", "best_time": 0.0, "cleared": false}, # Requires Rank A in Stage 3
	5: {"unlocked": false, "high_rank": "-", "best_time": 0.0, "cleared": false}  # Requires Rank S in Stage 4 (NIGHTMARE)
}

var unlocked_items: Array = [
	"skin_kael_default", "skin_vex_default", "skin_brutus_default",
	"wep_revolver_default", "wep_shotgun_default", "wep_smg_default",
	"hud_cyan", "gem_core"
]

var equipped_hero_skin: String = "default"
var equipped_weapon_skin: String = "default"
var equipped_hud_theme: String = "cyan"
var equipped_gem_skin: String = "core"

var audio_bgm: float = 0.8
var audio_sfx: float = 0.9
var language: String = "id"

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
	load_game()

func save_game() -> void:
	var data := {
		"nano_credits": nano_credits,
		"stages_data": stages_data,
		"unlocked_items": unlocked_items,
		"equipped_hero_skin": equipped_hero_skin,
		"equipped_weapon_skin": equipped_weapon_skin,
		"equipped_hud_theme": equipped_hud_theme,
		"equipped_gem_skin": equipped_gem_skin,
		"audio_bgm": audio_bgm,
		"audio_sfx": audio_sfx,
		"language": language,
		"runes": runes
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f:
		var content := f.get_as_text()
		f.close()
		var parsed = JSON.parse_string(content)
		if parsed is Dictionary:
			nano_credits = parsed.get("nano_credits", 300)
			stages_data = parsed.get("stages_data", stages_data)
			unlocked_items = parsed.get("unlocked_items", unlocked_items)
			equipped_hero_skin = parsed.get("equipped_hero_skin", "default")
			equipped_weapon_skin = parsed.get("equipped_weapon_skin", "default")
			equipped_hud_theme = parsed.get("equipped_hud_theme", "cyan")
			equipped_gem_skin = parsed.get("equipped_gem_skin", "core")
			audio_bgm = parsed.get("audio_bgm", 0.8)
			audio_sfx = parsed.get("audio_sfx", 0.9)
			language = parsed.get("language", "id")
			runes = parsed.get("runes", runes)

func add_credits(amount: int) -> void:
	nano_credits += amount
	save_game()

func record_stage_result(stage_id: int, time_survived: float, rank: String) -> void:
	if not stages_data.has(stage_id):
		return
	var s: Dictionary = stages_data[stage_id]
	s["cleared"] = true
	s["best_time"] = maxf(s.get("best_time", 0.0), time_survived)
	
	# Rank hierarchy: S > A > B > C
	var rank_val = {"S": 4, "A": 3, "B": 2, "C": 1, "-": 0}
	var old_rank = s.get("high_rank", "-")
	if rank_val.get(rank, 0) > rank_val.get(old_rank, 0):
		s["high_rank"] = rank
		
	# Check unlocks for next stage
	if stage_id == 1 and rank_val.get(rank, 0) >= rank_val["B"]:
		stages_data[2]["unlocked"] = true
	elif stage_id == 2 and rank_val.get(rank, 0) >= rank_val["B"]:
		stages_data[3]["unlocked"] = true
	elif stage_id == 3 and rank_val.get(rank, 0) >= rank_val["A"]:
		stages_data[4]["unlocked"] = true
	elif stage_id == 4 and rank_val.get(rank, 0) >= rank_val["S"]:
		stages_data[5]["unlocked"] = true
		
	save_game()


func buy_rune(rune_id: String, max_rank: int = 5, cost: int = 50) -> bool:
	var cur = runes.get(rune_id, 0)
	if cur >= max_rank: return false
	if nano_credits < cost: return false
	nano_credits -= cost
	runes[rune_id] = cur + 1
	save_game()
	return true

func respec_runes() -> void:
	var refund := 0
	for k in runes.keys():
		refund += runes[k] * 50
		runes[k] = 0
	nano_credits += refund
	save_game()
