extends Node2D

const Balance = preload("res://game/data/balance.gd")
const Economy = preload("res://game/scripts/economy.gd")
const WaveManager = preload("res://game/scripts/wave_manager.gd")
const Upgrades = preload("res://game/scripts/upgrades.gd")

const PLAYER_UNIT_SCRIPT := preload("res://game/entities/player_unit.gd")
const ENEMY_UNIT_SCRIPT := preload("res://game/entities/enemy_unit.gd")
const PROJECTILE_SCRIPT := preload("res://game/entities/projectile.gd")

@onready var state: Node = get_node("/root/GameState")
@onready var enemy_core_rect: ColorRect = $Battlefield/EnemyCore
@onready var player_units_root: Node2D = $Battlefield/PlayerUnits
@onready var enemy_units_root: Node2D = $Battlefield/EnemyUnits
@onready var projectiles_root: Node2D = $Battlefield/Projectiles

@onready var gold_label: Label = $UI/TopHUD/Layout/InfoRow/GoldLabel
@onready var unit_count_label: Label = $UI/TopHUD/Layout/InfoRow/UnitCountLabel
@onready var wave_label: Label = $UI/TopHUD/Layout/InfoRow/WaveLabel
@onready var wave_progress: ProgressBar = $UI/TopHUD/Layout/WaveProgress

@onready var tabs: TabContainer = $UI/Footer/Tabs
@onready var army_summary_label: Label = $UI/Footer/Tabs/Units/Layout/ArmySummaryLabel
@onready var recruit_lancer_button: Button = $UI/Footer/Tabs/Units/Layout/RecruitLancerButton
@onready var recruit_archer_button: Button = $UI/Footer/Tabs/Units/Layout/RecruitArcherButton
@onready var recruit_knight_button: Button = $UI/Footer/Tabs/Units/Layout/RecruitKnightButton

@onready var sharpen_blades_button: Button = $UI/Footer/Tabs/IndividualUpgrades/Layout/SharpenBladesButton
@onready var plate_armor_button: Button = $UI/Footer/Tabs/IndividualUpgrades/Layout/PlateArmorButton
@onready var marching_drill_button: Button = $UI/Footer/Tabs/IndividualUpgrades/Layout/MarchingDrillButton

@onready var auto_clicker_button: Button = $UI/Footer/Tabs/GlobalUpgrades/Layout/AutoClickerButton
@onready var recruitment_tent_button: Button = $UI/Footer/Tabs/GlobalUpgrades/Layout/RecruitmentTentButton
@onready var gold_multiplier_button: Button = $UI/Footer/Tabs/GlobalUpgrades/Layout/GoldMultiplierButton
@onready var unit_damage_global_button: Button = $UI/Footer/Tabs/GlobalUpgrades/Layout/UnitDamageGlobalButton
@onready var unit_health_global_button: Button = $UI/Footer/Tabs/GlobalUpgrades/Layout/UnitHealthGlobalButton

@onready var prestige_info_label: Label = $UI/Footer/Tabs/Prestige/Layout/PrestigeInfoLabel
@onready var renown_bonus_label: Label = $UI/Footer/Tabs/Prestige/Layout/RenownBonusLabel
@onready var claim_glory_button: Button = $UI/Footer/Tabs/Prestige/Layout/ClaimGloryButton

@onready var back_to_menu_button: Button = $UI/BackToMenuButton

var mode: String = "campaign"
var gold: float = 100.0
var current_wave: int = 1
var wave_name: String = ""

var current_wave_data: Dictionary = {}
var wave_enemy_spawn_total: int = 0
var wave_enemy_spawned: int = 0
var wave_spawn_interval: float = 0.7
var wave_spawn_timer: float = 0.0
var sandbox_elapsed: float = 0.0

var enemy_core_max_hp: float = 100.0
var enemy_core_hp: float = 100.0

var recruit_counts := {
	"lancer": 0,
	"archer": 0,
	"knight": 0
}

var upgrades = Upgrades.new()

var player_units: Array = []
var enemy_units: Array = []
var projectiles: Array = []

var auto_recruit_timer: float = 0.0
var ui_refresh_timer: float = 0.0
var save_sync_timer: float = 0.0


func _ready() -> void:
	randomize()
	mode = state.pending_mode

	enemy_core_rect.position = Balance.CORE_POSITION
	enemy_core_rect.size = Balance.CORE_SIZE
	enemy_core_rect.color = Color(0.85, 0.15, 0.15)

	_connect_buttons()
	_setup_tabs()

	if mode == "campaign":
		_start_campaign_wave(1)
	else:
		_start_sandbox_mode()

	_update_ui(true)


func _process(delta: float) -> void:
	delta = minf(delta, Balance.MAX_SIMULATION_DELTA)
	if mode == "sandbox":
		sandbox_elapsed += delta
		current_wave_data = WaveManager.get_sandbox_wave_data(sandbox_elapsed)
		current_wave = int(current_wave_data.get("wave", current_wave))
		wave_name = str(current_wave_data.get("name", "Sandbox"))
		wave_spawn_interval = float(current_wave_data.get("spawn_interval", wave_spawn_interval))

	_prune_dead_references()
	_handle_passive_income(delta)
	_handle_auto_recruitment(delta)
	_handle_enemy_spawning(delta)
	_handle_campaign_wave_clear()

	ui_refresh_timer += delta
	save_sync_timer += delta
	if ui_refresh_timer >= 0.1:
		ui_refresh_timer = 0.0
		_update_ui(false)
	if save_sync_timer >= 2.0:
		save_sync_timer = 0.0
		state.register_gold(gold)


func _connect_buttons() -> void:
	recruit_lancer_button.pressed.connect(_on_recruit_lancer_pressed)
	recruit_archer_button.pressed.connect(_on_recruit_archer_pressed)
	recruit_knight_button.pressed.connect(_on_recruit_knight_pressed)

	sharpen_blades_button.pressed.connect(_on_sharpen_blades_pressed)
	plate_armor_button.pressed.connect(_on_plate_armor_pressed)
	marching_drill_button.pressed.connect(_on_marching_drill_pressed)

	auto_clicker_button.pressed.connect(_on_auto_clicker_pressed)
	recruitment_tent_button.pressed.connect(_on_recruitment_tent_pressed)
	gold_multiplier_button.pressed.connect(_on_gold_multiplier_pressed)
	unit_damage_global_button.pressed.connect(_on_unit_damage_global_pressed)
	unit_health_global_button.pressed.connect(_on_unit_health_global_pressed)

	claim_glory_button.pressed.connect(_on_claim_glory_pressed)
	back_to_menu_button.pressed.connect(_on_back_to_menu_pressed)


func _setup_tabs() -> void:
	tabs.set_tab_title(0, "Units")
	tabs.set_tab_title(1, "Individual Upgrades")
	tabs.set_tab_title(2, "Global Upgrades")
	tabs.set_tab_title(3, "Prestige")


func _start_campaign_wave(wave: int) -> void:
	current_wave = wave
	state.register_wave(current_wave)

	current_wave_data = WaveManager.get_campaign_wave_data(current_wave)
	wave_name = str(current_wave_data.get("name", "Frontline"))
	wave_enemy_spawn_total = int(current_wave_data.get("enemy_count", 0))
	wave_enemy_spawned = 0
	wave_spawn_interval = float(current_wave_data.get("spawn_interval", 0.8))
	wave_spawn_timer = 0.15

	enemy_core_max_hp = float(current_wave_data.get("core_max_hp", 100.0))
	enemy_core_hp = enemy_core_max_hp
	enemy_core_rect.color = Color(0.85, 0.15, 0.15)


func _start_sandbox_mode() -> void:
	current_wave_data = WaveManager.get_sandbox_wave_data(0.0)
	current_wave = int(current_wave_data.get("wave", 1))
	wave_name = "Sandbox"
	wave_enemy_spawn_total = 0
	wave_enemy_spawned = 0
	wave_spawn_interval = float(current_wave_data.get("spawn_interval", 0.25))
	wave_spawn_timer = 0.1
	enemy_core_max_hp = 1.0
	enemy_core_hp = 1.0
	enemy_core_rect.color = Color(0.8, 0.2, 0.2)


func _handle_enemy_spawning(delta: float) -> void:
	wave_spawn_timer -= delta
	if wave_spawn_timer > 0.0:
		return

	if mode == "campaign":
		if wave_enemy_spawned >= wave_enemy_spawn_total:
			return
		if _spawn_enemy_from_wave_data(current_wave_data):
			wave_enemy_spawned += 1
		wave_spawn_timer = wave_spawn_interval
	else:
		var crowd_target := int(minf(3000.0, 350.0 + sandbox_elapsed * 3.0))
		if enemy_units.size() < crowd_target:
			_spawn_enemy_from_wave_data(current_wave_data)
		wave_spawn_timer = wave_spawn_interval


func _handle_campaign_wave_clear() -> void:
	if mode != "campaign":
		return
	if enemy_core_hp > 0.0:
		return
	_clear_enemy_units()
	_start_campaign_wave(current_wave + 1)


func _handle_passive_income(delta: float) -> void:
	var auto_gold := upgrades.get_auto_gold_per_second()
	if auto_gold > 0.0:
		add_gold(auto_gold * delta)


func _handle_auto_recruitment(delta: float) -> void:
	var tent_level := upgrades.get_recruitment_tent_level()
	if tent_level <= 0:
		return

	auto_recruit_timer += delta
	while auto_recruit_timer >= 5.0:
		auto_recruit_timer -= 5.0
		for _idx in range(tent_level):
			if get_total_active_units() >= Balance.ENGINE_UNIT_LIMIT:
				return
			_try_recruit("lancer", true, false)


func _spawn_enemy_from_wave_data(data: Dictionary) -> bool:
	if get_total_active_units() >= Balance.ENGINE_UNIT_LIMIT:
		return false

	var enemy = ENEMY_UNIT_SCRIPT.new()
	enemy.position = Balance.ENEMY_SPAWN_POINT + Vector2(randf_range(-18.0, 0.0), randf_range(-80.0, 80.0))
	enemy.setup(
		{
			"max_hp": float(data.get("enemy_max_hp", 10.0)),
			"damage": float(data.get("enemy_damage", 2.0)),
			"move_speed": float(data.get("enemy_speed", 60.0)),
			"attack_range": float(data.get("enemy_attack_range", 20.0)),
			"attack_cooldown": float(data.get("enemy_attack_cooldown", 1.0)),
			"gold_reward": float(data.get("enemy_gold_reward", Balance.BASE_KILL_GOLD))
		},
		self
	)
	enemy_units_root.add_child(enemy)
	enemy_units.append(enemy)
	return true


func _try_recruit(kind: String, free_spawn: bool = false, refresh_ui: bool = true) -> void:
	if not _is_unit_unlocked(kind):
		return
	if get_total_active_units() >= Balance.ENGINE_UNIT_LIMIT:
		return

	var cost := 0
	if not free_spawn:
		cost = _get_recruit_cost(kind)
		if gold < float(cost):
			return
		gold -= float(cost)

	recruit_counts[kind] = int(recruit_counts.get(kind, 0)) + 1
	var unit = PLAYER_UNIT_SCRIPT.new()
	unit.position = Balance.RALLY_POINT + Vector2(randf_range(0.0, 18.0), randf_range(-70.0, 70.0))
	unit.setup(_build_player_stats(kind), self)
	player_units_root.add_child(unit)
	player_units.append(unit)

	if refresh_ui:
		_update_ui(false)


func _build_player_stats(kind: String) -> Dictionary:
	var base: Dictionary = Balance.UNIT_DEFS.get(kind, {})
	var base_damage := float(base.get("base_damage", 1.0))
	var base_hp := float(base.get("base_hp", 10.0))
	var base_speed := float(base.get("base_speed", 75.0))
	var renown_multiplier: float = float(state.get_renown_multiplier())
	var total_damage: float = (base_damage + upgrades.get_damage_add()) * renown_multiplier
	var total_hp := maxf(1.0, base_hp + upgrades.get_health_add())
	var total_speed := maxf(1.0, base_speed + upgrades.get_speed_add())

	return {
		"unit_kind": kind,
		"damage": total_damage,
		"max_hp": total_hp,
		"move_speed": total_speed,
		"attack_range": float(base.get("attack_range", 24.0)),
		"attack_cooldown": float(base.get("attack_cooldown", 0.8)),
		"is_ranged": bool(base.get("is_ranged", false)),
		"projectile_speed": float(base.get("projectile_speed", 0.0))
	}


func _refresh_all_player_unit_stats() -> void:
	for unit in player_units:
		if not is_instance_valid(unit):
			continue
		unit.refresh_stats(_build_player_stats(unit.unit_kind), true)


func _get_recruit_cost(kind: String) -> int:
	var def: Dictionary = Balance.UNIT_DEFS.get(kind, {})
	if def.is_empty():
		return 0
	return Economy.scaled_cost(
		float(def.get("base_cost", 0.0)),
		float(def.get("cost_scaling", 1.0)),
		int(recruit_counts.get(kind, 0))
	)


func _is_unit_unlocked(kind: String) -> bool:
	var def: Dictionary = Balance.UNIT_DEFS.get(kind, {})
	var unlock_wave: int = int(def.get("unlock_wave", 1))
	var effective_wave: int = maxi(current_wave, state.max_wave_reached)
	return effective_wave >= unlock_wave


func _try_buy_individual_upgrade(key: String) -> void:
	var cost := upgrades.get_individual_cost(key)
	if gold < float(cost):
		return
	gold -= float(cost)
	upgrades.buy_individual(key)
	_refresh_all_player_unit_stats()
	_update_ui(false)


func _try_buy_global_upgrade(key: String) -> void:
	var cost := upgrades.get_global_cost(key)
	if gold < float(cost):
		return
	gold -= float(cost)
	upgrades.buy_global(key)
	if key == "unit_damage_global" or key == "unit_health_global":
		_refresh_all_player_unit_stats()
	_update_ui(false)


func _can_claim_glory() -> bool:
	return current_wave >= Balance.PRESTIGE_REQUIRED_WAVE or gold >= Balance.PRESTIGE_REQUIRED_GOLD


func _reset_run_after_prestige() -> void:
	gold = 100.0
	recruit_counts = {
		"lancer": 0,
		"archer": 0,
		"knight": 0
	}
	upgrades.reset()
	auto_recruit_timer = 0.0
	sandbox_elapsed = 0.0
	_clear_all_units()


func _clear_enemy_units() -> void:
	for enemy in enemy_units:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemy_units.clear()


func _clear_all_units() -> void:
	for unit in player_units:
		if is_instance_valid(unit):
			unit.queue_free()
	for enemy in enemy_units:
		if is_instance_valid(enemy):
			enemy.queue_free()
	for projectile in projectiles:
		if is_instance_valid(projectile):
			projectile.queue_free()
	player_units.clear()
	enemy_units.clear()
	projectiles.clear()


func _prune_dead_references() -> void:
	var live_players: Array = []
	for unit in player_units:
		if is_instance_valid(unit):
			live_players.append(unit)
	player_units = live_players

	var live_enemies: Array = []
	for enemy in enemy_units:
		if is_instance_valid(enemy):
			live_enemies.append(enemy)
	enemy_units = live_enemies

	var live_projectiles: Array = []
	for projectile in projectiles:
		if is_instance_valid(projectile):
			live_projectiles.append(projectile)
	projectiles = live_projectiles


func add_gold(raw_amount: float) -> void:
	gold += raw_amount * state.get_renown_multiplier()


func damage_enemy_core(amount: float) -> void:
	if mode != "campaign":
		return
	enemy_core_hp = maxf(0.0, enemy_core_hp - amount)
	if enemy_core_max_hp > 0.0:
		var lerp_t := enemy_core_hp / enemy_core_max_hp
		enemy_core_rect.color = Color(0.5 + 0.35 * lerp_t, 0.1 + 0.05 * lerp_t, 0.1 + 0.05 * lerp_t)


func spawn_projectile(start_pos: Vector2, target: Node2D, damage: float, speed: float, from_player: bool) -> void:
	if target == null or not is_instance_valid(target) or speed <= 0.0:
		return
	var projectile = PROJECTILE_SCRIPT.new()
	projectile.setup(start_pos, target, damage, speed, from_player, self)
	projectiles_root.add_child(projectile)
	projectiles.append(projectile)


func on_player_unit_died(unit: Node) -> void:
	player_units.erase(unit)


func on_enemy_unit_died(unit: Node, base_reward: float) -> void:
	enemy_units.erase(unit)
	if base_reward > 0.0:
		add_gold(base_reward * upgrades.get_gold_reward_multiplier())


func get_nearest_enemy(from_pos: Vector2, range_limit: float):
	var nearest = null
	var best_dist_sq := range_limit * range_limit
	for enemy in enemy_units:
		if not is_instance_valid(enemy):
			continue
		var dist_sq := from_pos.distance_squared_to(enemy.position)
		if dist_sq <= best_dist_sq:
			best_dist_sq = dist_sq
			nearest = enemy
	return nearest


func get_nearest_player(from_pos: Vector2, range_limit: float):
	var nearest = null
	var best_dist_sq := range_limit * range_limit
	for unit in player_units:
		if not is_instance_valid(unit):
			continue
		var dist_sq := from_pos.distance_squared_to(unit.position)
		if dist_sq <= best_dist_sq:
			best_dist_sq = dist_sq
			nearest = unit
	return nearest


func get_core_target_position() -> Vector2:
	return Balance.CORE_POSITION + Vector2(6.0, Balance.CORE_SIZE.y * 0.5)


func get_player_push(unit: Node2D) -> Vector2:
	return _compute_push_vector(unit, player_units, 13.0, 70)


func get_enemy_push(unit: Node2D) -> Vector2:
	return _compute_push_vector(unit, enemy_units, 13.0, 70)


func _compute_push_vector(unit: Node2D, units: Array, min_dist: float, max_checks: int) -> Vector2:
	var size := units.size()
	if size <= 1:
		return Vector2.ZERO

	var push := Vector2.ZERO
	var step := maxi(1, int(ceil(float(size) / float(max_checks))))
	for idx in range(0, size, step):
		var other: Node2D = units[idx]
		if other == unit or not is_instance_valid(other):
			continue
		var diff := unit.position - other.position
		var dist := diff.length()
		if dist > 0.001 and dist < min_dist:
			push += (diff / dist) * (min_dist - dist) * 26.0
	return push


func get_total_active_units() -> int:
	return player_units.size() + enemy_units.size()


func _update_ui(_force: bool) -> void:
	var unit_total := get_total_active_units()
	var gold_text := Economy.format_short(gold)
	gold_label.text = "Gold: %s" % gold_text
	unit_count_label.text = "Units: %s / %s" % [_format_int(unit_total), _format_int(Balance.ENGINE_UNIT_LIMIT)]

	if mode == "campaign":
		wave_label.text = "Wave %d - %s" % [current_wave, wave_name]
		wave_progress.value = (enemy_core_hp / maxf(1.0, enemy_core_max_hp)) * 100.0
	else:
		var stage := int(current_wave_data.get("wave", 1))
		wave_label.text = "Sandbox Stage %d" % stage
		var target := maxf(1.0, minf(3000.0, 350.0 + sandbox_elapsed * 3.0))
		wave_progress.value = minf(100.0, float(enemy_units.size()) / target * 100.0)

	_update_units_tab_ui()
	_update_individual_tab_ui()
	_update_global_tab_ui()
	_update_prestige_tab_ui()


func _update_units_tab_ui() -> void:
	var lancer_cost := _get_recruit_cost("lancer")
	var archer_cost := _get_recruit_cost("archer")
	var knight_cost := _get_recruit_cost("knight")
	var active_cap_reached := get_total_active_units() >= Balance.ENGINE_UNIT_LIMIT

	army_summary_label.text = "Army: %d active | Lancer %d | Archer %d | Knight %d" % [
		player_units.size(),
		int(recruit_counts.get("lancer", 0)),
		int(recruit_counts.get("archer", 0)),
		int(recruit_counts.get("knight", 0))
	]

	recruit_lancer_button.text = "Recruit Lancer (%s)" % Economy.format_short(lancer_cost)
	recruit_archer_button.text = "Recruit Archer (%s)" % Economy.format_short(archer_cost)

	var knight_unlocked := _is_unit_unlocked("knight")
	if knight_unlocked:
		recruit_knight_button.text = "Recruit Knight (%s)" % Economy.format_short(knight_cost)
	else:
		recruit_knight_button.text = "Recruit Knight (Unlock at Wave 10)"

	recruit_lancer_button.disabled = active_cap_reached or gold < float(lancer_cost)
	recruit_archer_button.disabled = active_cap_reached or gold < float(archer_cost)
	recruit_knight_button.disabled = active_cap_reached or not knight_unlocked or gold < float(knight_cost)


func _update_individual_tab_ui() -> void:
	var blades_level := int(upgrades.individual_levels.get("sharpen_blades", 0))
	var armor_level := int(upgrades.individual_levels.get("plate_armor", 0))
	var drill_level := int(upgrades.individual_levels.get("marching_drill", 0))

	var blades_cost := upgrades.get_individual_cost("sharpen_blades")
	var armor_cost := upgrades.get_individual_cost("plate_armor")
	var drill_cost := upgrades.get_individual_cost("marching_drill")

	sharpen_blades_button.text = "Sharpen Blades Lv.%d (%s)  [Damage +1]" % [blades_level, Economy.format_short(blades_cost)]
	plate_armor_button.text = "Plate Armor Lv.%d (%s)  [Health +10]" % [armor_level, Economy.format_short(armor_cost)]
	marching_drill_button.text = "Marching Drill Lv.%d (%s)  [Speed +8]" % [drill_level, Economy.format_short(drill_cost)]

	sharpen_blades_button.disabled = gold < float(blades_cost)
	plate_armor_button.disabled = gold < float(armor_cost)
	marching_drill_button.disabled = gold < float(drill_cost)


func _update_global_tab_ui() -> void:
	var auto_gold_level := int(upgrades.global_levels.get("auto_gold", 0))
	var tent_level := int(upgrades.global_levels.get("recruitment_tent", 0))
	var multiplier_level := int(upgrades.global_levels.get("gold_multiplier", 0))
	var dmg_level := int(upgrades.global_levels.get("unit_damage_global", 0))
	var hp_level := int(upgrades.global_levels.get("unit_health_global", 0))

	var auto_gold_cost := upgrades.get_global_cost("auto_gold")
	var tent_cost := upgrades.get_global_cost("recruitment_tent")
	var multiplier_cost := upgrades.get_global_cost("gold_multiplier")
	var dmg_cost := upgrades.get_global_cost("unit_damage_global")
	var hp_cost := upgrades.get_global_cost("unit_health_global")

	auto_clicker_button.text = "Auto-Clicker Lv.%d (%s)  [+5 Gold/sec]" % [auto_gold_level, Economy.format_short(auto_gold_cost)]
	recruitment_tent_button.text = "Recruitment Tent Lv.%d (%s)  [Auto Lancer / 5s]" % [tent_level, Economy.format_short(tent_cost)]
	gold_multiplier_button.text = "Gold Multiplier Lv.%d (%s)  [Kill Gold x2]" % [multiplier_level, Economy.format_short(multiplier_cost)]
	unit_damage_global_button.text = "Unit Damage Lv.%d (%s)  [+1 All Damage]" % [dmg_level, Economy.format_short(dmg_cost)]
	unit_health_global_button.text = "Unit Health Lv.%d (%s)  [+5 All HP]" % [hp_level, Economy.format_short(hp_cost)]

	auto_clicker_button.disabled = gold < float(auto_gold_cost)
	recruitment_tent_button.disabled = gold < float(tent_cost)
	gold_multiplier_button.disabled = gold < float(multiplier_cost)
	unit_damage_global_button.disabled = gold < float(dmg_cost)
	unit_health_global_button.disabled = gold < float(hp_cost)


func _update_prestige_tab_ui() -> void:
	var requirement_text := "Requirement: Reach Wave %d or %s Gold" % [Balance.PRESTIGE_REQUIRED_WAVE, Economy.format_short(Balance.PRESTIGE_REQUIRED_GOLD)]
	prestige_info_label.text = "%s\nCurrent: Wave %d, Gold %s" % [requirement_text, current_wave, Economy.format_short(gold)]

	var projected_gain := Economy.calculate_prestige_gain(max(current_wave, state.max_wave_reached), gold)
	claim_glory_button.text = "Claim Glory (+%d Renown)" % projected_gain
	claim_glory_button.disabled = not _can_claim_glory()

	var bonus_percent := int(round((state.get_renown_multiplier() - 1.0) * 100.0))
	renown_bonus_label.text = "Permanent Bonus: +%d%% Gold & Damage" % bonus_percent


func _format_int(value: int) -> String:
	var source := str(value)
	var out := ""
	var digits := 0
	for i in range(source.length() - 1, -1, -1):
		out = source.substr(i, 1) + out
		digits += 1
		if digits % 3 == 0 and i > 0:
			out = "," + out
	return out


func _on_recruit_lancer_pressed() -> void:
	_try_recruit("lancer")


func _on_recruit_archer_pressed() -> void:
	_try_recruit("archer")


func _on_recruit_knight_pressed() -> void:
	_try_recruit("knight")


func _on_sharpen_blades_pressed() -> void:
	_try_buy_individual_upgrade("sharpen_blades")


func _on_plate_armor_pressed() -> void:
	_try_buy_individual_upgrade("plate_armor")


func _on_marching_drill_pressed() -> void:
	_try_buy_individual_upgrade("marching_drill")


func _on_auto_clicker_pressed() -> void:
	_try_buy_global_upgrade("auto_gold")


func _on_recruitment_tent_pressed() -> void:
	_try_buy_global_upgrade("recruitment_tent")


func _on_gold_multiplier_pressed() -> void:
	_try_buy_global_upgrade("gold_multiplier")


func _on_unit_damage_global_pressed() -> void:
	_try_buy_global_upgrade("unit_damage_global")


func _on_unit_health_global_pressed() -> void:
	_try_buy_global_upgrade("unit_health_global")


func _on_claim_glory_pressed() -> void:
	if not _can_claim_glory():
		return

	var renown_gain := Economy.calculate_prestige_gain(max(current_wave, state.max_wave_reached), gold)
	state.grant_prestige(renown_gain)
	_reset_run_after_prestige()
	mode = "campaign"
	state.set_pending_mode("campaign")
	_start_campaign_wave(1)
	_update_ui(true)


func _on_back_to_menu_pressed() -> void:
	state.register_gold(gold)
	state.save()
	get_tree().change_scene_to_file("res://game/scenes/main_menu.tscn")
