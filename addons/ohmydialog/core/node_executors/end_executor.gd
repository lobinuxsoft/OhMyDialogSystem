@tool
class_name EndNodeExecutor
extends BaseNodeExecutor
## Executor for END nodes.
##
## Signals the end of graph execution.


func execute(node_data: DialogueNodeData, _context: Object) -> Dictionary:
	return end_graph()
