@tool
class_name BaseNodeEditor
extends PanelContainer
## Base class for node-specific wiki-style info panels.
##
## Shows useful read-only information about the node.
## Actual editing is done via Godot's native inspector.


## Accent color for this editor - override in subclasses.
var ACCENT_COLOR: Color = WikiInspectorTheme.AI_CYAN

## Icon for this node type - override in subclasses.
var ICON: String = WikiInspectorTheme.ICON_DIAMOND

## Title for this node type - override in subclasses.
var TITLE: String = "NODE"

var _node_data: DialogueNodeData
var _dialogue_graph: DialogueGraph
var _content: VBoxContainer


func _init(node_data: DialogueNodeData, graph: DialogueGraph = null) -> void:
	_node_data = node_data
	_dialogue_graph = graph


func _ready() -> void:
	add_theme_stylebox_override("panel", WikiInspectorTheme.create_header_style(ACCENT_COLOR))
	_setup_header()
	_setup_info()
	_connect_signals()


func _exit_tree() -> void:
	_disconnect_signals()


func _connect_signals() -> void:
	if _node_data:
		_node_data.changed.connect(_on_data_changed)
	var inspector := EditorInterface.get_inspector()
	if inspector:
		inspector.property_edited.connect(_on_property_edited)


func _disconnect_signals() -> void:
	if _node_data and _node_data.changed.is_connected(_on_data_changed):
		_node_data.changed.disconnect(_on_data_changed)
	var inspector := EditorInterface.get_inspector()
	if inspector and inspector.property_edited.is_connected(_on_property_edited):
		inspector.property_edited.disconnect(_on_property_edited)


func _on_data_changed() -> void:
	_refresh_info()


func _on_property_edited(_property: String) -> void:
	_refresh_info()


func _setup_header() -> void:
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 8)

	# Title row
	var title_hbox := HBoxContainer.new()
	title_hbox.add_theme_constant_override("separation", 10)

	var icon := Label.new()
	icon.text = ICON
	icon.add_theme_font_size_override("font_size", 18)
	icon.add_theme_color_override("font_color", ACCENT_COLOR)
	title_hbox.add_child(icon)

	var title := Label.new()
	title.text = TITLE
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", ACCENT_COLOR)
	title_hbox.add_child(title)

	_content.add_child(title_hbox)
	add_child(_content)


## Override in subclasses to add info widgets.
func _setup_info() -> void:
	pass


## Override in subclasses to update info when data changes.
func _refresh_info() -> void:
	pass


# ==================== Info Display Helpers ====================


## Adds a rich text label for dynamic info display.
func _add_info_label() -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	_content.add_child(label)
	return label


## Adds a simple key-value info row.
func _add_info_row(key: String, value: String, value_color: Color = WikiInspectorTheme.TEXT_PRIMARY) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var key_label := Label.new()
	key_label.text = key + ":"
	key_label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
	key_label.custom_minimum_size.x = 80
	hbox.add_child(key_label)

	var value_label := Label.new()
	value_label.text = value
	value_label.add_theme_color_override("font_color", value_color)
	hbox.add_child(value_label)

	_content.add_child(hbox)
	return hbox


## Adds a warning message.
func _add_warning(message: String) -> Label:
	var label := Label.new()
	label.text = "⚠ " + message
	label.add_theme_color_override("font_color", WikiInspectorTheme.AI_YELLOW)
	label.add_theme_font_size_override("font_size", 11)
	_content.add_child(label)
	return label


## Adds an error message.
func _add_error(message: String) -> Label:
	var label := Label.new()
	label.text = "✗ " + message
	label.add_theme_color_override("font_color", WikiInspectorTheme.AI_RED)
	label.add_theme_font_size_override("font_size", 11)
	_content.add_child(label)
	return label


## Adds a success/valid message.
func _add_success(message: String) -> Label:
	var label := Label.new()
	label.text = "✓ " + message
	label.add_theme_color_override("font_color", WikiInspectorTheme.AI_GREEN)
	label.add_theme_font_size_override("font_size", 11)
	_content.add_child(label)
	return label


## Adds a separator line.
func _add_separator() -> HSeparator:
	var sep := HSeparator.new()
	sep.add_theme_color_override("separator", WikiInspectorTheme.BORDER)
	_content.add_child(sep)
	return sep
