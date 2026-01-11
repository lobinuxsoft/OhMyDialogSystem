@tool
class_name BaseNodeExecutor
extends RefCounted
## Abstract base class for dialogue node executors.
##
## Each node type has its own executor that implements the execute() method.
## Executors return a dictionary with next_node and optional data.


## Result keys returned by execute()
const RESULT_NEXT_NODE := "next_node"
const RESULT_OUTPUT_SLOT := "output_slot"
const RESULT_TEXT := "text"
const RESULT_CHOICES := "choices"
const RESULT_EVENT := "event"
const RESULT_VARIABLE := "variable"
const RESULT_VALUE := "value"
const RESULT_ERROR := "error"
const RESULT_END_GRAPH := "end_graph"
const RESULT_ENTER_FREE := "enter_free"
const RESULT_EXIT_FREE := "exit_free"
const RESULT_WAIT_CONFIRM := "wait_for_confirm"


## Executes the node and returns result dictionary.
## Must be overridden by subclasses.
## @param node_data The DialogueNodeData to execute
## @param context Execution context (DialogueManager or similar)
## @return Dictionary with at minimum {next_node: String}
func execute(_node_data: DialogueNodeData, _context: Object) -> Dictionary:
	push_error("BaseNodeExecutor.execute() must be overridden")
	return {RESULT_ERROR: "Not implemented"}


## Helper to create a simple "continue to next node" result.
static func continue_to(next_node_id: String, output_slot: int = 0) -> Dictionary:
	return {
		RESULT_NEXT_NODE: next_node_id,
		RESULT_OUTPUT_SLOT: output_slot
	}


## Helper to create an end result.
static func end_graph() -> Dictionary:
	return {
		RESULT_END_GRAPH: true,
		RESULT_NEXT_NODE: ""
	}


## Helper to create an error result.
static func error(message: String) -> Dictionary:
	return {
		RESULT_ERROR: message,
		RESULT_NEXT_NODE: ""
	}
