@tool
class_name PromptBuilder
extends RefCounted
## Builds complete prompts for LLM inference from dialogue resources.
##
## Assembles prompts by combining character identity, world context,
## conversation history, and player input into a well-formatted prompt
## that respects token limits.
##
## Supports multiple chat template formats and can use llama.cpp's native
## template application when a LlamaInterface is provided.


## Known chat template formats
enum TemplateFormat {
	CHATML,    ## <|im_start|>, <|im_end|> (Qwen, OpenHermes)
	LLAMA2,    ## [INST] <<SYS>> (Llama 2)
	LLAMA3,    ## [INST] without <<SYS>> (Llama 3)
	MISTRAL,   ## <s>[INST] (Mistral)
	VICUNA,    ## USER: ASSISTANT: (Vicuna)
	PHI,       ## <|user|> <|assistant|> (Phi)
	GEMMA,     ## <start_of_turn> (Gemma)
	CUSTOM     ## User-provided template
}


## Default prompt template using ChatML format (compatible with Qwen, Mistral, etc.)
const TEMPLATE_CHATML := """<|im_start|>system
{system_prompt}<|im_end|>
<|im_start|>user
{user_content}<|im_end|>
<|im_start|>assistant
{assistant_prefill}"""

const TEMPLATE_LLAMA2 := """<s>[INST] <<SYS>>
{system_prompt}
<</SYS>>

{user_content} [/INST]"""

const TEMPLATE_LLAMA3 := """<|begin_of_text|><|start_header_id|>system<|end_header_id|>

{system_prompt}<|eot_id|><|start_header_id|>user<|end_header_id|>

{user_content}<|eot_id|><|start_header_id|>assistant<|end_header_id|>

{assistant_prefill}"""

const TEMPLATE_MISTRAL := """<s>[INST] {system_prompt}

{user_content} [/INST]"""

const TEMPLATE_VICUNA := """A chat between a user and an assistant.

{system_prompt}

USER: {user_content}
ASSISTANT:"""

const TEMPLATE_PHI := """<|system|>
{system_prompt}<|end|>
<|user|>
{user_content}<|end|>
<|assistant|>
"""

const TEMPLATE_GEMMA := """<start_of_turn>user
{system_prompt}

{user_content}<end_of_turn>
<start_of_turn>model
{assistant_prefill}"""

## Legacy template for build_prompt() method (ChatML format with full context)
const DEFAULT_TEMPLATE := """<|im_start|>system
You are {character_name}. Stay in character. Give SHORT, DIRECT responses (1-2 sentences max).

RULES:
- Respond naturally to what the player said
- Do NOT ask multiple questions
- Do NOT list options or items unless specifically asked
- Do NOT invent details not mentioned in your character description
- Keep responses conversational and brief

{character_prompt}

World: {world_context}

Memories: {memories}<|im_end|>
<|im_start|>user
{history}
{player_input}{instruction}<|im_end|>
<|im_start|>assistant
{assistant_prefill}{character_name}:"""


## Approximate characters per token (rough estimate for most LLMs).
const CHARS_PER_TOKEN := 4.0

## Maximum tokens to reserve for the response.
var response_token_reserve: int = 256

## Custom template (if set, overrides format-based templates).
var custom_template: String = ""

## Current template format to use
var template_format: TemplateFormat = TemplateFormat.CHATML

## Reference to LlamaInterface for native template application (optional)
var llama_interface: Object = null

## Text injected where the assistant turn opens, before it writes anything.
## Reasoning models open a <think> block on their first token and spend the
## whole budget in it, so handing them a closed one puts them straight into
## the reply. See AIPreset.assistant_prefill.
var assistant_prefill: String = ""


## Builds a complete prompt from the provided components.
## Returns the assembled prompt string.
## [param instruction]: Optional additional instruction for the AI (e.g., "respond sadly").
func build_prompt(
	character: CharacterIdentity,
	world: WorldContext,
	memories: Array[String],
	history: Array[Dictionary],
	player_input: String,
	max_context_tokens: int = 4096,
	instruction: String = ""
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

	# Format instruction if provided
	var instruction_text := ""
	if not instruction.is_empty():
		instruction_text = "\n\n[Instruction: %s]" % instruction

	# Assemble the prompt
	var prompt := template.format({
		"character_name": character_name,
		"character_prompt": character_prompt,
		"world_context": world_context,
		"memories": memories_text,
		"history": history_text,
		"player_input": player_input,
		"instruction": instruction_text,
		"assistant_prefill": assistant_prefill
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
{prefill}{name}:""".format({
		"name": character_name,
		"prompt": character_prompt,
		"input": player_input,
		"prefill": assistant_prefill
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
## Use placeholders: {system_prompt}, {user_content}
func set_template(template: String) -> void:
	custom_template = template
	template_format = TemplateFormat.CUSTOM


## Sets the template format to use
func set_format(format: TemplateFormat) -> void:
	template_format = format
	if format != TemplateFormat.CUSTOM:
		custom_template = ""


## Sets the template format from a string identifier (from GGUF metadata)
func set_format_from_string(format_name: String) -> void:
	match format_name.to_lower():
		"chatml":
			template_format = TemplateFormat.CHATML
		"llama2":
			template_format = TemplateFormat.LLAMA2
		"llama3":
			template_format = TemplateFormat.LLAMA3
		"mistral":
			template_format = TemplateFormat.MISTRAL
		"vicuna":
			template_format = TemplateFormat.VICUNA
		"phi":
			template_format = TemplateFormat.PHI
		"gemma":
			template_format = TemplateFormat.GEMMA
		_:
			# Unknown format, default to ChatML as it's widely compatible
			template_format = TemplateFormat.CHATML


## Sets the LlamaInterface for native template application
func set_llama_interface(llama: Object) -> void:
	llama_interface = llama


## Resets to the default template.
func reset_template() -> void:
	custom_template = ""
	template_format = TemplateFormat.CHATML


## Returns the current template being used based on format.
func get_template() -> String:
	if not custom_template.is_empty():
		return custom_template

	match template_format:
		TemplateFormat.CHATML:
			return TEMPLATE_CHATML
		TemplateFormat.LLAMA2:
			return TEMPLATE_LLAMA2
		TemplateFormat.LLAMA3:
			return TEMPLATE_LLAMA3
		TemplateFormat.MISTRAL:
			return TEMPLATE_MISTRAL
		TemplateFormat.VICUNA:
			return TEMPLATE_VICUNA
		TemplateFormat.PHI:
			return TEMPLATE_PHI
		TemplateFormat.GEMMA:
			return TEMPLATE_GEMMA
		_:
			return TEMPLATE_CHATML


## Builds a prompt using llama.cpp's native template application.
## Falls back to format-based templates if LlamaInterface is not available.
## [param system_prompt]: The system prompt content
## [param user_input]: The user's message
## [param history]: Optional conversation history as array of {role, content} dicts
## Returns the formatted prompt string.
func build_prompt_native(
	system_prompt: String,
	user_input: String,
	history: Array[Dictionary] = []
) -> String:
	# Try native llama.cpp template application first
	if llama_interface != null and llama_interface.has_method("is_model_loaded"):
		if llama_interface.is_model_loaded() and llama_interface.has_method("apply_chat_template"):
			var messages: Array[Dictionary] = []

			# Add system message
			if not system_prompt.is_empty():
				messages.append({"role": "system", "content": system_prompt})

			# Add history
			for entry in history:
				messages.append(entry)

			# Add user message
			messages.append({"role": "user", "content": user_input})

			var result = llama_interface.apply_chat_template(messages, true)
			if not result.is_empty():
				return result + assistant_prefill

	# Fallback to format-based template
	return _apply_format_template(system_prompt, user_input, history)


## Applies the current format template to build a prompt
func _apply_format_template(
	system_prompt: String,
	user_input: String,
	history: Array[Dictionary] = []
) -> String:
	var template := get_template()

	# Build user content including history
	var user_content := ""
	if not history.is_empty():
		for entry in history:
			var role: String = entry.get("role", "")
			var content: String = entry.get("content", "")
			if role == "user":
				user_content += "User: %s\n" % content
			elif role == "assistant":
				user_content += "Assistant: %s\n" % content
		user_content += "\n"
	user_content += user_input

	return template.format({
		"system_prompt": system_prompt,
		"user_content": user_content,
		"assistant_prefill": assistant_prefill
	})


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
