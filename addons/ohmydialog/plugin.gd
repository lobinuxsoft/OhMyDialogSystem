@tool
extends EditorPlugin
## OhMyDialogSystem - AI-powered dialogue system for Godot
##
## Main plugin entry point. Handles initialization and cleanup of
## editor components, custom types, and dock panels.


## Reference to the dialogue graph editor instance.
var _editor_instance: Control


func _enter_tree() -> void:
	# Load and instantiate the dialogue graph editor
	var editor_scene := preload("res://addons/ohmydialog/editor/dialogue_graph_editor.tscn")
	_editor_instance = editor_scene.instantiate()

	# Add as bottom panel (more space for graph editing than dock)
	add_control_to_bottom_panel(_editor_instance, "Dialogue Graph")

	print("OhMyDialogSystem: Plugin loaded")


func _exit_tree() -> void:
	# Remove and clean up the editor
	if _editor_instance:
		remove_control_from_bottom_panel(_editor_instance)
		_editor_instance.queue_free()
		_editor_instance = null

	print("OhMyDialogSystem: Plugin unloaded")


## Returns true if this plugin handles the given object type.
func _handles(object: Object) -> bool:
	return object is DialogueGraph


## Called when the user selects an object this plugin handles.
func _edit(object: Object) -> void:
	if object is DialogueGraph and _editor_instance:
		print("OhMyDialogSystem: _edit called for %s" % object.resource_path)
		# Make panel visible FIRST, then load the graph
		make_bottom_panel_item_visible(_editor_instance)
		# Use call_deferred to ensure panel is visible before loading
		_editor_instance.call_deferred("edit_graph", object)


## Makes the dialogue graph editor visible when editing.
func _make_visible(visible: bool) -> void:
	if _editor_instance:
		if visible:
			make_bottom_panel_item_visible(_editor_instance)
