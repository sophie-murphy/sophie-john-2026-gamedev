extends CharacterBody2D

@export_category("Movement Speeds")
@export var walk_speed: float = 120
@export var sprint_speed: float = 400
@export var dash_speed: float = 600

@export_category("Mechanic Settings")
@export var tap_threshold: float = 0.25
@export var dash_duration: float = 0.15
@export var interact_distance: float = 20 # Distance to move the interact shape

@export_category("Stamina Settings")
@export var max_stamina: float = 100
@export var sprint_drain_rate: float = 30 # Stamina drained per second
@export var dash_cost: float = 50         # Flat stamina cost per dash
@export var stamina_regen_rate: float = 10 # Stamina recovered per second
@export var stamina_regen_delay: float = 1 # Delay before regen starts

var current_stamina: float
var time_since_stamina_drain: float = 0.0

var sprint_held_time: float = 0.0
var is_dashing: bool = false
var dash_direction: Vector2 = Vector2.ZERO
var last_facing_direction: Vector2 = Vector2.DOWN # Tracks which way to push the interact area


@onready var interact_area: Area2D = $InteractionArea
@onready var interact_shape: CollisionShape2D = $InteractionArea/CollisionShape2D

func _ready() -> void:
	current_stamina = max_stamina

func handle_interact():
	interact_shape.position = last_facing_direction * interact_distance
	
	await get_tree().physics_frame
	await get_tree().physics_frame 
	
	var overlaps = interact_area.get_overlapping_areas()
	
	for area in overlaps:
		if area.has_method("when_interacted"):
			area.when_interacted()

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			print("SPAWNING!")
			ItemMaster.spawn(self.get_parent(),get_local_mouse_position(),"feather",1)

func _physics_process(delta: float) -> void:
	
	if is_dashing:
		velocity = dash_direction * dash_speed
		move_and_slide()
		return
		
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var current_speed := walk_speed
	var drained_stamina_this_frame := false
	
	# Track facing direction so the interact area knows where to go
	if input_dir != Vector2.ZERO:
		last_facing_direction = input_dir.normalized()
	
	if Input.is_action_just_pressed("sprint"):
		sprint_held_time = 0.0
	
	if Input.is_action_just_pressed("interact"):
		handle_interact() # Fixed typo here[cite: 1]
	
		
	if Input.is_action_pressed("sprint"):
		sprint_held_time += delta
		# Only sprint if we've held the button long enough, have stamina, and are moving
		if sprint_held_time >= tap_threshold and current_stamina > 0 and input_dir != Vector2.ZERO:
			current_speed = sprint_speed
			current_stamina = max(0.0, current_stamina - (sprint_drain_rate * delta))
			drained_stamina_this_frame = true
			
	if Input.is_action_just_released("sprint"):
		if sprint_held_time < tap_threshold and input_dir != Vector2.ZERO:
			if current_stamina >= dash_cost:
				_start_dash(input_dir)
				
	# Handle Stamina Regeneration
	if not drained_stamina_this_frame:
		time_since_stamina_drain += delta
		if time_since_stamina_drain >= stamina_regen_delay:
			current_stamina = min(max_stamina, current_stamina + (stamina_regen_rate * delta))
	else:
		time_since_stamina_drain = 0.0
			
	if input_dir != Vector2.ZERO:
		velocity = input_dir * current_speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, walk_speed * 10 * delta)
		
	move_and_slide()

func _start_dash(dir: Vector2) -> void:
	is_dashing = true
	dash_direction = dir
	
	# Apply dash cost and reset the regen delay timer
	current_stamina = max(0.0, current_stamina - dash_cost)
	time_since_stamina_drain = 0.0
	
	await get_tree().create_timer(dash_duration).timeout
	
	is_dashing = false
