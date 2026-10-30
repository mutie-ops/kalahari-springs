class_name PathPoint
extends Marker2D
## A Marker2D that can also do something when an NPC arrives.
## Use it in place of a plain Marker2D wherever you want a pause, a turn,
## or to pick up / put down / fill / empty a roller or bucket.
## Plain Marker2Ds still work.

## How long the NPC waits here. Give pick-ups, put-downs and fills about 0.5 s
## so the animation swap shows as a little pause.
@export var pause_seconds: float = 0.0

## Which way she faces while waiting here. "keep" = whatever she was facing.
@export_enum("keep", "down", "left", "right", "up") var face_after: String = "keep"

## What happens on arrival.
##   set_carry        switch to the animation set chosen in "carry" (no item involved)
##   pick_up_item     take the Item below (it must be within about 48 px of this point)
##   put_down_item    set down the item she is holding, here (it keeps its fill state)
##   fill_item        fill the item she is holding (bucket becomes "full")
##   empty_item       empty the item she is holding
@export_enum("none", "set_carry", "pick_up_item", "put_down_item", "fill_item", "empty_item") var action: String = "none"

## For set_carry only: the animation set to switch to.
@export_enum("none", "bucket_empty", "bucket_full", "roller") var carry: int = 0

## The roller or water bucket in the level. Needed for pick_up_item.
@export var item: Carryable

## put_down_item only: nudge where the item appears, relative to this point.
@export var drop_offset: Vector2 = Vector2.ZERO
