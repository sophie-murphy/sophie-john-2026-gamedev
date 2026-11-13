extends EnemyBehavior

var is_dashing: bool = false
var dash_timer: float = 0.0

func process_behavior(delta: float) -> void:
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
		return # Skip standard movement while dashing
		
	if body.target:
		var distance = body.global_position.distance_to(body.target.global_position)
		var direction = (body.target.global_position - body.global_position).normalized()
		
		# If the goblin gets moderately close, it lunges/dashes
		if distance < 80.0 and distance > 30.0 and randf() < 0.05:
			is_dashing = true
			dash_timer = 0.3
			body.velocity = direction * (body.walk_speed * 3.0) 
		else:
			# Normal approach
			body.velocity = direction * body.walk_speed
	else:
		body.velocity = body.velocity.move_toward(Vector2.ZERO, body.walk_speed * 10 * delta)
