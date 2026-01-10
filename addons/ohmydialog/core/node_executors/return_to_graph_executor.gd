@tool
class_name ReturnToGraphNodeExecutor
extends BaseNodeExecutor
## Executor for RETURN_TO_GRAPH nodes.
##
## Exits free conversation mode and returns to graph execution.


func execute(node_data: DialogueNodeData, context: Object) -> Dictionary:
	var return_node := node_data as ReturnToGraphNodeData
	var return_node_override: String = return_node.return_node_id if return_node else ""

	# The GraphRunner will handle exiting free mode
	return {
		RESULT_NEXT_NODE: "",
		RESULT_EXIT_FREE: true,
		"return_node_override": return_node_override  # If set, overrides stored return node
	}
