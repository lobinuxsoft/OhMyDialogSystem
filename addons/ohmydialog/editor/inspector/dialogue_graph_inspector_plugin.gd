@tool
class_name DialogueGraphInspectorPlugin
extends EditorInspectorPlugin
## Custom inspector plugin for DialogueGraph resources.
##
## Adds a wiki-styled header with statistics above Godot's default inspector.

## Reference to the dialogue graph window.
var _window: DialogueGraphWindow


## Sets the window reference for opening graphs.
func setup(window: DialogueGraphWindow) -> void:
	_window = window


func _can_handle(object: Object) -> bool:
	return object is DialogueGraph


func _parse_begin(object: Object) -> void:
	var graph := object as DialogueGraph
	if not graph:
		return

	var header := DialogueGraphHeader.new(graph, _window)
	add_custom_control(header)


## Decorative header panel with statistics for DialogueGraph.
class DialogueGraphHeader extends PanelContainer:
	const ACCENT_COLOR := WikiInspectorTheme.AI_PURPLE

	var _graph: DialogueGraph
	var _window: DialogueGraphWindow
	var _stats_label: RichTextLabel

	func _init(graph: DialogueGraph, window: DialogueGraphWindow) -> void:
		_graph = graph
		_window = window

	func _ready() -> void:
		add_theme_stylebox_override("panel", WikiInspectorTheme.create_header_style(ACCENT_COLOR))
		_setup_ui()
		_graph.changed.connect(_update_stats)
		EditorInterface.get_inspector().property_edited.connect(_on_property_edited)

	func _exit_tree() -> void:
		if _graph and _graph.changed.is_connected(_update_stats):
			_graph.changed.disconnect(_update_stats)
		var inspector := EditorInterface.get_inspector()
		if inspector and inspector.property_edited.is_connected(_on_property_edited):
			inspector.property_edited.disconnect(_on_property_edited)

	func _on_property_edited(_property: String) -> void:
		_update_stats()

	func _setup_ui() -> void:
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)

		# Title row with Open button
		var title_hbox := HBoxContainer.new()
		title_hbox.add_theme_constant_override("separation", 10)

		var icon := Label.new()
		icon.text = WikiInspectorTheme.ICON_BRAIN
		icon.add_theme_font_size_override("font_size", 18)
		icon.add_theme_color_override("font_color", ACCENT_COLOR)
		title_hbox.add_child(icon)

		var title := Label.new()
		title.text = "DIALOGUE GRAPH"
		title.add_theme_font_size_override("font_size", 13)
		title.add_theme_color_override("font_color", ACCENT_COLOR)
		title_hbox.add_child(title)

		# Spacer
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_hbox.add_child(spacer)

		# Open in Editor button
		var open_btn := Button.new()
		open_btn.text = "Open in Editor"
		open_btn.flat = true
		open_btn.add_theme_color_override("font_color", ACCENT_COLOR)
		open_btn.pressed.connect(_on_open_pressed)
		title_hbox.add_child(open_btn)

		vbox.add_child(title_hbox)

		# Stats
		_stats_label = RichTextLabel.new()
		_stats_label.bbcode_enabled = true
		_stats_label.fit_content = true
		_stats_label.scroll_active = false
		vbox.add_child(_stats_label)

		add_child(vbox)
		_update_stats()

	func _update_stats() -> void:
		if not _stats_label or not _graph:
			return

		var nodes := _graph.nodes.size()
		var connections := _graph.connections.size()
		var variables := _graph.local_variables.size()

		# Count by type
		var type_counts: Dictionary = {}
		for node_id in _graph.nodes:
			var node: DialogueNodeData = _graph.nodes[node_id]
			var type_name: String = DialogueNodeData.NodeType.keys()[node.node_type]
			type_counts[type_name] = type_counts.get(type_name, 0) + 1

		var text := "[code]Nodes: %d | Connections: %d | Variables: %d[/code]" % [nodes, connections, variables]
		_stats_label.text = text

	func _on_open_pressed() -> void:
		if not _graph:
			return
		if _window:
			_window.edit_graph(_graph)
