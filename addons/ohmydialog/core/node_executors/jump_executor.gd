@tool
class_name JumpNodeExecutor
extends BaseNodeExecutor
## Executor for JUMP nodes.
##
## Jumps to a specific node or another graph entirely.
## Preserves AI model in memory (only unloads the graph, not the model).


func execute(node_data: DialogueNodeData, context: Object) -> Dictionary:
	var target_node_id: String = node_data.data.get("target_node_id", "")
	var target_graph_path: String = node_data.data.get("target_graph_id", "")
	var preserve_context: bool = node_data.data.get("preserve_context", false)

	# Jump to another graph
	if not target_graph_path.is_empty():
		return {
			RESULT_NEXT_NODE: "",
			"jump_to_graph": target_graph_path,
			"target_node_in_graph": target_node_id,  # Optional: start at specific node
			"preserve_context": preserve_context
		}

	# Jump to node in same graph
	if not target_node_id.is_empty():
		return {
			RESULT_NEXT_NODE: target_node_id,
			RESULT_OUTPUT_SLOT: -1  # -1 indicates direct jump, not connection
		}

	return error("JumpExecutor: No target specified")
