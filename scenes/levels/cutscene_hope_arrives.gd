extends SubViewportContainer

# ── Node references ──────────────────────────
@onready var hope: Sprite2D = $SubViewport/Hope
@onready var bus_prop: Sprite2D = $SubViewport/BusProp
@onready var bg_landscape: Sprite2D = $SubViewport/BG_Landscape
@onready var bg_bus_doors: Sprite2D = $SubViewport/BG_BusDoors
@onready var photo_closeup: Sprite2D = $SubViewport/PhotoCloseup
@onready var anim: AnimationPlayer = $AnimationPlayer
# @onready var bus_audio: AudioStreamPlayer = $AudioStreamPlayer # Uncomment when you add audio

# ── Hope portrait frames (assign in Inspector) ──
@export var portrait_neutral: Texture2D
@export var portrait_look_right: Texture2D
@export var portrait_look_left: Texture2D
@export var portrait_musing: Texture2D
@export var portrait_warm: Texture2D
@export var portrait_determined: Texture2D
@export var portrait_holds_photo: Texture2D

func _ready() -> void:
	bg_landscape.visible = true
	# photo_closeup.visible = false
	
	Dialogic.signal_event.connect(_on_dialogic_signal)
	
	# Play the opening staging animation, then start the timeline
	anim.play("scene_open")
	await anim.animation_finished
	Dialogic.start("hope_arrives")

func _on_dialogic_signal(arg: String) -> void:
	match arg:
		"look_right":
			if portrait_look_right: hope.texture = portrait_look_right
		"look_left":
			if portrait_look_left: hope.texture = portrait_look_left
		"hope_musing":
			if portrait_musing: hope.texture = portrait_musing
		"hope_neutral":
			if portrait_neutral: hope.texture = portrait_neutral
		"hope_determined":
			if portrait_determined: hope.texture = portrait_determined
		"hope_holds_photo":
			if portrait_holds_photo: hope.texture = portrait_holds_photo
		"bus_depart":
			_play_bus_departure()
		"show_photo_closeup":
			_show_photo_closeup()
		"cutscene_end":
			_end_cutscene()

func _play_bus_departure() -> void:
	# bus_audio.play() # Uncomment when you add audio
	anim.play("bus_exit")

func _show_photo_closeup() -> void:
	anim.play("show_photo")

func _end_cutscene() -> void:
	GameState.first_launch_complete = true
	SaveManager.save_game(0)
	get_tree().change_scene_to_file("res://scenes/levels/level.tscn")
