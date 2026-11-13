extends CanvasLayer

signal inventory_changed
signal weight_changed(current_weight: float, max_weight: float)
signal inventory_full(item_name: String, quantity: int)

@onready var item_box: VBoxContainer = $Panel/ItemsUI
@onready var text: RichTextLabel = $Panel/ItemsUI/text

@export var max_weight: float = 50.0

var item_database: Dictionary = {}
var items: Array[Dictionary] = []
var current_weight: float = 0.0

const ITEMS = "res://scripts/data/items.json"


func _ready() -> void:
	print_tree_pretty()
	_load_database(ITEMS)

	weight_changed.connect(_on_weight_changed)
	inventory_full.connect(_on_inventory_full)
	inventory_changed.connect(_update_ui)

	_update_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		visible = not visible
		_update_ui()


func _on_weight_changed(cur: float, max_w: float) -> void:
	print("Weight: %.1f / %.1f kg" % [cur, max_w])


func _on_inventory_full(item_name: String, qty: int) -> void:
	print("Over encumbered! Cannot carry %d x %s." % [qty, item_name])


# -----------------------------
# DATABASE
# -----------------------------

func _load_database(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("Item database not found at %s!" % path)
		return

	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		push_error("Could not open item database!")
		return

	var json_string := file.get_as_text()
	var parsed_data = JSON.parse_string(json_string)

	if parsed_data is Dictionary:
		item_database = parsed_data
	else:
		push_error("Failed to parse items.json")


# -----------------------------
# INVENTORY UI
# -----------------------------

func _update_ui() -> void:
	if not item_box or not text:
		return

	# 1. Update the RichTextLabel with the header text
	var lines: PackedStringArray = []

	lines.append("Weight: %.1f / %.1f kg" % [current_weight, max_weight])
	lines.append("------------------------")

	if items.is_empty():
		lines.append("Inventory is empty.")
		
	text.text = "\n".join(lines)

	# 2. Remove old item rows (safely ignoring the text node!)
	for child in item_box.get_children():
		if child != text:
			item_box.remove_child(child)
			child.queue_free()

	# 3. Create UI elements for every inventory item below the text
	for entry in items:
		var hbox := HBoxContainer.new()

		var item_label := Label.new()
		item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var total_stack_weight: float = float(entry["weight"]) * int(entry["quantity"])

		item_label.text = "- %s x%d (%.1f kg)" % [
			entry["name"],
			entry["quantity"],
			total_stack_weight
		]

		hbox.add_child(item_label)

		# Usable item button
		var props: Dictionary = entry.get("properties", {})

		if props.get("usable", false):
			var use_btn := Button.new()

			use_btn.text = "Use"
			use_btn.modulate = Color(0.2, 0.8, 0.2)

			use_btn.pressed.connect(use_item.bind(entry["id"]))

			hbox.add_child(use_btn)

		# Drop one button
		var drop_one_btn := Button.new()

		drop_one_btn.text = "Drop 1"
		drop_one_btn.pressed.connect(remove_item.bind(entry["id"], 1))

		hbox.add_child(drop_one_btn)

		# Drop all button
		var drop_all_btn := Button.new()

		drop_all_btn.text = "Drop All"
		drop_all_btn.pressed.connect(remove_item.bind(entry["id"], entry["quantity"]))

		hbox.add_child(drop_all_btn)

		item_box.add_child(hbox)


# -----------------------------
# ADD ITEMS
# -----------------------------

func add_item(id: String, quantity: int = 1) -> bool:
	if quantity <= 0:
		return false

	if not item_database.has(id):
		push_error("Item ID %s does not exist in the database!" % id)
		return false

	var base_data: Dictionary = item_database[id]

	var item_name: String = str(base_data["name"])
	var weight_per_unit: float = float(base_data["weight"])
	var max_stack: int = maxi(1, int(base_data["max_stack"]))
	var properties: Dictionary = base_data.get("properties", {})

	var total_added_weight: float = weight_per_unit * quantity

	# Check weight capacity
	if current_weight + total_added_weight > max_weight:
		inventory_full.emit(item_name, quantity)
		return false

	var remaining_quantity: int = quantity

	# Fill existing stacks first
	for i in range(items.size()):
		var entry: Dictionary = items[i]

		if entry["id"] == id and entry["quantity"] < entry["max_stack"]:
			var space_in_stack: int = entry["max_stack"] - entry["quantity"]
			var to_add: int = mini(remaining_quantity, space_in_stack)

			entry["quantity"] += to_add
			remaining_quantity -= to_add

			items[i] = entry

			if remaining_quantity <= 0:
				break

	# Create new stacks for anything remaining
	while remaining_quantity > 0:
		var stack_amount: int = mini(remaining_quantity, max_stack)

		items.append({
			"id": id,
			"name": item_name,
			"weight": weight_per_unit,
			"max_stack": max_stack,
			"quantity": stack_amount,
			"properties": properties
		})

		remaining_quantity -= stack_amount

	print("Added %s x%d to inventory." % [item_name, quantity])

	_recalculate_weight()

	return true


# -----------------------------
# REMOVE ITEMS
# -----------------------------

func remove_item(id: String, quantity: int = 1) -> bool:
	if quantity <= 0:
		return false

	# Check whether enough items exist
	var total_available: int = 0

	for entry in items:
		if entry["id"] == id:
			total_available += int(entry["quantity"])

	if total_available < quantity:
		return false

	var remaining_quantity: int = quantity

	# Remove from existing stacks
	for i in range(items.size() - 1, -1, -1):
		if items[i]["id"] == id:
			var stack_quantity: int = items[i]["quantity"]

			if stack_quantity > remaining_quantity:
				items[i]["quantity"] -= remaining_quantity
				remaining_quantity = 0
			else:
				remaining_quantity -= stack_quantity
				items.remove_at(i)

			if remaining_quantity <= 0:
				break

	_recalculate_weight()

	return true


# -----------------------------
# USE ITEMS
# -----------------------------

func use_item(id: String) -> void:
	for entry in items:
		if entry["id"] == id:
			var props: Dictionary = entry.get("properties", {})

			if not props.get("usable", false):
				print("You cannot use %s." % entry["name"])
				return

			if props.has("heal_amount"):
				print("You drank %s! Recovered %d HP." % [
					entry["name"],
					int(props["heal_amount"])
				])
			else:
				print("You used %s!" % entry["name"])

			remove_item(id, 1)
			return


# -----------------------------
# WEIGHT / SIGNALS
# -----------------------------

func _recalculate_weight() -> void:
	current_weight = 0.0

	for entry in items:
		current_weight += float(entry["weight"]) * int(entry["quantity"])

	weight_changed.emit(current_weight, max_weight)
	inventory_changed.emit()
