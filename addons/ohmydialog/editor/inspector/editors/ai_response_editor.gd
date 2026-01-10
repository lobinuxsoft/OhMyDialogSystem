@tool
class_name AIResponseEditor
extends BaseNodeEditor
## Inspector editor for AI_RESPONSE nodes.
##
## Shows character, prompt template, emotion hint, max tokens, and context usage.


const EMOTIONS: Array[String] = ["", "neutral", "happy", "sad", "angry", "surprised", "confused", "scared"]
const CHATML_BASE_TOKENS: int = 100  # Approximate tokens for ChatML template structure

var _context_label: RichTextLabel
var _prompt_template_edit: TextEdit


func _setup_ui() -> void:
	_add_header("AI Response")
	_add_separator()
	_prompt_template_edit = _add_text_edit("Prompt Template", "prompt_template", 80)
	_prompt_template_edit.text_changed.connect(_update_context_estimate)
	_add_option_button("Emotion Hint", "emotion_hint", EMOTIONS)
	_add_spin_box("Max Tokens", "max_tokens", 32, 2048, 32)

	_add_separator()
	_add_context_estimate_ui()
	_update_context_estimate()


## Adds the context usage estimation UI.
func _add_context_estimate_ui() -> void:
	_context_label = RichTextLabel.new()
	_context_label.bbcode_enabled = true
	_context_label.fit_content = true
	_context_label.scroll_active = false
	add_child(_context_label)


## Updates the context usage estimation display.
func _update_context_estimate() -> void:
	if not _context_label:
		return

	var template_tokens := ceili(_prompt_template_edit.text.length() / 4.0) if _prompt_template_edit else 0

	# Get character and world from dialogue graph
	var char_tokens := 0
	var world_tokens := 0

	if _dialogue_graph:
		if _dialogue_graph.default_character:
			char_tokens = _dialogue_graph.default_character.estimate_tokens()
		if _dialogue_graph.world_context:
			world_tokens = _dialogue_graph.world_context.estimate_tokens()

	var total_base := CHATML_BASE_TOKENS + char_tokens + world_tokens + template_tokens

	# Get model context size if available
	var model_ctx := 4096  # Default
	var model_name := "unknown"
	var ai_service := AIService.get_singleton()
	if ai_service:
		var config := ai_service.get_current_config()
		if config:
			model_ctx = config.n_ctx
			model_name = config.display_name

	# Build display text
	var text := "[b]Context Usage Estimate[/b]\n"
	text += "Template: ~%d tokens\n" % CHATML_BASE_TOKENS
	text += "Character: ~%d tokens\n" % char_tokens
	text += "World: ~%d tokens\n" % world_tokens
	text += "Prompt: ~%d tokens\n" % template_tokens
	text += "━━━━━━━━━━━━━━━━━\n"
	text += "[b]Base Total: ~%d tokens[/b]\n" % total_base
	text += "(+ history + player input)\n\n"

	# Warning check
	var usage_percent := (total_base * 100.0) / model_ctx
	if total_base > model_ctx * 0.7:
		text += "[color=#ff6b6b]⚠ WARNING: Base context uses %.0f%% of model limit (%d tokens)!\n" % [usage_percent, model_ctx]
		text += "Risk of crash or truncated responses.\n"
		text += "Reduce character/world detail or use larger model.[/color]"
	elif total_base > model_ctx * 0.5:
		text += "[color=#ffd93d]⚠ CAUTION: Base context uses %.0f%% of model limit (%d tokens).\n" % [usage_percent, model_ctx]
		text += "Limited space for conversation history.[/color]"
	else:
		text += "[color=#6bcb77]Model: %s (%d tokens)\n" % [model_name, model_ctx]
		text += "Status: OK (%.0f%% used)[/color]" % usage_percent

	_context_label.text = text
