extends CanvasLayer
class_name SaveLoadMenu

signal game_saved
signal game_loaded(data: Dictionary)
signal save_requested

const SAVE_PATH := "res://scripts/data/saveFile.json"

@onready var panel: Panel = $Panel
@onready var vbox: VBoxContainer = $VBoxContainer
@onready var status_label: Label = $ifSaved

func _ready() -> void:
	# Randomize seed for the dummy data generator
	randomize() 
	_setup_buttons()

func _setup_buttons() -> void:
	if not vbox or not status_label:
		push_error("Missing child nodes! Ensure Panel/VBox/ifSaved exists.")
		return
		
	status_label.text = "Save / Load Menu"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Save Button (Emits signal for external game manager)
	var save_btn = Button.new()
	save_btn.text = "Save Game"
	save_btn.pressed.connect(func(): save_requested.emit())
	vbox.add_child(save_btn)

	# Load Button
	var load_btn = Button.new()
	load_btn.text = "Load Game"
	load_btn.pressed.connect(load_game)
	vbox.add_child(load_btn)

	# Dev Debug: Print Save File
	var debug_btn = Button.new()
	debug_btn.text = "[DEV] Print Save File"
	debug_btn.pressed.connect(debug_print_save)
	vbox.add_child(debug_btn)

	# Dev Debug: Save Dummy Data
	var test_save_btn = Button.new()
	test_save_btn.text = "[DEV] Save Dummy Data"
	test_save_btn.pressed.connect(_test_save_dummy_data)
	vbox.add_child(test_save_btn)

	# Close Button
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(hide)
	vbox.add_child(close_btn)

# --- Save Logic ---
func save_game(data_to_save: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		_set_status("Error opening file for write!", Color.RED)
		return

	var json_string := JSON.stringify(data_to_save, "\t")
	file.store_string(json_string)
	
	_set_status("Saved to saveFile.json!", Color.GREEN)
	game_saved.emit()
	print("Saved data to %s" % SAVE_PATH)

# --- Load Logic ---
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_set_status("No saveFile.json found!", Color.ORANGE)
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		_set_status("Error opening saveFile.json!", Color.RED)
		return

	var json_string := file.get_as_text()
	var parsed_data = JSON.parse_string(json_string)
	
	if parsed_data is Dictionary:
		_set_status("Loaded from saveFile.json!", Color.GREEN)
		game_loaded.emit(parsed_data)
		print("Loaded data from %s" % SAVE_PATH)
	else:
		_set_status("Corrupted save file!", Color.RED)

# --- Debug Logic ---
func debug_print_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("[DEV DEBUG] No save file exists at: ", SAVE_PATH)
		return
		
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		print("\n--- [DEV DEBUG] Current contents of saveFile.json ---")
		print(file.get_as_text())
		print("---------------------------------------------------\n")
	else:
		print("[DEV DEBUG] Failed to open save file for reading.")

func _test_save_dummy_data() -> void:
	var dummy_data := {
		"player_name": "Tester_" + str(randi() % 1000),
		"level": randi_range(1, 99),
		"health": randi_range(10, 100),
		"position": {
			"x": snapped(randf_range(-500.0, 500.0), 0.1), 
			"y": snapped(randf_range(-500.0, 500.0), 0.1)
		}
	}
	print("[DEV DEBUG] Generating dummy data...")
	save_game(dummy_data)

func _set_status(msg: String, color: Color = Color.WHITE) -> void:
	if status_label:
		status_label.text = msg
		status_label.add_theme_color_override("font_color", color)
