extends NpcBase
## Naledi's own rules. Everything else (walking, carrying, doors, dialog) lives in npc_base.gd.
##
## Inspector settings on her scene:
##   npc_id = naledi          dialog_timeline = naledi_router
##   start_facing = left      starting_carry = Bucket Full   (change to taste)
##
## The route names below must match nodes under  Routes  in the level.
## (Example times only. Change them to suit the story.)


func _choose_place() -> String:
	## "" = outdoors. Otherwise the Building Id of the place she is inside.
	if hour_between(12.0, 13.0) or hour_between(19.0, 24.0):
		return "naledi_homestead"
	return ""


func _choose_route() -> String:
	## Checked top to bottom. The FIRST rule that matches wins, so put the
	## most specific rules (quests, milestones, seasons) at the top.

	# --- special cases go here, e.g. (needs hooking up to GameState) ---
	# if <quest "bring the roller" is active>:   return "naledi_roller_run"
	# if <it is the rainy season>:               return "naledi_rainy_loop"
	# if <milestone "well repaired" reached>:    return "naledi_new_well_loop"

	# --- time of day ---
	if hour_between(6.0, 9.0):
		return "naledi_fetch_water"       # bucket route (empty -> full -> empty)
	return "naledi_village_loop"          # ordinary loop
