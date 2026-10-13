extends Label

## Shows the placeholder clock on screen.

func _ready() -> void:

	GameClock.hour_changed.connect(_update)

	_update(GameClock.hour)

func _update(h: float) -> void:

	text = GameClock.format_time(h)
