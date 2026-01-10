@tool
class_name PlayerChoiceEditor
extends BaseNodeEditor
## Inspector editor for PLAYER_CHOICE nodes.
##
## Shows prompt and a dynamic list of choices with add/remove buttons.


var _choices_container: VBoxContainer
var _choices_section: VBoxContainer


func _init(node_data: DialogueNodeData, graph: DialogueGraph = null) -> void:
	super(node_data, graph)
	ACCENT_COLOR = Color("#eab308")  # Choice node yellow


func _setup_ui() -> void:
	_create_main_header("Player Choice", "❓")

	var prompt_section := _create_section("Prompt")
	_add_line_edit("Prompt", "prompt", "Question for the player", prompt_section)

	_choices_section = _create_section("Choices")

	# Add button
	var add_btn := Button.new()
	add_btn.text = "+ Add Choice"
	add_btn.pressed.connect(_on_add_choice)
	_choices_section.add_child(add_btn)

	# Container for choices
	_choices_container = VBoxContainer.new()
	_choices_section.add_child(_choices_container)

	_rebuild_choices_list()


func _rebuild_choices_list() -> void:
	# Clear existing
	for child in _choices_container.get_children():
		child.queue_free()

	var choices: Array = _node_data.data.get("choices", [])

	for i in choices.size():
		var choice: Dictionary = choices[i]
		var choice_row := _create_choice_row(i, choice)
		_choices_container.add_child(choice_row)


func _create_choice_row(index: int, choice: Dictionary) -> Control:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

	# Header with index and delete button
	var header := HBoxContainer.new()

	var idx_label := Label.new()
	idx_label.text = "Choice %d" % (index + 1)
	idx_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	idx_label.add_theme_color_override("font_color", ACCENT_COLOR)
	header.add_child(idx_label)

	var del_btn := Button.new()
	del_btn.text = "×"
	del_btn.custom_minimum_size.x = 28
	del_btn.pressed.connect(_on_remove_choice.bind(index))
	header.add_child(del_btn)

	vbox.add_child(header)

	# Text field
	var text_row := HBoxContainer.new()
	var text_label := Label.new()
	text_label.text = "Text:"
	text_label.custom_minimum_size.x = 80
	text_label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
	text_row.add_child(text_label)

	var text_edit := LineEdit.new()
	text_edit.text = choice.get("text", "")
	text_edit.placeholder_text = "Choice text"
	text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_edit.text_changed.connect(_on_choice_text_changed.bind(index))
	text_row.add_child(text_edit)
	vbox.add_child(text_row)

	# Condition field (optional)
	var cond_row := HBoxContainer.new()
	var cond_label := Label.new()
	cond_label.text = "Condition:"
	cond_label.custom_minimum_size.x = 80
	cond_label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
	cond_row.add_child(cond_label)

	var cond_edit := LineEdit.new()
	cond_edit.text = choice.get("condition", "")
	cond_edit.placeholder_text = "Optional condition"
	cond_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cond_edit.text_changed.connect(_on_choice_condition_changed.bind(index))
	cond_row.add_child(cond_edit)
	vbox.add_child(cond_row)

	# Separator
	var sep := HSeparator.new()
	vbox.add_child(sep)

	return vbox


func _on_add_choice() -> void:
	var choices: Array = _node_data.data.get("choices", [])
	choices.append({"text": "", "condition": "", "metadata": {}})
	_node_data.data["choices"] = choices
	_node_data.refresh_output_count()
	_emit_changed()
	_rebuild_choices_list()


func _on_remove_choice(index: int) -> void:
	var choices: Array = _node_data.data.get("choices", [])
	if index >= 0 and index < choices.size():
		choices.remove_at(index)
		_node_data.data["choices"] = choices
		_node_data.refresh_output_count()
		_emit_changed()
		_rebuild_choices_list()


func _on_choice_text_changed(new_text: String, index: int) -> void:
	var choices: Array = _node_data.data.get("choices", [])
	if index >= 0 and index < choices.size():
		choices[index]["text"] = new_text
		_emit_changed()


func _on_choice_condition_changed(new_text: String, index: int) -> void:
	var choices: Array = _node_data.data.get("choices", [])
	if index >= 0 and index < choices.size():
		choices[index]["condition"] = new_text
		_emit_changed()
