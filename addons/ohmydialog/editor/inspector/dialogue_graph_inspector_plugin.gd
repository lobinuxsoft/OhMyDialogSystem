@tool
class_name DialogueGraphInspectorPlugin
extends EditorInspectorPlugin
## Custom inspector plugin for DialogueGraph resources.
##
## Adds a wiki-styled header with statistics above Godot's default inspector.


func _can_handle(object: Object) -> bool:
	return object is DialogueGraph


func _parse_begin(object: Object) -> void:
	var graph := object as DialogueGraph
	if not graph:
		return

	var header := DialogueGraphHeader.new(graph)
	add_custom_control(header)


## Decorative header panel with statistics for DialogueGraph.
class DialogueGraphHeader extends PanelContainer:
	const ACCENT_COLOR := WikiInspectorTheme.AI_PURPLE

	var _graph: DialogueGraph
	var _stats_label: RichTextLabel

	func _init(graph: DialogueGraph) -> void:
		_graph = graph

	func _ready() -> void:
		add_theme_stylebox_override("panel", WikiInspectorTheme.create_header_style(ACCENT_COLOR))
		_setup_ui()
		_graph.changed.connect(_update_stats)

	func _exit_tree() -> void:
		if _graph and _graph.changed.is_connected(_update_stats):
			_graph.changed.disconnect(_update_stats)

	func _setup_ui() -> void:
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)

		# Title row
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
