class_name EnemyBase
extends EntityBase

@export_category("Identity")
@export var enemy_id: String = "basic_slime"

var attack_damage: float = 15.0
var drop_item_id: String = "iron_ore"
var drop_chance: float = 0.5

@onready var enemy_sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D

# This expects you to have a node named "Behavior" as a child of your enemy
@onready var active_behavior: EnemyBehavior = $Behavior 

var target: Node2D = null

func _ready() -> void:
	super._ready()
	
	if collision_shape and collision_shape.shape:
		collision_shape.shape = collision_shape.shape.duplicate()
	if detection_shape and detection_shape.shape:
		detection_shape.shape = detection_shape.shape.duplicate()
		
	_match_collision_to_sprite()
	
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	# Initialize the attached behavior node directly
	if active_behavior:
		active_behavior.setup(self)
	else:
		push_warning("No Behavior node found on this enemy!")

# -----------------------------------------------------------------------------
# Movement & Logic
# -----------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if active_behavior:
		active_behavior.process_behavior(delta)
	move_and_slide()

# -----------------------------------------------------------------------------
# Adaptive Collision Logic
# -----------------------------------------------------------------------------

func _match_collision_to_sprite() -> void:
	if not enemy_sprite or not enemy_sprite.texture:
		return
		
	var sprite_size: Vector2 = enemy_sprite.texture.get_size() * enemy_sprite.scale
	
	# 1. Match the physical body collision to the sprite
	if collision_shape and collision_shape.shape:
		if collision_shape.shape is RectangleShape2D:
			collision_shape.shape.size = sprite_size
		elif collision_shape.shape is CircleShape2D:
			collision_shape.shape.radius = max(sprite_size.x, sprite_size.y) / 2.0
			
	# 2. Scale the detection area so it grows proportionately with larger enemies
	if detection_shape and detection_shape.shape:
		if detection_shape.shape is CircleShape2D:
			var base_radius = max(sprite_size.x, sprite_size.y) / 2.0
			detection_shape.shape.radius = base_radius

# -----------------------------------------------------------------------------
# Player Detection Signals
# -----------------------------------------------------------------------------

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = body

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == target:
		target = null
