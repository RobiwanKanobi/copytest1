extends SceneTree

const WaveManager = preload("res://game/scripts/wave_manager.gd")


func _initialize() -> void:
	var wave_one: Dictionary = WaveManager.get_campaign_wave_data(1)
	var enemy_count: int = int(wave_one.get("enemy_count", -1))
	print("Wave config smoke: wave1_enemy_count=%d" % enemy_count)

	if enemy_count != 2:
		push_error("Wave config smoke failed: expected wave 1 enemy count to be 2")
		quit(1)
		return

	quit(0)
