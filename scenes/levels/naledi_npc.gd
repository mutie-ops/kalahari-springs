extends CharacterBody2D




# ── tuneable constants ─────────────────────────────────────────────
const WALK_SPEED   := 30.0   # pixels per second
const DIALOG_TIMELINE := "Naledi_Act1"  # your Dialogic timeline name
# ── walk cycle definition ──────────────────────────────────────────
# Each step: [direction_string, duration_seconds, pause_after_seconds]
# direction "" means "stay put and idle in the stated facing direction"
const WALK_STEPS := [
	["left",  4.0, 0.0],
	["down",  0.0, 1.0],   # turn to face down, pause
	["down",  6.0, 0.0],
	["",      0.0, 4.0],  # idle in place
	["up",    6.0, 0.0],
	["",      0.0, 0.0],   # snap to face right
	["right", 0.0, 2.0],   # face right, pause
	["right", 4.0, 0.0],
	["",      0.0, 4.0],  # idle at origin
	["left",  0.0, 0.0],   # snap to face left before repeat
]

# ── state ──────────────────────────────────────────────────────────
enum State { WALKING, IDLE, PAUSED }
var _state        : State = State.IDLE
var _step_index   : int   = 0
var _step_timer   : float = 0.0
var _in_pause     : bool  = false
var _pause_timer  : float = 0.0
var _facing       : String = "left"
var _dialog_open  : bool  = false

@onready var _sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var _area   : Area2D           = $Area2D

# ── init ───────────────────────────────────────────────────────────
func _ready() -> void:
	_area.body_entered.connect(_on_hope_entered)
	_area.body_exited.connect(_on_hope_exited)
	Dialogic.timeline_ended.connect(_on_dialog_ended)
	_start_step()

# ── main loop ─────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if _dialog_open:
		_play_anim("idle")
		return

	if _in_pause:
		_step_timer = 0.0
		_pause_timer -= delta
		_play_anim("idle")
		if _pause_timer <= 0.0:
			_in_pause = false
			_advance_step()
		return

	var step : Array = WALK_STEPS[_step_index]
	var dir   : String = step[0]
	var dur   : float  = step[1]

	if dir == "" or dur == 0.0:
		# This is a pure facing/pause step — handled in _start_step
		return

	_state = State.WALKING
	_step_timer -= delta
	_play_anim("walk")
	_move(dir, delta)

	if _step_timer <= 0.0:
		velocity = Vector2.ZERO
		_enter_pause_if_needed()

func _move(dir: String, delta: float) -> void:
	match dir:
		"left":  velocity = Vector2(-WALK_SPEED, 0)
		"right": velocity = Vector2( WALK_SPEED, 0)
		"up":    velocity = Vector2(0, -WALK_SPEED)
		"down":  velocity = Vector2(0,  WALK_SPEED)
	move_and_slide()

# ── step management ───────────────────────────────────────────────
func _start_step() -> void:
	var step : Array = WALK_STEPS[_step_index]
	var dir  : String = step[0]
	var dur  : float  = step[1]
	var pause: float  = step[2]

	# Update facing whenever direction is specified
	if dir != "":
		_facing = dir

	if dur > 0.0:
		_step_timer = dur
	else:
		# Zero-duration step: just face + immediately enter pause
		_state = State.IDLE
		_play_anim("idle")
		_in_pause = pause > 0.0
		_pause_timer = pause
		if not _in_pause:
			_advance_step()

func _enter_pause_if_needed() -> void:
	var pause : float = WALK_STEPS[_step_index][2]
	_state = State.IDLE
	if pause > 0.0:
		_in_pause    = true
		_pause_timer = pause
	else:
		_advance_step()

func _advance_step() -> void:
	_step_index = (_step_index + 1) % WALK_STEPS.size()
	_start_step()

# ── animation helper ──────────────────────────────────────────────
func _play_anim(type: String) -> void:
	var anim_name := type + "_" + _facing
	if _sprite.animation != anim_name:
		_sprite.play(anim_name)

# ── proximity signals ─────────────────────────────────────────────
func _on_hope_entered(body: Node) -> void:
	# Check it's actually Hope, not another body
	if body.is_in_group("hope"):
		_dialog_open = true
		velocity = Vector2.ZERO
		_play_anim("idle")
		# Small delay so Hope finishes moving before dialog opens
		await get_tree().create_timer(0.3).timeout
		
		# 1. Start the dialog
		Dialogic.start(DIALOG_TIMELINE)
		
func _on_hope_exited(body: Node) -> void:
	# Dialog closing is handled by timeline_ended signal instead
	pass

func _on_dialog_ended() -> void:
	_dialog_open = false
	# Resume from exactly where we were — _step_timer retained
