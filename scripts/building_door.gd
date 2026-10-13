extends Area2D

## BuildingDoor — walk into this and BuildingManager decides what happens.

## Everything you tune is in the Inspector, per building. No code edits needed.

enum Access { ALWAYS_OPEN, BUSINESS_HOURS, NPC_TRUST, STORY_FLAG }

@export var building_id: String = ""            # unique, no spaces: "coop", "workshop", "naledi_home"

@export var display_name: String = "the building"   # how it reads in a sentence: "the co-op"

@export var interior_scene: PackedScene          # drag the interior .tscn here

@export var access: Access = Access.ALWAYS_OPEN

@export_group("Business hours")

@export_range(0.0, 24.0, 0.25) var open_hour: float = 8.0      # 8.0 = 8 a.m., 17.5 = 5:30 p.m.

@export_range(0.0, 24.0, 0.25) var close_hour: float = 17.0

@export_multiline var closed_message: String = ""   # leave empty for an automatic message

@export_group("NPC trust")

@export var host_npc: String = ""               # "naledi", "ezekiel", "mama_zulu" ... (GameState names)

@export_range(0, 10) var required_hearts: int = 4

@export_multiline var trust_message: String = ""

@export_group("Story flag")

@export var story_flag: String = ""             # a GameState variable name, e.g. "school_construction_complete"

@export_multiline var flag_message: String = ""

@export_group("Special")

@export var cutscene_timeline: String = ""      # Dialogic timeline to play INSTEAD of entering (e.g. meetinghouse)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2            # the player lives on physics layer 2
	body_entered.connect(_on_body_entered)
	if building_id != "":
		BuildingManager.register_door(self)
	else:
		push_warning("BuildingDoor '%s' has no Building Id." % name)


func _on_body_entered(body: Node2D) -> void:

	if body.is_in_group("player"):

		BuildingManager.try_enter(self, body)


func get_exit_position() -> Vector2:

	return $ExitSpawn.global_position


func get_denied_reason() -> String:

	## Returns "" if Hope may enter, otherwise the message to show.

	match access:

		Access.ALWAYS_OPEN:

			return ""

		Access.BUSINESS_HOURS:

			if not GameClock.is_between(open_hour, close_hour):

				if closed_message != "":

					return closed_message

				var when := "at " + GameClock.format_time(open_hour)

				if GameClock.hour >= close_hour:

					when = "tomorrow " + when

				return "%s is closed. Come back %s." % [_sentence_name(), when]

			# Inside normal hours — but is the owner out for a while?

			return BuildingManager.get_temporary_closure(building_id)

		Access.NPC_TRUST:

			if host_npc == "" or not (host_npc in GameState.NPCS):

				push_warning("BuildingDoor '%s': host_npc '%s' is not a valid NPC name." % [building_id, host_npc])

				return "(This door isn't set up yet.)"

			if GameState.hearts(host_npc) < required_hearts:

				if trust_message != "":

					return trust_message

				return "You haven't been invited in yet."

			return ""

		Access.STORY_FLAG:

			var v = GameState.get(story_flag)

			if v == true or v == "complete":

				return ""

			if flag_message != "":

				return flag_message

			return "%s is locked." % _sentence_name()

	return ""


func _sentence_name() -> String:

	## "the co-op" -> "The co-op"

	if display_name == "":

		return "This place"

	return display_name.substr(0, 1).to_upper() + display_name.substr(1)
