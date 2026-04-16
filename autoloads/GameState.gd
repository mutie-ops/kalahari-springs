extends Node

var good_will: int = 0
var active_quests: Array = []
var completed_quests: Array = []

func _ready():
	Dialogic.signal_event.connect(_on_dialogic_signal)

func _on_dialogic_signal(arg: String):
	match arg:
		"quest_start_water_burden":
			start_quest("water_burden_naledi")
		"quest_complete_water_burden":
			complete_quest("water_burden_naledi")
			start_quest("naledi_stall_reopening")
		"add_goodwill_5":
			good_will += 5
		"add_goodwill_20":
			good_will += 20
		"subtract_goodwill_5":
			good_will -= 5

func start_quest(quest_id: String):
	if quest_id not in active_quests and quest_id not in completed_quests:
		active_quests.append(quest_id)
		print("Quest started: ", quest_id)

func complete_quest(quest_id: String):
	if quest_id in active_quests:
		active_quests.erase(quest_id)
		completed_quests.append(quest_id)
		print("Quest completed: ", quest_id)
