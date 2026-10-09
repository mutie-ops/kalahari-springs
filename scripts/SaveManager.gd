extends Node
## SaveManager.gd — Autoload Singleton

var pending_player_data: Dictionary = {}

# Generates a unique file path for each of the 10 slots
func _get_save_path(slot: int) -> String:
	return "user://kalahari_save_%d.json" % slot

func save_game(slot: int) -> void:
	var player = get_tree().get_first_node_in_group("player")
	
	var save_dict = {
		"metadata": {
			"timestamp": Time.get_datetime_string_from_system(false, true).replace("T", " "),
			"chapter": GameState.chapter,
			"day": GameState.day
		},
		"game_state": GameState.get_save_dict(),
		"current_scene": get_tree().current_scene.scene_file_path,
		"player_data": player.get_save_dict() if player else {}
	}
	
	var file = FileAccess.open(_get_save_path(slot), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_dict, "\t"))
		print("Game saved successfully to slot ", slot)

func load_game(slot: int) -> void:
	var path = _get_save_path(slot)
	if not FileAccess.file_exists(path):
		print("No save file found in slot ", slot)
		return
		
	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	
	if error == OK:
		var data = json.data
		if data.has("game_state"): GameState.load_from_dict(data["game_state"])
		if data.has("player_data"): pending_player_data = data["player_data"]
		if data.has("current_scene"): get_tree().change_scene_to_file(data["current_scene"])
	else:
		print("Failed to parse save file.")

func get_save_metadata(slot: int) -> Dictionary:
	var path = _get_save_path(slot)
	if not FileAccess.file_exists(path):
		return {}
		
	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.new()
	if json.parse(file.get_as_text()) == OK:
		if json.data.has("metadata"):
			return json.data["metadata"]
	return {}

func delete_save(slot: int) -> void:
	var path = _get_save_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("Deleted save file in slot ", slot)
