extends Area2D

static var tutorial_shown: bool = false

var DIALOG_TIMELINE = 'Hippo_Act1'

func _process(_delta: float) -> void:
	# When E is pressed...s
	if Input.is_action_just_pressed("equip_item"):
		
		# ...grab a list of EVERYTHING currently touching the roller
		var touching_objects = get_overlapping_bodies()
		
		# Check the list to see if the player is one of them
		for body in touching_objects:
			if body.has_method("equip_hippo_roller"):
				print("SUCCESS: Picked up the roller!")
				body.equip_hippo_roller()
				
#				#____QUEST LOQIC____
				#Check Naledi Quest
				print("DEBUG: Checking quest status...")
				var current_status = Dialogic.VAR.Naledi_Quests.water_burden_status
				print("DEBUG: Current status is: ", current_status)
				
				if Dialogic.VAR.get_variable("Naledi_Quests.water_burden_status") ==1.0:
					# status update to found hippo roller item
					print("DEBUG: Status was 1, changing to 2!")
					Dialogic.VAR.set_variable("Naledi_Quests.water_burden_status", 2.0)
					print("DEBUG: The real Dialogic status is now: ", Dialogic.VAR.get_variable("Naledi_Quests.water_burden_status"))
					# Hope the hippo Dialog for found item
					Dialogic.start(DIALOG_TIMELINE)
				else:
					print("DEBUG: Status was NOT 1, so the quest didn't update.")
				
				if not tutorial_shown:
					show_tutorial()
					tutorial_shown = true
					
				queue_free() # Delete from ground
				return # Stop looking once we find the player

func show_tutorial() -> void:
	print("TUTORIAL: This is the Hippo Roller!")
