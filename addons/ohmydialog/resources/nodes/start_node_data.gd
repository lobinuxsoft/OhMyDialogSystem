@tool
class_name StartNodeData
extends DialogueNodeData
## Entry point node for a dialogue graph.


## Event name that starts this dialogue (empty = manual trigger).
@export var trigger: String = "":
	set(value):
		trigger = value
		emit_changed()

## Path to the AI model (DEPRECATED: use DialogueGraph.model_path instead).
## Kept for backwards compatibility. Will be removed in a future version.
@export_file("*.gguf") var model_path: String = "":
	set(value):
		model_path = value
		emit_changed()


func _get_node_type() -> DialogueNodeData.NodeType:
	return DialogueNodeData.NodeType.START


func _calculate_output_count() -> int:
	return 1


func to_dict() -> Dictionary:
	var dict := super.to_dict()
	dict["trigger"] = trigger
	dict["model_path"] = model_path
	return dict


func _load_from_dict(dict: Dictionary) -> void:
	trigger = dict.get("trigger", "")
	model_path = dict.get("model_path", "")
	super._load_from_dict(dict)


func _migrate_from_data_dict(data: Dictionary) -> void:
	trigger = data.get("trigger", "")
	model_path = data.get("model_path", "")
