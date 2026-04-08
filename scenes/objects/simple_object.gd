@tool
extends StaticBody2D

@export_range(0,3,1) var size: int:
	set(value):
		size = value
		if has_node("Sprite2D"):
			$Sprite2D.frame_coords = Vector2i(size, style)

@export_enum('Bush', 'Rock') var style: int:
	set(value):
		style = value
		if has_node("Sprite2D"):
			$Sprite2D.frame_coords = Vector2i(size, style)

@export var random: bool
@export_tool_button("Randomize", "Callable") var randomizer = randomize


func _ready() -> void:
	if random and has_node("Sprite2D"):
		size = randi_range(0, $Sprite2D.hframes - 1)
		style = [0,1].pick_random()

	if has_node("Sprite2D"):
		$Sprite2D.frame_coords = Vector2i(size, style)

	if has_node("CollisionShape2D"):
		$CollisionShape2D.disabled = size < 2

	z_index = -1 if size < 2 else 0


func randomize():
	if has_node("Sprite2D"):
		size = randi_range(0, $Sprite2D.hframes - 1)
		style = [0,1].pick_random()
		$Sprite2D.frame_coords = Vector2i(size, style)
