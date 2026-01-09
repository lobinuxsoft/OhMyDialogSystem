@tool
class_name PromptBuilder
extends RefCounted
## Builds complete prompts for LLM inference from dialogue resources.
##
## Assembles prompts by combining character identity, world context,
## conversation history, and player input into a well-formatted prompt
## that respects token limits.


## Default prompt template using ChatML format (compatible with Qwen, Mistral, etc.)
const DEFAULT_TEMPLATE := """<|im_start|>system
You are roleplaying as {character_name}. Stay in character at all times. Keep responses brief (1-3 sentences).
{character_prompt}

World: {world_context}

Memories: {memories}<|im_end|>
<|im_start|>user
{history}
{player_input}<|im_end|>
<|im_start|>assistant
{character_name}:"""


## Approximate characters per token (rough estimate for most LLMs).
const CHARS_PER_TOKEN := 4.0

## Maximum tokens to reserve for the response.
var response_token_reserve: int = 256

## Custom template (if set, overrides DEFAULT_TEMPLATE).
var custom_template: String = ""


## Builds a complete prompt from the provided components.
## Returns the assembled prompt string.
func build_prompt(
	character: CharacterIdentity,
	world: WorldContext,
	memories: Array[String],
	history: Array[Dictionary],
	player_input: String,
	max_context_tokens: int = 4096
) -> String:
	var template := custom_template if not custom_template.is_empty() else DEFAULT_TEMPLATE

	# Build each section
	var character_name := character.character_name if character else "Assistant"
	var character_prompt := character.to_system_prompt() if character else ""
	var world_context := world.to_context_prompt() if world else ""
	var memories_text := _format_memories(memories)
	var history_text := _format_history(history, character_name)

	# Calculate available tokens for history
	var fixed_tokens := _estimate_tokens(template) + _estimate_tokens(character_prompt) + \
					   _estimate_tokens(world_context) + _estimate_tokens(memories_text) + \
					   _estimate_tokens(player_input) + response_token_reserve

	var available_history_tokens := max_context_tokens - fixed_tokens

	# Truncate history if needed
	if available_history_tokens > 0:
		history_text = _truncate_to_tokens(history_text, available_history_tokens)
	else:
		history_text = "(History truncated due to context limit)"

	# Assemble the prompt
	var prompt := template.format({
		"character_name": character_name,
		"character_prompt": character_prompt,
		"world_context": world_context,
		"memories": memories_text,
		"history": history_text,
		"player_input": player_input
	})

	return prompt


## Builds a simple prompt without full context (for quick responses).
func build_simple_prompt(
	character: CharacterIdentity,
	player_input: String
) -> String:
	var character_name := character.character_name if character else "Assistant"
	var character_prompt := character.to_system_prompt() if character else ""

	return """<|im_start|>system
You are {name}. Keep responses brief (1-3 sentences). {prompt}<|im_end|>
<|im_start|>user
{input}<|im_end|>
<|im_start|>assistant
{name}:""".format({
		"name": character_name,
		"prompt": character_prompt,
		"input": player_input
	})


## Formats an array of memory strings into a single text block.
func _format_memories(memories: Array[String]) -> String:
	if memories.is_empty():
		return "(No relevant memories)"

	var lines: Array[String] = []
	for memory in memories:
		lines.append("- %s" % memory)
	return "\n".join(lines)


## Formats conversation history into a readable format.
## History is an array of {role: String, content: String} dictionaries.
func _format_history(history: Array[Dictionary], character_name: String) -> String:
	if history.is_empty():
		return "(New conversation)"

	var lines: Array[String] = []
	for entry in history:
		var role: String = entry.get("role", "unknown")
		var content: String = entry.get("content", "")

		match role:
			"player", "user":
				lines.append("Player: %s" % content)
			"assistant", "npc", "character":
				lines.append("%s: %s" % [character_name, content])
			"system":
				lines.append("[System: %s]" % content)
			_:
				lines.append("%s: %s" % [role.capitalize(), content])

	return "\n".join(lines)


## Estimates the number of tokens in a text string.
## This is a rough approximation - actual tokenization varies by model.
func _estimate_tokens(text: String) -> int:
	if text.is_empty():
		return 0
	return ceili(text.length() / CHARS_PER_TOKEN)


## Counts tokens in a text (alias for _estimate_tokens for public API).
func count_tokens(text: String) -> int:
	return _estimate_tokens(text)


## Truncates text to fit within a token limit.
## Preserves the most recent content (end of text).
func _truncate_to_tokens(text: String, max_tokens: int) -> String:
	var estimated := _estimate_tokens(text)
	if estimated <= max_tokens:
		return text

	# Calculate approximate character limit
	var max_chars := int(max_tokens * CHARS_PER_TOKEN)

	# Keep the end of the text (most recent history)
	var truncated := text.right(max_chars)

	# Try to start at a newline for cleaner truncation
	var newline_pos := truncated.find("\n")
	if newline_pos > 0 and newline_pos < 100:
		truncated = truncated.substr(newline_pos + 1)

	return "(...truncated...)\n" + truncated


## Sets a custom template for prompt building.
## Use placeholders: {character_name}, {character_prompt}, {world_context},
## {memories}, {history}, {player_input}
func set_template(template: String) -> void:
	custom_template = template


## Resets to the default template.
func reset_template() -> void:
	custom_template = ""


## Returns the current template being used.
func get_template() -> String:
	return custom_template if not custom_template.is_empty() else DEFAULT_TEMPLATE


## Calculates the total token usage for a prompt configuration.
## Useful for debugging context window usage.
func calculate_token_usage(
	character: CharacterIdentity,
	world: WorldContext,
	memories: Array[String],
	history: Array[Dictionary],
	player_input: String
) -> Dictionary:
	var character_prompt := character.to_system_prompt() if character else ""
	var world_context := world.to_context_prompt() if world else ""
	var memories_text := _format_memories(memories)
	var history_text := _format_history(history, character.character_name if character else "")

	return {
		"template": _estimate_tokens(get_template()),
		"character": _estimate_tokens(character_prompt),
		"world": _estimate_tokens(world_context),
		"memories": _estimate_tokens(memories_text),
		"history": _estimate_tokens(history_text),
		"input": _estimate_tokens(player_input),
		"total": _estimate_tokens(character_prompt) + _estimate_tokens(world_context) + \
				 _estimate_tokens(memories_text) + _estimate_tokens(history_text) + \
				 _estimate_tokens(player_input) + _estimate_tokens(get_template())
	}
