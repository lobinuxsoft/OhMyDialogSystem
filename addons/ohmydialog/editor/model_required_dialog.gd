@tool
class_name ModelRequiredDialog
extends ConfirmationDialog
## Dialog shown when an AI node requires a model but none is loaded.
##
## Provides two modes:
## - With downloaded models: Shows dropdown to select and activate
## - Without models: Shows message and button to open Model Manager

## Emitted when user requests to open the Model Manager
signal open_model_manager_requested()

## Emitted when a model is successfully activated
signal model_activated(config: ModelConfig)

## UI References
var _content_container: VBoxContainer
var _message_label: Label
var _model_dropdown: OptionButton
var _no_models_container: VBoxContainer

var _ai_service: AIService
var _downloaded_models: Array[ModelConfig] = []


func _init() -> void:
	title = "Modelo de IA Requerido"
	unresizable = false


func _ready() -> void:
	_setup_ui()
	_connect_signals()
	call_deferred("_connect_ai_service")


func _setup_ui() -> void:
	_content_container = VBoxContainer.new()
	_content_container.add_theme_constant_override("separation", 12)
	_content_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	add_child(_content_container)

	# Message label (shown in both modes)
	_message_label = Label.new()
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content_container.add_child(_message_label)

	# Model selection dropdown (only for "has models" mode)
	var dropdown_container = HBoxContainer.new()
	dropdown_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_content_container.add_child(dropdown_container)

	var dropdown_label = Label.new()
	dropdown_label.text = "Seleccionar modelo:"
	dropdown_container.add_child(dropdown_label)

	_model_dropdown = OptionButton.new()
	_model_dropdown.custom_minimum_size = Vector2(200, 0)
	dropdown_container.add_child(_model_dropdown)

	# No models container
	_no_models_container = VBoxContainer.new()
	_no_models_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_content_container.add_child(_no_models_container)

	var no_models_label = Label.new()
	no_models_label.text = "Necesitas descargar un modelo de IA\npara usar esta funcionalidad."
	no_models_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_no_models_container.add_child(no_models_label)

	var open_manager_btn = Button.new()
	open_manager_btn.text = "Ir al Gestor de Modelos"
	open_manager_btn.pressed.connect(_on_open_manager_pressed)
	_no_models_container.add_child(open_manager_btn)


func _connect_signals() -> void:
	confirmed.connect(_on_confirmed)
	canceled.connect(_on_canceled)


func _connect_ai_service() -> void:
	_ai_service = AIService.get_singleton()
	if not _ai_service:
		push_warning("ModelRequiredDialog: AIService not available")


## Shows the dialog, refreshing the model list
func show_dialog() -> void:
	_refresh_models()
	_update_ui()

	# Calculate size as 25% of screen
	var screen_size := DisplayServer.screen_get_size()
	var dialog_size := Vector2i(int(screen_size.x * 0.25), int(screen_size.y * 0.25))

	# Clip content to prevent overflow
	_content_container.clip_contents = true

	# Force dialog size
	reset_size()
	min_size = dialog_size
	max_size = dialog_size
	size = dialog_size
	popup_centered()


func _refresh_models() -> void:
	_downloaded_models.clear()

	if not _ai_service:
		return

	var manager = _ai_service.get_model_manager()
	if not manager:
		return

	for config in manager.get_available_models():
		if config.is_downloaded():
			_downloaded_models.append(config)


func _update_ui() -> void:
	var has_models = _downloaded_models.size() > 0

	# Update visibility
	_model_dropdown.get_parent().visible = has_models
	_no_models_container.visible = not has_models

	if has_models:
		_setup_models_mode()
	else:
		_setup_no_models_mode()


func _setup_models_mode() -> void:
	title = "Modelo de IA Requerido"
	_message_label.text = "Este nodo requiere un modelo de IA activo para funcionar."

	# Populate dropdown
	_model_dropdown.clear()
	for i in range(_downloaded_models.size()):
		var config = _downloaded_models[i]
		_model_dropdown.add_item(config.display_name, i)

	ok_button_text = "Activar Modelo"
	get_ok_button().disabled = false


func _setup_no_models_mode() -> void:
	title = "No hay modelos descargados"
	_message_label.text = ""

	ok_button_text = "Cerrar"
	get_ok_button().disabled = true


func _on_confirmed() -> void:
	if _downloaded_models.size() == 0:
		return

	var selected_idx = _model_dropdown.selected
	if selected_idx < 0 or selected_idx >= _downloaded_models.size():
		return

	var config = _downloaded_models[selected_idx]

	if _ai_service:
		var err = _ai_service.load_model(config)
		if err == OK:
			model_activated.emit(config)
		else:
			push_error("ModelRequiredDialog: Failed to load model: %s" % error_string(err))


func _on_canceled() -> void:
	pass


func _on_open_manager_pressed() -> void:
	open_model_manager_requested.emit()
	hide()
