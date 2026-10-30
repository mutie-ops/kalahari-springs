class_name HippoRoller
extends Carryable
## The free-standing hippo roller. All pick-up / put-down / water behaviour is in
## carryable.gd. This file only keeps the roller's own quest and tutorial logic.
## The player's side of carrying is in player.gd (equip_carryable and friends).

static var tutorial_shown: bool = false

var DIALOG_TIMELINE = 'Hippo_Act1'


func _item_kind() -> int:
	return KIND_ROLLER


func _on_picked_up_by_player() -> void:
	# ____QUEST LOGIC____  (only the player's pick-up counts, never an NPC's)
	print("DEBUG: Checking quest status...")
	var current_status = Dialogic.VAR.get_variable("Naledi_Quests.water_burden_status")
	print("DEBUG: Current status is: ", current_status)

	if current_status == 1.0:
		# status update to found hippo roller item
		print("DEBUG: Status was 1, changing to 2!")
		Dialogic.VAR.set_variable("Naledi_Quests.water_burden_status", 2.0)
		print("DEBUG: The real Dialogic status is now: ", Dialogic.VAR.get_variable("Naledi_Quests.water_burden_status"))
		# Hippo dialog for found item
		Dialogic.start(DIALOG_TIMELINE)
	else:
		print("DEBUG: Status was NOT 1, so the quest didn't update.")

	if not tutorial_shown:
		show_tutorial()
		tutorial_shown = true


func show_tutorial() -> void:
	print("TUTORIAL: This is the Hippo Roller!")
