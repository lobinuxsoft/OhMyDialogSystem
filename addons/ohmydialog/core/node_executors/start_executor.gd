@tool
class_name StartNodeExecutor
extends BaseNodeExecutor
## Executor for START nodes.
##
## Simply passes through to the next connected node.


func execute(node_data: DialogueNodeData, _context: Object) -> Dictionary:
	# Start node just passes through to whatever is connected
	# The GraphRunner will resolve the actual next node from connections
	return continue_to("", 0)
