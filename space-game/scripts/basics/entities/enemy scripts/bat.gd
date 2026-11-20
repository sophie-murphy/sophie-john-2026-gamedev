extends EnemyBehavior

func _on_setup() -> void:
	current_state = State.WANDER
	set_detection_radius(30)

func process_behavior(delta: float) -> void:
	tick_timers(delta)
	
	match current_state:
		State.WANDER:
			wander(0.8)
			if has_target():
				current_state = State.CHASE
				
		State.CHASE:
			# Dive-bomb the player
			chase(1.5) 
			
			# Once it makes contact (or gets extremely close), bounce away
			if get_distance_to_target() < 20.0:
				current_state = State.FLEE
				state_timer = 1.5 # Retreat for 1.5 seconds
				
		State.FLEE:
			# Retreat much faster than it approached
			flee(2.5) 
			
			if state_timer <= 0:
				current_state = State.CHASE # Go in for another strike
