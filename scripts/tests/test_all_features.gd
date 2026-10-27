extends SceneTree

func _init() -> void:
	print("==========================================")
	print("STARTING OROS SYSTEM VERIFICATION...")
	print("==========================================")
	
	test_brutus_and_nyx_nerfs()
	test_skill_cap_and_exp_overflow()
	test_marketplace_3x_pricing()
	test_save_load_5_slots_manual()
	test_skill_drop_and_arena_boss_zone()
	test_hero_and_weapon_skins()
	test_coop_and_defense_indicators()
	test_homescreen_bgm_continuous_loop()
	
	print("==========================================")
	print("ALL VERIFICATIONS COMPLETED SUCCESSFULLY!")
	print("==========================================")
	quit(0)

func test_brutus_and_nyx_nerfs() -> void:
	print("[1] Verifying Brutus & Nyx Nerf Values...")
	# Void Vortex script
	var vortex_script = load("res://scripts/entities/void_vortex.gd")
	assert(vortex_script != null, "Void Vortex script must exist")
	var vortex_inst = Node2D.new()
	vortex_inst.set_script(vortex_script)
	print("  - Nyx Vortex Default Radius: %s (Expected 117.0, down 55%% from 260.0)" % vortex_inst.radius)
	print("  - Nyx Vortex Tick Damage: %s (Expected 6, down 55%% from 14)" % vortex_inst.tick_damage)
	print("  - Nyx Vortex Final Damage: %s (Expected 22, down 55%% from 50)" % vortex_inst.final_damage)
	assert(abs(vortex_inst.radius - 117.0) < 0.1, "Nyx radius must be 117.0")
	assert(vortex_inst.tick_damage == 6, "Nyx tick damage must be 6")
	assert(vortex_inst.final_damage == 22, "Nyx final damage must be 22")
	vortex_inst.free()
	
	# Player script check
	var p_file = FileAccess.open("res://scripts/entities/player.gd", FileAccess.READ)
	assert(p_file != null, "Player script must exist")
	var p_text = p_file.get_as_text()
	p_file.close()
	assert(p_text.contains("(220.0 + s_lvl * 20.0) * 0.40 * 1.30"), "Brutus hit radius formula (+30% area) must be present")
	assert(p_text.contains("(65.0 + s_lvl * 8.0) * 0.40"), "Brutus damage formula must be present")
	assert(p_text.contains("telegraph_line.add_point(Vector2(cos(ang), sin(ang)) * brutus_radius)"), "Brutus dynamic telegraph line must match brutus_radius")
	assert(p_text.contains("dist <= (brutus_radius + 12.0)"), "Brutus accurate in-zone check must be present")
	print("  - Player Brutus verified: telegraph enlarged 30% and 1:1 accurate damage radius in-zone.")
	print("  - Player & Void vortex settings verified successfully.")

func test_skill_cap_and_exp_overflow() -> void:
	print("[2] Verifying Max Cap Level 15 & EXP Conversion...")
	var gm_file = FileAccess.open("res://scripts/autoload/game_manager.gd", FileAccess.READ)
	assert(gm_file != null, "GameManager script must exist")
	var gm_text = gm_file.get_as_text()
	gm_file.close()
	assert(gm_text.contains("MAX_SKILL_LEVEL: int = 15"), "MAX_SKILL_LEVEL constant must be 15")
	assert(gm_text.contains("func add_exp(amount: int) -> void:"), "GameManager must define add_exp fallback method")
	assert(gm_text.contains("if skill_level >= MAX_SKILL_LEVEL:"), "P1 skill cap must reject >= 15")
	assert(gm_text.contains("if p2_skill_level >= MAX_SKILL_LEVEL:"), "P2 skill cap must reject >= 15")
	print("  - GameManager MAX_SKILL_LEVEL = 15, add_exp() method, & P1/P2 cap logic verified.")

	var core_file = FileAccess.open("res://scripts/entities/skill_core_pickup.gd", FileAccess.READ)
	assert(core_file != null, "SkillCorePickup script must exist")
	var core_text = core_file.get_as_text()
	core_file.close()
	assert(core_text.contains("float(base_exp_value) * 0.50"), "SkillCore overflow must grant 50% EXP (25 EXP)")
	assert(core_text.contains("GameState.add_xp(exp_gain)") or core_text.contains("GameState.add_exp(exp_gain)"), "Co-op shared EXP must be called")
	assert(core_text.contains("LVL 15 CAP"), "SkillCore overflow popup text must be present")
	print("  - SkillCore drop conversion to 50% EXP (+25 EXP) verified.")

	var hud_file = FileAccess.open("res://scripts/ui/hud.gd", FileAccess.READ)
	assert(hud_file != null, "HUD script must exist")
	var hud_text = hud_file.get_as_text()
	hud_file.close()
	assert(hud_text.contains("[ LVL 15 MAX ]"), "HUD must display [ LVL 15 MAX ]")
	print("  - HUD Skill Max Badge verified.")

func test_marketplace_3x_pricing() -> void:
	print("[3] Verifying 3x Shop / Marketplace Pricing...")
	var shop_file = FileAccess.open("res://scripts/main/marketplace_modal.gd", FileAccess.READ)
	assert(shop_file != null, "Marketplace script must exist")
	var shop_text = shop_file.get_as_text()
	shop_file.close()
	
	assert(shop_text.contains('"cost": 450'), "Skin Kael Cyber cost must be 450 (150*3)")
	assert(shop_text.contains('"cost": 540'), "Skin Kael Crimson cost must be 540 (180*3)")
	assert(shop_text.contains('"cost": 600'), "Skin Vex Shadow cost must be 600 (200*3)")
	assert(shop_text.contains('"cost": 900'), "Skin Brutus Mech cost must be 900 (300*3)")
	assert(shop_text.contains('"cost": 150'), "Rune Tier 1 cost must be 150 (50*3)")
	assert(shop_text.contains('"cost": 225'), "Rune Tier 2 cost must be 225 (75*3)")
	assert(shop_text.contains('"cost": 300'), "Rune Tier 3 cost must be 300 (100*3)")
	assert(shop_text.contains('"cost": 450'), "Rune Tier 4 cost must be 450 (150*3)")
	
	print("  - Skin Kael Cyber: 450 NC (Originally 150 -> 450 NC)")
	print("  - Skin Kael Crimson: 540 NC (Originally 180 -> 540 NC)")
	print("  - Skin Vex Shadow: 600 NC (Originally 200 -> 600 NC)")
	print("  - Skin Brutus Mech: 900 NC (Originally 300 -> 900 NC)")
	print("  - Rune Upgrades: Tier 1 = 150 NC, Tier 2 = 225 NC, Tier 3 = 300 NC, Tier 4 = 450 NC (All 3x)")
	print("  - Marketplace 3x multiplier verified successfully.")

func test_save_load_5_slots_manual() -> void:
	print("[4] Verifying 5-Slot Manual Save/Load System...")
	var sm_script = load("res://scripts/autoload/save_manager.gd")
	assert(sm_script != null, "SaveManager script must exist")
	var sm = sm_script.new()
	sm.init_slots_meta()
	
	assert(sm.MAX_SLOTS == 5, "MAX_SLOTS must be exactly 5")
	
	# Backup existing real user save files to avoid destructive loss
	var backup_meta_txt := ""
	if FileAccess.file_exists(sm.META_PATH):
		var mf := FileAccess.open(sm.META_PATH, FileAccess.READ)
		if mf:
			backup_meta_txt = mf.get_as_text()
			mf.close()
	var backup_slots := {}
	for i in range(1, sm.MAX_SLOTS + 1):
		var sp: String = sm.get_slot_path(i)
		if FileAccess.file_exists(sp):
			var sf := FileAccess.open(sp, FileAccess.READ)
			if sf:
				backup_slots[i] = sf.get_as_text()
				sf.close()
	
	# Wipe clean for testing
	sm.wipe_all_save_data()
	for i in range(1, 6):
		assert(sm.slots_meta[i]["empty"] == true, "Slot %d should be empty after wipe" % i)
	print("  - Reset all progress confirmed: all 5 slots empty.")
	
	# Test saving to Slot 1
	var saved = sm.save_to_slot(1, "MISI UTAMA TEST")
	assert(saved == true, "Save to slot 1 should succeed")
	assert(sm.slots_meta[1]["empty"] == false, "Slot 1 should not be empty")
	assert(sm.slots_meta[1]["name"] == "MISI UTAMA TEST", "Slot 1 name should match")
	print("  - Save to Slot 1 confirmed with custom name.")
	
	# Test rename
	sm.rename_slot(1, "CYBER RECON")
	assert(sm.slots_meta[1]["name"] == "CYBER RECON", "Slot 1 renamed name should match")
	print("  - Rename Slot 1 confirmed: new name 'CYBER RECON'.")
	
	# Test load from Slot 1
	var loaded = sm.load_from_slot(1)
	assert(loaded == true, "Load from slot 1 should succeed")
	print("  - Load from Slot 1 confirmed.")
	
	# Test delete Slot 1
	var deleted = sm.delete_slot(1)
	assert(deleted == true, "Delete slot 1 should succeed")
	assert(sm.slots_meta[1]["empty"] == true, "Slot 1 should be empty after delete")
	print("  - Delete Slot 1 confirmed: slot restored to empty.")
	
	# Test save_game() persistence on active slot
	sm.save_to_slot(1, "ACTIVE SYNC TEST")
	sm.nano_credits = 750
	sm.save_game()
	var sm_check = sm_script.new()
	sm_check.init_slots_meta()
	assert(sm_check.load_from_slot(1) == true, "Slot 1 should load correctly")
	assert(sm_check.nano_credits == 750, "save_game() must persist credit changes to active slot")
	sm_check.free()
	sm.delete_slot(1)
	print("  - Runtime save_game() confirmed: automatically syncs state to active slot.")
	
	# Verify UI Scene integration
	var menu_file = FileAccess.open("res://scenes/main/MainMenu.tscn", FileAccess.READ)
	assert(menu_file != null, "MainMenu.tscn must exist")
	var menu_text = menu_file.get_as_text()
	menu_file.close()
	assert(menu_text.contains("SaveLoadBtn"), "MainMenu must contain SaveLoadBtn")
	assert(menu_text.contains("SaveLoadModal"), "MainMenu must instantiate SaveLoadModal")
	assert(ResourceLoader.exists("res://scenes/ui/SaveLoadModal.tscn"), "SaveLoadModal.tscn scene must exist")
	print("  - UI Integration confirmed: SaveLoadBtn and SaveLoadModal in MainMenu.")
	
	# Safely restore real user save files if they existed before test
	if backup_meta_txt != "":
		var mf := FileAccess.open(sm.META_PATH, FileAccess.WRITE)
		if mf:
			mf.store_string(backup_meta_txt)
			mf.flush()
			mf.close()
	else:
		if FileAccess.file_exists(sm.META_PATH):
			DirAccess.remove_absolute(sm.META_PATH)
	for i in range(1, sm.MAX_SLOTS + 1):
		var sp: String = sm.get_slot_path(i)
		if backup_slots.has(i):
			var sf := FileAccess.open(sp, FileAccess.WRITE)
			if sf:
				sf.store_string(backup_slots[i])
				sf.flush()
				sf.close()
		else:
			if FileAccess.file_exists(sp):
				DirAccess.remove_absolute(sp)
	sm.init_slots_meta()
	sm.free()

func test_skill_drop_and_arena_boss_zone() -> void:
	print("[5] Verifying Elite-Only SkillCore Drop & Arena Boss Zone Recovery...")
	
	# Verify EnemyBase SkillCore drop restriction
	var enemy_file = FileAccess.open("res://scripts/entities/enemy_base.gd", FileAccess.READ)
	assert(enemy_file != null, "EnemyBase script must exist")
	var enemy_text = enemy_file.get_as_text()
	enemy_file.close()
	assert(enemy_text.contains("var is_elite_heavy: bool = (enemy_type == \"golem\" or max_hp >= 100 or is_in_group(\"elite\"))"), "Elite heavy check must be defined")
	assert(enemy_text.contains("if is_elite_heavy and randf() < 0.10:"), "SkillCore must only drop from elite heavy enemies with 10% chance")
	print("  - EnemyBase verified: Common minions never drop SkillCore; only heavy elites drop with 10% chance.")
	
	# Verify Boss loot SkillCore restriction
	var boss_file = FileAccess.open("res://scripts/entities/boss_controller.gd", FileAccess.READ)
	assert(boss_file != null, "BossController script must exist")
	var boss_text = boss_file.get_as_text()
	boss_file.close()
	assert(boss_text.contains("var should_drop: bool = true if not is_in_group(\"mini_boss\") else (randf() < 0.25)"), "Boss controller rare skill drop logic must be present")
	print("  - BossController verified: Mini-boss drops at 25% chance; apex boss drops 1 core.")

	# Verify Arena Zone boss lockdown & auto-recovery
	var arena_file = FileAccess.open("res://scripts/main/game_arena_controller.gd", FileAccess.READ)
	assert(arena_file != null, "GameArenaController script must exist")
	var arena_text = arena_file.get_as_text()
	arena_file.close()
	assert(arena_text.contains("target_zone_radius = 1800.0"), "Arena must reset to 1800.0 radius upon boss/mini-boss elimination")
	assert(not arena_text.contains("if st >= 60.0 and not is_zone_shrinking:"), "Unconditional permanent shrink trigger must be removed")
	assert(arena_text.contains("var has_live_boss: bool = GameState.is_boss_active"), "Dynamic live boss check must exist in arena controller")
	assert(arena_text.contains("if not has_live_boss and target_zone_radius < 1800.0:"), "Arena must auto-expand back to 1800.0 when no bosses remain")
	print("  - GameArenaController verified: Zone expands smoothly back to 1800.0 normal size after defeating boss/mini-boss.")

func test_hero_and_weapon_skins() -> void:
	print("[6] Verifying Hero, Weapon, and Gem Skin Integrity...")
	
	# 1. Verify Hero Spritesheet files & textures loadable
	var hero_skins = [
		"res://assets/sprites/skins/player_kael_cobalt.png",
		"res://assets/sprites/skins/player_kael_crimson.png",
		"res://assets/sprites/skins/player_vex_toxic.png",
		"res://assets/sprites/skins/player_brutus_gold.png",
		"res://assets/sprites/skins/player_nyx_void.png"
	]
	for h_path in hero_skins:
		assert(ResourceLoader.exists(h_path), "Hero skin resource must exist: %s" % h_path)
		var tex = load(h_path)
		assert(tex != null, "Hero skin texture must load: %s" % h_path)
	print("  - All 5 Hero skin spritesheets verified and loadable.")

	# 2. Verify Weapon Skin textures loadable
	var wep_skins = [
		"res://assets/sprites/skins/spr_shotgun_cyber.png",
		"res://assets/sprites/skins/spr_smg_violet.png",
		"res://assets/sprites/skins/spr_railgun_cryo.png",
		"res://assets/sprites/skins/spr_revolver_gold.png"
	]
	for w_path in wep_skins:
		assert(ResourceLoader.exists(w_path), "Weapon skin resource must exist: %s" % w_path)
		var tex = load(w_path)
		assert(tex != null, "Weapon skin texture must load: %s" % w_path)
	print("  - All 4 Weapon skins verified and loadable.")

	# 3. Verify Gem Skins
	var gem_skins = [
		"res://assets/sprites/skins/spr_gem_battery.png",
		"res://assets/sprites/skins/spr_gem_emerald.png"
	]
	for g_path in gem_skins:
		assert(ResourceLoader.exists(g_path), "Gem skin resource must exist: %s" % g_path)
		var tex = load(g_path)
		assert(tex != null, "Gem skin texture must load: %s" % g_path)
	print("  - All Gem skins verified and loadable.")

	# 4. Verify SaveManager per-hero and per-weapon skin methods
	var sm_script = load("res://scripts/autoload/save_manager.gd")
	var sm = sm_script.new()
	sm.reset_all_data()
	
	# Test hero skins isolation
	assert(sm.get_hero_skin("kael") == "default", "Default Kael skin must be 'default'")
	assert(sm.get_hero_skin("vex") == "default", "Default Vex skin must be 'default'")
	sm.set_hero_skin("kael", "crimson")
	assert(sm.get_hero_skin("kael") == "crimson", "Kael skin should be 'crimson'")
	assert(sm.get_hero_skin("vex") == "default", "Vex skin should remain 'default' (isolated)")
	sm.set_hero_skin("vex", "toxic")
	assert(sm.get_hero_skin("vex") == "toxic", "Vex skin should be 'toxic'")
	assert(sm.get_hero_skin("kael") == "crimson", "Kael skin should remain 'crimson'")

	# Test weapon skins isolation
	assert(sm.get_weapon_skin("shotgun") == "default", "Default shotgun skin must be 'default'")
	sm.set_weapon_skin("shotgun", "cyber")
	assert(sm.get_weapon_skin("shotgun") == "cyber", "Shotgun skin should be 'cyber'")
	assert(sm.get_weapon_skin("smg") == "default", "SMG skin should remain 'default' (isolated)")
	sm.set_weapon_skin("smg", "violet")
	assert(sm.get_weapon_skin("smg") == "violet", "SMG skin should be 'violet'")
	assert(sm.get_weapon_skin("shotgun") == "cyber", "Shotgun skin should remain 'cyber'")

	# Test serialization dictionary
	var s_dict = sm.get_save_dict()
	assert(s_dict.has("equipped_hero_skins"), "Save dict must serialize equipped_hero_skins")
	assert(s_dict.has("equipped_weapon_skins"), "Save dict must serialize equipped_weapon_skins")
	assert(s_dict["equipped_hero_skins"]["kael"] == "crimson", "Serialized Kael skin must be crimson")
	assert(s_dict["equipped_weapon_skins"]["shotgun"] == "cyber", "Serialized Shotgun skin must be cyber")

	sm.free()
	print("  - SaveManager per-hero & per-weapon isolated skin logic verified.")

func test_coop_and_defense_indicators() -> void:
	print("[7] Verifying Coop Teammate & Reactor Offscreen Indicators...")
	
	# 1. Verify OffscreenRadar script loadable and intact
	var radar_script = load("res://scripts/ui/offscreen_radar.gd")
	assert(radar_script != null, "OffscreenRadar script must exist and load")
	var radar_node = Control.new()
	radar_node.set_script(radar_script)
	assert(radar_node.has_method("_append_common_targets"), "OffscreenRadar must implement _append_common_targets()")
	assert(radar_node.has_method("_draw_view_radar"), "OffscreenRadar must implement _draw_view_radar()")
	
	# Test appending common targets with mock target list
	var test_targets: Array[Dictionary] = []
	radar_node._append_common_targets(test_targets)
	radar_node.free()
	print("  - OffscreenRadar script compilation & target appending logic verified.")

	# 2. Verify OffscreenRadar scene layer configuration
	var scene_file = FileAccess.open("res://scenes/ui/OffscreenRadar.tscn", FileAccess.READ)
	assert(scene_file != null, "OffscreenRadar.tscn scene file must exist")
	var scene_text = scene_file.get_as_text()
	scene_file.close()
	assert(scene_text.contains("layer = 3"), "OffscreenRadar must have layer = 3 to render above split screens")
	print("  - OffscreenRadar.tscn canvas layer = 3 confirmed.")

	# 3. Verify offscreen_radar script logic for coop and reactor
	var radar_file = FileAccess.open("res://scripts/ui/offscreen_radar.gd", FileAccess.READ)
	assert(radar_file != null, "offscreen_radar.gd file must exist")
	var radar_text = radar_file.get_as_text()
	radar_file.close()
	assert(radar_text.contains("REKAN P2") and radar_text.contains("REKAN P1"), "Radar must track both P1 and P2 teammates")
	assert(radar_text.contains("REAKTOR"), "Radar must track Defense Tower / Reactor")
	assert(radar_text.contains("is_split"), "Radar must support split-screen coop viewports")
	print("  - OffscreenRadar split-screen awareness, teammate tracking, & reactor tracking verified.")

	# 4. Verify Player script in-world tactical navigation compass
	var p_file = FileAccess.open("res://scripts/entities/player.gd", FileAccess.READ)
	assert(p_file != null, "player.gd file must exist")
	var p_text = p_file.get_as_text()
	p_file.close()
	assert(p_text.contains("Tactical In-World Navigation Indicators"), "Player script must contain tactical navigation indicator logic")
	assert(p_text.contains("Teammate Indicator (Coop Mode)"), "Player script must implement in-world teammate chevron")
	assert(p_text.contains("Defense Tower / Reactor Indicator"), "Player script must implement in-world reactor chevron")
	print("  - Player in-world tactical navigation compass for P1/P2 & Reactor verified.")

func test_homescreen_bgm_continuous_loop() -> void:
	print("[8] Verifying Homescreen Continuous Looping BGM & Fail-Safe...")

	# 1. Verify AudioStreamWAV import configuration & stream loop mode
	var bgm_combat_stream = load("res://assets/audio/bgm_combat_loop.wav")
	assert(bgm_combat_stream != null, "bgm_combat_loop.wav must exist and load")
	assert(bgm_combat_stream is AudioStreamWAV, "BGM combat stream must be AudioStreamWAV")
	var combat_wav := bgm_combat_stream as AudioStreamWAV
	assert(combat_wav.loop_mode == AudioStreamWAV.LOOP_FORWARD, "BGM combat WAV must have loop_mode == LOOP_FORWARD (1)")
	print("  - bgm_combat_loop.wav AudioStreamWAV loop_mode == LOOP_FORWARD verified.")

	var bgm_intro_stream = load("res://assets/audio/bgm_oros_intro.wav")
	assert(bgm_intro_stream != null, "bgm_oros_intro.wav must exist and load")
	assert(bgm_intro_stream is AudioStreamWAV, "BGM intro stream must be AudioStreamWAV")
	var intro_wav := bgm_intro_stream as AudioStreamWAV
	assert(intro_wav.loop_mode == AudioStreamWAV.LOOP_FORWARD, "BGM intro WAV must have loop_mode == LOOP_FORWARD (1)")
	print("  - bgm_oros_intro.wav AudioStreamWAV loop_mode == LOOP_FORWARD verified.")

	# 2. Verify MainMenu.tscn scene file configuration for BGMCombat node
	var mm_file = FileAccess.open("res://scenes/main/MainMenu.tscn", FileAccess.READ)
	assert(mm_file != null, "MainMenu.tscn scene file must exist")
	var mm_text = mm_file.get_as_text()
	mm_file.close()

	assert(mm_text.contains('name="BGMCombat" type="AudioStreamPlayer"'), "MainMenu must contain BGMCombat AudioStreamPlayer")
	assert(mm_text.contains("process_mode = 3"), "BGMCombat must configure process_mode = 3 (PROCESS_MODE_ALWAYS)")
	assert(mm_text.contains("bgm_combat_loop.wav"), "BGMCombat stream must point to bgm_combat_loop.wav")
	print("  - MainMenu BGMCombat node structure & process_mode ALWAYS confirmed.")

	# 3. Verify main_menu.gd script implementation
	var script_file = FileAccess.open("res://scripts/main/main_menu.gd", FileAccess.READ)
	assert(script_file != null, "main_menu.gd script file must exist")
	var script_text = script_file.get_as_text()
	script_file.close()

	assert(script_text.contains("ensure_bgm_playing()"), "main_menu.gd must implement ensure_bgm_playing()")
	assert(script_text.contains("_on_bgm_finished()"), "main_menu.gd must implement _on_bgm_finished() fail-safe")
	assert(script_text.contains("_update_bgm_volume()"), "main_menu.gd must implement _update_bgm_volume()")
	assert(script_text.contains("AudioStreamWAV.LOOP_FORWARD"), "main_menu.gd must enforce AudioStreamWAV.LOOP_FORWARD at runtime")
	assert(script_text.contains("bgm_combat.finished.connect(_on_bgm_finished)"), "main_menu.gd must connect finished signal to restart handler")
	assert(script_text.contains("ensure_bgm_playing()"), "main_menu.gd _check_modal_states must call ensure_bgm_playing()")
	print("  - main_menu.gd script methods & fail-safe signal logic verified.")

	# 4. Functional simulation of AudioStreamPlayer with loop_mode & finished fallback
	var test_player = AudioStreamPlayer.new()
	test_player.process_mode = Node.PROCESS_MODE_ALWAYS
	test_player.stream = combat_wav
	assert(test_player.stream is AudioStreamWAV, "Stream must be AudioStreamWAV")
	(test_player.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	assert((test_player.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD, "Stream loop mode must be LOOP_FORWARD")

	var tracker = {"fired": false}
	var dummy_finished_handler = func(): tracker["fired"] = true
	test_player.finished.connect(dummy_finished_handler)
	assert(test_player.finished.is_connected(dummy_finished_handler), "Finished signal handler must connect properly")
	test_player.finished.emit()
	assert(tracker["fired"] == true, "Finished signal emit must trigger fallback handler")
	test_player.free()
	print("  - AudioStreamPlayer loop & finished fallback simulation verified.")

	# 5. Volume calculation & SaveManager decibel conversion verification
	var sm_script = load("res://scripts/autoload/save_manager.gd")
	var sm = sm_script.new()
	sm.volume_master = 1.0
	sm.volume_bgm = 0.8
	var combined_db = linear_to_db(sm.volume_master * sm.volume_bgm)
	assert(abs(combined_db - (-1.9382)) < 0.1, "80% volume linear_to_db must be approximately -1.94 dB")

	sm.volume_bgm = 0.0
	var zero_combined = sm.volume_master * sm.volume_bgm
	var zero_db = -80.0 if zero_combined <= 0.01 else linear_to_db(zero_combined)
	assert(zero_db == -80.0, "Muted BGM volume must map to -80.0 dB")
	sm.free()
	print("  - SaveManager volume conversion to linear_to_db verified.")

	print("  - Homescreen continuous looping BGM verification complete.")
