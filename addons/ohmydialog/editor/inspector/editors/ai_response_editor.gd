@tool
class_name AIResponseEditor
extends BaseNodeEditor
## Wiki-style info panel for AI Response nodes.
##
## Shows token estimation, model info, and validation status.


const CHATML_BASE_TOKENS: int = 100

var _info_label: RichTextLabel


func _init(node_data: DialogueNodeData, graph: DialogueGraph = null) -> void:
	super._init(node_data, graph)
	ACCENT_COLOR = Color("#3b82f6")
	ICON = "🧠"
	TITLE = "AI RESPONSE"


func _setup_info() -> void:
	_info_label = _add_info_label()
	_refresh_info()


func _refresh_info() -> void:
	if not _info_label or not _node_data:
		return

	var ai_node := _node_data as AIResponseNodeData
	if not ai_node:
		return

	# Calculate tokens
	var template_tokens := ceili(ai_node.prompt_template.length() / 4.0)
	var char_tokens := 0
	var world_tokens := 0

	if _dialogue_graph:
		if _dialogue_graph.default_character:
			char_tokens = _dialogue_graph.default_character.estimate_tokens()
		if _dialogue_graph.world_context:
			world_tokens = _dialogue_graph.world_context.estimate_tokens()

	var total_base := CHATML_BASE_TOKENS + char_tokens + world_tokens + template_tokens

	# Get model info
	var model_ctx := 4096
	var model_name := "unknown"
	var ai_service := AIService.get_singleton()
	if ai_service:
		var config := ai_service.get_current_config()
		if config:
			model_ctx = config.n_ctx
			model_name = config.display_name

	# Build display
	var text := ""
	var usage_percent := (total_base * 100.0) / model_ctx

	# Token breakdown
	text += "[b]~%d tokens base[/b] " % total_base
	if total_base > model_ctx * 0.7:
		text += "[color=#ef4444](%.0f%% - RIESGO)[/color]" % usage_percent
	elif total_base > model_ctx * 0.5:
		text += "[color=#f97316](%.0f%% - cuidado)[/color]" % usage_percent
	else:
		text += "[color=#10b981](%.0f%% OK)[/color]" % usage_percent

	text += "\n[color=#484f58]Modelo: %s (%d ctx)[/color]" % [model_name, model_ctx]

	# Validation
	if ai_node.prompt_template.is_empty():
		text += "\n[color=#f97316]⚠ Sin prompt - usará contexto del grafo[/color]"
	else:
		var var_count := ai_node.prompt_template.count("{")
		if var_count > 0:
			text += "\n[color=#10b981]✓ %d variable(s) en prompt[/color]" % var_count

	# Response limit
	text += "\n[color=#484f58]Límite respuesta: %d tokens[/color]" % ai_node.max_tokens

	_info_label.text = text
