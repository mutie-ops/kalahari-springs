extends Node2D

## Interior — attach to the root of every interior scene.

@export var fixed_camera: bool = true

## true  = the room stays still and Hope walks around it (Stardew style).

## false = the camera follows Hope instead (use for rooms bigger than the screen).


func _ready() -> void:

	$ExitArea.collision_layer = 0

	$ExitArea.collision_mask = 2

	$ExitArea.body_entered.connect(_on_exit_area_body_entered)


func _on_exit_area_body_entered(body: Node2D) -> void:

	if body.is_in_group("player"):

		BuildingManager.exit_building()


func get_entry_position() -> Vector2:

	return $EntryPoint.global_position


func get_camera_position() -> Vector2:

	return $CameraAnchor.global_position

func get_wake_position() -> Vector2:
	## Where Hope wakes after being put to bed. Add a Marker2D called "WakePoint"
	## beside the bed. If there isn't one, she wakes at the entry point.
	var wp := get_node_or_null("WakePoint") as Node2D
	if wp:
		return wp.global_position
	return $EntryPoint.global_position
