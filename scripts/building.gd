extends Sprite2D
## Shared by every building. Shows the right restoration stage.

@export var stage_textures: Array[Texture2D] = []      # body art for stage 0, 1, 2 ... (optional)
@export var stage_starts_at_chapter: Array[int] = [0]  # chapter where each stage begins

func _ready() -> void:
	GameState.day_started.connect(func(_day, _chapter): refresh())
	refresh()

func refresh() -> void:
	var stage := 0
	for i in stage_starts_at_chapter.size():
		if GameState.chapter >= stage_starts_at_chapter[i]:
			stage = i
	_apply_stage(stage)

func _apply_stage(n: int) -> void:
	if n < stage_textures.size() and stage_textures[n] != null:
		texture = stage_textures[n]
	for child in get_children():
		if child is CanvasItem and child.name.begins_with("Stage"):
			child.visible = n >= int(child.name.substr(5).get_slice("_", 0))
