@tool
extends EditorPlugin
## OhMyDialogSystem - AI-powered dialogue system for Godot
##
## Main plugin entry point. Handles initialization and cleanup of
## editor components, custom types, and dock panels.

const AUTOLOAD_NAME := "AIServiceAutoload"
const AUTOLOAD_PATH := "res://addons/ohmydialog/autoload/ai_service_autoload.gd"

## Reference to the dialogue graph editor instance.
var _editor_instance: Control

## Reference to the custom inspector plugin.
var _inspector_plugin: DialogueNodeInspectorPlugin

## Reference to the AI service singleton (editor context).
var _ai_service: AIService

## Reference to the AI dock panel.
var _ai_dock: AIDock

## Reference to the model required dialog.
var _model_required_dialog: ModelRequiredDialog

## Reference to the model manager window.
var _model_manager_window: ModelManagerWindow


func _enter_tree() -> void:
	# Register AutoLoad for runtime (automatic, user doesn't need to configure)
	_register_autoload()

	# Initialize AI service singleton for editor context
	_ai_service = AIService.new()
	_ai_service.name = "AIService"
	add_child(_ai_service)

	# Register inspector plugin for DialogueNodeData
	_inspector_plugin = DialogueNodeInspectorPlugin.new()
	add_inspector_plugin(_inspector_plugin)

	# Load and instantiate the dialogue graph editor
	var editor_scene := preload("res://addons/ohmydialog/editor/dialogue_graph_editor.tscn")
	_editor_instance = editor_scene.instantiate()

	# Pass inspector plugin reference to editor for context updates
	if _editor_instance.has_method("set_inspector_plugin"):
		_editor_instance.set_inspector_plugin(_inspector_plugin)

	# Add as bottom panel (more space for graph editing than dock)
	add_control_to_bottom_panel(_editor_instance, "Dialogue Graph")

	# Initialize AI dock panel
	var dock_scene := preload("res://addons/ohmydialog/editor/ai_dock.tscn")
	_ai_dock = dock_scene.instantiate()
	_ai_dock.config_requested.connect(_on_ai_config_requested)
	_ai_dock.load_requested.connect(_on_ai_load_requested)
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _ai_dock)

	# Initialize model required dialog
	var dialog_scene := preload("res://addons/ohmydialog/editor/model_required_dialog.tscn")
	_model_required_dialog = dialog_scene.instantiate()
	_model_required_dialog.open_model_manager_requested.connect(_on_open_model_manager_requested)
	_model_required_dialog.model_activated.connect(_on_model_activated)
	EditorInterface.get_base_control().add_child(_model_required_dialog)

	# Initialize model manager window
	var manager_scene := preload("res://addons/ohmydialog/editor/model_manager_window.tscn")
	_model_manager_window = manager_scene.instantiate()
	EditorInterface.get_base_control().add_child(_model_manager_window)

	print("OhMyDialogSystem: Plugin loaded")


func _exit_tree() -> void:
	# Remove inspector plugin
	if _inspector_plugin:
		remove_inspector_plugin(_inspector_plugin)
		_inspector_plugin = null

	# Remove and clean up the editor
	if _editor_instance:
		remove_control_from_bottom_panel(_editor_instance)
		_editor_instance.queue_free()
		_editor_instance = null

	# Clean up AI dock
	if _ai_dock:
		remove_control_from_docks(_ai_dock)
		_ai_dock.queue_free()
		_ai_dock = null

	# Clean up AI service
	if _ai_service:
		_ai_service.queue_free()
		_ai_service = null

	# Clean up model required dialog
	if _model_required_dialog:
		_model_required_dialog.queue_free()
		_model_required_dialog = null

	# Clean up model manager window
	if _model_manager_window:
		_model_manager_window.queue_free()
		_model_manager_window = null

	# Note: We don't unregister the autoload here because:
	# 1. It would break running games if user disables plugin while testing
	# 2. User can manually remove it from Project Settings if needed

	print("OhMyDialogSystem: Plugin unloaded")


## Registers the AIService AutoLoad if not already registered.
func _register_autoload() -> void:
	# Check if already registered
	if ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		return

	# Register the autoload
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
	print("OhMyDialogSystem: Registered AIService AutoLoad")


## Returns true if this plugin handles the given object type.
func _handles(object: Object) -> bool:
	return object is DialogueGraph


## Called when the user selects an object this plugin handles.
func _edit(object: Object) -> void:
	if object is DialogueGraph and _editor_instance:
		# Update inspector plugin with current graph for variable lookups
		if _inspector_plugin:
			_inspector_plugin.set_current_graph(object)

		# Make panel visible FIRST, then load the graph
		make_bottom_panel_item_visible(_editor_instance)
		# Use call_deferred to ensure panel is visible before loading
		_editor_instance.call_deferred("edit_graph", object)


## Makes the dialogue graph editor visible when editing.
func _make_visible(visible: bool) -> void:
	if _editor_instance:
		if visible:
			make_bottom_panel_item_visible(_editor_instance)


## Called when user requests AI configuration from dock.
## Opens the Model Manager window.
func _on_ai_config_requested() -> void:
	if _model_manager_window:
		_model_manager_window.show_window()


## Called when user requests to load a model from dock.
func _on_ai_load_requested() -> void:
	if _model_required_dialog:
		_model_required_dialog.show_dialog()


## Called when user requests to open the Model Manager from the dialog.
func _on_open_model_manager_requested() -> void:
	if _model_manager_window:
		_model_manager_window.show_window()


## Called when a model is activated from the dialog.
func _on_model_activated(config: ModelConfig) -> void:
	print("OhMyDialogSystem: Model activated - %s" % config.display_name)
