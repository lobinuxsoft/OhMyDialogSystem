@tool
extends EditorPlugin
## OhMyDialogSystem - AI-powered dialogue system for Godot
##
## Main plugin entry point. Handles initialization and cleanup of
## editor components, custom types, and dock panels.


## Reference to the dialogue graph editor instance.
var _editor_instance: Control

## Reference to the custom inspector plugin.
var _inspector_plugin: DialogueNodeInspectorPlugin

## Reference to the AI service singleton.
var _ai_service: AIService


func _enter_tree() -> void:
	# Initialize AI service singleton first
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

	# Clean up AI service
	if _ai_service:
		_ai_service.queue_free()
		_ai_service = null

	print("OhMyDialogSystem: Plugin unloaded")


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
