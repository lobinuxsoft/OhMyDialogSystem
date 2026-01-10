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

## Reference to the CharacterIdentity inspector plugin.
var _character_inspector_plugin: CharacterIdentityInspectorPlugin

## Reference to the WorldContext inspector plugin.
var _world_inspector_plugin: WorldContextInspectorPlugin

## Reference to the ModelConfig inspector plugin.
var _model_config_inspector_plugin: ModelConfigInspectorPlugin

## Reference to the AIPreset inspector plugin.
var _ai_preset_inspector_plugin: AIPresetInspectorPlugin

## Reference to the DialogueGraph inspector plugin.
var _dialogue_graph_inspector_plugin: DialogueGraphInspectorPlugin

## Reference to the AI service singleton (editor context).
var _ai_service: AIService

## Reference to the main screen button (found in editor tree).
var _main_screen_button: Button

## Last active main screen before opening AI Models.
var _last_main_screen: String = "2D"

## Flag to track if user clicked the AI button (vs automatic activation).
var _user_clicked_ai_button: bool = false

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

	# Register inspector plugin for CharacterIdentity
	_character_inspector_plugin = CharacterIdentityInspectorPlugin.new()
	add_inspector_plugin(_character_inspector_plugin)

	# Register inspector plugin for WorldContext
	_world_inspector_plugin = WorldContextInspectorPlugin.new()
	add_inspector_plugin(_world_inspector_plugin)

	# Register inspector plugin for ModelConfig
	_model_config_inspector_plugin = ModelConfigInspectorPlugin.new()
	add_inspector_plugin(_model_config_inspector_plugin)

	# Register inspector plugin for AIPreset
	_ai_preset_inspector_plugin = AIPresetInspectorPlugin.new()
	add_inspector_plugin(_ai_preset_inspector_plugin)

	# Register inspector plugin for DialogueGraph
	_dialogue_graph_inspector_plugin = DialogueGraphInspectorPlugin.new()
	add_inspector_plugin(_dialogue_graph_inspector_plugin)

	# Load and instantiate the dialogue graph editor
	var editor_scene := preload("res://addons/ohmydialog/editor/dialogue_graph_editor.tscn")
	_editor_instance = editor_scene.instantiate()

	# Pass inspector plugin reference to editor for context updates
	if _editor_instance.has_method("set_inspector_plugin"):
		_editor_instance.set_inspector_plugin(_inspector_plugin)

	# Pass AI service reference to editor for model status checks
	if _editor_instance.has_method("set_ai_service"):
		_editor_instance.set_ai_service(_ai_service)

	# Connect editor signals
	if _editor_instance.has_signal("ai_model_required"):
		_editor_instance.ai_model_required.connect(_on_ai_model_required)

	# Add as bottom panel (more space for graph editing than dock)
	add_control_to_bottom_panel(_editor_instance, "Dialogue Graph")

	# Connect to AI service signals for main screen button updates
	_ai_service.model_loaded.connect(_on_model_status_changed)
	_ai_service.model_unloaded.connect(_on_model_status_changed)
	_ai_service.models_changed.connect(_on_model_status_changed)

	# Track main screen changes to know where to return
	main_screen_changed.connect(_on_main_screen_changed)

	# Find and update main screen button after editor is ready
	call_deferred("_find_and_update_main_screen_button")

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
	# Remove inspector plugins
	if _inspector_plugin:
		remove_inspector_plugin(_inspector_plugin)
		_inspector_plugin = null

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

	if _dialogue_graph_inspector_plugin:
		remove_inspector_plugin(_dialogue_graph_inspector_plugin)
		_dialogue_graph_inspector_plugin = null

	# Remove and clean up the editor
	if _editor_instance:
		remove_control_from_bottom_panel(_editor_instance)
		_editor_instance.queue_free()
		_editor_instance = null

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


# ==================== Main Screen Plugin Methods ====================


## Returns true to show this as a main screen button (next to 2D, 3D, Script, etc.)
func _has_main_screen() -> bool:
	return true


## Returns the name shown in the main screen button.
func _get_plugin_name() -> String:
	return "AI"


## Returns the icon for the main screen button.
func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("Environment", "EditorIcons")


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


## Makes the main screen visible. For AI, we open the Model Manager and return.
func _make_visible(visible: bool) -> void:
	if visible:
		# Only open Model Manager if user explicitly clicked the AI button
		# (not when Godot auto-activates due to _handles() returning true)
		if _user_clicked_ai_button:
			_user_clicked_ai_button = false
			if _model_manager_window:
				_model_manager_window.show_window()
		# Always return to previous main screen (AI has no actual screen)
		call_deferred("_return_to_last_screen")


## Called when an AI node is added but no model is loaded.
func _on_ai_model_required() -> void:
	if _model_required_dialog:
		_model_required_dialog.show_dialog()


## Called when user requests to open the Model Manager from the dialog.
func _on_open_model_manager_requested() -> void:
	if _model_manager_window:
		_model_manager_window.show_window()


## Called when a model is activated from the dialog.
func _on_model_activated(config: ModelConfig) -> void:
	print("OhMyDialogSystem: Model activated - %s" % config.display_name)
	_update_main_screen_button_text()


## Called when main screen changes (to track where to return).
func _on_main_screen_changed(screen_name: String) -> void:
	# Don't track our own screen as "last"
	if screen_name != "AI":
		_last_main_screen = screen_name


## Called when model is loaded or unloaded.
func _on_model_status_changed(_arg = null) -> void:
	_update_main_screen_button_text()


## Returns to the last active main screen.
func _return_to_last_screen() -> void:
	EditorInterface.set_main_screen_editor(_last_main_screen)


## Finds our main screen button in the editor tree.
func _find_and_update_main_screen_button() -> void:
	# Main screen buttons are in a specific container in the editor
	# We search for our button by checking the text
	var base := EditorInterface.get_base_control()
	_main_screen_button = _find_button_recursive(base, "AI")

	# Connect to button press to track user clicks
	if _main_screen_button and not _main_screen_button.pressed.is_connected(_on_ai_button_pressed):
		_main_screen_button.pressed.connect(_on_ai_button_pressed)

	_update_main_screen_button_text()


## Called when user clicks the AI main screen button.
func _on_ai_button_pressed() -> void:
	_user_clicked_ai_button = true


## Recursively searches for a button with specific text.
func _find_button_recursive(node: Node, text: String) -> Button:
	if node is Button and node.text == text:
		return node
	for child in node.get_children():
		var result := _find_button_recursive(child, text)
		if result:
			return result
	return null


## Updates the main screen button text to show model status.
func _update_main_screen_button_text() -> void:
	if not _main_screen_button:
		return

	# Get available models count
	var available_count := 0
	if _ai_service and _ai_service.get_model_manager():
		var models := _ai_service.get_model_manager().get_available_models()
		for model in models:
			if model.is_downloaded():
				available_count += 1

	if _ai_service and _ai_service.is_model_loaded():
		var config := _ai_service.get_current_config()
		_main_screen_button.text = "AI"
		_main_screen_button.modulate = Color.WHITE
		var tooltip := ""
		if config:
			tooltip = "Modelo activo: %s" % config.display_name
		else:
			tooltip = "Modelo cargado"
		tooltip += "\n%d modelo(s) disponible(s)" % available_count
		tooltip += "\nClick para gestionar modelos"
		_main_screen_button.tooltip_text = tooltip
		# Add green indicator icon
		_main_screen_button.icon = _create_status_icon(Color("#10b981"))
	else:
		_main_screen_button.text = "AI"
		_main_screen_button.modulate = Color(0.7, 0.7, 0.7)
		var tooltip := ""
		if available_count > 0:
			tooltip = "Sin modelo activo\n%d modelo(s) disponible(s)\nClick para activar un modelo" % available_count
		else:
			tooltip = "No hay modelos descargados\nDescarga al menos un modelo AI para usar DialogueGraph\nClick para descargar modelos"
		_main_screen_button.tooltip_text = tooltip
		# Add red/gray indicator icon
		_main_screen_button.icon = _create_status_icon(Color("#6b7280"))


## Creates a small colored circle icon for status indication.
func _create_status_icon(color: Color) -> ImageTexture:
	var size := 12
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size / 2.0, size / 2.0)
	var radius := size / 2.0 - 1.0

	for x in size:
		for y in size:
			var dist := Vector2(x, y).distance_to(center)
			if dist <= radius:
				# Anti-aliased edge
				var alpha := clampf(radius - dist + 0.5, 0.0, 1.0)
				img.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

	return ImageTexture.create_from_image(img)
