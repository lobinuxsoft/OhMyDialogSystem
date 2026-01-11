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
	var usage_percent: float = (total_tokens * 100.0) / model_ctx

	# Container for the bar
	var bar_container := VBoxContainer.new()
	bar_container.add_theme_constant_override("separation", 2)

	# Token info label
	var info_label := Label.new()
	info_label.text = "~%d / %d tokens" % [total_tokens, model_ctx]
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


## Calculates token estimates for this node.
func _calculate_tokens() -> Dictionary:
	var template_tokens := 0
	var char_tokens := 0
	var world_tokens := 0

	# Prompt template tokens
	var ai_node := node_data as AIResponseNodeData
	var prompt_template: String = ai_node.prompt_template if ai_node else ""
	template_tokens = ceili(prompt_template.length() / 4.0)

	# Character and world tokens from graph
	if dialogue_graph:
		if dialogue_graph.default_character:
			char_tokens = dialogue_graph.default_character.estimate_tokens()
		if dialogue_graph.world_context:
			world_tokens = dialogue_graph.world_context.estimate_tokens()

	var total := CHATML_BASE_TOKENS + char_tokens + world_tokens + template_tokens

	# Get model context
	var model_ctx := 4096
	var ai_service := AIService.get_singleton()
	if ai_service:
		var config := ai_service.get_current_config()
		if config:
			model_ctx = config.n_ctx

	return {
		"template": template_tokens,
		"character": char_tokens,
		"world": world_tokens,
		"total": total,
		"model_ctx": model_ctx
	}
