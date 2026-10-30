extends ProgressBar
## The water gauge. It is shown only while the PLAYER is holding a hippo roller, and it
## always shows THAT roller's water. NPCs and buckets never affect it.

var _player: Node = null
var _roller: Carryable = null          # the roller currently in Hope's hands

func _ready() -> void:
	# 1. Hide the meter immediately when the game starts
	hide()
	
	# 2. Wait a tiny fraction of a second for the Player to load into the world
	await get_tree().process_frame
	
	# 3. Find the Player and listen for picking up / putting down a roller
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		return
	_player.hippo_roller_equipped.connect(_on_roller_equipped)
	_player.hippo_roller_dropped.connect(_on_roller_dropped)
	# Only used for an old-style roller that has no object behind it (see update_water_display)
	_player.water_updated.connect(update_water_display)
	
	# 4. If Hope already holds a roller (for example just after loading a save), catch up
	if _player.has_hippo_roller:
		_on_roller_equipped()


# Runs when the Player picks up a roller
func _on_roller_equipped() -> void:
	var held = _player.get_carried_item()
	if held != null and not (held is HippoRoller):
		return                          # the gauge is only for rollers, never buckets
	
	_follow(held)
	if held != null:
		# Show THIS roller's own numbers
		max_value = held.capacity
		value = held.water
	else:
		# Old-style roller with no object behind it: use the player's copy
		max_value = _player.max_water
		value = _player.current_water
	show()


# Runs when the roller is put down, left outside a door, or reset for a new day
func _on_roller_dropped() -> void:
	_follow(null)
	hide()


# Listen to one roller at a time: stop listening to the old one, start on the new one
func _follow(roller) -> void:
	if _roller != null and is_instance_valid(_roller):
		if _roller.water_changed.is_connected(_on_roller_water_changed):
			_roller.water_changed.disconnect(_on_roller_water_changed)
	_roller = roller
	if _roller != null:
		if not _roller.water_changed.is_connected(_on_roller_water_changed):
			_roller.water_changed.connect(_on_roller_water_changed)


func _on_roller_water_changed(amount: float) -> void:
	value = amount


func update_water_display(current_amount: float) -> void:
	if _roller == null:                 # normally the roller itself reports its water
		value = current_amount
