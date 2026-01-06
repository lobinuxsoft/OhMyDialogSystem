@tool
class_name BaseDialogueNode
extends GraphNode
## Base class for all visual dialogue nodes in the editor.
##
## Subclasses must implement _configure_slots() and _create_content_ui()
## to define their specific appearance and connection points.


## Reference to the underlying data resource.
var node_data: DialogueNodeData

## Main content container for subclasses to add UI elements.
var _content_container: VBoxContainer


## Sets up the visual node from DialogueNodeData.
func setup(data: DialogueNodeData) -> void:
	node_data = data
	name = data.node_id
	position_offset = data.editor_position

	_setup_base_appearance()
	_configure_slots()
	_create_content_container()
	_create_content_ui()


## Configures base appearance (title, colors).
func _setup_base_appearance() -> void:
	title = _get_node_title()

	var node_color := _get_node_color()

	# Titlebar style
	var titlebar_style := StyleBoxFlat.new()
	titlebar_style.bg_color = node_color
	titlebar_style.corner_radius_top_left = 4
	titlebar_style.corner_radius_top_right = 4
	titlebar_style.content_margin_left = 8
	titlebar_style.content_margin_right = 8
	titlebar_style.content_margin_top = 4
	titlebar_style.content_margin_bottom = 4
	add_theme_stylebox_override("titlebar", titlebar_style)

	# Selected style
	var selected_style := titlebar_style.duplicate()
	selected_style.bg_color = node_color.lightened(0.2)
	add_theme_stylebox_override("titlebar_selected", selected_style)


## Creates the content container used by subclasses.
func _create_content_container() -> void:
	# Clear existing children
	for child in get_children():
		if child is Control:
			child.queue_free()

	_content_container = VBoxContainer.new()
	_content_container.custom_minimum_size = Vector2(180, 0)
	add_child(_content_container)


## Returns the display title for this node type.
## Override in subclasses for custom titles.
func _get_node_title() -> String:
	return node_data.get_type_name() if node_data else "Node"


## Returns the color for this node type.
## Override in subclasses for custom colors.
func _get_node_color() -> Color:
	return node_data.get_type_color() if node_data else Color.WHITE


## Configures input/output slots for this node type.
## Must be implemented by subclasses.
func _configure_slots() -> void:
	push_error("BaseDialogueNode._configure_slots() must be overridden")


## Creates the content UI specific to this node type.
## Must be implemented by subclasses.
func _create_content_ui() -> void:
	push_error("BaseDialogueNode._create_content_ui() must be overridden")


## Synchronizes the visual position back to node_data.
func sync_position() -> void:
	if node_data:
		node_data.editor_position = position_offset


## Refreshes the visual representation from node_data.
func refresh() -> void:
	if node_data:
		_setup_base_appearance()
		_configure_slots()
		_create_content_container()
		_create_content_ui()


## Helper to add a simple label to the content container.
func _add_label(text: String, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	if color != Color.WHITE:
		label.add_theme_color_override("font_color", color)
	_content_container.add_child(label)
	return label


## Helper to add a centered, muted label.
func _add_hint_label(text: String) -> Label:
	var label := _add_label(text, Color(0.6, 0.6, 0.6))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
