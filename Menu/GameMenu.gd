extends CanvasLayer

# ============================================================
# GAME MENU SCRIPT (10-SLOT + DELETE & OVERWRITE CONFIRMATION)
# ============================================================
const PAUSE_GAME_WHEN_MENU_OPEN := false

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

const CHARACTER_PROFILE_IMAGE_PATH := "res://graphics/npcs/hippo_default.png"

# ============================================================
# DATA
# ============================================================
var character_info := {
	"name": "Hope", "class": "Farmer", "affection_points": 12,
	"experience_current": 1250, "experience_next": 2000,
	"health_current": 350, "hippo_roller_water_level": 350,
	"stamina_current": 150, "stamina_max": 150,
	"status_effects": "No active effects"
}

var inventory_items := [
	{"name": "Tomatoes", "amount": 5, "category": "Crops", "description": "Fresh tomatoes.", "icon": "res://assets/items/tomatoes.png"},
	{"name": "Old Key", "amount": 1, "category": "Quest Items", "description": "A key.", "icon": "res://assets/items/key.png"}
]

# ============================================================
# INTERNAL VARIABLES
# ============================================================
var menu_open: bool = false
var menu_panel: Control
var item_description_label: Label
var item_grid: GridContainer
var item_details_icon: TextureRect
var tab_inventory: HBoxContainer
var tab_character: HBoxContainer
var tab_load: PanelContainer
var tab_save: PanelContainer

var confirm_overlay: ColorRect
var confirm_label: Label
var pending_action: String = ""
var pending_slot: int = -1

var current_inventory_filter := "All"
var previous_mouse_mode := Input.MOUSE_MODE_VISIBLE
var current_selected_slot: int = -1

# ============================================================
# READY & INPUT
# ============================================================
func _ready() -> void:
	add_to_group("GameMenu")
	layer = 999
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_menu_ui()
	_force_menu_controls_active(menu_panel)
	menu_panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if confirm_overlay and confirm_overlay.visible:
			_on_confirm_no() # ESC closes prompt if it's open
		else:
			toggle_menu()
		get_viewport().set_input_as_handled()

func toggle_menu() -> void:
	if menu_open: close_menu()
	else: open_menu()

func open_menu() -> void:
	menu_open = true
	menu_panel.visible = true
	if confirm_overlay: confirm_overlay.visible = false
	previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_force_menu_controls_active(menu_panel)
	if PAUSE_GAME_WHEN_MENU_OPEN: get_tree().paused = true

func close_menu() -> void:
	menu_open = false
	menu_panel.visible = false
	if PAUSE_GAME_WHEN_MENU_OPEN: get_tree().paused = false
	Input.mouse_mode = previous_mouse_mode

# ============================================================
# UI BUILDERS
# ============================================================
func _build_menu_ui() -> void:
	menu_panel = Control.new()
	menu_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(menu_panel)

	var dim_background := ColorRect.new()
	dim_background.color = BACKGROUND_DIM_COLOR
	dim_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_panel.add_child(dim_background)

	var main_frame := Panel.new()
	var screen_size := get_viewport().get_visible_rect().size
	main_frame.position = (screen_size - MENU_SIZE) / 2.0
	main_frame.size = MENU_SIZE
	main_frame.add_theme_stylebox_override("panel", _make_panel_style(MAIN_PANEL_COLOR, MAIN_PANEL_BORDER_COLOR, 2))
	menu_panel.add_child(main_frame)

	var main_vbox := VBoxContainer.new()
	main_vbox.position = Vector2(12, 12)
	main_vbox.size = MENU_SIZE - Vector2(24, 24)
	main_vbox.add_theme_constant_override("separation", 14)
	main_frame.add_child(main_vbox)

	_build_top_bar(main_vbox)
	_build_content_area(main_vbox)
	_build_bottom_hint(main_vbox)
	
	# MUST be built last so it draws on top of everything
	_build_confirmation_overlay()

func _build_top_bar(parent: VBoxContainer) -> void:
	var top_tabs := HBoxContainer.new()
	top_tabs.custom_minimum_size = Vector2(0, 50)
	top_tabs.add_theme_constant_override("separation", 4)
	parent.add_child(top_tabs)
	_add_top_button(top_tabs, "Inventory")
	_add_top_button(top_tabs, "Load")
	_add_top_button(top_tabs, "Save")
	_add_top_button(top_tabs, "Character")
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_tabs.add_child(spacer)
	_add_close_button(top_tabs)

func _add_top_button(parent: HBoxContainer, text_value: String) -> void:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = TOP_BUTTON_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.08, 0.085, 0.08, 0.92)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.32, 0.24, 0.08, 1.0)))
	button.add_theme_color_override("font_color", TITLE_COLOR)
	button.pressed.connect(_on_button_pressed.bind(text_value))
	parent.add_child(button)

func _add_close_button(parent: HBoxContainer) -> void:
	var button := Button.new()
	button.text = "X"
	button.custom_minimum_size = CLOSE_BUTTON_SIZE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.10, 0.08, 0.08, 0.95)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.55, 0.08, 0.05, 1.0)))
	button.pressed.connect(close_menu)
	parent.add_child(button)

func _build_content_area(parent: VBoxContainer) -> void:
	var content_area := Control.new()
	content_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(content_area)

	tab_inventory = HBoxContainer.new()
	tab_inventory.set_anchors_preset(Control.PRESET_FULL_RECT)
	tab_inventory.add_theme_constant_override("separation", 14)
	content_area.add_child(tab_inventory)
	_build_inventory_panel(tab_inventory)
	_build_item_details_panel(tab_inventory)

	tab_character = HBoxContainer.new()
	tab_character.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_area.add_child(tab_character)
	_build_character_panel(tab_character)

	tab_load = PanelContainer.new()
	tab_load.set_anchors_preset(Control.PRESET_FULL_RECT)
	tab_load.add_theme_stylebox_override("panel", _make_panel_style(INNER_PANEL_COLOR, INNER_PANEL_BORDER_COLOR, 1))
	content_area.add_child(tab_load)
	
	tab_save = PanelContainer.new()
	tab_save.set_anchors_preset(Control.PRESET_FULL_RECT)
	tab_save.add_theme_stylebox_override("panel", _make_panel_style(INNER_PANEL_COLOR, INNER_PANEL_BORDER_COLOR, 1))
	content_area.add_child(tab_save)
	_switch_tab("Inventory")

# ============================================================
# CONFIRMATION MODAL OVERLAY
# ============================================================
func _build_confirmation_overlay() -> void:
	confirm_overlay = ColorRect.new()
	confirm_overlay.color = Color(0, 0, 0, 0.88)
	confirm_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	confirm_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	confirm_overlay.visible = false
	menu_panel.add_child(confirm_overlay)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	confirm_overlay.add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 250)
	panel.add_theme_stylebox_override("panel", _make_panel_style(MAIN_PANEL_COLOR, MAIN_PANEL_BORDER_COLOR, 3))
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 40)
	panel.add_child(vbox)

	confirm_label = Label.new()
	confirm_label.text = "Are you sure?"
	confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	confirm_label.add_theme_font_size_override("font_size", 22)
	confirm_label.add_theme_color_override("font_color", TITLE_COLOR)
	vbox.add_child(confirm_label)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 30)
	vbox.add_child(hbox)

	var yes_btn = Button.new()
	yes_btn.text = "YES"
	yes_btn.custom_minimum_size = Vector2(120, 45)
	yes_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	yes_btn.add_theme_stylebox_override("normal", _make_button_style(Color(0.55, 0.2, 0.05, 1.0)))
	yes_btn.add_theme_stylebox_override("hover", _make_button_style(Color(0.7, 0.25, 0.05, 1.0)))
	yes_btn.add_theme_color_override("font_color", TITLE_COLOR)
	yes_btn.pressed.connect(_on_confirm_yes)
	hbox.add_child(yes_btn)

	var no_btn = Button.new()
	no_btn.text = "NO"
	no_btn.custom_minimum_size = Vector2(120, 45)
	no_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	no_btn.add_theme_stylebox_override("normal", _make_button_style(Color(0.08, 0.085, 0.08, 0.92)))
	no_btn.add_theme_stylebox_override("hover", _make_button_style(Color(0.32, 0.24, 0.08, 1.0)))
	no_btn.add_theme_color_override("font_color", TITLE_COLOR)
	no_btn.pressed.connect(_on_confirm_no)
	hbox.add_child(no_btn)

func _prompt_confirmation(action: String, slot_index: int) -> void:
	pending_action = action
	pending_slot = slot_index
	
	if action == "overwrite":
		confirm_label.text = "Are you sure you want to overwrite Slot %d?\nPrevious progress will be permanently lost." % slot_index
	elif action == "delete":
		confirm_label.text = "Are you sure you want to delete Slot %d?\nThis cannot be undone." % slot_index
		
	confirm_overlay.visible = true

func _on_confirm_yes() -> void:
	confirm_overlay.visible = false
	if pending_action == "overwrite":
		_execute_save(pending_slot)
	elif pending_action == "delete":
		_execute_delete(pending_slot)
		
	pending_action = ""
	pending_slot = -1

func _on_confirm_no() -> void:
	confirm_overlay.visible = false
	pending_action = ""
	pending_slot = -1

func _execute_delete(slot_index: int) -> void:
	SaveManager.delete_save(slot_index)
	# Re-render whichever tab is currently active to reflect the deleted slot
	if tab_save.visible:
		_refresh_save_load_tab(tab_save, true)
	else:
		_refresh_save_load_tab(tab_load, false)

# ============================================================
# INVENTORY BUILDERS
# ============================================================
func _build_inventory_panel(parent: HBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(INVENTORY_PANEL_WIDTH, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_panel_style(INNER_PANEL_COLOR, INNER_PANEL_BORDER_COLOR, 1))
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "INVENTORY"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	vbox.add_child(title)

	_build_inventory_categories(vbox)
	_build_inventory_grid(vbox)

func _build_inventory_categories(parent: VBoxContainer) -> void:
	var categories := HBoxContainer.new()
	categories.custom_minimum_size = Vector2(0, 45)
	parent.add_child(categories)
	for category in ["All", "Accessories", "Crops", "Quest Items"]:
		var b := Button.new()
		b.text = category
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_stylebox_override("normal", _make_button_style(Color(0.08, 0.08, 0.08, 0.95)))
		b.pressed.connect(_filter_inventory.bind(category))
		categories.add_child(b)

func _build_inventory_grid(parent: VBoxContainer) -> void:
	item_grid = GridContainer.new()
	item_grid.columns = INVENTORY_GRID_COLUMNS
	item_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(item_grid)
	_populate_inventory_grid("All")

func _populate_inventory_grid(filter_category: String) -> void:
	if item_grid == null: return
	for child in item_grid.get_children():
		item_grid.remove_child(child)
		child.queue_free()

	var filtered_items := []
	for item in inventory_items:
		if filter_category == "All" or str(item.get("category", "")) == filter_category:
			filtered_items.append(item)

	for i in range(INVENTORY_SLOT_COUNT):
		var slot := Button.new()
		slot.custom_minimum_size = INVENTORY_SLOT_SIZE
		slot.add_theme_stylebox_override("normal", _make_button_style(Color(0.055, 0.055, 0.055, 0.96)))
		if i < filtered_items.size():
			_create_item_visual(slot, filtered_items[i])
			slot.pressed.connect(_on_item_pressed.bind(filtered_items[i]))
		item_grid.add_child(slot)

func _filter_inventory(category: String) -> void:
	current_inventory_filter = category
	_populate_inventory_grid(category)

func _create_item_visual(slot: Button, item: Dictionary) -> void:
	var icon := TextureRect.new()
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if item.get("icon", "") != "" and ResourceLoader.exists(item.get("icon", "")):
		icon.texture = load(item.get("icon", ""))
	slot.add_child(icon)

func _build_item_details_panel(parent: HBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(ITEM_DETAILS_PANEL_WIDTH, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_panel_style(INNER_PANEL_COLOR, INNER_PANEL_BORDER_COLOR, 1))
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	
	item_details_icon = TextureRect.new()
	item_details_icon.custom_minimum_size = Vector2(100, 100)
	item_details_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item_details_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(item_details_icon)
	
	item_description_label = Label.new()
	item_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(item_description_label)

func _on_item_pressed(item: Dictionary) -> void:
	item_description_label.text = item.get("name", "") + "\n\n" + item.get("description", "")
	if item.get("icon", "") != "" and ResourceLoader.exists(item.get("icon", "")):
		item_details_icon.texture = load(item.get("icon", ""))

# ============================================================
# CHARACTER BUILDERS
# ============================================================
func _build_character_panel(parent: HBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(CHARACTER_PANEL_WIDTH, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_panel_style(INNER_PANEL_COLOR, INNER_PANEL_BORDER_COLOR, 1))
	parent.add_child(panel)

func _build_bottom_hint(parent: VBoxContainer) -> void:
	var bottom_hint := Label.new()
	bottom_hint.text = "ESC  Close Menu"
	bottom_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(bottom_hint)

# ============================================================
# BUTTON & TAB LOGIC
# ============================================================
func _on_button_pressed(button_name: String) -> void:
	if button_name in ["Inventory", "Load", "Save", "Character"]:
		_switch_tab(button_name)

func _switch_tab(tab_name: String) -> void:
	if tab_inventory: tab_inventory.visible = (tab_name == "Inventory")
	if tab_character: tab_character.visible = (tab_name == "Character")
	
	if tab_load: 
		tab_load.visible = (tab_name == "Load")
		if tab_name == "Load": 
			current_selected_slot = -1
			_refresh_save_load_tab(tab_load, false)
			
	if tab_save: 
		tab_save.visible = (tab_name == "Save")
		if tab_name == "Save": 
			current_selected_slot = -1
			_refresh_save_load_tab(tab_save, true)

# ============================================================
# RPG SAVE / LOAD 10-SLOT SYSTEM
# ============================================================
func _refresh_save_load_tab(panel: PanelContainer, is_save_mode: bool) -> void:
	for child in panel.get_children():
		child.queue_free()
		
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 20)
	panel.add_child(main_vbox)
	
	var header = Label.new()
	header.text = "SAVE GAME" if is_save_mode else "LOAD GAME"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 28)
	header.add_theme_color_override("font_color", TITLE_COLOR)
	main_vbox.add_child(header)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)
	
	var slot_vbox = VBoxContainer.new()
	slot_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(slot_vbox)
	
	for i in range(1, 11):
		var save_meta = SaveManager.get_save_metadata(i)
		var has_save = not save_meta.is_empty()
		
		var slot_panel = PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(700, 80)
		slot_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		
		if i == current_selected_slot:
			slot_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.2, 0.2, 0.15, 0.95), GOLD_TEXT_COLOR, 2))
		else:
			slot_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.05, 0.05, 0.05, 0.9), MAIN_PANEL_BORDER_COLOR, 1))
			
		slot_vbox.add_child(slot_panel)
		
		var slot_hbox = HBoxContainer.new()
		slot_hbox.add_theme_constant_override("separation", 20)
		slot_panel.add_child(slot_hbox)
		
		var details_vbox = VBoxContainer.new()
		details_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		slot_hbox.add_child(details_vbox)
		
		var slot_title = Label.new()
		slot_title.add_theme_font_size_override("font_size", 18)
		details_vbox.add_child(slot_title)
		
		var time_label = Label.new()
		time_label.add_theme_font_size_override("font_size", 14)
		time_label.add_theme_color_override("font_color", NORMAL_TEXT_COLOR)
		details_vbox.add_child(time_label)
		
		if has_save:
			slot_title.text = "Slot %d: Chapter %s - Day %s" % [i, save_meta.get("chapter", 0), save_meta.get("day", 0)]
			slot_title.add_theme_color_override("font_color", GOLD_TEXT_COLOR)
			time_label.text = "Saved: " + save_meta.get("timestamp", "Unknown time")
		else:
			slot_title.text = "Slot %d: --- EMPTY ---" % i
			slot_title.add_theme_color_override("font_color", NORMAL_TEXT_COLOR)
			time_label.text = "No save data."
			
		var click_btn = Button.new()
		click_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		click_btn.flat = true
		click_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		click_btn.pressed.connect(_on_slot_selected.bind(panel, is_save_mode, i))
		slot_panel.add_child(click_btn)
		
	# ACTION HBOX AT THE BOTTOM
	var action_hbox = HBoxContainer.new()
	action_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	action_hbox.add_theme_constant_override("separation", 20)
	action_hbox.custom_minimum_size = Vector2(0, 70)
	main_vbox.add_child(action_hbox)
	
	if current_selected_slot != -1:
		var target_meta = SaveManager.get_save_metadata(current_selected_slot)
		var target_has_save = not target_meta.is_empty()
		
		var action_btn = Button.new()
		action_btn.custom_minimum_size = Vector2(300, 50)
		action_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		action_btn.add_theme_color_override("font_color", TITLE_COLOR)
		action_hbox.add_child(action_btn)
		
		# Build a delete button if data exists
		var del_btn = null
		if target_has_save:
			del_btn = Button.new()
			del_btn.text = "DELETE"
			del_btn.custom_minimum_size = Vector2(150, 50)
			del_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			del_btn.add_theme_color_override("font_color", TITLE_COLOR)
			del_btn.add_theme_stylebox_override("normal", _make_button_style(Color(0.25, 0.05, 0.05, 0.9)))
			del_btn.add_theme_stylebox_override("hover", _make_button_style(Color(0.45, 0.1, 0.1, 1.0)))
			del_btn.pressed.connect(_prompt_confirmation.bind("delete", current_selected_slot))
		
		if is_save_mode:
			if target_has_save:
				action_btn.text = "OVERWRITE SLOT " + str(current_selected_slot)
				action_btn.add_theme_stylebox_override("normal", _make_button_style(Color(0.55, 0.2, 0.05, 1.0)))
				action_btn.add_theme_stylebox_override("hover", _make_button_style(Color(0.7, 0.25, 0.05, 1.0)))
				action_btn.pressed.connect(_prompt_confirmation.bind("overwrite", current_selected_slot))
			else:
				action_btn.text = "CREATE SAVE IN SLOT " + str(current_selected_slot)
				action_btn.add_theme_stylebox_override("normal", _make_button_style(Color(0.08, 0.085, 0.08, 0.92)))
				action_btn.add_theme_stylebox_override("hover", _make_button_style(Color(0.32, 0.24, 0.08, 1.0)))
				action_btn.pressed.connect(_execute_save.bind(current_selected_slot))
				
			if del_btn:
				action_hbox.add_child(del_btn)
		else:
			if target_has_save:
				action_btn.text = "LOAD SLOT " + str(current_selected_slot)
				action_btn.add_theme_stylebox_override("normal", _make_button_style(Color(0.08, 0.085, 0.08, 0.92)))
				action_btn.add_theme_stylebox_override("hover", _make_button_style(Color(0.32, 0.24, 0.08, 1.0)))
				action_btn.pressed.connect(_execute_load.bind(current_selected_slot))
				action_hbox.add_child(del_btn)
			else:
				action_btn.text = "SLOT IS EMPTY"
				action_btn.disabled = true
				action_btn.add_theme_stylebox_override("disabled", _make_button_style(Color(0.1, 0.1, 0.1, 0.5)))
	else:
		var hint_label = Label.new()
		hint_label.text = "Select a slot above."
		hint_label.add_theme_color_override("font_color", NORMAL_TEXT_COLOR)
		action_hbox.add_child(hint_label)

func _on_slot_selected(panel: PanelContainer, is_save_mode: bool, slot_index: int) -> void:
	current_selected_slot = slot_index
	_refresh_save_load_tab(panel, is_save_mode)

func _execute_save(slot_index: int) -> void:
	SaveManager.save_game(slot_index)
	_refresh_save_load_tab(tab_save, true)

func _execute_load(slot_index: int) -> void:
	SaveManager.load_game(slot_index)
	close_menu()

# ============================================================
# HELPERS
# ============================================================
func _force_menu_controls_active(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	for child in node.get_children():
		_force_menu_controls_active(child)

func _make_panel_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 4; style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4; style.corner_radius_bottom_right = 4
	style.content_margin_left = 14; style.content_margin_right = 14
	style.content_margin_top = 14; style.content_margin_bottom = 14
	return style

func _make_button_style(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = Color(0.35, 0.31, 0.22, 0.9)
	style.set_border_width_all(1)
	return style
