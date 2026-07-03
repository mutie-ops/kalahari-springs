extends Area2D

static var tutorial_shown: bool = false

func _process(_delta: float) -> void:
	# When E is pressed...
	if Input.is_action_just_pressed("equip_item"):
		
		# ...grab a list of EVERYTHING currently touching the roller
		var touching_objects = get_overlapping_bodies()
		
		# Check the list to see if the player is one of them
		for body in touching_objects:
			if body.has_method("equip_hippo_roller"):
				print("SUCCESS: Picked up the roller!")
				body.equip_hippo_roller()
				
				if not tutorial_shown:
					show_tutorial()
					tutorial_shown = true
					
				queue_free() # Delete from ground
				return # Stop looking once we find the player

func show_tutorial() -> void:
	print("TUTORIAL: This is the Hippo Roller!")
