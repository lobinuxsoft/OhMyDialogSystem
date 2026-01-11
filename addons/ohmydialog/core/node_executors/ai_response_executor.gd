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
	# Duck typing - any object with generate() method works
	var llama: Object = context.get_context("llama_interface") if has_context else null
	var pb: PromptBuilder = context.get_context("prompt_builder") if has_context else null
	# Character and world come from DialogueGraph context (set when dialogue starts)
	var character: CharacterIdentity = context.get_context("character") if has_context else null
	var world: WorldContext = context.get_context("world") if has_context else null
	var history: Array[Dictionary] = context.get_context("history") if has_context else []
	var player_input: String = context.get_context("player_input") if has_context else ""

	# Clear player_input after consuming so next AI_RESPONSE doesn't inherit it
	if has_context and context.has_method("set_context"):
		context.set_context("player_input", "")

	# Validate required components (duck typing - check for generate method)
	if not llama or not llama.has_method("generate"):
		return error("AIResponseExecutor: No valid LlamaInterface in context")

	if not pb:
		# Create default prompt builder if not provided
		pb = PromptBuilder.new()

	# Get node-specific overrides from typed subclass
	var ai_node := node_data as AIResponseNodeData
	var temperature: float = 0.7  # Default, AIResponseNodeData doesn't have temperature yet
	var max_tokens: int = ai_node.max_tokens if ai_node else 64
	var prompt_template: String = ai_node.prompt_template if ai_node else ""

	# Build the prompt with instruction from prompt_template
	var memories: Array[String] = []
	if has_context and context.get_context("memories"):
		memories = context.get_context("memories")

	var prompt := pb.build_prompt(
		character,
		world,
		memories,
		history,
		player_input,
		4096,  # max_context_tokens
		prompt_template  # instruction - passed to user section of prompt
	)

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
