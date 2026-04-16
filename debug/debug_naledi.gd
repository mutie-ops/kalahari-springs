extends Control

func _ready():
	pass  # nothing needed here anymore

func _on_start_button_pressed():
	# Set test variables immediately before starting dialogue
	# so they are never overwritten by Dialogic's initialisation
	Dialogic.VAR.set("hearts_naledi", 2)
	Dialogic.VAR.set("hippo_has_roller", true)
	Dialogic.VAR.set("water_burden_quest_active", false)
	Dialogic.VAR.set("water_burden_quest_complete", false)
	Dialogic.VAR.set("water_burden_thanked", false)
	Dialogic.VAR.set("naledi_mentioned_stall", false)
	Dialogic.VAR.set("hippo_carried_water_today", false)
	Dialogic.VAR.set("current_season", "Summer")
	
	Dialogic.start("res://dialog/naledi_router.dtl")
