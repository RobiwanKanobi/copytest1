extends RefCounted
class_name Balance

const ENGINE_UNIT_LIMIT: int = 10000
const PRESTIGE_REQUIRED_WAVE: int = 50
const PRESTIGE_REQUIRED_GOLD: float = 1_000_000_000.0
const RENOWN_BONUS_PER_POINT: float = 0.10

const RALLY_POINT: Vector2 = Vector2(0, 420)
const ENEMY_SPAWN_POINT: Vector2 = Vector2(1110, 420)
const CORE_POSITION: Vector2 = Vector2(1082, 320)
const CORE_SIZE: Vector2 = Vector2(70, 120)

const UNIT_DEFS := {
	"lancer": {
		"display_name": "Lancer",
		"base_cost": 10.0,
		"cost_scaling": 1.15,
		"base_damage": 1.0,
		"base_hp": 10.0,
		"base_speed": 86.0,
		"attack_range": 24.0,
		"attack_cooldown": 0.75,
		"is_ranged": false,
		"projectile_speed": 0.0,
		"unlock_wave": 1
	},
	"archer": {
		"display_name": "Archer",
		"base_cost": 75.0,
		"cost_scaling": 1.20,
		"base_damage": 2.0,
		"base_hp": 5.0,
		"base_speed": 72.0,
		"attack_range": 160.0,
		"attack_cooldown": 1.1,
		"is_ranged": true,
		"projectile_speed": 320.0,
		"unlock_wave": 1
	},
	"knight": {
		"display_name": "Knight",
		"base_cost": 500.0,
		"cost_scaling": 1.25,
		"base_damage": 6.0,
		"base_hp": 35.0,
		"base_speed": 64.0,
		"attack_range": 30.0,
		"attack_cooldown": 0.9,
		"is_ranged": false,
		"projectile_speed": 0.0,
		"unlock_wave": 10
	}
}

const INDIVIDUAL_UPGRADE_DEFS := {
	"sharpen_blades": {
		"display_name": "Sharpen Blades",
		"description": "Damage +1 to all player units",
		"base_cost": 100.0,
		"scaling": 1.25,
		"damage_add": 1.0,
		"health_add": 0.0,
		"speed_add": 0.0
	},
	"plate_armor": {
		"display_name": "Plate Armor",
		"description": "Health +10 to all player units",
		"base_cost": 140.0,
		"scaling": 1.25,
		"damage_add": 0.0,
		"health_add": 10.0,
		"speed_add": 0.0
	},
	"marching_drill": {
		"display_name": "Marching Drill",
		"description": "Movement Speed +8 to all player units",
		"base_cost": 120.0,
		"scaling": 1.25,
		"damage_add": 0.0,
		"health_add": 0.0,
		"speed_add": 8.0
	}
}

const GLOBAL_UPGRADE_DEFS := {
	"auto_gold": {
		"display_name": "Auto-Clicker",
		"description": "+5 Gold/sec per level",
		"base_cost": 500.0,
		"scaling": 1.50,
		"gold_per_second_add": 5.0
	},
	"recruitment_tent": {
		"display_name": "Recruitment Tent",
		"description": "Auto-spawn 1 Lancer every 5 sec per level",
		"base_cost": 5000.0,
		"scaling": 1.60
	},
	"gold_multiplier": {
		"display_name": "Gold Multiplier",
		"description": "Kill rewards x2 per level",
		"base_cost": 2000.0,
		"scaling": 2.0
	},
	"unit_damage_global": {
		"display_name": "Unit Damage",
		"description": "+1 base damage to all player units",
		"base_cost": 200.0,
		"scaling": 2.0,
		"damage_add": 1.0
	},
	"unit_health_global": {
		"display_name": "Unit Health",
		"description": "+5 base HP to all player units",
		"base_cost": 150.0,
		"scaling": 1.80,
		"health_add": 5.0
	}
}

const BASE_KILL_GOLD: float = 5.0
const ENEMY_CONTACT_DAMAGE: float = 2.0
const ENEMY_ATTACK_COOLDOWN: float = 1.0
const MAX_SIMULATION_DELTA: float = 0.05

const WAVE_NAMES := [
	"Roman Outpost",
	"Iron Vanguard",
	"Siege Parade",
	"Warden Line",
	"Ashen Brigade",
	"Crimson Spear",
	"Citadel Front"
]


static func get_wave_name(wave: int) -> String:
	return WAVE_NAMES[(wave - 1) % WAVE_NAMES.size()]
