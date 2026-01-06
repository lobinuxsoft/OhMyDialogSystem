@tool
class_name DialogueManager
extends Node
## Main orchestrator for the dialogue system.
##
## Manages dialogue execution in three modes:
## - FREE: Open AI conversation with character personality
## - SCRIPTED: Graph-based dialogue with predefined nodes
## - HYBRID: Transitions between free and scripted modes


## Dialogue execution modes.
enum DialogueMode {
	FREE,      ## Open AI conversation
	SCRIPTED,  ## Graph-based execution only
	HYBRID     ## Transitions between free and scripted
}


## Emitted when a dialogue session starts.
signal dialogue_started(graph: DialogueGraph)

## Emitted when dialogue ends.
signal dialogue_ended(reason: String)

## Emitted when NPC starts speaking.
signal npc_speaking(speaker: String, text: String, is_streaming: bool)

## Emitted for each token during streaming.
signal npc_response_token(token: String)

## Emitted when NPC response is complete.
signal npc_response_completed(full_text: String)

## Emitted when player choices are available.
signal player_choices_available(choices: Array[Dictionary])

## Emitted when waiting for player text input.
signal waiting_for_player_input

## Emitted when an event is triggered.
signal event_triggered(event_name: String, data: Dictionary)

## Emitted when the dialogue mode changes.
signal mode_changed(old_mode: DialogueMode, new_mode: DialogueMode)

## Emitted when a variable changes.
signal variable_changed(name: String, old_value: Variant, new_value: Variant)

## Emitted when an error occurs.
signal error_occurred(message: String)


@export_group("Configuration")

## The LlamaInterface for AI generation.
@export var llama_interface: Object

## Default character for AI responses.
@export var default_character: CharacterIdentity

## World context for AI generation.
@export var world_context: WorldContext

## AI generation preset.
@export var ai_preset: AIPreset

## Enable streaming responses.
@export var streaming_enabled: bool = true


@export_group("Context Limits")

## Maximum context tokens for LLM.
@export var max_context_tokens: int = 4096

## Tokens reserved for response.
@export var response_reserve_tokens: int = 512


## Current dialogue mode.
var current_mode: DialogueMode = DialogueMode.HYBRID

## Current dialogue graph.
var current_graph: DialogueGraph

## Graph execution runner.
var graph_runner: GraphRunner

## Prompt builder for LLM.
var prompt_builder: PromptBuilder

## Conversation history.
var conversation_history: ConversationHistory

## Context/variable manager.
var context_manager: ContextManager

## Active character (may differ from default).
var active_character: CharacterIdentity

## Whether dialogue is currently active.
var _is_active: bool = false

## Pending inference request.
var _pending_inference: Dictionary = {}


func _ready() -> void:
	_initialize_components()


## Initializes all internal components.
func _initialize_components() -> void:
	graph_runner = GraphRunner.new()
	prompt_builder = PromptBuilder.new()
	conversation_history = ConversationHistory.new()
	context_manager = ContextManager.new()

	# Connect graph runner signals
	graph_runner.node_entered.connect(_on_node_entered)
	graph_runner.node_exited.connect(_on_node_exited)
	graph_runner.response_ready.connect(_on_response_ready)
	graph_runner.waiting_for_input.connect(_on_waiting_for_input)
	graph_runner.event_triggered.connect(_on_event_triggered)
	graph_runner.entered_free_mode.connect(_on_entered_free_mode)
	graph_runner.exited_free_mode.connect(_on_exited_free_mode)
	graph_runner.graph_completed.connect(_on_graph_completed)
	graph_runner.error_occurred.connect(_on_error_occurred)

	# Connect context manager signals
	context_manager.variable_changed.connect(_on_variable_changed)
	context_manager.event_triggered.connect(_on_context_event)


## Starts a dialogue session.
func start_dialogue(graph: DialogueGraph = null, mode: DialogueMode = DialogueMode.HYBRID) -> void:
	if _is_active:
		push_warning("DialogueManager: Dialogue already active, ending first")
		end_dialogue("new_dialogue_started")

	current_graph = graph
	current_mode = mode
	active_character = default_character
	_is_active = true

	# Initialize context from graph
	if graph:
		context_manager.local_variables = graph.local_variables.duplicate()
		if graph.default_character:
			active_character = graph.default_character

	# Apply AI preset
	if ai_preset and llama_interface:
		ai_preset.apply_to(llama_interface)

	dialogue_started.emit(graph)

	# Start execution based on mode
	match mode:
		DialogueMode.FREE:
			_start_free_mode()
		DialogueMode.SCRIPTED, DialogueMode.HYBRID:
			if graph:
				_start_graph_execution()
			else:
				_start_free_mode()


## Ends the current dialogue session.
func end_dialogue(reason: String = "ended") -> void:
	if not _is_active:
		return

	graph_runner.stop()
	context_manager.clear_local()
	_is_active = false
	_pending_inference.clear()

	dialogue_ended.emit(reason)


## Sends a player message (for FREE mode or text input nodes).
func send_player_message(text: String) -> void:
	if not _is_active:
		push_warning("DialogueManager: No active dialogue")
		return

	# Add to history
	conversation_history.add_user(text)

	if current_mode == DialogueMode.FREE or graph_runner.is_in_free_mode():
		_process_free_mode_message(text)
	else:
		graph_runner.provide_input(text)


## Selects a choice by index.
func select_choice(choice_index: int) -> void:
	if not _is_active:
		push_warning("DialogueManager: No active dialogue")
		return

	graph_runner.select_choice(choice_index)


## Sets the active character for AI responses.
func set_character(character: CharacterIdentity) -> void:
	active_character = character


## Sets the world context.
func set_world_context(context: WorldContext) -> void:
	world_context = context


## Sets the LlamaInterface.
func set_llama_interface(interface: Object) -> void:
	llama_interface = interface


## Sets the AI preset.
func set_ai_preset(preset: AIPreset) -> void:
	ai_preset = preset
	if llama_interface and preset:
		preset.apply_to(llama_interface)


## Sets streaming mode.
func set_streaming_enabled(enabled: bool) -> void:
	streaming_enabled = enabled


## Changes the dialogue mode during execution.
func set_mode(mode: DialogueMode) -> void:
	if mode == current_mode:
		return

	var old_mode := current_mode
	current_mode = mode
	mode_changed.emit(old_mode, mode)


## Returns whether dialogue is currently active.
func is_active() -> bool:
	return _is_active


## Gets a variable from context.
func get_variable(name: String, default: Variant = null) -> Variant:
	return context_manager.get_variable(name, default)


## Sets a variable in context.
func set_variable(name: String, value: Variant, scope: String = "local") -> void:
	context_manager.set_variable(name, value, scope)


## Evaluates a condition expression.
func evaluate_condition(expression: String) -> bool:
	return context_manager.evaluate_condition(expression)


# ==================== Internal Methods ====================


## Starts free conversation mode.
func _start_free_mode() -> void:
	set_mode(DialogueMode.FREE)
	waiting_for_player_input.emit()


## Starts graph-based execution.
func _start_graph_execution() -> void:
	if not current_graph:
		_emit_error("No graph to execute")
		return

	# Build execution context
	var exec_context := {
		"llama_interface": llama_interface,
		"prompt_builder": prompt_builder,
		"character": active_character,
		"world": world_context,
		"history": conversation_history.get_history(),
		"context_manager": context_manager
	}

	graph_runner.start(current_graph, exec_context)


## Processes a message in free mode.
func _process_free_mode_message(text: String) -> void:
	if not llama_interface:
		_emit_error("No LlamaInterface configured for AI responses")
		return

	# Build prompt
	var memories: Array[String] = []  # TODO: Integrate memory system
	var prompt := prompt_builder.build_prompt(
		active_character,
		world_context,
		memories,
		conversation_history.get_history(),
		text,
		max_context_tokens
	)

	# Request inference
	_request_inference(prompt)


## Requests AI inference.
func _request_inference(prompt: String) -> void:
	if not llama_interface:
		_emit_error("No LlamaInterface for inference")
		return

	_pending_inference = {"prompt": prompt}

	var speaker := active_character.character_name if active_character else "NPC"
	npc_speaking.emit(speaker, "", streaming_enabled)

	if streaming_enabled and llama_interface.has_method("generate_stream"):
		_start_streaming_inference(prompt)
	else:
		_start_blocking_inference(prompt)


## Starts streaming inference.
func _start_streaming_inference(prompt: String) -> void:
	# Connect to streaming signals
	if llama_interface.has_signal("token_generated"):
		if not llama_interface.token_generated.is_connected(_on_token_generated):
			llama_interface.token_generated.connect(_on_token_generated)
	if llama_interface.has_signal("generation_completed"):
		if not llama_interface.generation_completed.is_connected(_on_generation_completed):
			llama_interface.generation_completed.connect(_on_generation_completed)

	# Start generation
	if llama_interface.has_method("generate_stream"):
		llama_interface.generate_stream(prompt)
	elif llama_interface.has_method("generate"):
		# Fallback to blocking
		_start_blocking_inference(prompt)


## Starts blocking inference.
func _start_blocking_inference(prompt: String) -> void:
	if not llama_interface.has_method("generate"):
		_emit_error("LlamaInterface has no generate method")
		return

	var result: String = llama_interface.generate(prompt)
	_complete_inference(result)


## Called for each token during streaming.
func _on_token_generated(token: String) -> void:
	npc_response_token.emit(token)


## Called when streaming generation completes.
func _on_generation_completed(full_text: String) -> void:
	_complete_inference(full_text)


## Completes inference and updates state.
func _complete_inference(response: String) -> void:
	# Add to history
	conversation_history.add_assistant(response)

	var speaker := active_character.character_name if active_character else "NPC"
	npc_response_completed.emit(response)

	# Check if in free mode within graph
	if graph_runner.is_in_free_mode():
		# Let graph runner handle return conditions
		graph_runner.provide_input(response)
	elif current_mode == DialogueMode.FREE:
		# Pure free mode - continue conversation
		waiting_for_player_input.emit()
	else:
		# Graph mode - continue execution
		graph_runner.provide_input(response)

	_pending_inference.clear()


# ==================== Graph Runner Signal Handlers ====================


func _on_node_entered(node_data: DialogueNodeData) -> void:
	# Update active character if node specifies one
	var node_character: CharacterIdentity = node_data.data.get("character_override")
	if node_character:
		active_character = node_character


func _on_node_exited(_node_data: DialogueNodeData) -> void:
	pass


func _on_response_ready(text: String, speaker: String) -> void:
	if speaker.is_empty() and active_character:
		speaker = active_character.character_name

	conversation_history.add_assistant(text)
	npc_speaking.emit(speaker, text, false)
	npc_response_completed.emit(text)


func _on_waiting_for_input(input_type: String, data: Dictionary) -> void:
	match input_type:
		"choice":
			var choices: Array = data.get("choices", [])
			var typed_choices: Array[Dictionary] = []
			for c in choices:
				typed_choices.append(c)
			player_choices_available.emit(typed_choices)

		"inference":
			if data.get("mode") == "free":
				# Free mode inference request
				var player_input: String = data.get("player_input", "")
				_process_free_mode_message(player_input)
			elif data.has("prompt"):
				# Graph node requested inference
				_request_inference(data["prompt"])

		"text":
			waiting_for_player_input.emit()


func _on_event_triggered(event_name: String, event_data: Dictionary) -> void:
	event_triggered.emit(event_name, event_data)


func _on_entered_free_mode(conversation_state: ConversationState) -> void:
	set_mode(DialogueMode.FREE)


func _on_exited_free_mode() -> void:
	if current_graph:
		set_mode(DialogueMode.HYBRID)


func _on_graph_completed() -> void:
	end_dialogue("graph_completed")


func _on_error_occurred(message: String) -> void:
	_emit_error(message)


func _on_variable_changed(name: String, old_value: Variant, new_value: Variant) -> void:
	variable_changed.emit(name, old_value, new_value)


func _on_context_event(event_name: String, data: Dictionary) -> void:
	event_triggered.emit(event_name, data)


func _emit_error(message: String) -> void:
	push_error("DialogueManager: %s" % message)
	error_occurred.emit(message)


# ==================== Utility ====================


## Returns the current conversation history.
func get_conversation_history() -> ConversationHistory:
	return conversation_history


## Returns the context manager.
func get_context_manager() -> ContextManager:
	return context_manager


## Returns the prompt builder.
func get_prompt_builder() -> PromptBuilder:
	return prompt_builder


## Clears conversation history.
func clear_history() -> void:
	conversation_history.clear()


## Returns debug info.
func get_debug_info() -> Dictionary:
	return {
		"is_active": _is_active,
		"mode": DialogueMode.keys()[current_mode],
		"graph": current_graph.graph_id if current_graph else "none",
		"character": active_character.character_name if active_character else "none",
		"history": conversation_history.get_summary(),
		"context": context_manager.get_summary()
	}
