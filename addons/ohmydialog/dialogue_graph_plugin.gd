@tool
class_name DialogueGraphPlugin
extends EditorPlugin
## Plugin for DialogueGraph editing.
##
## Provides a main screen button "Dialogue" that opens the graph editor
## in a floating window. Handles DialogueGraph resources.

## Reference to the dialogue graph window.
var _dialogue_graph_window: DialogueGraphWindow

## Reference to the DialogueGraph inspector plugin.
var _inspector_plugin: DialogueGraphInspectorPlugin

## Reference to the DialogueNodeData inspector plugin.
var _node_inspector_plugin: DialogueNodeInspectorPlugin


func _enter_tree() -> void:
	# Register inspector plugin for DialogueNodeData
	_node_inspector_plugin = DialogueNodeInspectorPlugin.new()
	add_inspector_plugin(_node_inspector_plugin)

	# Initialize dialogue graph editor window
	_dialogue_graph_window = DialogueGraphWindow.new()
	EditorInterface.get_base_control().add_child(_dialogue_graph_window)

	# Wait for window to be ready before setting up
	_dialogue_graph_window.ready.connect(_on_window_ready)

	# Register inspector plugin for DialogueGraph
	_inspector_plugin = DialogueGraphInspectorPlugin.new()
	add_inspector_plugin(_inspector_plugin)


func _exit_tree() -> void:
	if _node_inspector_plugin:
		remove_inspector_plugin(_node_inspector_plugin)
		_node_inspector_plugin = null

	if _inspector_plugin:
		remove_inspector_plugin(_inspector_plugin)
		_inspector_plugin = null

	if _dialogue_graph_window:
		_dialogue_graph_window.queue_free()
		_dialogue_graph_window = null


func _on_window_ready() -> void:
	var editor := _dialogue_graph_window.get_editor()
	if editor and _node_inspector_plugin:
		editor.set_inspector_plugin(_node_inspector_plugin)
	if _inspector_plugin:
		_inspector_plugin.setup(_dialogue_graph_window)


## Returns true if this plugin handles the given object type.
func _handles(object: Object) -> bool:
	return object is DialogueGraph


## Called when the user selects an object this plugin handles.
func _edit(object: Object) -> void:
	if object is DialogueGraph and _dialogue_graph_window:
		if _node_inspector_plugin:
			_node_inspector_plugin.set_current_graph(object)
		_dialogue_graph_window.edit_graph(object)


# ==================== Main Screen Plugin Methods ====================


## Returns true to show this as a main screen button.
func _has_main_screen() -> bool:
	return true


## Returns the name shown in the main screen button.
func _get_plugin_name() -> String:
	return "Dialogue"


## Returns the icon for the main screen button.
func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("GraphEdit", "EditorIcons")


## Makes the main screen visible.
func _make_visible(visible: bool) -> void:
	if visible and _dialogue_graph_window:
		_dialogue_graph_window.show_window()
