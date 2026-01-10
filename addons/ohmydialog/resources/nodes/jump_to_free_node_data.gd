@tool
class_name JumpToFreeNodeData
extends DialogueNodeData
## Node that escapes to free conversation mode.


## Context prompt for the free conversation.
@export_multiline var context_prompt: String = "":
	set(v):
		context_prompt = v
		emit_changed()

## Keywords that trigger return to graph.
@export var return_keywords: PackedStringArray = []:
	set(v):
		return_keywords = v
		emit_changed()

## Optional expression condition for returning.
@export_multiline var return_condition: String = "":
	set(v):
		return_condition = v
		emit_changed()

## Maximum exchanges before auto-return (0 = unlimited).
@export_range(0, 100) var max_exchanges: int = 0:
	set(v):
		max_exchanges = v
		emit_changed()


func _get_node_type() -> DialogueNodeData.NodeType:
	return DialogueNodeData.NodeType.JUMP_TO_FREE


func _calculate_output_count() -> int:
	return 1  # Returns to graph eventually


func to_dict() -> Dictionary:
	var dict := super.to_dict()
	dict["context_prompt"] = context_prompt
	dict["return_keywords"] = Array(return_keywords)
	dict["return_condition"] = return_condition
	dict["max_exchanges"] = max_exchanges
	return dict


func _load_from_dict(dict: Dictionary) -> void:
	context_prompt = dict.get("context_prompt", "")
	var keywords: Array = dict.get("return_keywords", [])
	return_keywords = PackedStringArray(keywords)
	return_condition = dict.get("return_condition", "")
	max_exchanges = dict.get("max_exchanges", 0)
	super._load_from_dict(dict)


func _migrate_from_data_dict(data: Dictionary) -> void:
	context_prompt = data.get("context_prompt", "")
	var keywords: Array = data.get("return_keywords", [])
	return_keywords = PackedStringArray(keywords)
	return_condition = data.get("return_condition", "")
	max_exchanges = data.get("max_exchanges", 0)
