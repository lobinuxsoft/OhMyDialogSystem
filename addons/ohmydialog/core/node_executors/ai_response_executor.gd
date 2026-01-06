@tool
class_name AIResponseNodeExecutor
extends BaseNodeExecutor
## Executor for AI_RESPONSE nodes.
##
## Generates a response using LlamaInterface via the PromptBuilder.
## Requires context to have: character, world, llama_interface, prompt_builder


func execute(node_data: DialogueNodeData, context: Object) -> Dictionary:
	# Get required components from context
	var has_context := context.has_method("get_context")
	var llama: LlamaInterface = context.get_context("llama_interface") if has_context else null
	var pb: PromptBuilder = context.get_context("prompt_builder") if has_context else null
	var character: CharacterIdentity = context.get_context("character") if has_context else null
	var world: WorldContext = context.get_context("world") if has_context else null
	var history: Array[Dictionary] = context.get_context("history") if has_context else []
	var player_input: String = context.get_context("player_input") if has_context else ""

	# Validate required components
	if not llama:
		return error("AIResponseExecutor: No LlamaInterface in context")

	if not pb:
		# Create default prompt builder if not provided
		pb = PromptBuilder.new()

	# Get node-specific overrides
	var temperature: float = node_data.data.get("temperature", 0.7)
	var max_tokens: int = node_data.data.get("max_tokens", 256)
	var system_override: String = node_data.data.get("system_prompt_override", "")

	# Build the prompt
	var memories: Array[String] = []
	if has_context and context.get_context("memories"):
		memories = context.get_context("memories")

	var prompt := pb.build_prompt(
		character,
		world,
		memories,
		history,
		player_input
	)

	# Apply system override if specified
	if not system_override.is_empty():
		prompt = system_override + "\n\n" + prompt

	# Generate response (this would be async in real usage)
	# The GraphRunner should handle the async nature
	var result := {
		RESULT_NEXT_NODE: "",
		RESULT_OUTPUT_SLOT: 0,
		RESULT_TEXT: "",
		"prompt": prompt,
		"temperature": temperature,
		"max_tokens": max_tokens,
		"requires_inference": true  # Signal that LLM call is needed
	}

	return result
