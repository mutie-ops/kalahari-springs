class_name NpcBase
extends CharacterBody2D
## Base script for every NPC in Kalahari Springs (attach to the root of npc_base.tscn).
##
## What this script does for every NPC:
##   1. CARRY ANIMATIONS: swaps between four animation sets
##        none / bucket_empty / bucket_full / roller
##   2. ITEMS: picks up, carries, fills and puts down real Rollers and Buckets
##      (carryable.gd). Items remember whether they are full.
##   3. ROUTES: follows a path of Marker2D / PathPoint nodes under "Routes" in the level.
##      Which route is active is decided by the NPC's own script.
##   4. BUILDINGS: walks to a door and goes inside. Anything she is carrying is
##      left outside the door.
##   5. DIALOG: starts a Dialogic timeline when the player walks into InteractionArea.
##
## Each NPC's own script (e.g. naledi_npc.gd) only overrides two small functions:
##   _choose_place() -> String    where is she right now? ""=outdoors, or a building id
##   _choose_route() -> String    which route does she follow outdoors? ""=stand still

# ── carry versions ─────────────────────────────────────────────────
enum Carry { NONE, BUCKET_EMPTY, BUCKET_FULL, ROLLER }
# Animation names are  <idle|walk>_<down|left|right|up>[_<suffix>]
const CARRY_SUFFIX := ["", "bucket_empty", "bucket_full", "roller"]

enum Mode { STAND, ROUTE, TRANSIT, INSIDE }

# ── per-NPC settings (set in the Inspector) ────────────────────────
@export var npc_id: String = ""                   # must match GameState.NPCS, e.g. "naledi"
@export var dialog_timeline: String = ""          # Dialogic timeline name
@export var walk_speed: float = 30.0              # pixels per second
@export_enum("down", "left", "right", "up") var start_facing: String = "down"
@export var starting_carry: Carry = Carry.NONE    # what she carries each morning
@export var player_group: StringName = &"hope"    # group the player's body is in
@export var talk_delay: float = 0.3               # lets the player stop before dialog opens
## How close she must be to an item to pick it up.
@export var pickup_reach: float = 48.0
## Where a carried item is left, relative to the spot just outside a door.
@export var door_drop_offset: Vector2 = Vector2(16, 8)

# ── state ──────────────────────────────────────────────────────────
var _mode: int = Mode.STAND
var _carry: int = Carry.NONE
var _facing: String = "down"
var _dialog_open: bool = false

var _place: String = ""             # building she is inside ("" = outdoors)
var _route_name: String = ""        # outdoor route she is on ("" = none)
var _points: Array[Dictionary] = [] # the points she is walking through right now
var _route_mode: int = NpcRoute.Mode.ONCE
var _index: int = 0
var _dir: int = 1
var _pause_left: float = 0.0
var _transit_kind: String = ""      # "enter" or "leave"
var _transit_building: String = ""
var _held_item: Carryable = null

var _home_pos: Vector2 = Vector2.ZERO
var _last_pos: Vector2 = Vector2.ZERO
var _stuck_time: float = 0.0
var _warned: Dictionary = {}

var _clock = null                   # GameClock autoload (if it exists)
var _buildings = null               # BuildingManager autoload (if it exists)
var _routes_root: Node = null

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _area: Area2D = $InteractionArea


# ══════════════════════════════════════════════════════════════════
#  OVERRIDE THESE IN THE NPC'S OWN SCRIPT
# ══════════════════════════════════════════════════════════════════
func _choose_place() -> String:
	return ""          # "" = outdoors, otherwise a Building Id such as "naledi_homestead"


func _choose_route() -> String:
	return ""          # "" = stand still, otherwise the name of a node under Routes


# ── helpers for the NPC's own script ───────────────────────────────
func current_hour() -> float:
	if _clock != null:
		return _clock.hour
	return 12.0


func hour_between(start_hour: float, end_hour: float) -> bool:
	var h := current_hour()
	return h >= start_hour and h < end_hour


# ══════════════════════════════════════════════════════════════════
#  SETUP
# ══════════════════════════════════════════════════════════════════
func _ready() -> void:
	add_to_group("npc")
	add_to_group("npc_schedule")      # BuildingManager calls start_new_day() on this group
	_clock = get_node_or_null("/root/GameClock")
	_buildings = get_node_or_null("/root/BuildingManager")
	_facing = start_facing
	_carry = starting_carry
	_home_pos = global_position
	_last_pos = global_position

	_area.body_entered.connect(_on_body_entered)
	Dialogic.timeline_ended.connect(_on_dialog_ended)
	if _clock != null and _clock.has_signal("hour_changed"):
		_clock.hour_changed.connect(_on_hour_changed)

	_play_anim("idle")
	refresh.call_deferred()           # decide what to do once the whole level exists


func _on_hour_changed(_hour: float) -> void:
	refresh()


# ══════════════════════════════════════════════════════════════════
#  DECIDING WHAT TO DO
#  Call refresh() any time something changes (the clock calls it for you).
# ══════════════════════════════════════════════════════════════════
func refresh() -> void:
	if _mode == Mode.TRANSIT:
		return                          # finish walking to/from the door first

	var want_place := _choose_place()
	if want_place != _place:
		if _place != "":
			_leave_building()
			return
		if _start_walk_into(want_place):
			return
		# couldn't go in (door missing?) so carry on outdoors
	if _place != "":
		return                          # stays inside

	var want_route := _choose_route()
	if want_route == _route_name:
		return                          # already on the right route
	_start_route(want_route)


func start_new_day() -> void:
	## Called by BuildingManager every morning while the screen is black.
	## (level.gd resets all rollers and buckets separately, in level_reset().)
	_points.clear()
	_place = ""
	_route_name = ""
	_transit_building = ""
	_held_item = null
	_warned.clear()
	velocity = Vector2.ZERO
	global_position = _home_pos
	_carry = starting_carry
	_facing = start_facing
	_mode = Mode.STAND
	var want := _choose_place()
	if want != "" and _buildings != null and _buildings.npc_enter(self, want):
		_place = want
		_mode = Mode.INSIDE
		_facing = "down"
	else:
		refresh()
	_play_anim("idle")


# ══════════════════════════════════════════════════════════════════
#  CARRYING
# ══════════════════════════════════════════════════════════════════
func set_carry(new_carry: int) -> void:
	## Switch animation set. Safe to call from cutscenes, quests, or PathPoints.
	_carry = new_carry
	_play_anim("idle")        # walking states replace this on the next frame


func get_carry() -> int:
	return _carry


func get_carried_item() -> Carryable:
	return _held_item


func on_carryable_reset(item) -> void:
	## The morning reset took the item she was holding.
	if item == _held_item:
		_held_item = null
		_carry = Carry.NONE
		_play_anim("idle")


func _pick_up_item(item) -> void:
	if _held_item != null:
		_warn_once("hands_" + name, "%s: already holding something, so she can't pick up another item." % name)
		return
	if item == null or not is_instance_valid(item):
		_warn_once("noitem_" + name, "%s: a PathPoint says pick_up_item but no Item is assigned on it." % name)
		return
	if item.global_position.distance_to(global_position) > pickup_reach:
		_warn_once("far_" + name, "%s: the item isn't within reach (someone may have moved it)." % name)
		return
	if not item.pick_up(self):
		_warn_once("taken_" + name, "%s: the item is already being carried by someone else." % name)
		return
	_held_item = item
	set_carry(item.carry_code())


func _put_down_item(at: Vector2) -> void:
	if _held_item == null or not is_instance_valid(_held_item):
		_held_item = null
		_warn_once("nothing_" + name, "%s: a PathPoint says put_down_item but she isn't holding anything." % name)
		return
	_held_item.put_down(at)
	_held_item = null
	set_carry(Carry.NONE)


func _drop_item_outside(spot: Vector2) -> void:
	## She is about to go indoors: whatever she carries stays outside.
	if _held_item != null and is_instance_valid(_held_item):
		_held_item.put_down(spot)
	_held_item = null
	_carry = Carry.NONE


func _play_anim(type: String) -> void:
	var base := "%s_%s" % [type, _facing]
	var suffix: String = CARRY_SUFFIX[_carry]
	var anim := base if suffix == "" else base + "_" + suffix
	if not _sprite.sprite_frames.has_animation(anim):
		if suffix != "":
			_warn_once("anim_" + anim, "%s: missing animation '%s', using '%s'" % [name, anim, base])
		anim = base
		if not _sprite.sprite_frames.has_animation(anim):
			return
	if _sprite.animation != anim:
		_sprite.play(anim)


# ══════════════════════════════════════════════════════════════════
#  PHYSICS LOOP
# ══════════════════════════════════════════════════════════════════
func _physics_process(delta: float) -> void:
	if _dialog_open:
		velocity = Vector2.ZERO
		_play_anim("idle")
		return

	match _mode:
		Mode.ROUTE:
			if _follow_points(delta):
				_mode = Mode.STAND          # a one-way route ended; she waits there
				_play_anim("idle")
		Mode.TRANSIT:
			if _follow_points(delta):
				_finish_transit()
		_:
			pass                            # STAND and INSIDE: nothing to do


# ══════════════════════════════════════════════════════════════════
#  ROUTES
# ══════════════════════════════════════════════════════════════════
func _start_route(route_name: String) -> void:
	_route_name = route_name
	velocity = Vector2.ZERO
	if route_name == "":
		_mode = Mode.STAND
		_play_anim("idle")
		return

	var node := _find_route(route_name)
	if node == null:
		_warn_once("route_" + route_name, "%s: no route called '%s' under Routes in the level." % [name, route_name])
		_mode = Mode.STAND
		_play_anim("idle")
		return
	_points = _build_points(node, false)
	if _points.is_empty():
		_warn_once("empty_" + route_name, "%s: route '%s' has no Marker2D children." % [name, route_name])
		_mode = Mode.STAND
		_play_anim("idle")
		return

	_route_mode = NpcRoute.Mode.ONCE
	var route := node as NpcRoute
	if route != null:
		_route_mode = route.mode
		if route.carry_on_start > 0 and _held_item == null:
			set_carry(route.carry_on_start - 1)   # 0 = keep, 1 = none, 2 = empty, 3 = full
	if _points.size() == 1:
		_route_mode = NpcRoute.Mode.ONCE
	_begin_walk(Mode.ROUTE)


func _begin_walk(new_mode: int) -> void:
	_mode = new_mode
	_index = 0
	_dir = 1
	_pause_left = 0.0
	_stuck_time = 0.0
	_last_pos = global_position
	velocity = Vector2.ZERO


func _follow_points(delta: float) -> bool:
	## Walks the current points. Returns true when a one-way list has finished.
	if _points.is_empty():
		return true

	if _pause_left > 0.0:
		_pause_left -= delta
		_play_anim("idle")
		if _pause_left <= 0.0:
			return _advance_point()
		return false

	var point: Dictionary = _points[_index]
	var target: Vector2 = point["pos"]
	var to_target := target - global_position
	if to_target.length() <= maxf(2.0, walk_speed * delta * 1.5):
		velocity = Vector2.ZERO
		return _arrive(point)

	if absf(to_target.x) > absf(to_target.y):
		_facing = "right" if to_target.x > 0.0 else "left"
	else:
		_facing = "down" if to_target.y > 0.0 else "up"
	velocity = to_target.normalized() * walk_speed
	_play_anim("walk")
	move_and_slide()

	# If something blocks her for 3 seconds, hop to the point instead of freezing.
	if global_position.distance_to(_last_pos) < 0.05:
		_stuck_time += delta
		if _stuck_time > 3.0:
			global_position = target
			_stuck_time = 0.0
	else:
		_stuck_time = 0.0
	_last_pos = global_position
	return false


func _arrive(point: Dictionary) -> bool:
	_run_action(point)
	if point["face"] != "":
		_facing = point["face"]
	if point["pause"] > 0.0:
		_pause_left = point["pause"]
		_play_anim("idle")
		return false
	return _advance_point()


func _advance_point() -> bool:
	## Moves to the next point. Returns true if a one-way list just finished.
	var count := _points.size()
	if _route_mode == NpcRoute.Mode.PING_PONG and count > 1:
		if _index + _dir >= count or _index + _dir < 0:
			_dir = -_dir
		_index += _dir
		return false
	_index += 1
	if _index >= count:
		if _route_mode == NpcRoute.Mode.LOOP:
			_index = 0
			return false
		_index = count - 1
		return true
	return false


func _run_action(point: Dictionary) -> void:
	match point["action"]:
		"set_carry":
			set_carry(point["carry"])
		"pick_up_item", "pick_up_roller":          # old name still works
			_pick_up_item(point["item"])
		"put_down_item", "put_down_roller":
			_put_down_item(point["pos"] + point["drop_offset"])
		"fill_item":
			if _held_item != null and is_instance_valid(_held_item):
				_held_item.fill()
				set_carry(_held_item.carry_code())
			else:
				_warn_once("fill_" + name, "%s: a PathPoint says fill_item but she isn't holding anything." % name)
		"empty_item":
			if _held_item != null and is_instance_valid(_held_item):
				_held_item.empty()
				set_carry(_held_item.carry_code())
			else:
				_warn_once("empty_" + name, "%s: a PathPoint says empty_item but she isn't holding anything." % name)


func _build_points(route: Node, reverse: bool) -> Array[Dictionary]:
	## Turns the Marker2D children of a route node into a list of points.
	var pts: Array[Dictionary] = []
	if route == null:
		return pts
	for child in route.get_children():
		var node := child as Node2D
		if node == null:
			continue
		var point := {
			"pos": node.global_position, "pause": 0.0, "face": "",
			"action": "none", "carry": 0, "item": null, "drop_offset": Vector2.ZERO,
		}
		var pp := node as PathPoint
		if pp != null:
			point["pause"] = pp.pause_seconds
			point["face"] = "" if pp.face_after == "keep" else pp.face_after
			point["action"] = pp.action
			point["carry"] = pp.carry
			point["item"] = pp.item
			point["drop_offset"] = pp.drop_offset
		pts.append(point)
	if reverse:
		pts.reverse()
		for point in pts:               # a walk back through a doorway just walks
			point["pause"] = 0.0
			point["face"] = ""
			point["action"] = "none"
	return pts


func _find_route(route_name: String) -> Node:
	var root := _get_routes_root()
	if root == null or route_name == "":
		return null
	return root.get_node_or_null(route_name)    # "folder/route" paths work too


func _get_routes_root() -> Node:
	if _routes_root == null or not is_instance_valid(_routes_root):
		var scene := get_tree().current_scene
		if scene != null:
			_routes_root = scene.find_child("Routes", true, false)
	return _routes_root


# ══════════════════════════════════════════════════════════════════
#  GOING INTO / OUT OF BUILDINGS  (needs BuildingManager)
# ══════════════════════════════════════════════════════════════════
func _start_walk_into(building_id: String) -> bool:
	if _buildings == null:
		return false
	var door = _buildings.get_door(building_id)
	if door == null or door.interior_scene == null:
		_warn_once("door_" + building_id, "%s: can't go into '%s'. Is its door placed with an Interior Scene filled in?" % [name, building_id])
		return false
	var pts := _build_points(_find_route("%s_to_%s" % [npc_id, building_id]), false)
	pts.append({
		"pos": door.get_exit_position(), "pause": 0.0, "face": "",
		"action": "none", "carry": 0, "item": null, "drop_offset": Vector2.ZERO,
	})
	_points = pts
	_route_mode = NpcRoute.Mode.ONCE
	_transit_kind = "enter"
	_transit_building = building_id
	_begin_walk(Mode.TRANSIT)
	return true


func _leave_building() -> void:
	var id := _place
	_place = ""
	_route_name = ""
	if _buildings == null or not _buildings.npc_exit(self, id):
		global_position = _home_pos
		_mode = Mode.STAND
		refresh()
		return
	var pts := _build_points(_find_route("%s_to_%s" % [npc_id, id]), true)
	if pts.is_empty():
		_mode = Mode.STAND
		refresh()
		return
	_points = pts
	_route_mode = NpcRoute.Mode.ONCE
	_transit_kind = "leave"
	_transit_building = id
	_begin_walk(Mode.TRANSIT)


func _finish_transit() -> void:
	velocity = Vector2.ZERO
	_route_name = ""
	if _transit_kind == "enter" and _choose_place() == _transit_building:
		var spot := global_position + door_drop_offset
		var door = _buildings.get_door(_transit_building) if _buildings != null else null
		if door != null:
			spot = door.get_exit_position() + door_drop_offset
		if _buildings != null and _buildings.npc_enter(self, _transit_building):
			_drop_item_outside(spot)    # the roller or bucket stays outside the door
			_place = _transit_building
			_mode = Mode.INSIDE
			_facing = "down"
			_play_anim("idle")
		else:
			_mode = Mode.STAND
			_play_anim("idle")
	else:
		# Finished walking back out, or the schedule changed while she was walking
		# to the door (so there is no point going in just to come straight out).
		_mode = Mode.STAND
		_play_anim("idle")
	_transit_building = ""
	refresh()                           # the clock may have moved on while she walked


# ══════════════════════════════════════════════════════════════════
#  DIALOG
# ══════════════════════════════════════════════════════════════════
func _on_body_entered(body: Node) -> void:
	if _dialog_open or not body.is_in_group(player_group):
		return
	if dialog_timeline == "":
		_warn_once("timeline", "%s: no dialog_timeline set." % name)
		return
	_dialog_open = true
	velocity = Vector2.ZERO
	_play_anim("idle")
	await get_tree().create_timer(talk_delay).timeout
	Dialogic.start(dialog_timeline)


func _on_dialog_ended() -> void:
	_dialog_open = false      # she carries on exactly where she stopped


func _warn_once(key: String, message: String) -> void:
	if not _warned.has(key):
		_warned[key] = true
		push_warning(message)
