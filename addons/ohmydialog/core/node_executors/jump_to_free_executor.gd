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

	# The GraphRunner will handle entering free mode
	return {
		RESULT_NEXT_NODE: "",
		RESULT_ENTER_FREE: true,
		"context_prompt": context_prompt,
		"return_keywords": Array(return_keywords),
		"return_condition": return_condition,
		"max_exchanges": max_exchanges
	}
