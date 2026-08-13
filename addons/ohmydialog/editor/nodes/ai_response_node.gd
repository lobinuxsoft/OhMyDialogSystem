@tool
class_name AIResponseNode
extends BaseDialogueNode
## Visual node for AI-generated dialogue responses.
##
## This node uses the LLM to generate dynamic responses based on
## the character identity, world context, and conversation history.

const CHATML_BASE_TOKENS: int = 100


func _configure_slots() -> void:
	clear_all_slots()
	# One input, one output
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)


func _create_content_ui() -> void:
	var ai_node := node_data as AIResponseNodeData
	var prompt_template: String = ai_node.prompt_template if ai_node else ""

	_add_hint_label("AI generates response")
	if not prompt_template.is_empty():
		_add_separator()
		_add_text_preview(prompt_template, 2)

	# Add context usage bar
	_add_separator()
	_add_context_bar()


## Adds a visual context usage bar to the node.
func _add_context_bar() -> void:
	var tokens_info := _calculate_tokens()
	var total_tokens: int = tokens_info.total
	var model_ctx: int = tokens_info.model_ctx
	var prefix: String = "" if tokens_info.is_exact else "~"

	# Container for the bar
	var bar_container := VBoxContainer.new()
	bar_container.add_theme_constant_override("separation", 2)

	# No model loaded: show the cost, but no bar - there is no budget to fill
	if model_ctx <= 0:
		var plain_label := Label.new()
		plain_label.text = "%s%d tokens" % [prefix, total_tokens]
		plain_label.add_theme_font_size_override("font_size", 10)
		plain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		plain_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
		bar_container.add_child(plain_label)
		_content_container.add_child(bar_container)
		return

	var usage_percent: float = (total_tokens * 100.0) / model_ctx

	# Token info label
	var info_label := Label.new()
	info_label.text = "%s%d / %d tokens" % [prefix, total_tokens, model_ctx]
	info_label.add_theme_font_size_override("font_size", 10)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Color based on usage
	var bar_color: Color
	if usage_percent > 70:
		bar_color = Color(1.0, 0.42, 0.42)  # Red
		info_label.add_theme_color_override("font_color", bar_color)
	elif usage_percent > 50:
		bar_color = Color(1.0, 0.85, 0.24)  # Yellow
		info_label.add_theme_color_override("font_color", bar_color)
	else:
		bar_color = Color(0.42, 0.8, 0.47)  # Green
		info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

	bar_container.add_child(info_label)

	# Progress bar
	var progress := ProgressBar.new()
	progress.custom_minimum_size = Vector2(0, 8)
	progress.max_value = 100
	progress.value = minf(usage_percent, 100)
	progress.show_percentage = false

	# Style the progress bar
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.15, 0.15)
	bg_style.set_corner_radius_all(2)
	progress.add_theme_stylebox_override("background", bg_style)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = bar_color
	fill_style.set_corner_radius_all(2)
	progress.add_theme_stylebox_override("fill", fill_style)

	bar_container.add_child(progress)

	# Warning icon if over limit
	if usage_percent > 70:
		var warning := Label.new()
		warning.text = "Context limit!"
		warning.add_theme_font_size_override("font_size", 9)
		warning.add_theme_color_override("font_color", bar_color)
		warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bar_container.add_child(warning)

	_content_container.add_child(bar_container)


## Counts the tokens this node costs. model_ctx is 0 when no model is loaded:
## there is no context window to measure against, and inventing one would
## render a usage bar that validates against nothing.
func _calculate_tokens() -> Dictionary:
	var ai_node := node_data as AIResponseNodeData
	var prompt: String = ai_node.to_prompt_text(dialogue_graph) if ai_node else ""

	var exact := TokenCounter.count(TokenCounter.path_for(dialogue_graph), prompt)
	var is_exact := exact >= 0
	var total := CHATML_BASE_TOKENS + (exact if is_exact else ceili(prompt.length() / 4.0))

	var model_ctx := 0
	var ai_service := AIService.get_singleton()
	if ai_service and ai_service.is_model_loaded():
		var config := ai_service.get_current_config()
		if config:
			model_ctx = config.n_ctx

	return {
		"total": total,
		"model_ctx": model_ctx,
		"is_exact": is_exact,
	}
