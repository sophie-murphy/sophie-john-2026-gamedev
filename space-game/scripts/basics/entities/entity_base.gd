class_name EntityBase
extends CharacterBody2D

@export_category("Entity Stats")
@export var walk_speed: float = 120 
@export var max_health: float = 100.0

var current_health: float

func _ready() -> void:
	current_health = max_health

func take_damage(amount: float) -> void:
	current_health -= amount
	if current_health <= 0:
		die()

func die() -> void:
	queue_free()
