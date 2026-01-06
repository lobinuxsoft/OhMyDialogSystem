@tool
class_name DialogueGraphNode
extends GraphNode
## Visual representation of a DialogueNodeData in the graph editor.
##
## This class wraps a DialogueNodeData and renders it as a GraphNode
## with appropriate slots, colors, and content based on the node type.


## Reference to the underlying data.
var node_data: DialogueNodeData

## Cached reference to the content label.
var _content_label: Label

## Cached reference to choices container (for PLAYER_CHOICE nodes).
var _choices_container: VBoxContainer


## Sets up the visual node from DialogueNodeData.
func setup(data: DialogueNodeData) -> void:
	node_data = data
	name = data.node_id

	# Set position from data
	position_offset = data.editor_position

	# Configure appearance
	_update_title_and_color()
	_configure_slots()
	_create_content_ui()


## Updates title and color based on node type.
func _update_title_and_color() -> void:
	title = node_data.get_type_name()

	# Get color for this node type
	var type_color := node_data.get_type_color()

	# Create a stylebox for the titlebar
	var titlebar_style := StyleBoxFlat.new()
	titlebar_style.bg_color = type_color
	titlebar_style.corner_radius_top_left = 4
	titlebar_style.corner_radius_top_right = 4
	titlebar_style.content_margin_left = 8
	titlebar_style.content_margin_right = 8
	titlebar_style.content_margin_top = 4
	titlebar_style.content_margin_bottom = 4

	add_theme_stylebox_override("titlebar", titlebar_style)

	# Selected style
	var selected_style := titlebar_style.duplicate()
	selected_style.bg_color = type_color.lightened(0.2)
	add_theme_stylebox_override("titlebar_selected", selected_style)


## Configures input/output slots based on node type.
func _configure_slots() -> void:
	# Clear existing slots
	clear_all_slots()

	# Slot colors
	var input_color := Color.WHITE
	var output_color := Color.WHITE

	match node_data.node_type:
		DialogueNodeData.NodeType.START:
			# No input, 1 output
			set_slot(0, false, 0, input_color, true, 0, output_color)

		DialogueNodeData.NodeType.END:
			# 1 input, no output
			set_slot(0, true, 0, input_color, false, 0, output_color)

		DialogueNodeData.NodeType.AI_RESPONSE, \
		DialogueNodeData.NodeType.STATIC_RESPONSE, \
		DialogueNodeData.NodeType.EVENT, \
		DialogueNodeData.NodeType.SET_VARIABLE, \
		DialogueNodeData.NodeType.JUMP_TO_FREE:
			# 1 input, 1 output
			set_slot(0, true, 0, input_color, true, 0, output_color)

		DialogueNodeData.NodeType.PLAYER_CHOICE:
			# 1 input, N outputs (one per choice)
			var choices: Array = node_data.data.get("choices", [])
			var output_count := maxi(1, choices.size())
			set_slot(0, true, 0, input_color, true, 0, output_color)
			for i in range(1, output_count):
				set_slot(i, false, 0, input_color, true, 0, output_color)

		DialogueNodeData.NodeType.CONDITION:
			# 1 input, 2 outputs (TRUE/FALSE)
			set_slot(0, true, 0, input_color, true, 0, Color.GREEN)  # TRUE
			set_slot(1, false, 0, input_color, true, 0, Color.RED)   # FALSE

		DialogueNodeData.NodeType.JUMP, \
		DialogueNodeData.NodeType.RETURN_TO_GRAPH:
			# 1 input, no visual output (jumps are handled differently)
			set_slot(0, true, 0, input_color, false, 0, output_color)


## Creates the content UI inside the node.
func _create_content_ui() -> void:
	# Clear existing children (except built-in)
	for child in get_children():
		if child is Control:
			child.queue_free()

	# Create main container
	var container := VBoxContainer.new()
	container.custom_minimum_size = Vector2(180, 0)
	add_child(container)

	match node_data.node_type:
		DialogueNodeData.NodeType.START:
			_create_start_ui(container)
		DialogueNodeData.NodeType.END:
			_create_end_ui(container)
		DialogueNodeData.NodeType.AI_RESPONSE:
			_create_ai_response_ui(container)
		DialogueNodeData.NodeType.STATIC_RESPONSE:
			_create_static_response_ui(container)
		DialogueNodeData.NodeType.PLAYER_CHOICE:
			_create_player_choice_ui(container)
		DialogueNodeData.NodeType.CONDITION:
			_create_condition_ui(container)
		DialogueNodeData.NodeType.EVENT:
			_create_event_ui(container)
		DialogueNodeData.NodeType.SET_VARIABLE:
			_create_set_variable_ui(container)
		DialogueNodeData.NodeType.JUMP:
			_create_jump_ui(container)
		DialogueNodeData.NodeType.JUMP_TO_FREE:
			_create_jump_to_free_ui(container)
		DialogueNodeData.NodeType.RETURN_TO_GRAPH:
			_create_return_ui(container)


func _create_start_ui(container: VBoxContainer) -> void:
	var label := Label.new()
	label.text = "Entry Point"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	container.add_child(label)


func _create_end_ui(container: VBoxContainer) -> void:
	var label := Label.new()
	label.text = "Dialogue ends here"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	container.add_child(label)


func _create_ai_response_ui(container: VBoxContainer) -> void:
	_content_label = Label.new()
	_content_label.text = node_data.data.get("prompt_hint", "AI generates response...")
	_content_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_content_label.custom_minimum_size.x = 180
	container.add_child(_content_label)


func _create_static_response_ui(container: VBoxContainer) -> void:
	_content_label = Label.new()
	var text: String = node_data.data.get("text", "")
	_content_label.text = text.substr(0, 50) + ("..." if text.length() > 50 else "")
	_content_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_content_label.custom_minimum_size.x = 180
	container.add_child(_content_label)


func _create_player_choice_ui(container: VBoxContainer) -> void:
	_choices_container = VBoxContainer.new()
	container.add_child(_choices_container)

	var choices: Array = node_data.data.get("choices", [])
	if choices.is_empty():
		var label := Label.new()
		label.text = "(No choices defined)"
		label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		_choices_container.add_child(label)
	else:
		for i in choices.size():
			var choice: Dictionary = choices[i]
			var label := Label.new()
			label.text = "%d. %s" % [i + 1, choice.get("text", "Choice")]
			_choices_container.add_child(label)


func _create_condition_ui(container: VBoxContainer) -> void:
	var variable: String = node_data.data.get("variable", "")
	var op: int = node_data.data.get("operator", DialogueNodeData.ComparisonOperator.EQUAL)
	var value: Variant = node_data.data.get("value", "")

	var op_str: String
	match op:
		DialogueNodeData.ComparisonOperator.EQUAL: op_str = "=="
		DialogueNodeData.ComparisonOperator.NOT_EQUAL: op_str = "!="
		DialogueNodeData.ComparisonOperator.GREATER: op_str = ">"
		DialogueNodeData.ComparisonOperator.LESS: op_str = "<"
		DialogueNodeData.ComparisonOperator.GREATER_EQUAL: op_str = ">="
		DialogueNodeData.ComparisonOperator.LESS_EQUAL: op_str = "<="
		DialogueNodeData.ComparisonOperator.CONTAINS: op_str = "contains"
		DialogueNodeData.ComparisonOperator.IS_EMPTY: op_str = "is_empty"
		DialogueNodeData.ComparisonOperator.IS_TRUE: op_str = "is_true"
		DialogueNodeData.ComparisonOperator.IS_FALSE: op_str = "is_false"
		_: op_str = "?"

	_content_label = Label.new()
	_content_label.text = "if %s %s %s" % [variable, op_str, str(value)]
	container.add_child(_content_label)

	# TRUE/FALSE labels for outputs
	var true_label := Label.new()
	true_label.text = "✓ TRUE"
	true_label.add_theme_color_override("font_color", Color.GREEN)
	container.add_child(true_label)

	var false_label := Label.new()
	false_label.text = "✗ FALSE"
	false_label.add_theme_color_override("font_color", Color.RED)
	container.add_child(false_label)


func _create_event_ui(container: VBoxContainer) -> void:
	var event_name: String = node_data.data.get("event_name", "")
	_content_label = Label.new()
	_content_label.text = "Event: %s" % event_name if event_name else "(No event)"
	container.add_child(_content_label)


func _create_set_variable_ui(container: VBoxContainer) -> void:
	var variable: String = node_data.data.get("variable", "")
	var op: int = node_data.data.get("operation", DialogueNodeData.VariableOperation.SET)
	var value: Variant = node_data.data.get("value", "")

	var op_str: String
	match op:
		DialogueNodeData.VariableOperation.SET: op_str = "="
		DialogueNodeData.VariableOperation.ADD: op_str = "+="
		DialogueNodeData.VariableOperation.SUBTRACT: op_str = "-="
		DialogueNodeData.VariableOperation.MULTIPLY: op_str = "*="
		DialogueNodeData.VariableOperation.DIVIDE: op_str = "/="
		DialogueNodeData.VariableOperation.TOGGLE: op_str = "toggle"
		_: op_str = "?"

	_content_label = Label.new()
	_content_label.text = "%s %s %s" % [variable, op_str, str(value)]
	container.add_child(_content_label)


func _create_jump_ui(container: VBoxContainer) -> void:
	var target: String = node_data.data.get("target_node_id", "")
	_content_label = Label.new()
	_content_label.text = "→ %s" % target if target else "(No target)"
	container.add_child(_content_label)


func _create_jump_to_free_ui(container: VBoxContainer) -> void:
	var label := Label.new()
	label.text = "Enter free conversation mode"
	label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
	container.add_child(label)


func _create_return_ui(container: VBoxContainer) -> void:
	var target: String = node_data.data.get("return_node_id", "")
	_content_label = Label.new()
	_content_label.text = "← Return to: %s" % target if target else "← Return to graph"
	container.add_child(_content_label)


## Synchronizes the visual position back to node_data.
func sync_position() -> void:
	if node_data:
		node_data.editor_position = position_offset


## Refreshes the visual representation from node_data.
func refresh() -> void:
	if node_data:
		_update_title_and_color()
		_configure_slots()
		_create_content_ui()
