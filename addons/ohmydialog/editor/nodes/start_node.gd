@tool
class_name StartNode
extends BaseDialogueNode
## Visual node representing the entry point of a dialogue graph.
##
## The START node has no inputs and one output. There should only
## be one START node per graph.


func _configure_slots() -> void:
	clear_all_slots()
	# No input, one output
	set_slot(0, false, 0, Color.WHITE, true, 0, Color.WHITE)


func _create_content_ui() -> void:
	_add_hint_label("Entry Point")

	# Show AI model info from DialogueGraph (not StartNode - deprecated)
	var model_path: String = dialogue_graph.model_path if dialogue_graph else ""
	if model_path.is_empty():
		_add_info("AI", "(sin configurar)", Color(0.6, 0.6, 0.6))
	else:
		var model_name := model_path.get_file().get_basename()
		if FileAccess.file_exists(model_path):
			_add_info("AI", model_name, Color(0.4, 0.8, 1.0))
		else:
			_add_info("AI", model_name + " ✗", Color(0.94, 0.27, 0.27))

	_add_output_label(">")
