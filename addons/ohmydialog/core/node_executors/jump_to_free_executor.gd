@tool
class_name JumpToFreeNodeExecutor
extends BaseNodeExecutor
## Executor for JUMP_TO_FREE nodes.
##
## Enters free conversation mode with the AI.
## Stores return node for when conversation ends.


func execute(node_data: DialogueNodeData, context: Object) -> Dictionary:
	var return_node_id: String = node_data.data.get("return_node_id", "")
	var max_exchanges: int = node_data.data.get("max_exchanges", 0)
	var timeout: float = node_data.data.get("timeout_seconds", 0.0)
	var return_conditions: Array = node_data.data.get("return_conditions", [])

	# The GraphRunner will handle entering free mode
	return {
		RESULT_NEXT_NODE: "",
		RESULT_ENTER_FREE: true,
		"return_node_id": return_node_id,
		"max_exchanges": max_exchanges,
		"timeout_seconds": timeout,
		"return_conditions": return_conditions
	}
