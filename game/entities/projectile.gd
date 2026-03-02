extends Node2D
class_name Projectile

var battle: Node = null
var target: Node2D = null
var damage: float = 1.0
var speed: float = 320.0
var from_player: bool = true


func setup(start_pos: Vector2, target_node: Node2D, impact_damage: float, projectile_speed: float, player_owned: bool, battle_ref: Node) -> void:
	position = start_pos
	target = target_node
	damage = impact_damage
	speed = projectile_speed
	from_player = player_owned
	battle = battle_ref
	queue_redraw()


func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		queue_free()
		return

	position = position.move_toward(target.position, speed * delta)
	if position.distance_to(target.position) <= 7.0:
		if from_player and target is EnemyUnit:
			(target as EnemyUnit).take_damage(damage)
		elif not from_player and target is PlayerUnit:
			(target as PlayerUnit).take_damage(damage)
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.9, 0.2))
