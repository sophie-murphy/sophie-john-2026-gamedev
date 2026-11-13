class_name EnemyBase
extends EntityBase

const ENEMY_DB_PATH = "res://scripts/data/enemies.json"

@export_category("Identity")
@export var enemy_id: String = "basic_slime"

# These stats are now standard variables populated by the JSON file
var attack_damage: float = 15.0
var drop_item_id: String = "iron_ore"
var drop_chance: float = 0.5
var detection_radius_multiplier: float = 30

@onready var enemy_sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D

var target: Node2D = null


func _ready() -> void:
	_load_enemy_data()
	
	super._ready() # Initialize health from EntityBase (uses updated max_health)
	
	# Duplicate shapes so resizing one enemy variant doesn't resize all of them[cite: 8]
	if collision_shape and collision_shape.shape:
		collision_shape.shape = collision_shape.shape.duplicate()
	if detection_shape and detection_shape.shape:
		detection_shape.shape = detection_shape.shape.duplicate()
		
	_match_collision_to_sprite()
	
	# Connect detection signals dynamically
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)


# -----------------------------------------------------------------------------
# Database Loading
# -----------------------------------------------------------------------------

func _load_enemy_data() -> void:
	if not FileAccess.file_exists(ENEMY_DB_PATH):
		push_warning("Enemy database not found at %s! Using default stats." % ENEMY_DB_PATH)
		return

	var json_string := FileAccess.get_file_as_string(ENEMY_DB_PATH)
	var db = JSON.parse_string(json_string)

	if typeof(db) == TYPE_DICTIONARY and db.has(enemy_id):
		var data: Dictionary = db[enemy_id]
		
		# Override values if they exist in the JSON
		if data.has("walk_speed"): walk_speed = float(data["walk_speed"])
		if data.has("max_health"): max_health = float(data["max_health"])
		if data.has("attack_damage"): attack_damage = float(data["attack_damage"])
		if data.has("drop_item_id"): drop_item_id = str(data["drop_item_id"])
		if data.has("drop_chance"): drop_chance = float(data["drop_chance"])
		if data.has("detection_multiplier"): detection_radius_multiplier = float(data["detection_multiplier"])
	else:
		push_warning("Enemy ID '%s' not found in database. Using default stats." % enemy_id)


# -----------------------------------------------------------------------------
# Movement & Logic
# -----------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if target:
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * walk_speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, walk_speed * 10 * delta)
		
	move_and_slide()


func die() -> void:
	if randf() <= drop_chance:
		ItemMaster.spawn(get_parent(), global_position, drop_item_id, 1) 
		
	super.die()


# -----------------------------------------------------------------------------
# Adaptive Collision Logic
# -----------------------------------------------------------------------------

func _match_collision_to_sprite() -> void:
	if not enemy_sprite or not enemy_sprite.texture:
		return
		
	var sprite_size: Vector2 = enemy_sprite.texture.get_size() * enemy_sprite.scale
	
	# 1. Match the physical body collision to the sprite[cite: 8]
	if collision_shape and collision_shape.shape:
		if collision_shape.shape is RectangleShape2D:
			collision_shape.shape.size = sprite_size
		elif collision_shape.shape is CircleShape2D:
			collision_shape.shape.radius = max(sprite_size.x, sprite_size.y) / 2.0
			
	# 2. Scale the detection area so it grows proportionately with larger enemies
	if detection_shape and detection_shape.shape:
		if detection_shape.shape is CircleShape2D:
			var base_radius = max(sprite_size.x, sprite_size.y) / 2.0
			detection_shape.shape.radius = base_radius * detection_radius_multiplier


# -----------------------------------------------------------------------------
# Player Detection Signals
# -----------------------------------------------------------------------------

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = body


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == target:
		target = null
