extends Control

@onready var campaign_button: Button = $CenterPanel/Layout/CampaignButton
@onready var sandbox_button: Button = $CenterPanel/Layout/SandboxButton
@onready var settings_button: Button = $CenterPanel/Layout/SettingsButton
@onready var max_wave_label: Label = $CenterPanel/Layout/MaxWaveLabel
@onready var high_score_label: Label = $CenterPanel/Layout/HighScoreLabel
@onready var renown_label: Label = $CenterPanel/Layout/RenownLabel

@onready var settings_panel: Panel = $SettingsPanel
@onready var fps_slider: HSlider = $SettingsPanel/Layout/FpsSlider
@onready var fps_value_label: Label = $SettingsPanel/Layout/FpsValueLabel
@onready var close_settings_button: Button = $SettingsPanel/Layout/CloseSettingsButton


func _ready() -> void:
	campaign_button.pressed.connect(_on_campaign_pressed)
	sandbox_button.pressed.connect(_on_sandbox_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	close_settings_button.pressed.connect(_on_close_settings_pressed)
	fps_slider.value_changed.connect(_on_fps_slider_changed)
	_refresh_ui()


func _refresh_ui() -> void:
	max_wave_label.text = "Max Wave Reached: %d" % GameState.max_wave_reached
	high_score_label.text = "High Gold: %s" % Economy.format_short(GameState.high_gold)
	renown_label.text = "Renown Points: %d" % GameState.renown_points

	sandbox_button.disabled = not GameState.has_prestiged_once
	if sandbox_button.disabled:
		sandbox_button.text = "Sandbox (Unlock after first Prestige)"
	else:
		sandbox_button.text = "Sandbox"

	fps_slider.set_value_no_signal(float(GameState.fps_limit))
	_update_fps_label()
	settings_panel.visible = false


func _on_campaign_pressed() -> void:
	GameState.set_pending_mode("campaign")
	get_tree().change_scene_to_file("res://game/scenes/battle_scene.tscn")


func _on_sandbox_pressed() -> void:
	if sandbox_button.disabled:
		return
	GameState.set_pending_mode("sandbox")
	get_tree().change_scene_to_file("res://game/scenes/battle_scene.tscn")


func _on_settings_pressed() -> void:
	settings_panel.visible = not settings_panel.visible


func _on_close_settings_pressed() -> void:
	settings_panel.visible = false


func _on_fps_slider_changed(value: float) -> void:
	GameState.set_fps_limit(int(value))
	_update_fps_label()


func _update_fps_label() -> void:
	fps_value_label.text = "FPS Limit: %d" % int(fps_slider.value)
