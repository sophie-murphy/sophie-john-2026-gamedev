extends CanvasLayer

class_name InventorySystem

signal inventory_changed
signal weight_changed(current_weight: float, max_weight: float)
signal inventory_full(item_name: String, quantity: int)

@onready var items_text: RichTextLabel = $Panel/Items
@onready var item_box: VBoxContainer = $Panel/ItemsUI
@export var max_weight: float = 50.0

var item_database: Dictionary = {}
var items: Array[Dictionary] = [] 
var current_weight: float = 0.0
const ITEMS = "res://scripts/data/items.json"

func _ready() -> void:
	# 1. Load the item database from JSON
	_load_database(ITEMS)
	
	# Connect signals for demonstration
	weight_changed.connect(func(cur, max_w): 
		print("Weight: %.1f / %.1f kg" % [cur, max_w])
	)
	inventory_full.connect(func(item_name, qty): 
		print("Over encumbered! Cannot carry %d x %s." % [qty, item_name])
	)
	
	# Automatically update the UI whenever the inventory changes
	inventory_changed.connect(_update_ui)

	# Run a self-contained test
	print("--- Initializing Inventory Test ---")
	add_item("iron_ore", 8) 
	add_item("health_potion", 3)
	add_item("feather", 5)
	
	# Simulate using an item in code
	use_item("health_potion")
	
	_update_ui()

# --- JSON Database Loading ---
func _load_database(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("Item database not found at %s!" % path)
		return
		
	var file := FileAccess.open(path, FileAccess.READ)
	var json_string := file.get_as_text()
	var parsed_data = JSON.parse_string(json_string)
	
	if parsed_data != null:
		item_database = parsed_data
	else:
		push_error("Failed to parse items.json")
# -----------------------------

func _update_ui() -> void:
	if items_text:
		items_text.text = "Weight: %.1f / %.1f kg\n" % [current_weight, max_weight]
		items_text.text += "------------------------\n"
		if items.is_empty():
			items_text.text += "Inventory is empty."
			
	if not item_box:
		return
		
	# Clear the old interactive UI elements
	for child in item_box.get_children():
		child.queue_free()

	for entry in items:
		var hbox = HBoxContainer.new()
		
		var item_label = Label.new()
		item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var total_stack_weight: float = entry["weight"] * entry["quantity"]
		item_label.text = "- %s x%d (%.1f kg)" % [entry["name"], entry["quantity"], total_stack_weight]
		hbox.add_child(item_label)
		
		# --- Check Properties for Usability ---
		var props = entry.get("properties", {})
		if props.has("usable") and props["usable"] == true:
			var use_btn = Button.new()
			use_btn.text = "Use"
			# Modulate color to make the Use button stand out (green)
			use_btn.modulate = Color(0.2, 0.8, 0.2)
			use_btn.pressed.connect(use_item.bind(entry["id"]))
			hbox.add_child(use_btn)
		# --------------------------------------
		
		var drop_one_btn = Button.new()
		drop_one_btn.text = "Drop 1"
		drop_one_btn.pressed.connect(remove_item.bind(entry["id"], 1))
		hbox.add_child(drop_one_btn)
		
		var drop_all_btn = Button.new()
		drop_all_btn.text = "Drop All"
		drop_all_btn.pressed.connect(remove_item.bind(entry["id"], entry["quantity"]))
		hbox.add_child(drop_all_btn)
		
		item_box.add_child(hbox)

# --- New Use Item Logic ---
func use_item(id: String) -> void:
	for entry in items:
		if entry["id"] == id:
			var props = entry.get("properties", {})
			if props.has("usable") and props["usable"]:
				# Execute property-based logic
				if props.has("heal_amount"):
					print(">>> You drank %s! Recovered %d HP." % [entry["name"], int(props["heal_amount"])])
				else:
					print(">>> You used %s!" % entry["name"])
					
				# Consume the item
				remove_item(id, 1)
				return
			else:
				print("You cannot use %s." % entry["name"])
				return
# --------------------------

func add_item(id: String, quantity: int = 1) -> bool:
	if not item_database.has(id):
		push_error("Item ID %s does not exist in the database!" % id)
		return false
		
	var base_data = item_database[id]
	var item_name: String = base_data["name"]
	var weight_per_unit: float = float(base_data["weight"])
	var max_stack: int = int(base_data["max_stack"])
	var properties: Dictionary = base_data.get("properties", {})
	
	var total_added_weight := weight_per_unit * quantity
	
	if current_weight + total_added_weight > max_weight:
		inventory_full.emit(item_name, quantity)
		return false

	for entry in items:
		if entry["id"] == id and entry["quantity"] < entry["max_stack"]:
			var space_in_stack: int = entry["max_stack"] - entry["quantity"]
			var to_add: int = mini(quantity, space_in_stack)
			
			entry["quantity"] += to_add
			quantity -= to_add
			
			if quantity <= 0:
				_recalculate_weight()
				return true

	while quantity > 0:
		var stack_amount: int = mini(quantity, max_stack)
		items.append({
			"id": id,
			"name": item_name,
			"weight": weight_per_unit,
			"max_stack": max_stack,
			"quantity": stack_amount,
			"properties": properties # Store properties with the inventory entry
		})
		quantity -= stack_amount

	_recalculate_weight()
	return true

func remove_item(id: String, quantity: int = 1) -> bool:
	for i in range(items.size() - 1, -1, -1):
		if items[i]["id"] == id:
			if items[i]["quantity"] > quantity:
				items[i]["quantity"] -= quantity
				quantity = 0
				break
			else:
				quantity -= items[i]["quantity"]
				items.remove_at(i)
				
			if quantity <= 0:
				break

	_recalculate_weight()
	return true

func _recalculate_weight() -> void:
	current_weight = 0.0
	for entry in items:
		current_weight += entry["weight"] * entry["quantity"]
	
	weight_changed.emit(current_weight, max_weight)
	inventory_changed.emit()
