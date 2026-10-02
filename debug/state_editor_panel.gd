extends Control
## Auto-generates one editable field per GameState variable.
## Drop this script onto the root Control node of a new debug panel tab.
## Requires two child nodes underneath it (see setup instructions):
##   ScrollContainer -> PropertyList (a VBoxContainer)

@onready var property_list_container: VBoxContainer = $ScrollContainer/PropertyList

# Column widths in pixels, tuned to fit comfortably inside a 640x360
# viewport. Increase these if your project's base resolution is larger.
const LABEL_WIDTH: int = 150
const FIELD_WIDTH: int = 110

# Keeps track of which LineEdit belongs to which GameState property,
# so we can refresh their displayed values later.
var field_refs: Dictionary = {}


func _ready() -> void:
	_build_fields()


func _process(_delta: float) -> void:
	# Only bother refreshing while this tab is actually visible on screen.
	if visible:
		_refresh_values()


func _build_fields() -> void:
	# Clear out anything already there (in case this ever gets rebuilt).
	for child in property_list_container.get_children():
		child.queue_free()
	field_refs.clear()

	# get_property_list() returns EVERY property on GameState, including
	# built-in ones inherited from Node. PROPERTY_USAGE_SCRIPT_VARIABLE
	# filters that down to just the "var" declarations you wrote yourself.
	for prop in GameState.get_property_list():
		if not (prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue

		var prop_name: String = prop.name
		var row := HBoxContainer.new()

		var label := Label.new()
		label.text = prop_name
		label.custom_minimum_size.x = LABEL_WIDTH
		# Without this, a property name longer than LABEL_WIDTH would keep
		# growing the Label (and the whole row) past the edge of the
		# screen -- this is what was pushing content off both sides.
		label.clip_text = true
		# Lets you hover over a truncated name to see the full text.
		label.tooltip_text = prop_name
		row.add_child(label)

		var field := LineEdit.new()
		field.text = str(GameState.get(prop_name))
		field.custom_minimum_size.x = FIELD_WIDTH
		# text_submitted fires when you press Enter inside the field.
		field.text_submitted.connect(_on_field_submitted.bind(prop_name))
		row.add_child(field)

		property_list_container.add_child(row)
		field_refs[prop_name] = field


func _on_field_submitted(new_text: String, prop_name: String) -> void:
	var current_value = GameState.get(prop_name)
	var parsed_value = _parse_value(new_text, current_value)
	GameState.set(prop_name, parsed_value)
	print("[Debug Panel] Set GameState.%s = %s" % [prop_name, str(parsed_value)])


func _parse_value(text: String, reference_value: Variant) -> Variant:
	# Uses the CURRENT value's type to decide how to interpret what you typed,
	# so typing into an int field gives you an int, a bool field gives you a bool, etc.
	match typeof(reference_value):
		TYPE_BOOL:
			return text.strip_edges().to_lower() in ["true", "1", "yes"]
		TYPE_INT:
			return text.to_int()
		TYPE_FLOAT:
			return text.to_float()
		_:
			return text


func _refresh_values() -> void:
	for prop_name in field_refs.keys():
		var live_value = GameState.get(prop_name)
		var field: LineEdit = field_refs[prop_name]
		# Don't overwrite text while you're actively typing/editing a field.
		if not field.has_focus():
			field.text = str(live_value)
