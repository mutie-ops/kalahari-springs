extends CanvasLayer
## Attach this script to the CanvasLayer node that holds your debug panel.
## Press F1 during play to show/hide the whole panel.

func _ready() -> void:
	# Start hidden so it isn't sitting on screen the moment the game launches.
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_QUOTELEFT:
			visible = not visible
			# Marks the event as handled so it doesn't also trigger something
			# else in your game that might be listening for F1 or any input.
			get_viewport().set_input_as_handled()
