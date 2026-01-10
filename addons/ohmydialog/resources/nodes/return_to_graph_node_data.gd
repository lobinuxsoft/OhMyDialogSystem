@tool
class_name ReturnToGraphNodeData
extends DialogueNodeData
## Node that returns from free mode to graph execution.


## Node ID to return to (if empty, returns to caller).
@export var return_node_id: String = "":
	set(v):
		return_node_id = v
		emit_changed()


func _get_node_type() -> DialogueNodeData.NodeType:
	return DialogueNodeData.NodeType.RETURN_TO_GRAPH


func _calculate_output_count() -> int:
	return 0  # Terminal node (returns to caller)


func to_dict() -> Dictionary:
	var dict := super.to_dict()
	dict["return_node_id"] = return_node_id
	return dict


func _load_from_dict(dict: Dictionary) -> void:
	return_node_id = dict.get("return_node_id", "")
	super._load_from_dict(dict)


func _migrate_from_data_dict(data: Dictionary) -> void:
	return_node_id = data.get("return_node_id", "")
