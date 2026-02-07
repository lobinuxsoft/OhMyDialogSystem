@tool
class_name BaseDialogueNode
extends GraphNode
## Base class for all visual dialogue nodes in the editor.
##
## Nodes are READ-ONLY displays. Editing is done via the Inspector.
## Subclasses implement _configure_slots() and _create_content_ui().


## Reference to the underlying data resource.
var node_data: DialogueNodeData

## Reference to the parent DialogueGraph (for context-aware nodes).
var dialogue_graph: DialogueGraph

## Names for VariableOperation enum display.
const OPERATION_NAMES := ["Set", "Add", "Subtract", "Multiply", "Divide", "Toggle"]

## Names for ComparisonOperator enum display.
const OPERATOR_NAMES := ["==", "!=", ">", ">=", "<", "<=", "contains", "is_empty", "is_true", "is_false"]


## Converts VariableOperation enum to display string.
static func operation_to_string(op: int) -> String:
	if op >= 0 and op < OPERATION_NAMES.size():
		return OPERATION_NAMES[op]
	return str(op)


## Converts ComparisonOperator enum to display string.
static func operator_to_string(op: int) -> String:
	if op >= 0 and op < OPERATOR_NAMES.size():
		return OPERATOR_NAMES[op]
	return str(op)

## Main content container for subclasses to add UI elements.
var _content_container: VBoxContainer


## Sets up the visual node from DialogueNodeData.
func setup(data: DialogueNodeData, graph: DialogueGraph = null) -> void:
	node_data = data
	dialogue_graph = graph

	# Ensure node_id is never empty (prevents GraphEdit naming issues)
	if data.node_id.is_empty():
		push_error("BaseDialogueNode: node_id is empty, generating fallback UUID")
		data.node_id = data._generate_uuid()

	name = data.node_id
	position_offset = data.editor_position

	# Disable manual resizing - size is automatic
	resizable = false

	# Listen for data changes to refresh display
	if not data.changed.is_connected(_on_data_changed):
		data.changed.connect(_on_data_changed)

	# Listen for DialogueGraph changes (for nodes that display graph-level data like model_path)
	if graph and not graph.changed.is_connected(_on_data_changed):
		graph.changed.connect(_on_data_changed)

	_setup_base_appearance()
	_create_content_container()
	_configure_slots()
	_create_content_ui()

	# Reset size to fit content
	reset_size()


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
func _get_node_title() -> String:
	return node_data.get_type_name() if node_data else "Node"


## Returns the color for this node type.
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


## Called when the underlying data changes (edited in Inspector).
func _on_data_changed() -> void:
	refresh()


## Refreshes the visual representation from node_data.
func refresh() -> void:
	if not node_data:
		return

	_setup_base_appearance()
	clear_all_slots()
	_clear_all_children()
	_create_content_container()
	_configure_slots()
	_create_content_ui()

	# Reset size to fit new content
	reset_size()


## Clears all child controls (for refresh).
func _clear_all_children() -> void:
	var children_to_remove: Array[Node] = []
	for child in get_children():
		if child is Control:
			children_to_remove.append(child)

	for child in children_to_remove:
		remove_child(child)
		child.queue_free()


# ==================== Display Helpers (Read-Only) ====================


## Adds a labeled value display with improved styling.
func _add_info(label_text: String, value: String, value_color: Color = Color.WHITE) -> Label:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	# Label with bold-like appearance
	var label := Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size.x = 60
	label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	label.add_theme_font_size_override("font_size", 12)
	hbox.add_child(label)

	# Value with optional color
	var value_label := Label.new()
	value_label.text = value if not value.is_empty() else "(empty)"
	value_label.clip_text = true
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if value.is_empty():
		value_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		value_label.add_theme_font_size_override("font_size", 11)
	elif value_color != Color.WHITE:
		value_label.add_theme_color_override("font_color", value_color)
	else:
		value_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

	hbox.add_child(value_label)
	_content_container.add_child(hbox)
	return value_label


## Adds a multiline text preview (truncated).
func _add_text_preview(text: String, max_lines: int = 3) -> Label:
	var label := Label.new()
	var lines := text.split("\n")
	if lines.size() > max_lines:
		label.text = "\n".join(lines.slice(0, max_lines)) + "..."
	else:
		label.text = text if not text.is_empty() else "(no text)"

	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.custom_minimum_size = Vector2(180, 0)

	if text.is_empty():
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

	_content_container.add_child(label)
	return label


## Adds a simple label.
func _add_label(text: String, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	if color != Color.WHITE:
		label.add_theme_color_override("font_color", color)
	_content_container.add_child(label)
	return label


## Adds a centered, muted hint label.
func _add_hint_label(text: String) -> Label:
	var label := _add_label(text, Color(0.6, 0.6, 0.6))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


## Adds a horizontal separator.
func _add_separator() -> HSeparator:
	var sep := HSeparator.new()
	_content_container.add_child(sep)
	return sep


## Adds an output label aligned to the right (for slot labels).
func _add_output_label(text: String, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if color != Color.WHITE:
		label.add_theme_color_override("font_color", color)
	_content_container.add_child(label)
	return label
