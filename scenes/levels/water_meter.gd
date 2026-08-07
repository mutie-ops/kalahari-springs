extends ProgressBar

func _ready() -> void:
	# 1. Hide the meter immediately when the game starts
	hide()
	
	# 2. Wait a tiny fraction of a second for the Player to load into the world
	await get_tree().process_frame
	
	# 3. Find the Player and connect our ear to their megaphone
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.hippo_roller_equipped.connect(_on_roller_equipped)
		player.water_updated.connect(update_water_display)

# 4. This runs exactly when the Player yells "I have the roller!"
func _on_roller_equipped() -> void:
	show()
	
	# Sync the UI's numbers with the Player's numbers
	var player = get_tree().get_first_node_in_group("player")
	if player:
		max_value = player.max_water
		value = player.current_water
		print("DEBUG: WaterMeter heard the signal, showed up, and synced to 90L!")

# 5. We will call this function later when we stand in the river!
func update_water_display(current_amount: float) -> void:
	value = current_amount
