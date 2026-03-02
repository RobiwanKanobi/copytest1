extends Node

const SAVE_PATH := "user://save_game.json"
const BalanceData = preload("res://game/data/balance.gd")

var max_wave_reached: int = 1
var high_gold: float = 0.0
var renown_points: int = 0
var has_prestiged_once: bool = false
var fps_limit: int = 120
var pending_mode: String = "campaign"


func _ready() -> void:
	load_save()
	_apply_fps_limit()


func register_wave(wave: int) -> void:
	if wave > max_wave_reached:
		max_wave_reached = wave
		save()


func register_gold(gold: float) -> void:
	if gold > high_gold:
		high_gold = gold
		save()


func set_pending_mode(mode: String) -> void:
	pending_mode = mode


func set_fps_limit(value: int) -> void:
	fps_limit = clampi(value, 30, 240)
	_apply_fps_limit()
	save()


func get_renown_multiplier() -> float:
	return 1.0 + float(renown_points) * BalanceData.RENOWN_BONUS_PER_POINT


func grant_prestige(renown_gain: int) -> void:
	renown_points += maxi(1, renown_gain)
	has_prestiged_once = true
	save()


func save() -> void:
	var payload := {
		"max_wave_reached": max_wave_reached,
		"high_gold": high_gold,
		"renown_points": renown_points,
		"has_prestiged_once": has_prestiged_once,
		"fps_limit": fps_limit
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(payload))


func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	if text.is_empty():
		return
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	max_wave_reached = int(parsed.get("max_wave_reached", 1))
	high_gold = float(parsed.get("high_gold", 0.0))
	renown_points = int(parsed.get("renown_points", 0))
	has_prestiged_once = bool(parsed.get("has_prestiged_once", false))
	fps_limit = int(parsed.get("fps_limit", 120))


func _apply_fps_limit() -> void:
	Engine.max_fps = fps_limit
