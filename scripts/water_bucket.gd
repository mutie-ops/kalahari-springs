class_name WaterBucket
extends Carryable
## A free-standing water bucket. Same rules as the hippo roller (see carryable.gd):
## it is hidden while carried, remembers how much water it holds, and is left outside
## when its carrier walks into a building.
##
## Scene setup: Area2D root (collision mask = the player's layer, like the roller),
## a Sprite2D, a CollisionShape2D, and this script. In the Inspector set Capacity
## (litres) and, optionally, Texture Empty / Texture Full.


func _item_kind() -> int:
	return KIND_BUCKET


func _player_can_pick_up() -> bool:
	## NPCs can carry buckets. The player has no bucket animations yet, so the E key
	## ignores them. Change this to  return true  once the player has them.
	return false
