@tool
class_name GraphRunner
extends RefCounted
## Runtime executor for DialogueGraph resources.
##
## Interprets dialogue graphs by delegating node execution to NodeExecutors.
## Handles both scripted graph flow and free conversation mode.


## Emitted when entering a new node.
signal node_entered(node_data: DialogueNodeData)

## Emitted when exiting a node.
signal node_exited(node_data: DialogueNodeData)

## Emitted when waiting for player input (choices, text input).
signal waiting_for_input(input_type: String, data: Dictionary)

## Emitted when an NPC response is ready to display.
signal response_ready(text: String, speaker: String)

## Emitted when entering free conversation mode.
signal entered_free_mode(conversation_state: ConversationState)

## Emitted when exiting free conversation mode.
signal exited_free_mode

## Emitted when graph execution completes normally.
signal graph_completed

## Emitted when an event node triggers.
signal event_triggered(event_name: String, event_data: Dictionary)

## Emitted when an error occurs during execution.
signal error_occurred(message: String)


## Execution states.
enum State {
	IDLE,           ## Not running
	RUNNING,        ## Executing nodes
	WAITING_INPUT,  ## Waiting for player input
	FREE_MODE,      ## In free conversation
	PAUSED,         ## Manually paused
	COMPLETED,      ## Finished normally
	ERROR           ## Stopped due to error
}

## Current execution state.
var state: State = State.IDLE

## The graph being executed.
var current_graph: DialogueGraph

## Current node being executed.
var current_node: DialogueNodeData

## Executors by node type.
var _executors: Dictionary = {}

## Conversation state for free mode.
var _conversation_state: ConversationState

## Variables context (dialogue + global).
var _variables: Dictionary = {}

## Execution context passed to executors.
var _context: Dictionary = {}

## Return node for when exiting free mode.
var _free_mode_return_node: String = ""

## Pending choices when waiting for player selection.
var _pending_choices: Array = []


func _init() -> void:
	_register_default_executors()
	_conversation_state = ConversationState.new()


## Registers all default node executors.
func _register_default_executors() -> void:
	_executors[DialogueNodeData.NodeType.START] = StartNodeExecutor.new()
	_executors[DialogueNodeData.NodeType.END] = EndNodeExecutor.new()
	_executors[DialogueNodeData.NodeType.AI_RESPONSE] = AIResponseNodeExecutor.new()
	_executors[DialogueNodeData.NodeType.STATIC_RESPONSE] = StaticResponseNodeExecutor.new()
	_executors[DialogueNodeData.NodeType.PLAYER_CHOICE] = PlayerChoiceNodeExecutor.new()
	_executors[DialogueNodeData.NodeType.CONDITION] = ConditionNodeExecutor.new()
	_executors[DialogueNodeData.NodeType.EVENT] = EventNodeExecutor.new()
	_executors[DialogueNodeData.NodeType.SET_VARIABLE] = SetVariableNodeExecutor.new()
	_executors[DialogueNodeData.NodeType.JUMP] = JumpNodeExecutor.new()
	_executors[DialogueNodeData.NodeType.JUMP_TO_FREE] = JumpToFreeNodeExecutor.new()
	_executors[DialogueNodeData.NodeType.RETURN_TO_GRAPH] = ReturnToGraphNodeExecutor.new()


## Registers a custom executor for a node type.
func register_executor(node_type: DialogueNodeData.NodeType, executor: BaseNodeExecutor) -> void:
	_executors[node_type] = executor


## Starts executing a dialogue graph.
func start(graph: DialogueGraph, initial_context: Dictionary = {}) -> void:
	if state == State.RUNNING or state == State.WAITING_INPUT:
		push_warning("GraphRunner: Cannot start while already running")
		return

	if not graph:
		_emit_error("No graph provided")
		return

	current_graph = graph
	_variables = graph.local_variables.duplicate()
	_context = initial_context.duplicate()
	_context["runner"] = self

	# Find start node
	var start_node := graph.get_start_node()
	if not start_node:
		_emit_error("Graph has no start node")
		return

	state = State.RUNNING
	current_node = start_node
	_execute_current_node()


## Stops graph execution.
func stop() -> void:
	if state == State.FREE_MODE:
		_conversation_state.end_conversation()
		exited_free_mode.emit()

	state = State.IDLE
	current_node = null
	current_graph = null
	_pending_choices.clear()


## Pauses execution (can be resumed).
func pause() -> void:
	if state == State.RUNNING:
		state = State.PAUSED


## Resumes paused execution.
func resume() -> void:
	if state == State.PAUSED:
		state = State.RUNNING
		_execute_current_node()


## Provides player input (for choice selection or text input).
func provide_input(input: Variant) -> void:
	if state != State.WAITING_INPUT:
		push_warning("GraphRunner: Not waiting for input")
		return

	if input is int:
		# Choice selection - get text and store as player_input
		if input >= 0 and input < _pending_choices.size():
			var selected_choice: Dictionary = _pending_choices[input]
			_context["player_input"] = selected_choice.get("text", "")
		_pending_choices.clear()
		_advance_to_next_node(input)
	elif input is String:
		# Text input - store in context
		_context["player_input"] = input
		if state == State.FREE_MODE:
			_process_free_mode_input(input)
		else:
			_advance_to_next_node(0)


## Provides choice selection by index.
func select_choice(choice_index: int) -> void:
	provide_input(choice_index)


## Executes the current node and handles the result.
func _execute_current_node() -> void:
	if not current_node or state != State.RUNNING:
		return

	node_entered.emit(current_node)

	# Process node metadata conditions (if DialogueManager available)
	var dialogue_manager: Object = _context.get("dialogue_manager")
	if dialogue_manager and dialogue_manager.has_method("check_node_metadata_conditions"):
		if not dialogue_manager.check_node_metadata_conditions(current_node):
			# Conditions not met - skip to next node via default slot
			_advance_to_next_node(0)
			return

	# Get executor for this node type
	var executor: BaseNodeExecutor = _executors.get(current_node.node_type)
	if not executor:
		_emit_error("No executor for node type: %s" % current_node.node_type)
		return

	# Build execution context
	_context["graph"] = current_graph
	_context["current_node"] = current_node
	_context["variables"] = _variables

	# Execute the node
	var result := executor.execute(current_node, _create_context_object())

	# Process node metadata actions (if DialogueManager available)
	if dialogue_manager and dialogue_manager.has_method("process_node_metadata"):
		dialogue_manager.process_node_metadata(current_node)

	# Handle the result
	_handle_result(result)


## Handles the result from a node executor.
func _handle_result(result: Dictionary) -> void:
	# Check for errors
	if result.has(BaseNodeExecutor.RESULT_ERROR):
		_emit_error(result[BaseNodeExecutor.RESULT_ERROR])
		return

	# Check for graph end
	if result.get(BaseNodeExecutor.RESULT_END_GRAPH, false):
		_complete_graph()
		return

	# Check for entering free mode
	if result.get(BaseNodeExecutor.RESULT_ENTER_FREE, false):
		_enter_free_mode(result)
		return

	# Check for exiting free mode
	if result.get(BaseNodeExecutor.RESULT_EXIT_FREE, false):
		_exit_free_mode(result)
		return

	# Handle text response
	if result.has(BaseNodeExecutor.RESULT_TEXT):
		var text: String = result[BaseNodeExecutor.RESULT_TEXT]
		var speaker: String = result.get("speaker", "")
		if not text.is_empty():
			response_ready.emit(text, speaker)

	# Handle event
	if result.has(BaseNodeExecutor.RESULT_EVENT):
		var event_name: String = result[BaseNodeExecutor.RESULT_EVENT]
		var event_data: Dictionary = result.get("event_data", {})
		event_triggered.emit(event_name, event_data)

	# Handle variable changes
	if result.has(BaseNodeExecutor.RESULT_VARIABLE):
		var var_name: String = result[BaseNodeExecutor.RESULT_VARIABLE]
		var var_value: Variant = result.get(BaseNodeExecutor.RESULT_VALUE)
		_variables[var_name] = var_value

	# Handle choices (wait for input)
	if result.has(BaseNodeExecutor.RESULT_CHOICES):
		_pending_choices = result[BaseNodeExecutor.RESULT_CHOICES]
		state = State.WAITING_INPUT
		waiting_for_input.emit("choice", {"choices": result[BaseNodeExecutor.RESULT_CHOICES]})
		return

	# Handle wait for confirmation (e.g., after static response)
	if result.get(BaseNodeExecutor.RESULT_WAIT_CONFIRM, false):
		state = State.WAITING_INPUT
		waiting_for_input.emit("confirm", {
			"output_slot": result.get(BaseNodeExecutor.RESULT_OUTPUT_SLOT, 0)
		})
		return

	# Handle inference request (wait for LLM)
	if result.get("requires_inference", false):
		state = State.WAITING_INPUT
		waiting_for_input.emit("inference", result)
		return

	# Handle jump to another graph
	if result.has("jump_to_graph"):
		_jump_to_graph(result["jump_to_graph"], result.get("target_node_in_graph", ""))
		return

	# Normal flow - advance to next node
	var output_slot: int = result.get(BaseNodeExecutor.RESULT_OUTPUT_SLOT, 0)
	var direct_next: String = result.get(BaseNodeExecutor.RESULT_NEXT_NODE, "")

	if not direct_next.is_empty():
		# Direct jump specified by executor
		_go_to_node(direct_next)
	else:
		# Follow connection from output slot
		_advance_to_next_node(output_slot)


## Advances to the next node via connection.
func _advance_to_next_node(output_slot: int) -> void:
	if not current_node or not current_graph:
		_complete_graph()
		return

	node_exited.emit(current_node)

	var next_node := current_graph.get_next_node(current_node.node_id, output_slot)
	if not next_node:
		# No connection from this slot - check if this is expected
		if current_node.node_type == DialogueNodeData.NodeType.END:
			_complete_graph()
		else:
			_emit_error("No connection from node %s slot %d" % [current_node.node_id, output_slot])
		return

	current_node = next_node
	state = State.RUNNING
	_execute_current_node()


## Goes directly to a specific node by ID.
func _go_to_node(node_id: String) -> void:
	if not current_graph:
		return

	var node := current_graph.get_node(node_id)
	if not node:
		_emit_error("Node not found: %s" % node_id)
		return

	if current_node:
		node_exited.emit(current_node)

	current_node = node
	_execute_current_node()


## Jumps to another graph entirely.
func _jump_to_graph(graph_path: String, target_node: String = "") -> void:
	var new_graph := load(graph_path) as DialogueGraph
	if not new_graph:
		_emit_error("Could not load graph: %s" % graph_path)
		return

	# Preserve context but switch graphs
	current_graph = new_graph
	_variables.merge(new_graph.local_variables)

	if not target_node.is_empty():
		_go_to_node(target_node)
	else:
		var start := new_graph.get_start_node()
		if start:
			current_node = start
			_execute_current_node()
		else:
			_emit_error("Target graph has no start node")


## Enters free conversation mode.
func _enter_free_mode(result: Dictionary) -> void:
	_free_mode_return_node = result.get("return_node_id", "")

	_conversation_state.start_conversation(_free_mode_return_node)
	_conversation_state.set_max_exchanges(result.get("max_exchanges", 0))
	_conversation_state.set_timeout(result.get("timeout_seconds", 0.0))

	# Add return conditions
	var conditions: Array = result.get("return_conditions", [])
	for cond in conditions:
		_conversation_state.return_conditions.append(cond)

	state = State.FREE_MODE
	entered_free_mode.emit(_conversation_state)

	# Wait for first player input
	waiting_for_input.emit("text", {"mode": "free"})


## Processes input while in free mode.
func _process_free_mode_input(input: String) -> void:
	_conversation_state.add_player_message(input)

	# Check return conditions
	var return_reason := _conversation_state.should_return_to_graph(input)
	if not return_reason.is_empty():
		_exit_free_mode({"return_reason": return_reason})
		return

	# Continue in free mode - emit signal for AI response
	waiting_for_input.emit("inference", {
		"mode": "free",
		"history": _conversation_state.messages,
		"player_input": input
	})


## Exits free conversation mode.
func _exit_free_mode(result: Dictionary) -> void:
	_conversation_state.end_conversation()
	exited_free_mode.emit()

	# Determine return node
	var return_node: String = result.get("return_node_override", "")
	if return_node.is_empty():
		return_node = _free_mode_return_node

	if return_node.is_empty():
		# No return node - follow connection from JumpToFree node
		_advance_to_next_node(0)
	else:
		_go_to_node(return_node)


## Completes graph execution normally.
func _complete_graph() -> void:
	if current_node:
		node_exited.emit(current_node)

	state = State.COMPLETED
	graph_completed.emit()


## Emits an error and stops execution.
func _emit_error(message: String) -> void:
	push_error("GraphRunner: %s" % message)
	state = State.ERROR
	error_occurred.emit(message)


## Creates a context object for executors.
func _create_context_object() -> Object:
	# Return a simple wrapper that provides the context interface
	return GraphRunnerContext.new(self)


## Gets a variable value.
func get_variable(name: String) -> Variant:
	return _variables.get(name)


## Sets a variable value.
## Note: scope is currently stored locally. For full scope support,
## use DialogueManager which delegates to ContextManager.
func set_variable(name: String, value: Variant, _scope: String = "local") -> void:
	_variables[name] = value


## Evaluates a condition expression.
func evaluate_condition(expression: String) -> bool:
	# Simple expression evaluation
	# Format: "variable operator value" or just "variable" (truthy check)

	var parts := expression.strip_edges().split(" ", false)
	if parts.is_empty():
		return false

	var var_name: String = parts[0]
	var value: Variant = get_variable(var_name)

	if parts.size() == 1:
		# Truthy check
		return bool(value)

	if parts.size() >= 3:
		var operator: String = parts[1]
		var compare_str: String = " ".join(parts.slice(2))
		var compare_value: Variant = _parse_value(compare_str)

		match operator:
			"==", "is":
				return value == compare_value
			"!=", "not":
				return value != compare_value
			">":
				return value > compare_value
			"<":
				return value < compare_value
			">=":
				return value >= compare_value
			"<=":
				return value <= compare_value

	return false


## Parses a string value into the appropriate type.
func _parse_value(str_value: String) -> Variant:
	str_value = str_value.strip_edges()

	# Boolean
	if str_value == "true":
		return true
	if str_value == "false":
		return false

	# Number
	if str_value.is_valid_int():
		return str_value.to_int()
	if str_value.is_valid_float():
		return str_value.to_float()

	# String (remove quotes if present)
	if str_value.begins_with("\"") and str_value.ends_with("\""):
		return str_value.substr(1, str_value.length() - 2)

	return str_value


## Returns true if currently in free conversation mode.
func is_in_free_mode() -> bool:
	return state == State.FREE_MODE


## Returns the current conversation state (for free mode).
func get_conversation_state() -> ConversationState:
	return _conversation_state


## Returns all current variables.
func get_all_variables() -> Dictionary:
	return _variables.duplicate()


# ==================== Context Wrapper ====================


## Simple wrapper class to provide context interface to executors.
class GraphRunnerContext extends RefCounted:
	var _runner: GraphRunner

	func _init(runner: GraphRunner) -> void:
		_runner = runner

	func get_context(key: String) -> Variant:
		match key:
			"graph":
				return _runner.current_graph
			"current_node":
				return _runner.current_node
			"variables":
				return _runner._variables
			"character":
				if _runner.current_graph:
					return _runner.current_graph.default_character
			"world":
				if _runner.current_graph:
					return _runner.current_graph.world_context
			"history":
				return _runner._conversation_state.messages
			"player_input":
				return _runner._context.get("player_input", "")
			"memories":
				return []  # TODO: Integrate with memory system
			"llama_interface":
				return _runner._context.get("llama_interface")
			"prompt_builder":
				return _runner._context.get("prompt_builder")
		return null

	func set_context(key: String, value: Variant) -> void:
		_runner._context[key] = value

	func context_has_method(method_name: String) -> bool:
		return method_name in ["get_context", "set_context", "get_variable", "set_variable", "evaluate_condition"]

	func get_variable(name: String) -> Variant:
		return _runner.get_variable(name)

	func set_variable(name: String, value: Variant, scope: String = "local") -> void:
		_runner.set_variable(name, value, scope)

	func evaluate_condition(expression: String) -> bool:
		return _runner.evaluate_condition(expression)
