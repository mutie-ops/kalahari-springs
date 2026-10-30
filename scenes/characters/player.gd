extends CharacterBody2D

var direction: Vector2
var last_direction: Vector2
var speed := 50
var can_move: bool = true
var frozen: bool = false   # set by BuildingManager during fades
@onready var move_state_machine = $Animation/AnimationTree.get("parameters/MoveStateMachine/playback")
@onready var tool_state_machine = $Animation/AnimationTree.get("parameters/ToolStateMachine/playback")
var current_tool: Enum.Tool = Enum.Tool.AXE
var current_seed: Enum.Seed
var current_state: Enum.State
var current_style: Enum.Style
var current_style_index: int
var current_machine: Enum.Machine
var current_machine_index: int
@onready var tool_sounds = {
	Enum.Tool.AXE: $Sounds/Axe,
	Enum.Tool.SWORD: $Sounds/Axe,
	Enum.Tool.FISH: $Sounds/Fish,
	Enum.Tool.HOE: $Sounds/Hoe,
	Enum.Tool.SEED: $Sounds/Seed,
	Enum.Tool.WATER: $Sounds/Water,
}

var has_hippo_roller: bool = false
# NEW: the roller (or other item) Hope is carrying. Its water lives ON the item,
# so current_water / max_water below are just a copy of it for the HUD.
var held_item: Carryable = null

var max_water: float = 90.0
var current_water: float = 0.0

var hippo_roller_scene = preload("res://scenes/objects/hippo_roller.tscn") # Make sure this path is correct!
var hippo_roller_item_data := {
	"name": "Hippo Roller",
	"amount": 1,
	"category": "Quest Items",
	"description": "A barrel used to carry water efficiently.",
	"icon": "res://resources/HippoRoller.tres" # Make sure this points to your icon!
}

signal tool_use(tool: Enum.Tool, pos: Vector2)

signal diagnose
signal day_change
signal build(current_machine: Enum.Machine)
signal machine_change(current_machine: Enum.Machine)
signal close_shop
signal hippo_roller_equipped
signal hippo_roller_dropped
signal water_updated(new_amount: float)


func _ready() -> void:
	add_to_group("player")
	# If we just loaded a game, apply the pending data
	if not SaveManager.pending_player_data.is_empty():
		load_from_dict(SaveManager.pending_player_data)
		global_position = Vector2(
			SaveManager.pending_player_data["pos_x"], 
			SaveManager.pending_player_data["pos_y"]
		)
		# Clear it so it doesn't accidentally trigger on normal map transitions
		SaveManager.pending_player_data = {}
	
	

#Saving Player information
func get_save_dict() -> Dictionary:
	return {
		"pos_x": global_position.x,
		"pos_y": global_position.y,
		"has_hippo_roller": has_hippo_roller,
		"current_water": current_water,
		"held_item_id": held_item.item_id if held_item != null else ""
	}
#Loading saved player information

func load_from_dict(data: Dictionary) -> void:
	# Position will be applied by the SaveManager/Scene Load, but we handle state here
	var saved_water: float = data.get("current_water", 0.0)
	if data.get("has_hippo_roller", false):
		# Wait one moment so every roller in the level exists, then pick one up
		_restore_held_roller.call_deferred(saved_water, str(data.get("held_item_id", "")))
	else:
		current_water = 0.0
		water_updated.emit(current_water)
	
	
	
func _physics_process(_delta: float) -> void:
	if frozen:
		velocity = Vector2.ZERO
		direction = Vector2.ZERO
		$Sounds/StepTimer.stop()
		move_state_machine.travel('RollerIdle' if has_hippo_roller else 'Idle')
		return

	match current_state:
		Enum.State.DEFAULT:
			if can_move:
				get_basic_input()
				move()
				animate()
		Enum.State.FISHING:
			get_fishing_input()
		Enum.State.BUILDING:
			get_building_input()
			move()
			animate()
		Enum.State.SHOP:
			get_shopping_input()
	if direction:
		last_direction = direction
		var ray_y = int(direction.y) if not direction.x else 0
		$RayCast2D.target_position = Vector2(direction.x,ray_y).normalized() * 20
		
		if not $Sounds/StepTimer.time_left:
			$Sounds/StepTimer.start()
	else:
		$Sounds/StepTimer.stop()


func get_basic_input():
	if Input.is_action_just_pressed("tool_forward") or Input.is_action_just_pressed("tool_backward"):
		var dir = Input.get_axis("tool_backward", "tool_forward")
		current_tool = posmod(current_tool + int(dir), Enum.Tool.size()) as Enum.Tool
		$ToolUI.reveal(true)
		get_tree().get_first_node_in_group("ResourceUI").visible = current_tool == Enum.Tool.SEED
	
	if Input.is_action_just_pressed("seed_forward"):
		current_seed = posmod(current_seed + 1, Enum.Seed.size()) as Enum.Seed
		$ToolUI.reveal(false)
	
	if Input.is_action_just_pressed("action"):
		if not $RayCast2D.get_collider():
			tool_state_machine.travel(Data.TOOL_STATE_ANIMATIONS[current_tool])
			$Animation/AnimationTree.set("parameters/ToolOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		else:
			$RayCast2D.get_collider().interact(self)
	
	if Input.is_action_just_pressed("diagnose"):
		diagnose.emit()

	if Input.is_action_just_pressed("style_toggle"):
		current_style_index = posmod(current_style_index + 1, Data.unlocked_styles.size())
		current_style = Data.unlocked_styles[current_style_index] as Enum.Style
		$Sprite2D.texture = Data.PLAYER_SKINS[current_style]

	
	if Input.is_action_just_pressed("build"):
		current_state = Enum.State.BUILDING
		current_machine = Data.unlocked_machines[current_machine_index] as Enum.Machine
		
	# --- ADD THIS DROP CHECK ---
	if Input.is_action_just_pressed("drop_item") and has_hippo_roller:
		drop_hippo_roller()


func get_fishing_input():
	if Input.is_action_just_pressed("action"):
		$FishingGame.action()


func get_building_input():
	if Input.is_action_just_pressed("build"):
		current_state = Enum.State.DEFAULT
	
	if Input.is_action_just_pressed("tool_forward") or Input.is_action_just_pressed("tool_backward"):
		var dir = Input.get_axis("tool_backward", "tool_forward")
		current_machine_index = posmod(current_machine_index + int(dir), Data.unlocked_machines.size())
		current_machine = Data.unlocked_machines[current_machine_index] as Enum.Machine
		machine_change.emit(current_machine)

	if Input.is_action_just_pressed("action"):
		build.emit(current_machine)


func get_shopping_input():
	if Input.is_action_just_pressed("ui_cancel"):
		close_shop.emit()
		get_tree().get_first_node_in_group("ResourceUI").hide()


func move():
	direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * speed
	move_and_slide()


func animate():
	if direction:
		# Check if we have the roller to play the right walk
		if has_hippo_roller:
			move_state_machine.travel('RollerWalk')
		else:
			move_state_machine.travel('Walk')
		var direction_animation = Vector2(round(direction.x),round(direction.y))
		$Animation/AnimationTree.set("parameters/MoveStateMachine/Idle/blend_position", direction_animation)
		$Animation/AnimationTree.set("parameters/MoveStateMachine/Walk/blend_position", direction_animation)
		$Animation/AnimationTree.set("parameters/FishBlendSpace2D/blend_position", direction_animation)
		
		# Set the roller blend positions
		if has_hippo_roller:
			$Animation/AnimationTree.set("parameters/MoveStateMachine/RollerIdle/blend_position", direction_animation)
			$Animation/AnimationTree.set("parameters/MoveStateMachine/RollerWalk/blend_position", direction_animation)
		for animation in Data.TOOL_STATE_ANIMATIONS.values():
			var animation_name: String = "parameters/ToolStateMachine/"+ animation +"/blend_position"
			$Animation/AnimationTree.set(animation_name, direction_animation)
	else:
		# Check if we have the roller to play the right idle
		if has_hippo_roller:
			move_state_machine.travel('RollerIdle')
		else:
			move_state_machine.travel('Idle')
		


func start_fishing():
	$FishingGame.reveal()
	current_state = Enum.State.FISHING
	$Animation/AnimationTree.set("parameters/FishBlend/blend_amount", 1)
	# return coord * Data.TILE_SIZE + Vector2i(8,8)


func _on_step_timer_timeout() -> void:
	$Sounds/Step.play()

func stop_fishing():
	can_move = true
	current_state = Enum.State.DEFAULT
	$Animation/AnimationTree.set("parameters/FishBlend/blend_amount", 0)


func tool_use_emit():
	tool_use.emit(current_tool, position + last_direction * 16 + Vector2(0,4))
	tool_sounds[current_tool].play()


func _on_animation_tree_animation_started(_anim_name: StringName) -> void:
	can_move = false


func _on_animation_tree_animation_finished(_anim_name: StringName) -> void:
	can_move = true


func day_change_emit():
	day_change.emit()


func get_machine_coord() -> Vector2i:
	var pos = position + last_direction * 20 + Vector2(0,8)
	var coord = Vector2i(pos.x / Data.TILE_SIZE, pos.y / Data.TILE_SIZE)
	coord.x += -1 if pos.x < 0 else 0
	coord.y += -1 if pos.y < 0 else 0
	return coord * Data.TILE_SIZE + Vector2i(8,8)


# =====================================================================
#  CARRYING A HIPPO ROLLER
#  The roller is a real object (carryable.gd) that remembers its own water.
#  The functions below are what the roller, BuildingManager and the new-day
#  reset use to talk to Hope.
# =====================================================================

func can_carry_item() -> bool:
	## False while Hope is already pushing something.
	return held_item == null and not has_hippo_roller


func get_carried_item() -> Carryable:
	return held_item


func equip_carryable(item: Carryable) -> void:
	## Called by the roller right after it has been picked up.
	held_item = item
	max_water = item.capacity
	current_water = item.water
	if not item.water_changed.is_connected(_on_held_item_water_changed):
		item.water_changed.connect(_on_held_item_water_changed)
	equip_hippo_roller()                 # push animations, HUD signal, inventory entry
	water_updated.emit(current_water)


func release_carried_item(at: Vector2) -> void:
	## Puts the item down at "at". It keeps its water.
	## (Also used by BuildingManager so nothing is carried indoors.)
	if held_item == null:
		return
	var item := held_item
	_forget_held_item()
	item.put_down(at)
	_clear_roller_state()


func on_carryable_reset(item) -> void:
	## The new-day reset took the item away from Hope.
	if item == held_item:
		_forget_held_item()
		_clear_roller_state()


func _forget_held_item() -> void:
	if held_item != null and is_instance_valid(held_item):
		if held_item.water_changed.is_connected(_on_held_item_water_changed):
			held_item.water_changed.disconnect(_on_held_item_water_changed)
	held_item = null


func _on_held_item_water_changed(amount: float) -> void:
	current_water = amount
	water_updated.emit(amount)


func _clear_roller_state() -> void:
	has_hippo_roller = false
	hippo_roller_dropped.emit()
	
	# Find the menu and remove the item from the inventory
	var menu = get_tree().get_first_node_in_group("GameMenu")
	if menu != null:
		if menu.has_method("remove_item"):
			menu.remove_item("Hippo Roller")
	
	current_water = 0.0
	water_updated.emit(current_water)


func _restore_held_roller(saved_water: float, wanted_id: String = "") -> void:
	## After loading a save that says Hope was holding a roller.
	## With several rollers, wanted_id says which one (saves made before item_id
	## existed have no id, so the first free roller is used).
	for item in get_tree().get_nodes_in_group("carryable"):
		var roller := item as HippoRoller
		if roller == null or roller.is_carried:
			continue
		if wanted_id != "" and roller.item_id != wanted_id:
			continue
		if roller.pick_up(self):
			roller.set_water(saved_water)
			equip_carryable(roller)
			return
	# No roller object in the level: fall back to the old behaviour
	push_warning("Saved game says Hope held a hippo roller, but there is no free roller in the level.")
	equip_hippo_roller()
	current_water = saved_water
	water_updated.emit(current_water)


func equip_hippo_roller() -> void:
	has_hippo_roller = true
	hippo_roller_equipped.emit()
	
	
	# Find the menu and add the item to the inventory
	var menu = get_tree().get_first_node_in_group("GameMenu")
	if menu != null:
		if menu.has_method("add_item"):
			menu.add_item(hippo_roller_item_data)

func drop_hippo_roller() -> void:
	if held_item != null:
		# Put the SAME roller down, so it keeps its water
		release_carried_item(position + last_direction * 20)
		return
	
	# A roller with no object behind it (for example from an old save): behave as before
	_clear_roller_state()
	var dropped_roller = hippo_roller_scene.instantiate()
	dropped_roller.global_position = position + last_direction * 20 
	get_parent().add_child(dropped_roller)

func add_water(amount: float) -> void:
	if held_item != null:
		# The roller keeps the water (and never holds more than its capacity)
		held_item.add_water(amount)
		print("DEBUG: Filled from water source! Current level: ", current_water)
	elif has_hippo_roller:
		# clampf prevents the water from ever going above max_water (90)
		current_water = clampf(current_water + amount, 0.0, max_water)
		
		# Broadcast the new amount to the UI!
		water_updated.emit(current_water)
		print("DEBUG: Filled from water source! Current level: ", current_water)

func pour_water(amount: float) -> void:
	if held_item != null:
		held_item.remove_water(amount)
		print("DEBUG: Poured water! Current water: ", current_water)
	elif has_hippo_roller:
		# Empty the roller, stopping at 0L
		current_water = clampf(current_water - amount, 0.0, max_water)
		water_updated.emit(current_water)
		print("DEBUG: Poured water! Current water: ", current_water)
