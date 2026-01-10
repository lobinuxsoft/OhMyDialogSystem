@tool
class_name DialogueGraphWindow
extends Window
## Floating window for the DialogueGraph visual editor.
##
## Wraps the DialogueGraphEditor in a resizable window that can be
## opened from the main screen button or when editing a DialogueGraph.


## Reference to the embedded editor.
var _editor: DialogueGraphEditor


func _init() -> void:
	title = "Dialogue Graph Editor"
	size = Vector2i(1200, 800)
	min_size = Vector2i(800, 600)
	visible = false
	wrap_controls = true
	close_requested.connect(_on_close_requested)


func _ready() -> void:
	# Load and add the editor
	var editor_scene := preload("res://addons/ohmydialog/editor/dialogue_graph_editor.tscn")
	_editor = editor_scene.instantiate()
	add_child(_editor)


## Shows the window.
func show_window() -> void:
	popup_centered()


## Hides the window.
func hide_window() -> void:
	hide()


## Returns the embedded editor.
func get_editor() -> DialogueGraphEditor:
	return _editor


## Edits the given DialogueGraph.
func edit_graph(graph: DialogueGraph) -> void:
	if _editor:
		_editor.edit_graph(graph)
	show_window()


func _on_close_requested() -> void:
	hide()
