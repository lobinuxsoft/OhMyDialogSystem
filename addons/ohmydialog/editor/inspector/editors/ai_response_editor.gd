@tool
class_name AIResponseEditor
extends BaseNodeEditor
## Wiki-style info panel for AI Response nodes.
##
## Shows token estimation, model info, and validation status.

## Emitted when the user asks to open the model manager.
signal model_requested()

## Chat template overhead. Stays an estimate even when the prompt itself is
## counted exactly: the template is applied by the model at generation time.
const CHATML_BASE_TOKENS: int = 100

var _info_label: RichTextLabel
var _load_button: Button


func _init(node_data: DialogueNodeData, graph: DialogueGraph = null) -> void:
	super._init(node_data, graph)
	ACCENT_COLOR = Color("#3b82f6")
	ICON = "🧠"
	TITLE = "AI RESPONSE"


func _setup_info() -> void:
	_info_label = _add_info_label()
	_load_button = _add_load_button()
	_refresh_info()


## Also listens to AIService so the panel never reports a model that is gone.
func _connect_signals() -> void:
	super._connect_signals()

	var ai_service := AIService.get_singleton()
	if not ai_service:
		return

	ai_service.model_loaded.connect(_on_model_loaded)
	ai_service.model_unloaded.connect(_on_model_unloaded)


func _disconnect_signals() -> void:
	super._disconnect_signals()

	var ai_service := AIService.get_singleton()
	if not ai_service:
		return

	if ai_service.model_loaded.is_connected(_on_model_loaded):
		ai_service.model_loaded.disconnect(_on_model_loaded)
	if ai_service.model_unloaded.is_connected(_on_model_unloaded):
		ai_service.model_unloaded.disconnect(_on_model_unloaded)


func _on_model_loaded(_config: ModelConfig) -> void:
	_refresh_info()


func _on_model_unloaded() -> void:
	_refresh_info()


func _refresh_info() -> void:
	if not _info_label or not _node_data:
		return

	var ai_node := _node_data as AIResponseNodeData
	if not ai_node:
		return

	var config := _current_config()
	var prompt := ai_node.to_prompt_text(_dialogue_graph)
	var exact := TokenCounter.count(TokenCounter.path_for(_dialogue_graph), prompt)
	var is_exact := exact >= 0
	var base_tokens := CHATML_BASE_TOKENS + (exact if is_exact else ceili(prompt.length() / 4.0))

	if config:
		_info_label.text = _text_with_model(ai_node, base_tokens, config, is_exact)
	else:
		_info_label.text = _text_without_model(ai_node, base_tokens, is_exact)

	if _load_button:
		_load_button.visible = config == null


## Returns the config of the loaded model, or null when none is loaded.
func _current_config() -> ModelConfig:
	var ai_service := AIService.get_singleton()
	if not ai_service or not ai_service.is_model_loaded():
		return null

	return ai_service.get_current_config()


func _text_with_model(ai_node: AIResponseNodeData, base_tokens: int, config: ModelConfig, is_exact: bool) -> String:
	var usage := (base_tokens * 100.0) / config.n_ctx
	var text := "[b]%s%d tokens base[/b] " % ["" if is_exact else "~", base_tokens]

	if base_tokens > config.n_ctx * 0.7:
		text += "[color=#ef4444](%.0f%% - RIESGO)[/color]" % usage
	elif base_tokens > config.n_ctx * 0.5:
		text += "[color=#f97316](%.0f%% - cuidado)[/color]" % usage
	else:
		text += "[color=#10b981](%.0f%% OK)[/color]" % usage

	text += "\n[color=#484f58]Modelo: %s (%d ctx)[/color]" % [config.display_name, config.n_ctx]

	return text + _counting_text(is_exact) + _validation_text(ai_node)


## Without a loaded model there is no context window to measure against,
## so no percentage is shown: a made-up budget reads as a passing check.
func _text_without_model(ai_node: AIResponseNodeData, base_tokens: int, is_exact: bool) -> String:
	var text := "[b]%s%d tokens base[/b]" % ["" if is_exact else "~", base_tokens]
	text += "\n[color=#f97316]⚠ Ningún modelo cargado para generar - sin ventana de contexto que validar[/color]"

	return text + _counting_text(is_exact) + _validation_text(ai_node)


## States which of the two counts is on screen, and with which vocabulary, so
## a number is never mistaken for a precision it does not have. Counting only
## needs the vocabulary; generating needs the whole model.
func _counting_text(is_exact: bool) -> String:
	if not is_exact:
		return "\n[color=#484f58]Conteo aproximado (~4 caracteres por token)[/color]"

	var vocab := TokenCounter.path_for(_dialogue_graph).get_file()

	return "\n[color=#484f58]Contado con el vocabulario de %s (+%d del chat template)[/color]" % [vocab, CHATML_BASE_TOKENS]


## Prompt checks that do not depend on the loaded model.
func _validation_text(ai_node: AIResponseNodeData) -> String:
	var text := ""

	if ai_node.prompt_template.is_empty():
		text += "\n[color=#f97316]⚠ Sin prompt - usará contexto del grafo[/color]"
	else:
		var var_count := ai_node.prompt_template.count("{")
		if var_count > 0:
			text += "\n[color=#10b981]✓ %d variable(s) en prompt[/color]" % var_count

	text += "\n[color=#484f58]Límite respuesta: %d tokens[/color]" % ai_node.max_tokens

	return text


## Shown only while no model is loaded.
func _add_load_button() -> Button:
	var button := Button.new()
	button.text = "Cargar modelo"
	button.tooltip_text = "Abre el gestor de modelos para cargar uno"
	button.pressed.connect(_on_load_pressed)
	_content.add_child(button)

	return button


func _on_load_pressed() -> void:
	model_requested.emit()
