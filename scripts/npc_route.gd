@tool
class_name NpcRoute
extends Node2D
## A walking route. Put one under the level's "Routes" node and add Marker2D
## (or PathPoint) children. Top-to-bottom order in the Scene dock = walking order.
## A plain Node2D also works as a route; it is treated as ONCE with no carry change.

enum Mode { ONCE, LOOP, PING_PONG }

## ONCE: walk to the last point and stop.  LOOP: last point -> first point, forever.
## PING_PONG: walk to the end, then back to the start, forever.
@export var mode: Mode = Mode.ONCE

## What she carries as soon as she starts this route.
## "keep" leaves it alone (use a PathPoint to change it part-way along).
@export_enum("keep", "none", "bucket_empty", "bucket_full") var carry_on_start: int = 0


# ── editor-only: draw the path so you can see it ──────────────────
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var pts: Array[Vector2] = []
	for child in get_children():
		var node := child as Node2D
		if node != null:
			pts.append(to_local(node.global_position))
	for i in range(pts.size() - 1):
		draw_line(pts[i], pts[i + 1], Color(0.96, 0.0, 0.729, 0.902), 1.0)
	if mode == Mode.LOOP and pts.size() > 2:
		draw_line(pts[pts.size() - 1], pts[0], Color(1.0, 0.8, 0.2, 0.4), 1.0)
