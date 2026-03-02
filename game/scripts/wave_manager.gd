extends RefCounted
class_name WaveManager


static func get_campaign_wave_data(wave: int) -> Dictionary:
	var difficulty := maxf(1.0, float(wave))
	return {
		"wave": wave,
		"name": Balance.get_wave_name(wave),
		"enemy_count": 8 + wave * 3,
		"enemy_max_hp": 8.0 + difficulty * 2.4,
		"enemy_damage": 1.2 + difficulty * 0.22,
		"enemy_speed": 52.0 + minf(difficulty * 1.3, 40.0),
		"enemy_attack_range": 20.0,
		"enemy_attack_cooldown": maxf(0.45, 1.0 - difficulty * 0.004),
		"enemy_gold_reward": Balance.BASE_KILL_GOLD + difficulty * 0.6,
		"spawn_interval": maxf(0.12, 0.9 - difficulty * 0.012),
		"core_max_hp": 120.0 + difficulty * 45.0
	}


static func get_sandbox_wave_data(elapsed_seconds: float) -> Dictionary:
	var stage := int(floor(elapsed_seconds / 20.0)) + 1
	return {
		"wave": stage,
		"name": "Sandbox",
		"enemy_count": 9999999, # effectively endless
		"enemy_max_hp": 10.0 + float(stage) * 1.8,
		"enemy_damage": 1.0 + float(stage) * 0.15,
		"enemy_speed": 58.0 + minf(float(stage) * 0.8, 28.0),
		"enemy_attack_range": 20.0,
		"enemy_attack_cooldown": maxf(0.5, 1.0 - float(stage) * 0.003),
		"enemy_gold_reward": Balance.BASE_KILL_GOLD + float(stage) * 0.5,
		"spawn_interval": maxf(0.08, 0.4 - float(stage) * 0.005),
		"core_max_hp": 9999999.0
	}
