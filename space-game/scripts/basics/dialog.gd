extends Node

@export_file("*.json") var dialog_file_path: String = "res://scripts/data/dialog.json"
@export var auto_start_dialog: bool = true
@export var initial_dialog_id: String = "guard_greeting"
@export_range(1, 100, 1) var max_dialog_redirects: int = 20
@export var typing_speed: float = 0.03 

# References
@onready var lable: RichTextLabel = $Panel/Lable
# Add a VBoxContainer (or HBoxContainer) inside your Panel to hold the buttons!
@onready var option_container: Control = $Panel/OptionContainer 

signal dialogue_displayed(dialog_id: String, text: String)
signal dialogue_action_executed(action: String, target: String)

var dialog_database: Dictionary = {}
var current_tween: Tween

@onready var condition_function_map: Dictionary = {
	"player_has_pass": Callable(self, "_check_player_has_pass")
}
@onready var action_function_map: Dictionary = {
	"trigger_combat": Callable(self, "_trigger_combat")
}


func _ready() -> void:
	add_to_group("dialog_ui")
	
	for node in get_tree().get_nodes_in_group("dialog_ui"):
		if node != self:
			node.queue_free()

	if load_dialog_file() and auto_start_dialog and not initial_dialog_id.is_empty():
		read_text(initial_dialog_id)


func load_dialog_file(file_path: String = dialog_file_path) -> bool:
	if not FileAccess.file_exists(file_path):
		push_error("Dialogue file does not exist: ", file_path)
		return false

	var json_text: String = FileAccess.get_file_as_string(file_path)
	var parsed_data = JSON.parse_string(json_text)
	
	if typeof(parsed_data) != TYPE_DICTIONARY:
		push_error("Failed to parse dialogue JSON. Ensure the root is an object.")
		return false

	dialog_database = parsed_data
	return true


func read_text(dialog_id: String, visited_ids: Array[String] = []) -> void:
	if visited_ids.size() >= max_dialog_redirects:
		push_error("Dialogue loop detected. Exceeded max redirects.")
		return
		
	var entry: Dictionary = dialog_database.get(dialog_id, {})
	if entry.is_empty():
		push_error("Dialogue ID not found: ", dialog_id)
		return

	visited_ids.append(dialog_id)

	# Process conditions and branching
	if entry.has("condition"):
		var condition: Dictionary = entry["condition"]
		var check_func: String = condition.get("check_function", "")
		
		if condition_function_map.has(check_func):
			var actual_val = condition_function_map[check_func].call()
			var expected_val = condition.get("expected_value")
			
			var branch: Dictionary = condition.get("on_true", {}) if actual_val == expected_val else condition.get("on_false", {})
			var action_name: String = branch.get("action", "")
			var target: String = branch.get("target", "")

			match action_name:
				"switch_dialog":
					read_text(target, visited_ids)
					return 
				"run_function":
					if action_function_map.has(target):
						action_function_map[target].call()
						dialogue_action_executed.emit("run_function", target)

	# Pass the entire entry dictionary now so we can extract options
	_display_dialog(dialog_id, entry)


func _display_dialog(dialog_id: String, entry: Dictionary) -> void:
	var text_value: String = entry.get("text", "")
	var options_list: Array = entry.get("options", [])
	
	# NEW: If there is no text and no options, the conversation is over. Kill the UI.
	if text_value.is_empty() and options_list.is_empty():
		queue_free() # Destroys this entire dialog node so they don't stack up
		return
	
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		
	lable.clear() 
	lable.text = text_value
	lable.visible_characters = 0 
	
	var duration: float = text_value.length() * typing_speed
	current_tween = create_tween()
	current_tween.tween_property(lable, "visible_characters", text_value.length(), duration)
	
	_setup_options(options_list)
	
	dialogue_displayed.emit(dialog_id, text_value)


func _setup_options(options: Array) -> void:
	for child in option_container.get_children():
		# Disable old buttons immediately so they can't be clicked while dying
		if child is Button:
			child.disabled = true 
		option_container.remove_child(child)
		child.queue_free()
		
	for option in options:
		var btn := Button.new()
		btn.text = option.get("text", "...")
		var target: String = option.get("target", "")
		
		btn.pressed.connect(func(): 
			# 2. Disable ALL options immediately upon one being clicked to prevent double-firing
			for c in option_container.get_children():
				if c is Button:
					c.disabled = true
			read_text(target)
		)
		
		option_container.add_child(btn)


# -----------------------------------------------------------------------------
# Gameplay Logic Stubs
# -----------------------------------------------------------------------------

func _check_player_has_pass() -> bool:
	return true

func _trigger_combat() -> void:
	print("*Combat Started!*")
