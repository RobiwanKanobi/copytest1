extends Node2D
class_name PlayerUnit

var battle: Node = null
var unit_kind: String = "lancer"
var max_hp: float = 10.0
var hp: float = 10.0
var damage: float = 1.0
var move_speed: float = 80.0
var attack_range: float = 24.0
var attack_cooldown: float = 0.8
var projectile_speed: float = 0.0
var is_ranged: bool = false

var _cooldown_left: float = 0.0


func setup(stats: Dictionary, battle_ref: Node) -> void:
	battle = battle_ref
	refresh_stats(stats, false)


func refresh_stats(stats: Dictionary, preserve_ratio: bool = true) -> void:
	var hp_ratio := 1.0
	if preserve_ratio and max_hp > 0.0:
		hp_ratio = clampf(hp / max_hp, 0.0, 1.0)

	unit_kind = str(stats.get("unit_kind", unit_kind))
	max_hp = float(stats.get("max_hp", max_hp))
	damage = float(stats.get("damage", damage))
	move_speed = float(stats.get("move_speed", move_speed))
	attack_range = float(stats.get("attack_range", attack_range))
	attack_cooldown = float(stats.get("attack_cooldown", attack_cooldown))
	projectile_speed = float(stats.get("projectile_speed", projectile_speed))
	is_ranged = bool(stats.get("is_ranged", is_ranged))

	hp = max_hp if not preserve_ratio else max_hp * hp_ratio
	queue_redraw()


func _process(delta: float) -> void:
	if battle == null:
		return
	if hp <= 0.0:
		_die()
		return

	_cooldown_left = maxf(0.0, _cooldown_left - delta)
	var push := battle.get_player_push(self)
	position += push * delta

	var target: EnemyUnit = battle.get_nearest_enemy(position, attack_range)
	if target != null:
		if not is_ranged and position.distance_to(target.position) > attack_range * 0.8:
			_move_toward(target.position, delta)
		_try_attack_enemy(target)
		return

	if battle.enemy_core_hp > 0.0 and position.distance_to(battle.get_core_target_position()) <= attack_range:
		_try_attack_core()
	else:
		_move_toward(battle.get_core_target_position(), delta)


func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		_die()


func _move_toward(target_pos: Vector2, delta: float) -> void:
	position = position.move_toward(target_pos, move_speed * delta)
	position.y = clampf(position.y, 20.0, 430.0)


func _try_attack_enemy(target: EnemyUnit) -> void:
	if _cooldown_left > 0.0:
		return
	_cooldown_left = attack_cooldown
	if is_ranged:
		battle.spawn_projectile(position, target, damage, projectile_speed, true)
	else:
		target.take_damage(damage)


func _try_attack_core() -> void:
	if _cooldown_left > 0.0:
		return
	_cooldown_left = attack_cooldown
	battle.damage_enemy_core(damage)


func _die() -> void:
	if battle != null:
		battle.on_player_unit_died(self)
	queue_free()


func _draw() -> void:
	draw_rect(Rect2(Vector2(-9.0, -9.0), Vector2(18.0, 18.0)), Color(0.25, 0.55, 1.0))
	var hp_ratio := 0.0 if max_hp <= 0.0 else clampf(hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(Vector2(-9.0, -13.0), Vector2(18.0, 3.0)), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(Vector2(-9.0, -13.0), Vector2(18.0 * hp_ratio, 3.0)), Color(0.4, 1.0, 0.4))
