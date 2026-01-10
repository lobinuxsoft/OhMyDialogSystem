@tool
extends EditorPlugin
## OhMyDialogSystem - AI-powered dialogue system for Godot
##
## Main plugin entry point. Handles initialization and cleanup of
## editor components, custom types, and windows.

const AUTOLOAD_NAME := "AIServiceAutoload"
const AUTOLOAD_PATH := "res://addons/ohmydialog/autoload/ai_service_autoload.gd"

## Reference to the toolbar container (HBoxContainer with indicator + menu).
var _toolbar_container: HBoxContainer

## Reference to the toolbar menu button.
var _toolbar_menu: MenuButton

## Reference to the AI status indicator.
var _status_indicator: Label

## Reference to the dialogue graph editor window.
var _dialogue_graph_window: DialogueGraphWindow

## Reference to the DialogueNodeData inspector plugin.
var _node_inspector_plugin: DialogueNodeInspectorPlugin

## Reference to the DialogueGraph inspector plugin.
var _dialogue_graph_inspector_plugin: DialogueGraphInspectorPlugin

## Reference to the CharacterIdentity inspector plugin.
var _character_inspector_plugin: CharacterIdentityInspectorPlugin

## Reference to the WorldContext inspector plugin.
var _world_inspector_plugin: WorldContextInspectorPlugin

## Reference to the ModelConfig inspector plugin.
var _model_config_inspector_plugin: ModelConfigInspectorPlugin

## Reference to the AIPreset inspector plugin.
var _ai_preset_inspector_plugin: AIPresetInspectorPlugin

## Reference to the AI service singleton (editor context).
var _ai_service: AIService

## Reference to the model manager window.
var _model_manager_window: ModelManagerWindow


func _enter_tree() -> void:
	# Register AutoLoad for runtime (automatic, user doesn't need to configure)
	_register_autoload()

	# Initialize AI service singleton for editor context
	_ai_service = AIService.new()
	_ai_service.name = "AIService"
	add_child(_ai_service)

	# Register inspector plugins
	_node_inspector_plugin = DialogueNodeInspectorPlugin.new()
	add_inspector_plugin(_node_inspector_plugin)

	_character_inspector_plugin = CharacterIdentityInspectorPlugin.new()
	add_inspector_plugin(_character_inspector_plugin)

	_world_inspector_plugin = WorldContextInspectorPlugin.new()
	add_inspector_plugin(_world_inspector_plugin)

	_model_config_inspector_plugin = ModelConfigInspectorPlugin.new()
	add_inspector_plugin(_model_config_inspector_plugin)

	_ai_preset_inspector_plugin = AIPresetInspectorPlugin.new()
	add_inspector_plugin(_ai_preset_inspector_plugin)

	# Initialize dialogue graph editor window
	_dialogue_graph_window = DialogueGraphWindow.new()
	EditorInterface.get_base_control().add_child(_dialogue_graph_window)
	_dialogue_graph_window.ready.connect(_on_dialogue_graph_window_ready)

	# Register inspector plugin for DialogueGraph
	_dialogue_graph_inspector_plugin = DialogueGraphInspectorPlugin.new()
	add_inspector_plugin(_dialogue_graph_inspector_plugin)

	# Initialize model manager window
	var manager_scene := preload("res://addons/ohmydialog/editor/model_manager_window.tscn")
	_model_manager_window = manager_scene.instantiate()
	EditorInterface.get_base_control().add_child(_model_manager_window)

	# Create toolbar container with status indicator and menu
	_toolbar_container = HBoxContainer.new()
	_toolbar_container.add_theme_constant_override("separation", 4)

	# Status indicator (circle that shows AI model status)
	_status_indicator = Label.new()
	_status_indicator.text = "●"
	_status_indicator.add_theme_font_size_override("font_size", 12)
	_status_indicator.tooltip_text = "No AI model loaded"
	_update_status_indicator(false, null)
	_toolbar_container.add_child(_status_indicator)

	# Menu button
	_toolbar_menu = MenuButton.new()
	_toolbar_menu.text = "OhMyDialog"
	_toolbar_menu.flat = true
	_toolbar_menu.focus_mode = Control.FOCUS_NONE

	var popup := _toolbar_menu.get_popup()
	popup.add_item("AI Models", 0)
	popup.add_item("Dialogue Graph", 1)
	popup.id_pressed.connect(_on_toolbar_menu_id_pressed)
	_toolbar_container.add_child(_toolbar_menu)

	add_control_to_container(CONTAINER_TOOLBAR, _toolbar_container)

	# Move to left side of toolbar (after adding, move to first position)
	call_deferred("_reposition_toolbar_control")

	# Connect to ModelManager signals after a frame (needs AIService to be ready)
	call_deferred("_connect_model_manager_signals")

	print("OhMyDialogSystem: Plugin loaded")


func _exit_tree() -> void:
	# Disconnect ModelManager signals
	_disconnect_model_manager_signals()

	# Remove toolbar container
	if _toolbar_container:
		remove_control_from_container(CONTAINER_TOOLBAR, _toolbar_container)
		_toolbar_container.queue_free()
		_toolbar_container = null
		_toolbar_menu = null
		_status_indicator = null

	# Remove inspector plugins
	if _node_inspector_plugin:
		remove_inspector_plugin(_node_inspector_plugin)
		_node_inspector_plugin = null

	if _dialogue_graph_inspector_plugin:
		remove_inspector_plugin(_dialogue_graph_inspector_plugin)
		_dialogue_graph_inspector_plugin = null

	if _character_inspector_plugin:
		remove_inspector_plugin(_character_inspector_plugin)
		_character_inspector_plugin = null

	if _world_inspector_plugin:
		remove_inspector_plugin(_world_inspector_plugin)
		_world_inspector_plugin = null

	if _model_config_inspector_plugin:
		remove_inspector_plugin(_model_config_inspector_plugin)
		_model_config_inspector_plugin = null

	if _ai_preset_inspector_plugin:
		remove_inspector_plugin(_ai_preset_inspector_plugin)
		_ai_preset_inspector_plugin = null

	# Clean up dialogue graph window
	if _dialogue_graph_window:
		_dialogue_graph_window.queue_free()
		_dialogue_graph_window = null

	# Clean up AI service
	if _ai_service:
		_ai_service.queue_free()
		_ai_service = null

	# Clean up model manager window
	if _model_manager_window:
		_model_manager_window.queue_free()
		_model_manager_window = null

	print("OhMyDialogSystem: Plugin unloaded")


## Registers the AIService AutoLoad if not already registered.
func _register_autoload() -> void:
	if ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		return

	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
	print("OhMyDialogSystem: Registered AIService AutoLoad")


## Returns true if this plugin handles the given object type.
func _handles(object: Object) -> bool:
	return object is DialogueGraph


## Called when the user selects an object this plugin handles.
func _edit(object: Object) -> void:
	if object is DialogueGraph and _dialogue_graph_window:
		if _node_inspector_plugin:
			_node_inspector_plugin.set_current_graph(object)
		_dialogue_graph_window.edit_graph(object)


## Called when the dialogue graph window is ready.
func _on_dialogue_graph_window_ready() -> void:
	var editor := _dialogue_graph_window.get_editor()
	if editor and _node_inspector_plugin:
		editor.set_inspector_plugin(_node_inspector_plugin)
	if _dialogue_graph_inspector_plugin:
		_dialogue_graph_inspector_plugin.setup(_dialogue_graph_window)


## Called when a toolbar menu item is pressed.
func _on_toolbar_menu_id_pressed(id: int) -> void:
	match id:
		0:  # AI Models
			if _model_manager_window:
				_model_manager_window.show_window()
		1:  # Dialogue Graph
			if _dialogue_graph_window:
				_dialogue_graph_window.show_window()


## Repositions the toolbar control to the left side.
func _reposition_toolbar_control() -> void:
	if not _toolbar_container or not is_instance_valid(_toolbar_container):
		return

	var parent := _toolbar_container.get_parent()
	if parent:
		parent.move_child(_toolbar_container, 0)


## Connects to ModelManager signals for status updates.
func _connect_model_manager_signals() -> void:
	if not _ai_service:
		return

	var model_manager := _ai_service.get_model_manager()
	if not model_manager:
		return

	if not model_manager.model_loaded.is_connected(_on_model_loaded):
		model_manager.model_loaded.connect(_on_model_loaded)
	if not model_manager.model_unloaded.is_connected(_on_model_unloaded):
		model_manager.model_unloaded.connect(_on_model_unloaded)

	# Check current state
	if model_manager.is_model_loaded() and model_manager.current_config:
		_update_status_indicator(true, model_manager.current_config)


## Disconnects ModelManager signals.
func _disconnect_model_manager_signals() -> void:
	if not _ai_service:
		return

	var model_manager := _ai_service.get_model_manager()
	if not model_manager:
		return

	if model_manager.model_loaded.is_connected(_on_model_loaded):
		model_manager.model_loaded.disconnect(_on_model_loaded)
	if model_manager.model_unloaded.is_connected(_on_model_unloaded):
		model_manager.model_unloaded.disconnect(_on_model_unloaded)


## Updates the status indicator appearance.
func _update_status_indicator(is_loaded: bool, config: ModelConfig) -> void:
	if not _status_indicator:
		return

	if is_loaded and config:
		_status_indicator.add_theme_color_override("font_color", Color.GREEN)
		_status_indicator.tooltip_text = "Model loaded: %s" % config.display_name
	else:
		_status_indicator.add_theme_color_override("font_color", Color.GRAY)
		_status_indicator.tooltip_text = "No AI model loaded"


## Called when a model is loaded.
func _on_model_loaded(config: ModelConfig) -> void:
	_update_status_indicator(true, config)


## Called when a model is unloaded.
func _on_model_unloaded() -> void:
	_update_status_indicator(false, null)
