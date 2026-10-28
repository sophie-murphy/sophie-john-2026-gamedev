class_name ItemBase
extends interactable

const SPRITE_DIRECTORY = "res://assets/items/" 

@onready var item_shape: CollisionShape2D = $ItemShape
@onready var item_sprite: Sprite2D = $ItemSprite

@export var item_id: String
@export var item_amount: int = 1

@export_group("Visuals")
@export var fallback_texture: Texture2D = preload("uid://c0vqy5auxtroc")

func _ready() -> void:
	if item_shape and item_shape.shape:
		item_shape.shape = item_shape.shape.duplicate()

func when_interacted() -> void:
	Inventory.add_item(item_id, item_amount)
	queue_free()

## Called by the spawner to initialize the item
func setup(id: String, amount: int) -> void:
	item_id = id
	item_amount = amount
	
	_load_and_apply_texture()
	_match_collision_to_sprite()

func _load_and_apply_texture() -> void:
	if not item_sprite:
		await ready
		
	var texture_path = SPRITE_DIRECTORY + item_id + ".png"
	var loaded_texture = load(texture_path)
	
	if loaded_texture:
		item_sprite.texture = loaded_texture
	else:
		push_warning("Could not find sprite for: " + item_id + ". Using fallback.")
		item_sprite.texture = fallback_texture

func _match_collision_to_sprite() -> void:
	if not item_sprite or not item_sprite.texture or not item_shape:
		return
		
	var sprite_size: Vector2 = item_sprite.texture.get_size() * item_sprite.scale
	
	if item_shape.shape is RectangleShape2D:
		item_shape.shape.size = sprite_size
	elif item_shape.shape is CircleShape2D:
		item_shape.shape.radius = max(sprite_size.x, sprite_size.y) / 2.0
