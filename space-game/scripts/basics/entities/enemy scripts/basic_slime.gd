extends EnemyBehavior

func _on_setup() -> void:
	current_state = State.WANDER

func process_behavior(delta: float) -> void:
	tick_timers(delta)
	
	match current_state:
		State.WANDER:
			wander(0.4) # Slowly wiggle around
			
			# If the player is detected and gets within 70 pixels, attack!
			if has_target() and get_distance_to_target() < 70.0 and attack_cooldown <= 0:
				current_state = State.DASHING
				state_timer = 0.5   # Dash duration
				attack_cooldown = 2.5 # Time before it can dash again
				
		State.DASHING:
			chase(2.5) # Lunge at 2.5x speed
			
			if state_timer <= 0:
				current_state = State.WANDER
