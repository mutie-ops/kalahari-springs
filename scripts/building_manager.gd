extends Node
## BuildingManager — autoload. ONE shared brain for entering/leaving every building.
## Doors and interiors are tiny; all the real work happens here.

signal building_entered(building_id: String)
signal building_exited(building_id: String)

# ---- Settings you can tune -------------------------------------------------
const INTERIOR_ORIGIN_X := 20000.0   # interiors are parked this far from the village
const INTERIOR_SPACING := 3000.0     # gap between parked interiors
const FADE_TIME := 0.25              # seconds to fade out, and again to fade in
const MESSAGE_SECONDS := 2.5         # how long a message stays
const RETRIGGER_COOLDOWN_MSEC := 1500
const HOME_BUILDING_ID := "homestead_interior"    # the door Hope wakes up behind after a forced bedtime
const DEBUG_KEYS := true             # set to false before shipping
const CARRIED_ITEM_DROP_OFFSET := Vector2(16, 8)

# ---- Internals --------------------------------------------------------------
@onready var fade_rect: ColorRect = $FadeLayer/FadeRect
@onready var message_panel: PanelContainer = $MessageLayer/MessagePanel
@onready var message_label: Label = $MessageLayer/MessagePanel/MessageLabel

var _busy := false
var _cooldown_until_msec := 0
var _interiors: Dictionary = {}      # building_id -> the interior instance (cached)
var _slots: Dictionary = {}          # building_id -> parking slot number
var _doors: Dictionary = {}          # building_id -> the BuildingDoor node
var _current_interior            # untyped on purpose
var _current_door                # untyped on purpose
var _player                      # untyped on purpose
var _message_tween: Tween

var temporary_closures: Dictionary = {}   # building_id -> {until, reason}
var last_door_id := ""


# =============================================================================
#  DOOR REGISTRY  (NEW) — doors add themselves here when the level loads
# =============================================================================
func register_door(door) -> void:
	_doors[door.building_id] = door


func get_door(building_id: String):
	var d = _doors.get(building_id)
	if d != null and is_instance_valid(d):
		return d
	return null


func is_busy() -> bool:
	return _busy


# =============================================================================
#  ENTERING
# =============================================================================
func try_enter(door, player) -> void:
	if _busy or Time.get_ticks_msec() < _cooldown_until_msec:
		return
	last_door_id = door.building_id

	# 1. Locked?
	var reason: String = door.get_denied_reason()
	if reason != "":
		show_message(reason)
		_cooldown_until_msec = Time.get_ticks_msec() + RETRIGGER_COOLDOWN_MSEC
		return

	# 2. Special case: this door plays a Dialogic cutscene instead of an interior
	if door.cutscene_timeline != "":
		_cooldown_until_msec = Time.get_ticks_msec() + RETRIGGER_COOLDOWN_MSEC
		Dialogic.start(door.cutscene_timeline)
		return

	# 3. No interior built yet?
	if door.interior_scene == null:
		show_message("(There's no interior for this building yet.)")
		_cooldown_until_msec = Time.get_ticks_msec() + RETRIGGER_COOLDOWN_MSEC
		return

	await _enter(door, player)


func _enter(door, player) -> void:
	_busy = true
	_current_door = door
	_player = player
	_player.frozen = true
	_leave_carried_item_outside(door)
	await _fade(1.0)

	# Build the interior the first time, then reuse it (so chests, etc. keep their contents)
	_current_interior = _get_or_make_interior(door, _player.get_parent())
	_current_interior.visible = true

	_player.global_position = _current_interior.get_entry_position()
	_player.velocity = Vector2.ZERO
	_set_day_tint(false)
	_set_camera(_current_interior)
	building_entered.emit(door.building_id)

	await _fade(0.0)
	_player.frozen = false
	_busy = false


func _get_or_make_interior(door, parent: Node):
	var id: String = door.building_id
	if not _interiors.has(id) or not is_instance_valid(_interiors[id]):
		var inst = door.interior_scene.instantiate()
		parent.add_child(inst)                    # same y-sorted layer the player lives in
		if not _slots.has(id):
			_slots[id] = _slots.size()
		inst.global_position = Vector2(INTERIOR_ORIGIN_X + INTERIOR_SPACING * _slots[id], 0.0)
		_interiors[id] = inst
	return _interiors[id]


# =============================================================================
#  LEAVING
# =============================================================================
func exit_building() -> void:
	if _busy or _current_interior == null:
		return
	_busy = true
	_player.frozen = true
	await _fade(1.0)

	_restore_camera()
	_set_day_tint(true)
	_player.global_position = _current_door.get_exit_position()
	_player.velocity = Vector2.ZERO
	_current_interior.visible = false
	var id: String = _current_door.building_id
	_current_interior = null
	_current_door = null
	building_exited.emit(id)
	_cooldown_until_msec = Time.get_ticks_msec() + 800

	await _fade(0.0)
	_player.frozen = false
	_busy = false


# =============================================================================
#  A NEW DAY  (NEW) — called by level.gd while the screen is black
# =============================================================================
func start_new_day(passed_out: bool) -> void:
	temporary_closures.clear()
	for npc in get_tree().get_nodes_in_group("npc_schedule"):
		npc.start_new_day()
	if passed_out:
		if _wake_at_home():
			show_message("You stayed up too late. You wake up at home.")
		else:
			show_message("You stayed up too late.")


func _wake_at_home() -> bool:
	var door = get_door(HOME_BUILDING_ID)
	var player = get_tree().get_first_node_in_group("player")
	if door == null or player == null or door.interior_scene == null:
		return false
	_player = player
	if _current_interior != null and _current_door == door:
		return true                                    # already inside the homestead
	if _current_interior != null:                      # was inside some other building
		_current_interior.visible = false
		building_exited.emit(_current_door.building_id)
	_current_door = door
	_current_interior = _get_or_make_interior(door, player.get_parent())
	_current_interior.visible = true
	player.global_position = _current_interior.get_wake_position()
	player.velocity = Vector2.ZERO
	_set_day_tint(false)
	_set_camera(_current_interior)
	_cooldown_until_msec = Time.get_ticks_msec() + 800
	building_entered.emit(HOME_BUILDING_ID)
	return true


# =============================================================================
#  NPCs GOING IN AND OUT  (NEW) — used by the NPC schedule code (Part C)
# =============================================================================
func npc_enter(npc, building_id: String) -> bool:
	## Moves the NPC into the building's parked interior. Returns false if it can't.
	var door = get_door(building_id)
	if door == null or door.interior_scene == null:
		return false
	var interior = _get_or_make_interior(door, npc.get_parent())
	var spot := interior.get_node_or_null("NPCSpot_" + npc.npc_id) as Node2D
	if spot:
		npc.global_position = spot.global_position
	else:
		npc.global_position = interior.get_entry_position() + Vector2(0, -40)
	npc.velocity = Vector2.ZERO
	return true


func npc_exit(npc, building_id: String) -> bool:
	## Puts the NPC just outside the building's door.
	var door = get_door(building_id)
	if door == null:
		return false
	npc.global_position = door.get_exit_position()
	npc.velocity = Vector2.ZERO
	return true
	
# =============================================================================
#  LEAVE CARRIED ITEM OUTSIDE.
# =============================================================================

func _leave_carried_item_outside(door) -> void:
	## Anything the player is pushing or carrying stays outside the door.
	if not _player.has_method("get_carried_item"):
		return
	var item = _player.get_carried_item()
	if item == null:
		return
	_player.release_carried_item(door.get_exit_position() + CARRIED_ITEM_DROP_OFFSET)
	show_message("You leave the %s outside." % item.display_name())

# =============================================================================
#  CAMERA — fixed inside the room, normal outside
# =============================================================================
func _set_camera(interior) -> void:
	var cam := _player.get_node_or_null("Camera2D") as Camera2D
	if cam == null or not interior.fixed_camera:
		return
	cam.top_level = true                      # detach from following the player
	cam.global_position = interior.get_camera_position()


func _restore_camera() -> void:
	var cam := _player.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return
	cam.top_level = false
	cam.position = Vector2.ZERO               # back to sitting on the player


# =============================================================================
#  DAY/NIGHT TINT — switched off indoors so the room isn't darkened at night
#  (Your DayTimeColor node must be in the group "day_tint" — see v01 Section 8.)
# =============================================================================
func _set_day_tint(on: bool) -> void:
	for n in get_tree().get_nodes_in_group("day_tint"):
		n.visible = on


# =============================================================================
#  FADE + MESSAGE
# =============================================================================
func _fade(target_alpha: float) -> void:
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", target_alpha, FADE_TIME)
	await tw.finished


func show_message(text: String) -> void:
	message_label.text = text
	message_panel.visible = true
	message_panel.modulate.a = 0.0
	if _message_tween:
		_message_tween.kill()
	_message_tween = create_tween()
	_message_tween.tween_property(message_panel, "modulate:a", 1.0, 0.15)
	_message_tween.tween_interval(MESSAGE_SECONDS)
	_message_tween.tween_property(message_panel, "modulate:a", 0.0, 0.4)
	_message_tween.tween_callback(func(): message_panel.visible = false)


# =============================================================================
#  INFORMAL CLOSURES — "Getting water. Back at 2 p.m."
#  Example:   BuildingManager.close_temporarily("coop", 14.0, "Getting water")
#             BuildingManager.reopen("coop")
#  All closures clear automatically each morning.
# =============================================================================
func close_temporarily(building_id: String, back_at_hour: float, reason: String = "Getting water") -> void:
	temporary_closures[building_id] = {"until": back_at_hour, "reason": reason}


func reopen(building_id: String) -> void:
	temporary_closures.erase(building_id)


func get_temporary_closure(building_id: String) -> String:
	## Returns the message if temporarily closed, or "" if not.
	if not temporary_closures.has(building_id):
		return ""
	var c: Dictionary = temporary_closures[building_id]
	if GameClock.hour >= c["until"]:
		temporary_closures.erase(building_id)   # time's up, auto-reopen
		return ""
	return "%s. Back at %s." % [c["reason"], GameClock.format_time(c["until"])]


# =============================================================================
#  DEBUG KEYS (testing only — set DEBUG_KEYS to false when you're done)
#     [   = village clock one hour earlier     ]   = one hour later
#     \   = close the last door you touched for 2 hours ("Getting water")
#     =   = give Naledi +1 Heart (to test trust-gated homes)
#  (The [ and ] keys move the clock only; the day/night tint doesn't follow.
#   Offsets reset every morning.)
# =============================================================================
func _unhandled_input(event: InputEvent) -> void:
	if not DEBUG_KEYS:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_BRACKETLEFT:
			GameClock.debug_offset -= 1.0
			print("DEBUG clock offset: ", GameClock.debug_offset, " h")
		KEY_BRACKETRIGHT:
			GameClock.debug_offset += 1.0
			print("DEBUG clock offset: ", GameClock.debug_offset, " h")
		KEY_BACKSLASH:
			if last_door_id != "":
				close_temporarily(last_door_id, GameClock.hour + 2.0)
				print("DEBUG: closed '", last_door_id, "' for 2 hours")
		KEY_EQUAL:
			GameState.award_hearts("naledi", 1)
			print("DEBUG: naledi hearts = ", GameState.naledi_hearts)
