@tool
class_name EndNodeExecutor
extends BaseNodeExecutor
## Executor for END nodes.
##
## Signals the end of graph execution. The AI model will be
## automatically unloaded by DialogueManager when this executes.


func execute(_node_data: DialogueNodeData, _context: Object) -> Dictionary:
	return end_graph()
