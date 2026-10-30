class_name Carryable
extends Area2D
## Shared behaviour for anything a character can pick up, carry and put down:
## hippo rollers (hippo_roller.gd) and water buckets (water_bucket.gd).
##
## The item is NEVER deleted. When someone picks it up it is hidden and switched off,
## and it keeps remembering how much water it holds (in litres). When it is put down it
## reappears where it was dropped, with the same amount of water.
## Every item is its own object, so every roller and bucket has its own water.
##
## Anyone can carry it: the player (player.gd) or an NPC (PathPoint actions in npc_base.gd).
## Every morning, level.gd calls reset_for_new_day(): the item is emptied and returned
## to its home spot.

signal water_changed(amount: float)
signal picked_up(by: Node)
signal put_down_at(where: Vector2)

const KIND_ROLLER := 0
const KIND_BUCKET := 1

# Animation-set codes. These numbers match NpcBase.Carry.
const CODE_BUCKET_EMPTY := 1
const CODE_BUCKET_FULL := 2
const CODE_ROLLER := 3

## A short, unique, permanent name such as "roller_1" or "bucket_naledi".
## Saved games use it to tell items apart. Never change it once players have saves.
@export var item_id: String = ""
## Where this item goes every morning. Place a Marker2D in the level and drag it here.
## (Rollers: somewhere public in town. Buckets: just outside their household's front door.)
## If left empty, the item returns to wherever you placed it in the editor.
@export var home_marker: Marker2D
## How many litres it holds when full. (The player's old max_water was 90.)
@export var capacity: float = 90.0
## Optional pictures for the free-standing item. Leave empty to keep the one sprite you have.
## texture_full is shown whenever there is any water in it.
@export var texture_empty: Texture2D
@export var texture_full: Texture2D
## After being put down, it can't be picked up again for this long (stops one key press
## from putting it down and instantly picking it back up).
@export var pickup_cooldown: float = 0.4

var water: float = 0.0
var is_carried: bool = false
var carrier: Node = null

static var _handled_frame: int = -1     # makes sure one key press picks up only ONE item

var _active: bool = true                # true = lying on the ground and usable
var _start_pos: Vector2 = Vector2.ZERO
var _start_visible: bool = true
var _blocked_until_msec: int = 0
var _default_texture: Texture2D = null

@onready var _sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D


# ── things the child scripts change ────────────────────────────────
func _item_kind() -> int:
	return KIND_ROLLER


func _player_can_pick_up() -> bool:
	return true


func _on_picked_up_by_player() -> void:
	pass          # hippo_roller.gd uses this for its quest and tutorial


# ── setup ──────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("carryable")
	_start_pos = global_position
	_start_visible = visible
	if _sprite != null:
		_default_texture = _sprite.texture
	water = 0.0
	_refresh_texture()
	_set_active(_start_visible)


# ── information ────────────────────────────────────────────────────
func display_name() -> String:
	return "hippo roller" if _item_kind() == KIND_ROLLER else "water bucket"


func is_empty() -> bool:
	return water <= 0.0


func is_full() -> bool:
	return water >= capacity - 0.001


func carry_code() -> int:
	## Which animation set a carrier should use while holding this.
	if _item_kind() == KIND_ROLLER:
		return CODE_ROLLER
	return CODE_BUCKET_EMPTY if is_empty() else CODE_BUCKET_FULL


# ── picking up and putting down (used by players and NPCs) ─────────
func pick_up(by: Node) -> bool:
	## Returns false if someone already has it, or it isn't lying on the ground.
	if is_carried or not _active:
		return false
	is_carried = true
	carrier = by
	_set_active(false)
	picked_up.emit(by)
	return true


func put_down(at: Vector2) -> void:
	global_position = at
	is_carried = false
	carrier = null
	_blocked_until_msec = Time.get_ticks_msec() + int(pickup_cooldown * 1000.0)
	_set_active(true)
	put_down_at.emit(at)


# ── water ──────────────────────────────────────────────────────────
func set_water(value: float) -> void:
	var new_amount := clampf(value, 0.0, capacity)
	if is_equal_approx(new_amount, water):
		return
	water = new_amount
	_refresh_texture()
	water_changed.emit(water)


func add_water(amount: float) -> float:
	## Returns how much actually went in (the rest would overflow).
	var before := water
	set_water(water + amount)
	return water - before


func remove_water(amount: float) -> float:
	## Returns how much actually came out.
	var before := water
	set_water(water - amount)
	return before - water


func fill() -> void:
	set_water(capacity)


func empty() -> void:
	set_water(0.0)


# ── a new day ──────────────────────────────────────────────────────
func reset_for_new_day() -> void:
	## Emptied, and back to its home spot.
	var old_carrier = carrier
	is_carried = false
	carrier = null
	if old_carrier != null and is_instance_valid(old_carrier) and old_carrier.has_method("on_carryable_reset"):
		old_carrier.on_carryable_reset(self)       # tells the carrier to let go
	global_position = home_position()
	set_water(0.0)
	_set_active(_start_visible)


func home_position() -> Vector2:
	if home_marker != null and is_instance_valid(home_marker):
		return home_marker.global_position
	return _start_pos


# ── saving (for SaveManager) ───────────────────────────────────────
func get_save_dict() -> Dictionary:
	return {
		"id": item_id,
		"water": water,
		"x": global_position.x,
		"y": global_position.y,
		"carried": is_carried,
	}


func load_from_dict(data: Dictionary) -> void:
	set_water(float(data.get("water", 0.0)))
	if not data.get("carried", false):
		global_position = Vector2(
			float(data.get("x", global_position.x)),
			float(data.get("y", global_position.y)))
	# If it was being carried, whoever carried it restores it (the player does, by item_id).


# ── the player's pick-up key ───────────────────────────────────────
func _process(_delta: float) -> void:
	if not Input.is_action_just_pressed("equip_item"):
		return
	if not _player_can_pick_up():
		return
	if Engine.get_process_frames() == _handled_frame:
		return                                      # another item already took this key press
	if Time.get_ticks_msec() < _blocked_until_msec:
		return                                      # just put down; leave it alone
	for body in get_overlapping_bodies():
		if body.has_method("equip_carryable") or body.has_method("equip_hippo_roller"):
			_handled_frame = Engine.get_process_frames()
			_try_player_pickup(body)
			return


func _try_player_pickup(body) -> void:
	if body.has_method("equip_carryable"):
		# Full system: the item is kept, hidden, and remembers its water.
		if body.has_method("can_carry_item") and not body.can_carry_item():
			_say("Your hands are full.")            # already pushing or carrying something
			return
		if not pick_up(body):
			return
		body.equip_carryable(self)
		_on_picked_up_by_player()
	elif _item_kind() == KIND_ROLLER and body.has_method("equip_hippo_roller"):
		# Old player script: behave exactly as before (no water memory).
		body.equip_hippo_roller()
		_on_picked_up_by_player()
		queue_free()


# ── internals ──────────────────────────────────────────────────────
func _set_active(on: bool) -> void:
	_active = on
	visible = on
	set_deferred("monitoring", on)
	set_deferred("monitorable", on)
	set_process(on)


func _refresh_texture() -> void:
	if _sprite == null:
		return
	if not is_empty() and texture_full != null:
		_sprite.texture = texture_full
	else:
		_sprite.texture = texture_empty if texture_empty != null else _default_texture


func _say(text: String) -> void:
	var manager = get_node_or_null("/root/BuildingManager")
	if manager != null and manager.has_method("show_message"):
		manager.show_message(text)
	else:
		print(text)
