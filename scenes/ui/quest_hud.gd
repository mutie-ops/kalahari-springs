extends CanvasLayer

@onready var panel_container = $PanelContainer
@onready var title_label = $PanelContainer/VBoxContainer/QuestTitle
@onready var objective_label = $PanelContainer/VBoxContainer/QuestObjective

func _ready() -> void:
	# Tell the HUD to update itself every time ANY dialogue finishes
	Dialogic.timeline_ended.connect(_update_quest_hud)
	
	# Run it once right when the game starts to set the initial state
	_update_quest_hud()

func _update_quest_hud() -> void:
	# Grab the live status directly from Dialogic's master database
	var naledi_status = Dialogic.VAR.get_variable("Naledi_Quests.water_burden_status")
	
	# Phase 0 (Not Started) or Phase 3 (Finished) -> Hide the HUD
	if naledi_status == 0.0 or naledi_status == 3.0:
		panel_container.hide()
		title_label.text = ""
		objective_label.text = ""
		
	# Phase 1: Quest Active -> Show "Find the Roller" text
	elif naledi_status == 1.0:
		title_label.text = "Water Burden"
		objective_label.text = "Find a solution for fetching water before evening."
		panel_container.show()
		
	# Phase 2: Found Item -> Show "Return to Naledi" text
	elif naledi_status == 2.0:
		title_label.text = "Water Burden"
		objective_label.text = "You found the Hippo Roller! Return it to Naledi."
		panel_container.show()
