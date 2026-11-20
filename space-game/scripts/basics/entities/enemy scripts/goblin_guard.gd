extends EnemyBehavior

var strafe_clockwise: bool = true

func _on_setup() -> void:
	current_state = State.IDLE
	set_detection_radius(5.0) # Wide vision cone[cite: 3]

func process_behavior(delta: float) -> void:
	tick_timers(delta)
	
	# Desperation Mode: Flee if health drops below 30%[cite: 1, 2]
	if get_health_percent() < 0.3 and current_state != State.FLEE:
		current_state = State.FLEE

	match current_state:
		State.IDLE:
			wander(0.6)
			if has_target():
				current_state = State.CHASE
				
		State.CHASE:
			chase(1.0)
			
			# Once close enough, switch to circling the player
			if get_distance_to_target() < 60.0:
				current_state = State.STRAFING
				state_timer = randf_range(1.0, 2.5) # Circle for a random duration
				strafe_clockwise = randf() > 0.5    # Pick a random direction
				
		State.STRAFING:
			strafe(0.8, strafe_clockwise) 
			
			# If the player backs away, chase them again
			if get_distance_to_target() > 80.0:
				current_state = State.CHASE
			# If the strafe timer finishes, lunge in
			elif state_timer <= 0:
				current_state = State.DASHING
				state_timer = 0.2
				
		State.DASHING:
			chase(3.0)
			if state_timer <= 0:
				current_state = State.CHASE # Reset to chase mode after strike
				
		State.FLEE:
			flee(1.5) # Run away at 1.5x speed
