@tool
extends EditorPlugin
## OhMyDialogSystem - AI-powered dialogue system for Godot
##
## Main plugin entry point. Handles initialization and cleanup of
## editor components, custom types, and windows.

const AUTOLOAD_NAME := "AIServiceAutoload"
const AUTOLOAD_PATH := "res://addons/ohmydialog/autoload/ai_service_autoload.gd"
const SESSION_CACHE_KEY := "ohmydialog/editor/last_graph_path"

## Reference to the toolbar menu button with icon.
var _toolbar_menu: MenuButton

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

## Reference to the model export plugin.
var _model_export_plugin: ModelExportPlugin

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

	# Register export plugin for copying models
	_model_export_plugin = ModelExportPlugin.new()
	add_export_plugin(_model_export_plugin)

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

	# Let AI Response nodes send the user here when no model is loaded
	_node_inspector_plugin.set_model_manager(_model_manager_window)

	# Create toolbar MenuButton with icon and text
	_toolbar_menu = MenuButton.new()
	_toolbar_menu.text = "AI"
	_toolbar_menu.icon = preload("res://addons/ohmydialog/icon.png")
	_toolbar_menu.flat = true
	_toolbar_menu.focus_mode = Control.FOCUS_NONE
	_toolbar_menu.add_theme_constant_override("icon_max_width", 32)

	var popup := _toolbar_menu.get_popup()
	popup.add_item("AI Models", 0)
	popup.add_item("Dialogue Graph", 1)
	popup.id_pressed.connect(_on_toolbar_menu_id_pressed)

	_update_status_indicator(false, null)
	add_control_to_container(CONTAINER_TOOLBAR, _toolbar_menu)

	# Connect to AIService signals after a frame (needs AIService to be ready)
	call_deferred("_connect_ai_service_signals")

	print("OhMyDialogSystem: Plugin loaded")


func _exit_tree() -> void:
	# Disconnect AIService signals
	_disconnect_ai_service_signals()

	# Remove toolbar menu
	if _toolbar_menu:
		remove_control_from_container(CONTAINER_TOOLBAR, _toolbar_menu)
		_toolbar_menu.queue_free()
		_toolbar_menu = null

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

	# Remove export plugin
	if _model_export_plugin:
		remove_export_plugin(_model_export_plugin)
		_model_export_plugin = null

	# Save session cache before cleanup
	_save_session_cache()

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

	# Restore last opened graph from session cache
	_restore_session_cache()


## Called when a toolbar menu item is pressed.
func _on_toolbar_menu_id_pressed(id: int) -> void:
	match id:
		0:  # AI Models
			if _model_manager_window:
				_model_manager_window.show_window()
		1:  # Dialogue Graph
			if _dialogue_graph_window:
				_dialogue_graph_window.show_window()


## Connects to AIService signals for status updates.
func _connect_ai_service_signals() -> void:
	if not _ai_service:
		return

	if not _ai_service.model_loaded.is_connected(_on_model_loaded):
		_ai_service.model_loaded.connect(_on_model_loaded)
	if not _ai_service.model_unloaded.is_connected(_on_model_unloaded):
		_ai_service.model_unloaded.connect(_on_model_unloaded)

	# Check current state and update tooltip
	if _ai_service.is_model_loaded():
		_update_status_indicator(true, _ai_service.get_current_config())
	else:
		_update_status_indicator(false, null)


## Disconnects AIService signals.
func _disconnect_ai_service_signals() -> void:
	if not _ai_service:
		return

	if _ai_service.model_loaded.is_connected(_on_model_loaded):
		_ai_service.model_loaded.disconnect(_on_model_loaded)
	if _ai_service.model_unloaded.is_connected(_on_model_unloaded):
		_ai_service.model_unloaded.disconnect(_on_model_unloaded)


## Updates the toolbar button appearance and tooltip.
func _update_status_indicator(is_loaded: bool, config: ModelConfig) -> void:
	if not _toolbar_menu:
		return

	var tooltip := ""

	if is_loaded and config:
		_toolbar_menu.add_theme_color_override("font_color", Color.GREEN)
		tooltip = "Active: %s\nClick to manage models" % config.display_name
	else:
		_toolbar_menu.remove_theme_color_override("font_color")
		tooltip = "No model loaded\nClick to manage models"

	_toolbar_menu.tooltip_text = tooltip


## Called when a model is loaded.
func _on_model_loaded(config: ModelConfig) -> void:
	_update_status_indicator(true, config)


## Called when a model is unloaded.
func _on_model_unloaded() -> void:
	_update_status_indicator(false, null)


## Saves the current graph path to editor settings for session persistence.
func _save_session_cache() -> void:
	if not _dialogue_graph_window:
		return

	var editor := _dialogue_graph_window.get_editor()
	if not editor:
		return

	var graph := editor.current_graph
	if graph and not graph.resource_path.is_empty():
		EditorInterface.get_editor_settings().set_setting(
			SESSION_CACHE_KEY,
			graph.resource_path
		)


## Restores the last opened graph from editor settings.
func _restore_session_cache() -> void:
	var settings := EditorInterface.get_editor_settings()
	if not settings.has_setting(SESSION_CACHE_KEY):
		return

	var path: String = settings.get_setting(SESSION_CACHE_KEY)
	if path.is_empty() or not FileAccess.file_exists(path):
		return

	var graph := load(path) as DialogueGraph
	if graph and _dialogue_graph_window:
		var editor := _dialogue_graph_window.get_editor()
		if editor:
			editor.edit_graph(graph)
