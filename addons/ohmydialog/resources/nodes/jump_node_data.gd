@tool
class_name JumpNodeData
extends DialogueNodeData
## Node that jumps to another graph or specific node.


## Target graph resource path (if jumping to another graph).
@export_file("*.tres") var target_graph_id: String = "":
	set(v):
		target_graph_id = v
		emit_changed()

## Target node ID within the graph.
@export var target_node_id: String = "":
	set(v):
		target_node_id = v
		emit_changed()

## Whether to preserve dialogue context when jumping.
@export var preserve_context: bool = true:
	set(v):
		preserve_context = v
		emit_changed()


func _get_node_type() -> DialogueNodeData.NodeType:
	return DialogueNodeData.NodeType.JUMP


func _calculate_output_count() -> int:
	return 0  # Terminal node (jumps elsewhere)


func validate() -> Array[String]:
	var errors := super.validate()
	if target_graph_id.is_empty() and target_node_id.is_empty():
		errors.append("JUMP requires either target_graph_id or target_node_id")
	return errors


func to_dict() -> Dictionary:
	var dict := super.to_dict()
	dict["target_graph_id"] = target_graph_id
	dict["target_node_id"] = target_node_id
	dict["preserve_context"] = preserve_context
	return dict


func _load_from_dict(dict: Dictionary) -> void:
	target_graph_id = dict.get("target_graph_id", "")
	target_node_id = dict.get("target_node_id", "")
	preserve_context = dict.get("preserve_context", true)
	super._load_from_dict(dict)


func _migrate_from_data_dict(data: Dictionary) -> void:
	target_graph_id = data.get("target_graph_id", "")
	target_node_id = data.get("target_node_id", "")
	preserve_context = data.get("preserve_context", true)
