class_name ItemSpawner
extends Node

const ITEM_SCENE_PATH = "res://scenes/basics/common/item_base.tscn"

func spawn(parent: Node, spawn_position: Vector2, id: String, amount: int = 1) -> ItemBase:
	var scene = load(ITEM_SCENE_PATH) as PackedScene
	var new_item = scene.instantiate() as ItemBase
	
	parent.add_child(new_item)
	new_item.position = spawn_position 
	new_item.setup(id, amount)
	
	return new_item
