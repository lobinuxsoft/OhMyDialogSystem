@tool
class_name JumpToFreeNodeExecutor
extends BaseNodeExecutor
## Executor for JUMP_TO_FREE nodes.
##
## Enters free conversation mode with the AI.
## Stores return node for when conversation ends.


func execute(node_data: DialogueNodeData, context: Object) -> Dictionary:
	var free_node := node_data as JumpToFreeNodeData
	var context_prompt: String = free_node.context_prompt if free_node else ""
	var return_keywords: PackedStringArray = free_node.return_keywords if free_node else PackedStringArray()
	var return_condition: String = free_node.return_condition if free_node else ""
	var max_exchanges: int = free_node.max_exchanges if free_node else 0

	# Build return_conditions array for graph_runner
	var conditions: Array[Dictionary] = []

	if not return_keywords.is_empty():
		conditions.append({
			"name": "exit_keywords",
			"type": "keyword",
			"value": Array(return_keywords)
		})

	if not return_condition.is_empty():
		conditions.append({
			"name": "custom_condition",
			"type": "custom",
			"value": return_condition
		})

	# The GraphRunner will handle entering free mode
	return {
		RESULT_NEXT_NODE: "",
		RESULT_ENTER_FREE: true,
		"context_prompt": context_prompt,
		"return_conditions": conditions,
		"max_exchanges": max_exchanges
	}
