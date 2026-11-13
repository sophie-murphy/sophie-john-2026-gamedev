class_name EnemyBehavior
extends Node

var body: EnemyBase 

# -----------------------------------------------------------------------------
# 1. State & Modifiers
# -------------------------------------F----------------------------------------
enum State { IDLE, WANDER, CHASE, ATTACK, FLEE, STUNNED, DASHING, STRAFING }
var current_state: State = State.IDLE

var state_timer: float = 0.0
var attack_cooldown: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO

# Dynamic modifiers that let you tweak stats on the fly without changing the base JSON
var speed_modifier: float = 1.0 
var damage_modifier: float = 1.0

# -----------------------------------------------------------------------------
# 2. Setup & Core Loop
# -----------------------------------------------------------------------------
func setup(enemy_node: EnemyBase) -> void:
	body = enemy_node
	_on_setup()

func _on_setup() -> void:
	pass

func process_behavior(delta: float) -> void:
	pass

func tick_timers(delta: float) -> void:
	if state_timer > 0: state_timer -= delta
	if attack_cooldown > 0: attack_cooldown -= delta

# -----------------------------------------------------------------------------
# 3. Dynamic Stat & Shape Manipulation
# -----------------------------------------------------------------------------

# Changes how far the enemy can see on the fly (updates the physical collision shape)[cite: 1]
func set_detection_radius(radius: float) -> void:
	body.detection_shape.radius = radius

# Temporarily overrides the walk_speed loaded from the JSON[cite: 1, 3]
func override_base_speed(new_speed: float) -> void:
	body.walk_speed = new_speed

# Modifies the attack damage loaded from the JSON[cite: 1, 3]
func get_calculated_damage() -> float:
	return body.attack_damage * damage_modifier

# Reads the health values inherited from EntityBase[cite: 1, 2]
func get_health_percent() -> float:
	if body.max_health <= 0: return 0.0
	return body.current_health / body.max_health

# -----------------------------------------------------------------------------
# 4. Advanced Target & Math Helpers
# -----------------------------------------------------------------------------
func has_target() -> bool:
	return body.target != null

func get_distance_to_target() -> float:
	if body.target:
		return body.global_position.distance_to(body.target.global_position)
	return 9999.0

func get_direction_to_target() -> Vector2:
	if body.target:
		return (body.target.global_position - body.global_position).normalized()
	return Vector2.ZERO

func chase(local_speed_multi: float = 1.0) -> void:
	if has_target():
		body.velocity = get_direction_to_target() * (body.walk_speed * speed_modifier * local_speed_multi)

func flee(local_speed_multi: float = 1.0) -> void:
	if has_target():
		# Moves in the exact opposite direction of the target
		body.velocity = -get_direction_to_target() * (body.walk_speed * speed_modifier * local_speed_multi)

func strafe(local_speed_multi: float = 1.0, clockwise: bool = true) -> void:
	if has_target():
		# Rotates the direction vector by 90 degrees to walk in a circle around the target
		var dir = get_direction_to_target()
		var strafe_dir = Vector2(-dir.y, dir.x) if clockwise else Vector2(dir.y, -dir.x)
		body.velocity = strafe_dir * (body.walk_speed * speed_modifier * local_speed_multi)

func wander(local_speed_multi: float = 0.5) -> void:
	if state_timer <= 0:
		wander_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		state_timer = randf_range(1.5, 3.0)
	body.velocity = wander_direction * (body.walk_speed * speed_modifier * local_speed_multi)

func apply_friction(delta: float, friction: float = 10.0) -> void:
	body.velocity = body.velocity.move_toward(Vector2.ZERO, body.walk_speed * friction * delta)
