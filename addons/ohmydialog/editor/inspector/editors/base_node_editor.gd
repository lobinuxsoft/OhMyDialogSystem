@tool
class_name BaseNodeEditor
extends VBoxContainer
## Base class for node-specific inspector editors.
##
## Provides common helper methods for creating form fields.
## Uses WikiInspectorTheme for consistent styling.


## Accent color for this editor - override in subclasses.
var ACCENT_COLOR: Color = WikiInspectorTheme.AI_BLUE

var _node_data: DialogueNodeData
var _dialogue_graph: DialogueGraph
var _sections: Dictionary = {}  # title -> section data

## Current selected category for variable selector.
var _current_variable_category: int = 0

## References to variable selector components.
var _variable_selectors: Dictionary = {}  # data_key -> {container, option, tabs}


func _init(node_data: DialogueNodeData, graph: DialogueGraph = null) -> void:
	_node_data = node_data
	_dialogue_graph = graph


func _ready() -> void:
	add_theme_constant_override("separation", 0)
	_setup_ui()


## Override this in subclasses to create the UI.
func _setup_ui() -> void:
	push_error("BaseNodeEditor._setup_ui() must be overridden")


## Notifies that data changed (updates visual node).
func _emit_changed() -> void:
	_node_data.emit_changed()


# ==================== Wiki-Style UI ====================


## Creates a wiki-styled main header for the editor.
func _create_main_header(title: String, icon: String = "") -> PanelContainer:
	var header_panel := PanelContainer.new()
	header_panel.add_theme_stylebox_override("panel", WikiInspectorTheme.create_header_style(ACCENT_COLOR))

	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 10)

	if not icon.is_empty():
		var icon_label := Label.new()
		icon_label.text = icon
		icon_label.add_theme_font_size_override("font_size", 16)
		icon_label.add_theme_color_override("font_color", ACCENT_COLOR)
		header_hbox.add_child(icon_label)

	var title_label := RichTextLabel.new()
	title_label.bbcode_enabled = true
	title_label.fit_content = true
	title_label.scroll_active = false
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.text = "[b]%s[/b]" % title.to_upper()
	title_label.add_theme_font_size_override("normal_font_size", 12)
	title_label.add_theme_color_override("default_color", ACCENT_COLOR)
	header_hbox.add_child(title_label)

	header_panel.add_child(header_hbox)
	add_child(header_panel)
	return header_panel


## Creates a collapsible wiki-styled section.
func _create_section(title: String, expanded: bool = false) -> VBoxContainer:
	var section_container := VBoxContainer.new()
	section_container.add_theme_constant_override("separation", 0)

	# Section header
	var header_panel := PanelContainer.new()
	header_panel.add_theme_stylebox_override("panel", WikiInspectorTheme.create_section_header_style())
	header_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 8)
	header_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	header_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Arrow indicator
	var arrow := Label.new()
	arrow.text = "▼" if expanded else "▶"
	arrow.add_theme_font_size_override("font_size", 16)
	arrow.add_theme_color_override("font_color", ACCENT_COLOR)
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_hbox.add_child(arrow)

	# Title
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_PRIMARY)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_hbox.add_child(title_label)

	header_panel.add_child(header_hbox)
	section_container.add_child(header_panel)

	# Content container
	var content_panel := PanelContainer.new()
	content_panel.add_theme_stylebox_override("panel", WikiInspectorTheme.create_content_style())
	content_panel.visible = expanded

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	content_panel.add_child(content)
	section_container.add_child(content_panel)

	_sections[title] = {
		"arrow": arrow,
		"content_panel": content_panel,
		"header_panel": header_panel,
		"expanded": expanded
	}

	# Click to toggle
	header_panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var section: Dictionary = _sections[title]
			section.expanded = not section.expanded
			section.content_panel.visible = section.expanded
			section.arrow.text = "▼" if section.expanded else "▶"
	)

	# Hover effect
	header_panel.mouse_entered.connect(func():
		header_panel.add_theme_stylebox_override("panel", WikiInspectorTheme.create_section_header_style(true))
	)
	header_panel.mouse_exited.connect(func():
		header_panel.add_theme_stylebox_override("panel", WikiInspectorTheme.create_section_header_style(false))
	)

	add_child(section_container)
	return content


# ==================== Helper Methods ====================


## Gets the target container (parent or self).
func _get_target(parent: Control) -> Control:
	return parent if parent else self


## Creates a labeled LineEdit.
func _add_line_edit(label_text: String, data_key: String, placeholder: String = "", parent: Control = null) -> LineEdit:
	var target := _get_target(parent)
	var hbox := HBoxContainer.new()

	var label := Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size.x = 100
	label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
	hbox.add_child(label)

	var line_edit := LineEdit.new()
	line_edit.text = str(_node_data.data.get(data_key, ""))
	line_edit.placeholder_text = placeholder
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.text_changed.connect(func(new_text: String):
		_node_data.data[data_key] = new_text
		_emit_changed()
	)
	hbox.add_child(line_edit)

	target.add_child(hbox)
	return line_edit


## Creates a multiline TextEdit with label.
func _add_text_edit(label_text: String, data_key: String, min_height: int = 80, parent: Control = null) -> TextEdit:
	var target := _get_target(parent)

	var label := Label.new()
	label.text = label_text + ":"
	label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
	target.add_child(label)

	var text_edit := TextEdit.new()
	text_edit.text = str(_node_data.data.get(data_key, ""))
	text_edit.custom_minimum_size.y = min_height
	text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	text_edit.text_changed.connect(func():
		_node_data.data[data_key] = text_edit.text
		_emit_changed()
	)

	target.add_child(text_edit)
	return text_edit


## Creates a labeled SpinBox.
func _add_spin_box(label_text: String, data_key: String, min_val: float = 0, max_val: float = 9999, step: float = 1, parent: Control = null) -> SpinBox:
	var target := _get_target(parent)
	var hbox := HBoxContainer.new()

	var label := Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size.x = 100
	label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
	hbox.add_child(label)

	var spin := SpinBox.new()
	spin.min_value = min_val
	spin.max_value = max_val
	spin.step = step
	spin.value = float(_node_data.data.get(data_key, min_val))
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin.value_changed.connect(func(value: float):
		_node_data.data[data_key] = int(value) if step == 1 else value
		_emit_changed()
	)
	hbox.add_child(spin)

	target.add_child(hbox)
	return spin


## Creates a labeled OptionButton.
func _add_option_button(label_text: String, data_key: String, options: Array[String], default_index: int = 0, parent: Control = null) -> OptionButton:
	var target := _get_target(parent)
	var hbox := HBoxContainer.new()

	var label := Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size.x = 100
	label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
	hbox.add_child(label)

	var option := OptionButton.new()
	for opt in options:
		option.add_item(opt)

	var current_value: Variant = _node_data.data.get(data_key, default_index)
	if current_value is int:
		option.select(mini(current_value, options.size() - 1))
	elif current_value is String:
		var idx := options.find(current_value)
		option.select(idx if idx >= 0 else default_index)

	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.item_selected.connect(func(index: int):
		_node_data.data[data_key] = options[index]
		_emit_changed()
	)
	hbox.add_child(option)

	target.add_child(hbox)
	return option


## Creates a labeled CheckBox.
func _add_check_box(label_text: String, data_key: String, default_value: bool = false, parent: Control = null) -> CheckBox:
	var target := _get_target(parent)
	var hbox := HBoxContainer.new()

	var label := Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size.x = 100
	label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
	hbox.add_child(label)

	var check := CheckBox.new()
	check.button_pressed = bool(_node_data.data.get(data_key, default_value))
	check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	check.toggled.connect(func(pressed: bool):
		_node_data.data[data_key] = pressed
		_emit_changed()
	)
	hbox.add_child(check)

	target.add_child(hbox)
	return check


## Adds a separator. (Legacy - use _create_section instead)
func _add_separator(parent: Control = null) -> HSeparator:
	var target := _get_target(parent)
	var sep := HSeparator.new()
	target.add_child(sep)
	return sep


## Adds a section header label. (Legacy - use _create_section instead)
func _add_header(text: String, parent: Control = null) -> Label:
	var target := _get_target(parent)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", ACCENT_COLOR)
	target.add_child(label)
	return label


# ==================== Variable Selector ====================


## Creates a variable selector with category tabs (Local, Global, AutoLoads).
func _add_variable_selector(label_text: String, data_key: String, parent: Control = null) -> Control:
	var target := _get_target(parent)
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)

	# Label
	var label := Label.new()
	label.text = label_text + ":"
	label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
	container.add_child(label)

	# Tab buttons for categories
	var tab_container := HBoxContainer.new()
	tab_container.add_theme_constant_override("separation", 2)

	var categories: Array[String] = [VariableProvider.CATEGORY_LOCAL, VariableProvider.CATEGORY_GLOBAL, VariableProvider.CATEGORY_AUTOLOADS]
	var tab_buttons: Array[Button] = []

	for i in categories.size():
		var btn := Button.new()
		btn.text = categories[i] as String
		btn.toggle_mode = true
		btn.button_pressed = (i == 0)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 11)
		btn.pressed.connect(_on_variable_tab_pressed.bind(data_key, i))
		tab_container.add_child(btn)
		tab_buttons.append(btn)

	container.add_child(tab_container)

	# Dropdown for variables
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.item_selected.connect(_on_variable_selected.bind(data_key))
	container.add_child(option)

	# Manual input fallback (for custom variable names)
	var manual_hbox := HBoxContainer.new()
	var manual_check := CheckBox.new()
	manual_check.text = "Custom"
	manual_check.add_theme_font_size_override("font_size", 11)
	manual_check.toggled.connect(_on_manual_mode_toggled.bind(data_key))
	manual_hbox.add_child(manual_check)

	var manual_edit := LineEdit.new()
	manual_edit.placeholder_text = "custom_var_name"
	manual_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	manual_edit.visible = false
	manual_edit.text_changed.connect(func(new_text: String):
		_node_data.data[data_key] = new_text
		_emit_changed()
	)
	manual_hbox.add_child(manual_edit)
	container.add_child(manual_hbox)

	# Store references
	_variable_selectors[data_key] = {
		"container": container,
		"option": option,
		"tabs": tab_buttons,
		"manual_check": manual_check,
		"manual_edit": manual_edit,
		"current_tab": 0
	}

	# Populate initial dropdown
	_populate_variable_dropdown(data_key, 0)

	# Set current value if exists
	var current_value: String = str(_node_data.data.get(data_key, ""))
	if not current_value.is_empty():
		_select_current_variable(data_key, current_value)

	target.add_child(container)
	return container


## Populates the variable dropdown for a specific category.
func _populate_variable_dropdown(data_key: String, category_index: int) -> void:
	var selector_data: Dictionary = _variable_selectors.get(data_key, {})
	if selector_data.is_empty():
		return

	var option: OptionButton = selector_data["option"]
	option.clear()
	option.add_item("-- Select Variable --")

	var categories: Array[String] = [VariableProvider.CATEGORY_LOCAL, VariableProvider.CATEGORY_GLOBAL, VariableProvider.CATEGORY_AUTOLOADS]
	var category: String = categories[category_index]

	var all_vars := VariableProvider.get_all_variables(_dialogue_graph)

	if category == VariableProvider.CATEGORY_AUTOLOADS:
		# Show AutoLoad.property format
		var autoloads: Dictionary = all_vars[VariableProvider.CATEGORY_AUTOLOADS]
		for autoload_name in autoloads:
			for prop_name in autoloads[autoload_name]:
				option.add_item("%s.%s" % [autoload_name, prop_name])
	else:
		# Show simple variable names
		var vars: Array = all_vars[category]
		for var_name in vars:
			option.add_item(var_name)


## Called when a category tab is pressed.
func _on_variable_tab_pressed(data_key: String, tab_index: int) -> void:
	var selector_data: Dictionary = _variable_selectors.get(data_key, {})
	if selector_data.is_empty():
		return

	# Update tab buttons
	var tabs: Array = selector_data["tabs"]
	for i in tabs.size():
		tabs[i].button_pressed = (i == tab_index)

	selector_data["current_tab"] = tab_index

	# Repopulate dropdown
	_populate_variable_dropdown(data_key, tab_index)


## Called when a variable is selected from dropdown.
func _on_variable_selected(index: int, data_key: String) -> void:
	var selector_data: Dictionary = _variable_selectors.get(data_key, {})
	if selector_data.is_empty():
		return

	var option: OptionButton = selector_data["option"]
	if index == 0:
		# "Select" placeholder
		return

	var selected_text := option.get_item_text(index)
	_node_data.data[data_key] = selected_text
	_emit_changed()


## Called when manual mode checkbox is toggled.
func _on_manual_mode_toggled(enabled: bool, data_key: String) -> void:
	var selector_data: Dictionary = _variable_selectors.get(data_key, {})
	if selector_data.is_empty():
		return

	var option: OptionButton = selector_data["option"]
	var manual_edit: LineEdit = selector_data["manual_edit"]

	option.visible = not enabled
	manual_edit.visible = enabled

	if enabled:
		manual_edit.text = str(_node_data.data.get(data_key, ""))
		manual_edit.grab_focus()


## Selects the current value in dropdown or enables manual mode.
func _select_current_variable(data_key: String, current_value: String) -> void:
	var selector_data: Dictionary = _variable_selectors.get(data_key, {})
	if selector_data.is_empty():
		return

	var option: OptionButton = selector_data["option"]

	# Try to find in current dropdown
	for i in option.item_count:
		if option.get_item_text(i) == current_value:
			option.select(i)
			return

	# Not found - check other categories or enable manual mode
	var all_vars := VariableProvider.get_all_variables(_dialogue_graph)
	var categories: Array[String] = [VariableProvider.CATEGORY_LOCAL, VariableProvider.CATEGORY_GLOBAL, VariableProvider.CATEGORY_AUTOLOADS]

	for cat_idx in categories.size():
		var cat: String = categories[cat_idx]
		if cat == VariableProvider.CATEGORY_AUTOLOADS:
			var autoloads: Dictionary = all_vars[cat]
			for autoload_name in autoloads:
				for prop_name in autoloads[autoload_name]:
					if "%s.%s" % [autoload_name, prop_name] == current_value:
						_on_variable_tab_pressed(data_key, cat_idx)
						_select_current_variable(data_key, current_value)
						return
		else:
			if current_value in all_vars[cat]:
				_on_variable_tab_pressed(data_key, cat_idx)
				_select_current_variable(data_key, current_value)
				return

	# Not found anywhere - enable manual mode
	var manual_check: CheckBox = selector_data["manual_check"]
	var manual_edit: LineEdit = selector_data["manual_edit"]
	manual_check.button_pressed = true
	_on_manual_mode_toggled(true, data_key)
	manual_edit.text = current_value


# ==================== Resource Picker ====================


## Creates a resource picker for selecting Resource files.
## base_type: The base class name (e.g., "DialogueGraph", "CharacterIdentity")
func _add_resource_picker(label_text: String, data_key: String, base_type: String, parent: Control = null) -> EditorResourcePicker:
	var target := _get_target(parent)
	var hbox := HBoxContainer.new()

	var label := Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size.x = 100
	label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
	hbox.add_child(label)

	var picker := EditorResourcePicker.new()
	picker.base_type = base_type
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Load current resource if path exists
	var current_path: String = str(_node_data.data.get(data_key, ""))
	if not current_path.is_empty() and ResourceLoader.exists(current_path):
		picker.edited_resource = load(current_path)

	picker.resource_changed.connect(func(new_resource: Resource):
		if new_resource:
			_node_data.data[data_key] = new_resource.resource_path
		else:
			_node_data.data[data_key] = ""
		_emit_changed()
	)

	hbox.add_child(picker)
	target.add_child(hbox)
	return picker
