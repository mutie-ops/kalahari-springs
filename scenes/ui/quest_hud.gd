extends CanvasLayer

func _ready() -> void:
	# This confirms the script is actually loaded in your game world
	print("============ [HUD DEBUG] ALIVE AND LISTENING FOR QUESTS ============")
	
	QuestWeaverGlobal.quest_objective_state_changed.connect(_on_objective_state_changed)


func _on_objective_state_changed(quest_id: StringName, objective_id: StringName, new_status: int) -> void:
	print("\n=============================================")
	print("📢 [QUEST WEAVER SIGNAL DETECTED]")
	print("🔹 Quest ID: ", quest_id)
	print("🔹 Objective ID: ", objective_id)
	print("🔹 New Status Enum Value: ", new_status)
	print("=============================================\n")
