@tool
class_name EndNodeData
extends DialogueNodeData
## Terminal node that ends dialogue execution.
##
## When reached, the dialogue session ends and any loaded AI model is unloaded.


func _get_node_type() -> DialogueNodeData.NodeType:
	return DialogueNodeData.NodeType.END


func _calculate_output_count() -> int:
	return 0  # Terminal node
