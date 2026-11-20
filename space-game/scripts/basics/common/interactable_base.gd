class_name interactable
extends Area2D

@export var id: String
var interaction_database: Dictionary = {}

func _ready():
	load_database()

func load_database():
	var file_path = "res://scripts/data/interactions.json"
	
	if FileAccess.file_exists(file_path):
		var json_string = FileAccess.get_file_as_string(file_path)
		var parsed_data = JSON.parse_string(json_string)
		
		if parsed_data != null:
			interaction_database = parsed_data
		else:
			push_error("Failed to parse JSON database.")
	else:
		push_error("Database file not found at: " + file_path)

func when_interacted():
	# Look up the exported ID in the loaded JSON dictionary
	if interaction_database.has(id):
		var data = interaction_database[id]
		
		# Route the logic based on the data we found
		if data["type"] == "message" or data["type"] == "dialogue":
			print(data["text"])
		elif data["type"] == "action":
			print("Performing action: ", data["action_name"])
			
	else:
		print("Error: No data found in JSON for ID: ", id)
