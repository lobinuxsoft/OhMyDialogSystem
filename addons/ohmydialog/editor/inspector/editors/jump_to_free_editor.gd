@tool
class_name JumpToFreeEditor
extends BaseNodeEditor
## Inspector editor for JUMP_TO_FREE nodes.
##
## Shows context prompt, return keywords, return condition, and max exchanges.


var _keywords_container: VBoxContainer


func _setup_ui() -> void:
	_add_header("Jump to Free Mode")
	_add_separator()
	_add_text_edit("Context Prompt", "context_prompt", 60)
	_add_line_edit("Return Condition", "return_condition", "Expression that triggers return")
	_add_spin_box("Max Exchanges", "max_exchanges", 0, 100, 1)

	_add_separator()
	_add_header("Return Keywords")

	# Add keyword button
	var add_btn := Button.new()
	add_btn.text = "+ Add Keyword"
	add_btn.pressed.connect(_on_add_keyword)
	add_child(add_btn)

	# Container for keywords
	_keywords_container = VBoxContainer.new()
	add_child(_keywords_container)

	_rebuild_keywords_list()


func _rebuild_keywords_list() -> void:
	# Clear existing
	for child in _keywords_container.get_children():
		child.queue_free()

	var keywords: Array = _node_data.data.get("return_keywords", [])

	for i in keywords.size():
		var keyword: String = keywords[i] if keywords[i] is String else str(keywords[i])
		var row := _create_keyword_row(i, keyword)
		_keywords_container.add_child(row)


func _create_keyword_row(index: int, keyword: String) -> Control:
	var hbox := HBoxContainer.new()

	var edit := LineEdit.new()
	edit.text = keyword
	edit.placeholder_text = "keyword"
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.text_changed.connect(_on_keyword_changed.bind(index))
	hbox.add_child(edit)

	var del_btn := Button.new()
	del_btn.text = "×"
	del_btn.custom_minimum_size.x = 28
	del_btn.pressed.connect(_on_remove_keyword.bind(index))
	hbox.add_child(del_btn)

	return hbox


func _on_add_keyword() -> void:
	var keywords: Array = _node_data.data.get("return_keywords", [])
	keywords.append("")
	_node_data.data["return_keywords"] = keywords
	_emit_changed()
	_rebuild_keywords_list()


func _on_remove_keyword(index: int) -> void:
	var keywords: Array = _node_data.data.get("return_keywords", [])
	if index >= 0 and index < keywords.size():
		keywords.remove_at(index)
		_node_data.data["return_keywords"] = keywords
		_emit_changed()
		_rebuild_keywords_list()


func _on_keyword_changed(new_text: String, index: int) -> void:
	var keywords: Array = _node_data.data.get("return_keywords", [])
	if index >= 0 and index < keywords.size():
		keywords[index] = new_text
		_emit_changed()
