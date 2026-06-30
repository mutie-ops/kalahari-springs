extends CanvasLayer

# ============================================================
# GAME MENU PREVIEW SCRIPT
# For Godot 4
#
# What this does:
# - Press ESC to open/close menu
# - X button closes menu
# - Buttons print their name
# - Inventory items can show images/icons
# - Inventory category buttons filter items
# - Character profile image can be attached
# - Character information is editable at the top
# - Menu is forced above other UI layers
# - Designed to fit 1280 x 720
# ============================================================


# ============================================================
# IMPORTANT TEST SETTING
# ============================================================

# Keep this FALSE while testing.
# Once everything works, you can change it to TRUE
# if you want the game to pause when menu is open.
const PAUSE_GAME_WHEN_MENU_OPEN := false


# ============================================================
# CHANGE THESE VALUES FIRST
# ============================================================

const MENU_SIZE := Vector2(1220, 660)

const BACKGROUND_DIM_COLOR := Color(0, 0, 0, 0.55)

const MAIN_PANEL_COLOR := Color(0.03, 0.04, 0.045, 0.94)
const MAIN_PANEL_BORDER_COLOR := Color(0.55, 0.48, 0.33, 0.7)

const INNER_PANEL_COLOR := Color(0.025, 0.03, 0.032, 0.96)
const INNER_PANEL_BORDER_COLOR := Color(0.28, 0.27, 0.22, 1.0)

const TITLE_COLOR := Color(0.95, 0.9, 0.78)
const NORMAL_TEXT_COLOR := Color(0.86, 0.84, 0.78)
const GOLD_TEXT_COLOR := Color(0.95, 0.88, 0.65)

const TOP_BUTTON_SIZE := Vector2(145, 48)
const CLOSE_BUTTON_SIZE := Vector2(52, 48)

const INVENTORY_SLOT_SIZE := Vector2(72, 58)

const INVENTORY_PANEL_WIDTH := 430
const ITEM_DETAILS_PANEL_WIDTH := 360
const CHARACTER_PANEL_WIDTH := 360

const INVENTORY_SLOT_COUNT := 20
const INVENTORY_GRID_COLUMNS := 5


# ============================================================
# CHARACTER PROFILE IMAGE
# ============================================================
# Change this to your character portrait image.
#
# Example:
# const CHARACTER_PROFILE_IMAGE_PATH := "res://graphics/npcs/hippo_default.png"
# ============================================================

const CHARACTER_PROFILE_IMAGE_PATH := "res://graphics/npcs/hippo_default.png"


# ============================================================
# CHARACTER INFORMATION
# ============================================================
# CHANGE YOUR CHARACTER DETAILS HERE.
# These are the ONLY character variables now used by the UI.
# Removed variables:
# level, health_max, mana, attack, defense, magic, crit chance, move speed.
# ============================================================

var character_info := {
	"name": "Hope",
	"class": "Farmer",
	"affection_points": 12,

	"experience_current": 1250,
	"experience_next": 2000,

	"health_current": 350,
	"hippo_roller_water_level": 350,

	"stamina_current": 150,
	"stamina_max": 150,

	"status_effects": "No active effects"
}


# ============================================================
# INVENTORY ITEMS
# ============================================================
# CATEGORY FILTERING USES THIS FIELD:
#
# "category": "Crops"
# "category": "Accessories"
# "category": "Quest Items"
#
# The category text must match the button text exactly.
# ============================================================

var inventory_items := [
	{
		"name": "Tomatoes",
		"amount": 5,
		"category": "Crops",
		"description": "Fresh tomatoes grown on the farm.",
		"icon": "res://assets/items/tomatoes.png"
	},
	{
		"name": "Corn",
		"amount": 3,
		"category": "Crops",
		"description": "Corn harvested from the field.",
		"icon": "res://assets/items/corn.png"
	},
	{
		"name": "Carrot",
		"amount": 8,
		"category": "Crops",
		"description": "A fresh carrot from the garden.",
		"icon": "res://assets/items/carrot.png"
	},
	{
		"name": "Wheat",
		"amount": 12,
		"category": "Crops",
		"description": "Useful for making bread and other foods.",
		"icon": "res://assets/items/wheat.png"
	},
	{
		"name": "Silver Ring",
		"amount": 1,
		"category": "Accessories",
		"description": "A simple silver ring. It looks valuable.",
		"icon": "res://assets/items/ring.png"
	},
	{
		"name": "Lucky Charm",
		"amount": 1,
		"category": "Accessories",
		"description": "A small charm said to bring good fortune.",
		"icon": "res://assets/items/charm.png"
	},
	{
		"name": "Necklace",
		"amount": 1,
		"category": "Accessories",
		"description": "A decorative necklace.",
		"icon": "res://assets/items/necklace.png"
	},
	{
		"name": "Old Key",
		"amount": 1,
		"category": "Quest Items",
		"description": "A key needed to open an old locked door.",
		"icon": "res://assets/items/key.png"
	},
	{
		"name": "Ancient Scroll",
		"amount": 1,
		"category": "Quest Items",
		"description": "A scroll with writing from an old civilization.",
		"icon": "res://assets/items/scroll.png"
	},
	{
		"name": "Village Letter",
		"amount": 1,
		"category": "Quest Items",
		"description": "A letter that must be delivered to someone in the village.",
		"icon": "res://assets/items/letter.png"
	}
]


# ============================================================
# INTERNAL VARIABLES
# ============================================================

var menu_open: bool = false
var menu_panel: Control
var item_description_label: Label
var item_grid: GridContainer

var current_inventory_filter := "All"
var previous_mouse_mode := Input.MOUSE_MODE_VISIBLE


# ============================================================
# READY
# ============================================================

func _ready() -> void:
	# Put this menu above other HUDs / overlays / CanvasLayers.
	layer = 999

	# Keep script active.
	process_mode = Node.PROCESS_MODE_ALWAYS

	_build_menu_ui()

	# Keep generated UI active.
	_force_menu_controls_active(menu_panel)

	menu_panel.visible = false

	print("Menu preview loaded.")


# ============================================================
# ESCAPE KEY OPEN / CLOSE
# ============================================================

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_menu()
		get_viewport().set_input_as_handled()


func toggle_menu() -> void:
	if menu_open:
		close_menu()
	else:
		open_menu()


func open_menu() -> void:
	menu_open = true
	menu_panel.visible = true

	previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_force_menu_controls_active(menu_panel)

	if PAUSE_GAME_WHEN_MENU_OPEN:
		get_tree().paused = true

	print("Menu opened")


func close_menu() -> void:
	menu_open = false
	menu_panel.visible = false

	if PAUSE_GAME_WHEN_MENU_OPEN:
		get_tree().paused = false

	Input.mouse_mode = previous_mouse_mode

	print("Menu closed")


# ============================================================
# BUILD FULL MENU UI
# ============================================================

func _build_menu_ui() -> void:
	menu_panel = Control.new()
	menu_panel.name = "MenuPanel"
	menu_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(menu_panel)

	var dim_background := ColorRect.new()
	dim_background.name = "DimBackground"
	dim_background.color = BACKGROUND_DIM_COLOR
	dim_background.mouse_filter = Control.MOUSE_FILTER_STOP
	dim_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_panel.add_child(dim_background)

	var main_frame := Panel.new()
	main_frame.name = "MainFrame"

	var screen_size := get_viewport().get_visible_rect().size
	main_frame.position = (screen_size - MENU_SIZE) / 2.0
	main_frame.size = MENU_SIZE
	main_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE

	main_frame.add_theme_stylebox_override(
		"panel",
		_make_panel_style(
			MAIN_PANEL_COLOR,
			MAIN_PANEL_BORDER_COLOR,
			2
		)
	)

	menu_panel.add_child(main_frame)

	var main_vbox := VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.position = Vector2(12, 12)
	main_vbox.size = MENU_SIZE - Vector2(24, 24)
	main_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_theme_constant_override("separation", 14)
	main_frame.add_child(main_vbox)

	_build_top_bar(main_vbox)
	_build_content_area(main_vbox)
	_build_bottom_hint(main_vbox)


# ============================================================
# TOP BAR
# ============================================================

func _build_top_bar(parent: VBoxContainer) -> void:
	var top_tabs := HBoxContainer.new()
	top_tabs.name = "TopTabs"
	top_tabs.custom_minimum_size = Vector2(0, 50)
	top_tabs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_tabs.add_theme_constant_override("separation", 4)
	parent.add_child(top_tabs)

	_add_top_button(top_tabs, "Inventory")
	_add_top_button(top_tabs, "Load")
	_add_top_button(top_tabs, "Save")
	_add_top_button(top_tabs, "Character")

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_tabs.add_child(spacer)

	_add_close_button(top_tabs)


func _add_top_button(parent: HBoxContainer, text_value: String) -> void:
	var button := Button.new()

	button.name = text_value + "Button"
	button.text = text_value
	button.custom_minimum_size = TOP_BUTTON_SIZE
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	button.add_theme_stylebox_override(
		"normal",
		_make_button_style(Color(0.08, 0.085, 0.08, 0.92))
	)

	button.add_theme_stylebox_override(
		"hover",
		_make_button_style(Color(0.32, 0.24, 0.08, 1.0))
	)

	button.add_theme_stylebox_override(
		"pressed",
		_make_button_style(Color(0.35, 0.25, 0.08, 1.0))
	)

	button.add_theme_color_override("font_color", TITLE_COLOR)
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.62))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.82, 0.40))

	button.pressed.connect(_on_button_pressed.bind(text_value))

	parent.add_child(button)


func _add_close_button(parent: HBoxContainer) -> void:
	var button := Button.new()

	button.name = "CloseButton"
	button.text = "X"
	button.custom_minimum_size = CLOSE_BUTTON_SIZE
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	button.add_theme_stylebox_override(
		"normal",
		_make_button_style(Color(0.10, 0.08, 0.08, 0.95))
	)

	button.add_theme_stylebox_override(
		"hover",
		_make_button_style(Color(0.55, 0.08, 0.05, 1.0))
	)

	button.add_theme_stylebox_override(
		"pressed",
		_make_button_style(Color(0.70, 0.05, 0.04, 1.0))
	)

	button.add_theme_color_override("font_color", Color(1.0, 0.85, 0.78))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))

	button.pressed.connect(close_menu)

	parent.add_child(button)


# ============================================================
# MAIN CONTENT AREA
# ============================================================

func _build_content_area(parent: VBoxContainer) -> void:
	var content_area := HBoxContainer.new()
	content_area.name = "ContentArea"
	content_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_area.add_theme_constant_override("separation", 14)
	parent.add_child(content_area)

	_build_inventory_panel(content_area)
	_build_item_details_panel(content_area)
	_build_character_panel(content_area)


# ============================================================
# LEFT PANEL: INVENTORY
# ============================================================

func _build_inventory_panel(parent: HBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.name = "InventoryPanel"
	panel.custom_minimum_size = Vector2(INVENTORY_PANEL_WIDTH, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(
			INNER_PANEL_COLOR,
			INNER_PANEL_BORDER_COLOR,
			1
		)
	)

	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.name = "InventoryVBox"
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "INVENTORY"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	vbox.add_child(title)

	_build_inventory_categories(vbox)
	_build_inventory_grid(vbox)
	_build_inventory_bottom(vbox)


func _build_inventory_categories(parent: VBoxContainer) -> void:
	var categories := HBoxContainer.new()
	categories.name = "CategoryButtons"
	categories.custom_minimum_size = Vector2(0, 45)
	categories.mouse_filter = Control.MOUSE_FILTER_IGNORE
	categories.add_theme_constant_override("separation", 4)
	parent.add_child(categories)

	for category in ["All", "Accessories", "Crops", "Quest Items"]:
		var b := Button.new()
		b.text = category
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		b.add_theme_stylebox_override(
			"normal",
			_make_button_style(Color(0.08, 0.08, 0.08, 0.95))
		)

		b.add_theme_stylebox_override(
			"hover",
			_make_button_style(Color(0.26, 0.20, 0.08, 1.0))
		)

		b.add_theme_stylebox_override(
			"pressed",
			_make_button_style(Color(0.35, 0.25, 0.08, 1.0))
		)

		b.add_theme_color_override("font_color", TITLE_COLOR)
		b.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.62))

		# CATEGORY FILTER HAPPENS HERE
		b.pressed.connect(_filter_inventory.bind(category))

		categories.add_child(b)


func _build_inventory_grid(parent: VBoxContainer) -> void:
	item_grid = GridContainer.new()
	item_grid.name = "ItemGrid"
	item_grid.columns = INVENTORY_GRID_COLUMNS
	item_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_grid.add_theme_constant_override("h_separation", 6)
	item_grid.add_theme_constant_override("v_separation", 6)
	parent.add_child(item_grid)

	# Load all items by default.
	_populate_inventory_grid("All")


func _populate_inventory_grid(filter_category: String) -> void:
	if item_grid == null:
		return

	# Clear old slots before rebuilding the grid.
	for child in item_grid.get_children():
		item_grid.remove_child(child)
		child.queue_free()

	var filtered_items := []

	for item in inventory_items:
		var item_category: String = str(item.get("category", ""))

		if filter_category == "All" or item_category == filter_category:
			filtered_items.append(item)

	for i in range(INVENTORY_SLOT_COUNT):
		var slot := Button.new()

		slot.custom_minimum_size = INVENTORY_SLOT_SIZE
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.focus_mode = Control.FOCUS_NONE
		slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		slot.text = ""

		slot.add_theme_stylebox_override(
			"normal",
			_make_button_style(Color(0.055, 0.055, 0.055, 0.96))
		)

		slot.add_theme_stylebox_override(
			"hover",
			_make_button_style(Color(0.22, 0.17, 0.08, 1.0))
		)

		slot.add_theme_stylebox_override(
			"pressed",
			_make_button_style(Color(0.35, 0.25, 0.08, 1.0))
		)

		slot.add_theme_color_override("font_color", NORMAL_TEXT_COLOR)
		slot.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.62))

		if i < filtered_items.size():
			var item: Dictionary = filtered_items[i]
			_create_item_visual(slot, item)
			slot.pressed.connect(_on_item_pressed.bind(item))
		else:
			slot.pressed.connect(_on_button_pressed.bind("Empty slot " + str(i + 1)))

		item_grid.add_child(slot)


func _filter_inventory(category: String) -> void:
	current_inventory_filter = category

	print("Filtering inventory by: ", category)

	_populate_inventory_grid(category)

	if item_description_label != null:
		item_description_label.text = "Showing: " + category


func _create_item_visual(slot: Button, item: Dictionary) -> void:
	var item_name: String = str(item.get("name", "Unknown Item"))
	var amount: int = int(item.get("amount", 1))
	var icon_path: String = str(item.get("icon", ""))

	slot.tooltip_text = item_name + " x" + str(amount)

	var icon := TextureRect.new()
	icon.name = "ItemIcon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)

	icon.offset_left = 6
	icon.offset_top = 6
	icon.offset_right = -6
	icon.offset_bottom = -14

	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	if icon_path != "":
		if ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
		else:
			push_warning("Item icon not found: " + icon_path)

	slot.add_child(icon)

	var amount_label := Label.new()
	amount_label.name = "AmountLabel"
	amount_label.text = "x" + str(amount)
	amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amount_label.set_anchors_preset(Control.PRESET_FULL_RECT)

	amount_label.offset_left = 4
	amount_label.offset_top = 4
	amount_label.offset_right = -5
	amount_label.offset_bottom = -3

	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	amount_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.62))
	amount_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	amount_label.add_theme_constant_override("shadow_offset_x", 1)
	amount_label.add_theme_constant_override("shadow_offset_y", 1)

	slot.add_child(amount_label)


func _build_inventory_bottom(parent: VBoxContainer) -> void:
	var bottom := Label.new()
	bottom.text = "Weight: 18.6 / 50.0        Gold: 1,250"
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_theme_color_override("font_color", GOLD_TEXT_COLOR)
	parent.add_child(bottom)


# ============================================================
# MIDDLE PANEL: ITEM DETAILS
# ============================================================

func _build_item_details_panel(parent: HBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.name = "ItemDetailsPanel"
	panel.custom_minimum_size = Vector2(ITEM_DETAILS_PANEL_WIDTH, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(
			INNER_PANEL_COLOR,
			INNER_PANEL_BORDER_COLOR,
			1
		)
	)

	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.name = "ItemDetailsVBox"
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "ITEM DETAILS"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	vbox.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(spacer)

	item_description_label = Label.new()
	item_description_label.name = "ItemDescription"
	item_description_label.text = "Select an item to see details."
	item_description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_description_label.add_theme_color_override("font_color", Color(0.75, 0.72, 0.66))
	vbox.add_child(item_description_label)

	var bottom_spacer := Control.new()
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(bottom_spacer)


func _on_item_pressed(item: Dictionary) -> void:
	var item_name: String = str(item.get("name", "Unknown Item"))
	var amount: int = int(item.get("amount", 1))
	var category: String = str(item.get("category", "Unknown"))
	var description: String = str(item.get("description", "No description."))

	print("Item clicked: ", item_name)

	if item_description_label != null:
		item_description_label.text = item_name + "\n\nCategory: " + category + "\nAmount: x" + str(amount) + "\n\n" + description


# ============================================================
# RIGHT PANEL: CHARACTER INFORMATION
# ============================================================

func _build_character_panel(parent: HBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.name = "CharacterPanel"
	panel.custom_minimum_size = Vector2(CHARACTER_PANEL_WIDTH, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(
			INNER_PANEL_COLOR,
			INNER_PANEL_BORDER_COLOR,
			1
		)
	)

	parent.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.name = "CharacterScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.name = "CharacterVBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)

	var title := Label.new()
	title.text = "CHARACTER INFORMATION"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	vbox.add_child(title)

	_build_character_top_info(vbox)
	_build_character_stats(vbox)


func _build_character_top_info(parent: VBoxContainer) -> void:
	var info_row := HBoxContainer.new()
	info_row.name = "CharacterTopInfo"
	info_row.custom_minimum_size = Vector2(0, 125)
	info_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_row.add_theme_constant_override("separation", 12)
	parent.add_child(info_row)

	var portrait_box := PanelContainer.new()
	portrait_box.name = "CharacterPortraitBox"
	portrait_box.custom_minimum_size = Vector2(120, 120)
	portrait_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_box.add_theme_stylebox_override(
		"panel",
		_make_panel_style(
			Color(0.12, 0.11, 0.10, 1.0),
			Color(0.40, 0.34, 0.22, 1.0),
			1
		)
	)
	info_row.add_child(portrait_box)

	var portrait := TextureRect.new()
	portrait.name = "CharacterPortraitImage"
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(120, 120)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_box.add_child(portrait)

	if CHARACTER_PROFILE_IMAGE_PATH != "":
		if ResourceLoader.exists(CHARACTER_PROFILE_IMAGE_PATH):
			portrait.texture = load(CHARACTER_PROFILE_IMAGE_PATH)
		else:
			push_warning("Character profile image not found: " + CHARACTER_PROFILE_IMAGE_PATH)

	var info := Label.new()
	info.text = _get_character_top_text()
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_theme_color_override("font_color", TITLE_COLOR)
	info_row.add_child(info)


func _build_character_stats(parent: VBoxContainer) -> void:
	var stats_title := Label.new()
	stats_title.text = "VITALS"
	stats_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_title.add_theme_font_size_override("font_size", 20)
	stats_title.add_theme_color_override("font_color", TITLE_COLOR)
	parent.add_child(stats_title)

	var stats := Label.new()
	stats.text = _get_character_stats_text()
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats.add_theme_color_override("font_color", NORMAL_TEXT_COLOR)
	parent.add_child(stats)


func _get_character_top_text() -> String:
	return "Name\n%s\n\nClass\n%s\n\nAffection Points\n%s\n\nExperience\n%s / %s" % [
		character_info["name"],
		character_info["class"],
		character_info["affection_points"],
		character_info["experience_current"],
		character_info["experience_next"]
	]


func _get_character_stats_text() -> String:
	return """
Health                  %s
Hippo Roller Water      %s
Stamina                 %s / %s

STATUS EFFECTS

%s
""" % [
		character_info["health_current"],
		character_info["hippo_roller_water_level"],
		character_info["stamina_current"],
		character_info["stamina_max"],
		character_info["status_effects"]
	]


# ============================================================
# BOTTOM HINT
# ============================================================

func _build_bottom_hint(parent: VBoxContainer) -> void:
	var bottom_hint := Label.new()
	bottom_hint.name = "BottomHint"
	bottom_hint.text = "ESC  Close Menu"
	bottom_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom_hint.add_theme_color_override("font_color", TITLE_COLOR)
	parent.add_child(bottom_hint)


# ============================================================
# BUTTON CLICK TEST
# ============================================================

func _on_button_pressed(button_name: String) -> void:
	print("Button clicked: ", button_name)


# ============================================================
# HOVER / PAUSE FIX
# ============================================================

func _force_menu_controls_active(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_ALWAYS

	for child in node.get_children():
		_force_menu_controls_active(child)


# ============================================================
# STYLE HELPERS
# ============================================================

func _make_panel_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()

	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)

	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4

	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 14
	style.content_margin_bottom = 14

	return style


func _make_button_style(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()

	style.bg_color = bg_color
	style.border_color = Color(0.35, 0.31, 0.22, 0.9)
	style.set_border_width_all(1)

	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3

	return style
