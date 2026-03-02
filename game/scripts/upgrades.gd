extends RefCounted
class_name Upgrades

const BalanceData = preload("res://game/data/balance.gd")
const EconomyUtil = preload("res://game/scripts/economy.gd")

var individual_levels := {
	"sharpen_blades": 0,
	"plate_armor": 0,
	"marching_drill": 0
}

var global_levels := {
	"auto_gold": 0,
	"recruitment_tent": 0,
	"gold_multiplier": 0,
	"unit_damage_global": 0,
	"unit_health_global": 0
}


func reset() -> void:
	for key in individual_levels.keys():
		individual_levels[key] = 0
	for key in global_levels.keys():
		global_levels[key] = 0


func get_individual_cost(key: String) -> int:
	var def: Dictionary = BalanceData.INDIVIDUAL_UPGRADE_DEFS.get(key, {})
	if def.is_empty():
		return 0
	return EconomyUtil.scaled_cost(float(def.get("base_cost", 0.0)), float(def.get("scaling", 1.0)), int(individual_levels.get(key, 0)))


func get_global_cost(key: String) -> int:
	var def: Dictionary = BalanceData.GLOBAL_UPGRADE_DEFS.get(key, {})
	if def.is_empty():
		return 0
	return EconomyUtil.scaled_cost(float(def.get("base_cost", 0.0)), float(def.get("scaling", 1.0)), int(global_levels.get(key, 0)))


func buy_individual(key: String) -> void:
	individual_levels[key] = int(individual_levels.get(key, 0)) + 1


func buy_global(key: String) -> void:
	global_levels[key] = int(global_levels.get(key, 0)) + 1


func get_damage_add() -> float:
	var blades_level := int(individual_levels.get("sharpen_blades", 0))
	var global_damage_level := int(global_levels.get("unit_damage_global", 0))
	return float(blades_level + global_damage_level)


func get_health_add() -> float:
	var armor_level := int(individual_levels.get("plate_armor", 0))
	var global_health_level := int(global_levels.get("unit_health_global", 0))
	return float(armor_level * 10 + global_health_level * 5)


func get_speed_add() -> float:
	return float(int(individual_levels.get("marching_drill", 0)) * 8)


func get_auto_gold_per_second() -> float:
	return float(int(global_levels.get("auto_gold", 0)) * 5)


func get_recruitment_tent_level() -> int:
	return int(global_levels.get("recruitment_tent", 0))


func get_gold_reward_multiplier() -> float:
	return pow(2.0, int(global_levels.get("gold_multiplier", 0)))
