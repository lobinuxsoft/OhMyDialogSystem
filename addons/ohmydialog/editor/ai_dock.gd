@tool
class_name AIDock
extends Control
## Compact dock panel for AI status and controls in the editor.
##
## Shows current model status and provides quick access to load/unload
## and configuration options.

## Emitted when user requests to open config dialog
signal config_requested()

## Emitted when user requests to load a model (no model loaded)
signal load_requested()

## UI References
@onready var _status_icon: TextureRect = %StatusIcon
@onready var _status_label: Label = %StatusLabel
@onready var _model_label: Label = %ModelLabel
@onready var _action_button: Button = %ActionButton
@onready var _config_button: Button = %ConfigButton

var _ai_service: AIService


func _ready() -> void:
	_action_button.pressed.connect(_on_action_pressed)
	_config_button.pressed.connect(_on_config_pressed)

	# Set config button icon
	_config_button.icon = get_theme_icon("Tools", "EditorIcons")

	# Set status icon with plugin icon (using load to avoid preload issues)
	var plugin_icon = load("res://addons/ohmydialog/icons/plugin_icon.svg")
	if plugin_icon:
		_status_icon.texture = plugin_icon
	else:
		# Fallback to editor icon if SVG not imported
		_status_icon.texture = get_theme_icon("Node", "EditorIcons")

	# Defer connection to AIService to ensure it's initialized
	call_deferred("_connect_ai_service")


func _connect_ai_service() -> void:
	_ai_service = AIService.get_singleton()

	if _ai_service:
		_ai_service.model_loaded.connect(_on_model_loaded)
		_ai_service.model_unloaded.connect(_on_model_unloaded)
		_update_ui()
	else:
		push_warning("AIDock: AIService not available")
		_set_disconnected_state()


func _update_ui() -> void:
	if not _ai_service:
		_set_disconnected_state()
		return

	if _ai_service.is_model_loaded():
		_set_loaded_state()
	else:
		_set_unloaded_state()


func _set_loaded_state() -> void:
	_status_label.text = "Model Loaded"
	_status_label.add_theme_color_override("font_color", Color.GREEN)

	var config = _ai_service.get_current_config()
	if config:
		_model_label.text = config.display_name
	else:
		_model_label.text = "Unknown Model"
	_model_label.visible = true

	_action_button.text = "Unload"
	_action_button.icon = get_theme_icon("Stop", "EditorIcons")

	_status_icon.modulate = Color.GREEN


func _set_unloaded_state() -> void:
	_status_label.text = "No Model"
	_status_label.add_theme_color_override("font_color", Color.GRAY)

	_model_label.text = ""
	_model_label.visible = false

	_action_button.text = "Load"
	_action_button.icon = get_theme_icon("Play", "EditorIcons")

	_status_icon.modulate = Color.GRAY


func _set_disconnected_state() -> void:
	_status_label.text = "Disconnected"
	_status_label.add_theme_color_override("font_color", Color.RED)

	_model_label.text = ""
	_model_label.visible = false

	_action_button.text = "Retry"
	_action_button.icon = get_theme_icon("Reload", "EditorIcons")

	_status_icon.modulate = Color.RED


func _on_action_pressed() -> void:
	if not _ai_service:
		_connect_ai_service()
		return

	if _ai_service.is_model_loaded():
		_ai_service.unload_model()
	else:
		load_requested.emit()


func _on_config_pressed() -> void:
	config_requested.emit()


func _on_model_loaded(_config: ModelConfig) -> void:
	_update_ui()


func _on_model_unloaded() -> void:
	_update_ui()
