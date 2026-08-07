extends Area2D

@export var fill_amount: float = 90.0 

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("water_action"): # (or "equip_item" if you used E!)
		print("--- WATER TEST TRIGGERED ---")
		
		var touching_objects = get_overlapping_bodies()
		print("Objects touching the water: ", touching_objects.size())
		
		for body in touching_objects:
			print("I see: ", body.name)
			
			if body.is_in_group("player"):
				print("SUCCESS: Found the player!")
				
				if body.has_hippo_roller:
					print("SUCCESS: Player has the roller!")
					if body.has_method("add_water"):
						body.add_water(fill_amount)
				else:
					print("FAIL: Player does NOT have the roller equipped!")
			else:
				print("FAIL: This object is not in the 'player' group.")
