extends Node2D
class_name EnemyUnit

var battle: Node = null
var max_hp: float = 12.0
var hp: float = 12.0
var damage: float = 2.0
var move_speed: float = 62.0
var attack_range: float = 22.0
var attack_cooldown: float = 1.0
var gold_reward: float = 5.0

var _cooldown_left: float = 0.0


func setup(stats: Dictionary, battle_ref: Node) -> void:
	max_hp = float(stats.get("max_hp", 12.0))
	hp = max_hp
	damage = float(stats.get("damage", 2.0))
	move_speed = float(stats.get("move_speed", 62.0))
	attack_range = float(stats.get("attack_range", 22.0))
	attack_cooldown = float(stats.get("attack_cooldown", 1.0))
	gold_reward = float(stats.get("gold_reward", 5.0))
	battle = battle_ref
	add_to_group("enemy_unit")
	queue_redraw()


func _process(delta: float) -> void:
	if battle == null:
		return
	if hp <= 0.0:
		_die(true)
		return

	_cooldown_left = maxf(0.0, _cooldown_left - delta)
	position += battle.get_enemy_push(self) * delta

	var target = battle.get_nearest_player(position)
	if target == null:
		return

	if position.distance_to(target.position) > attack_range * 0.8:
		position = position.move_toward(target.position, move_speed * delta)
		position.y = clampf(position.y, 20.0, 430.0)
	_try_attack(target)


func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		_die(true)


func _try_attack(target: Node2D) -> void:
	if _cooldown_left > 0.0:
		return
	_cooldown_left = attack_cooldown
	if target.has_method("take_damage"):
		target.take_damage(damage)


func _die(grant_gold: bool) -> void:
	if battle != null:
		battle.on_enemy_unit_died(self, gold_reward if grant_gold else 0.0)
	queue_free()


func _draw() -> void:
	draw_rect(Rect2(Vector2(-9.0, -9.0), Vector2(18.0, 18.0)), Color(0.95, 0.25, 0.25))
	var hp_ratio := 0.0 if max_hp <= 0.0 else clampf(hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(Vector2(-9.0, -13.0), Vector2(18.0, 3.0)), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(Vector2(-9.0, -13.0), Vector2(18.0 * hp_ratio, 3.0)), Color(1.0, 0.55, 0.55))
