@tool
class_name EventEditor
extends BaseNodeEditor
## Wiki-style info panel for Event nodes.
##
## Shows event name and data summary.


var _info_label: RichTextLabel


func _init(node_data: DialogueNodeData, graph: DialogueGraph = null) -> void:
	super._init(node_data, graph)
	ACCENT_COLOR = Color("#a855f7")
	ICON = "⚡"
	TITLE = "EVENT"


func _setup_info() -> void:
	_info_label = _add_info_label()
	_refresh_info()


func _refresh_info() -> void:
	if not _info_label or not _node_data:
		return

	var event_node := _node_data as EventNodeData
	if not event_node:
		return

	var text := ""

	# Event name
	if event_node.event_name.is_empty():
		text += "[color=#ef4444]✗ Sin nombre de evento[/color]"
	else:
		text += "[b]Evento:[/b] %s" % event_node.event_name

	# Event data summary
	var data_count := event_node.event_data.size()
	if data_count > 0:
		text += "\n[color=#10b981]✓ %d campo(s) de datos[/color]" % data_count
		# Show keys
		var keys: Array = event_node.event_data.keys()
		if keys.size() <= 3:
			text += "\n[color=#484f58]Keys: %s[/color]" % ", ".join(keys)
		else:
			text += "\n[color=#484f58]Keys: %s...[/color]" % ", ".join(keys.slice(0, 3))
	else:
		text += "\n[color=#484f58]Sin datos adicionales[/color]"

	_info_label.text = text
