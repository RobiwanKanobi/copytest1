extends SceneTree

const BattleScene = preload("res://game/scenes/battle_scene.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("/root/GameState")
	state.pending_mode = "campaign"
	var battle: Node = BattleScene.instantiate()
	root.add_child(battle)

	await process_frame
	await process_frame

	var gold_before: float = float(battle.get("gold"))
	battle.call("_try_recruit", "lancer")
	await process_frame

	var active_units := 0
	var players = battle.get("player_units")
	if players is Array:
		active_units = players.size()
	print("Recruit smoke: active_units=%d gold_before=%s gold_after=%s" % [active_units, str(gold_before), str(battle.get("gold"))])

	if active_units <= 0:
		push_error("Recruit smoke test failed: no active units after recruiting")
		quit(1)
		return

	quit(0)
