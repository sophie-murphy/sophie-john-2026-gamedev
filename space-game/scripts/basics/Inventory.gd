extends CanvasLayer

class_name InventorySystem

signal inventory_changed
signal weight_changed(current_weight: float, max_weight: float)
signal inventory_full(item_name: String, quantity: int)

@onready var items_text: RichTextLabel = $Panel/Items
@onready var item_box: VBoxContainer = $Panel/ItemsUI
@export var max_weight: float = 50.0

# Stores items as dictionaries: {"id": String, "name": String, "weight": float, "max_stack": int, "quantity": int}
var items: Array[Dictionary] = [] 
var current_weight: float = 0.0

func _ready() -> void:
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
	add_item("iron_ore", "Iron Ore", 5.0, 8)  # Adds 40.0 kg -> Success
	add_item("feather", "Feather", 0.1, 20)   # Adds 2.0 kg -> Success
	add_item("iron_ore", "Iron Ore", 5.0, 3)  # Attempts to add 15.0 kg -> Fails (limit is 50.0 kg)
	
	remove_item("iron_ore", 2)                # Removes 10.0 kg
	add_item("iron_ore", "Iron Ore", 5.0, 3)  # Attempts 15.0 kg again -> Success (current weight is now 32.0 kg)
	
	# Force an initial UI update (catches anything added before the node was ready)
	_update_ui()

func _update_ui() -> void:
	# 1. Update the Header / Weight Text
	if items_text:
		items_text.text = "Weight: %.1f / %.1f kg\n" % [current_weight, max_weight]
		items_text.text += "------------------------\n"
		if items.is_empty():
			items_text.text += "Inventory is empty."
			
	# 2. Update the Interactive Item Box
	if not item_box:
		return
		
	# Clear the old interactive UI elements before drawing new ones
	for child in item_box.get_children():
		child.queue_free()

	# Generate a new row with buttons for each item stack
	for entry in items:
		var hbox = HBoxContainer.new()
		
		# Item description label
		var item_label = Label.new()
		item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL # Pushes buttons to the right
		var total_stack_weight: float = entry["weight"] * entry["quantity"]
		item_label.text = "- %s x%d (%.1f kg)" % [entry["name"], entry["quantity"], total_stack_weight]
		
		# Drop 1 Button
		var drop_one_btn = Button.new()
		drop_one_btn.text = "Drop 1"
		# Bind the specific item ID and a quantity of 1 to the remove_item function
		drop_one_btn.pressed.connect(remove_item.bind(entry["id"], 1))
		
		# Drop All Button
		var drop_all_btn = Button.new()
		drop_all_btn.text = "Drop All"
		# Bind the specific item ID and the total stack quantity to the remove_item function
		drop_all_btn.pressed.connect(remove_item.bind(entry["id"], entry["quantity"]))
		
		# Add elements to the horizontal row
		hbox.add_child(item_label)
		hbox.add_child(drop_one_btn)
		hbox.add_child(drop_all_btn)
		
		# Add the horizontal row to the vertical container
		item_box.add_child(hbox)
# ------------------------------

func add_item(id: String, item_name: String, weight_per_unit: float, quantity: int = 1, max_stack: int = 99) -> bool:
	var total_added_weight := weight_per_unit * quantity
	
	if current_weight + total_added_weight > max_weight:
		inventory_full.emit(item_name, quantity)
		return false

	# Try stacking with an existing item entry
	for entry in items:
		if entry["id"] == id and entry["quantity"] < entry["max_stack"]:
			var space_in_stack: int = entry["max_stack"] - entry["quantity"]
			var to_add: int = mini(quantity, space_in_stack)
			
			entry["quantity"] += to_add
			quantity -= to_add
			
			if quantity <= 0:
				_recalculate_weight()
				return true

	# If quantity remains, create new inventory slots
	while quantity > 0:
		var stack_amount: int = mini(quantity, max_stack)
		items.append({
			"id": id,
			"name": item_name,
			"weight": weight_per_unit,
			"max_stack": max_stack,
			"quantity": stack_amount
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
