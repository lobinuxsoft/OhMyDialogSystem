@tool
class_name StartNodeEditor
extends BaseNodeEditor
## Wiki-style info panel for Start nodes.
##
## Shows trigger info and model status.


var _info_label: RichTextLabel


func _init(node_data: DialogueNodeData, graph: DialogueGraph = null) -> void:
	super._init(node_data, graph)
	ACCENT_COLOR = Color("#10b981")
	ICON = "▶"
	TITLE = "START NODE"


func _setup_info() -> void:
	_info_label = _add_info_label()
	_refresh_info()


func _refresh_info() -> void:
	if not _info_label or not _node_data:
		return

	var start_node := _node_data as StartNodeData
	if not start_node:
		return

	var text := ""

	# Trigger info
	if start_node.trigger.is_empty():
		text += "[color=#484f58]Trigger: manual (sin evento)[/color]"
	else:
		text += "[b]Trigger:[/b] %s" % start_node.trigger

	# Model info
	text += "\n"
	if start_node.model_path.is_empty():
		text += "[color=#f97316]⚠ Sin modelo IA configurado[/color]"
	else:
		var model_name := start_node.model_path.get_file().get_basename()
		if FileAccess.file_exists(start_node.model_path):
			text += "[color=#10b981]✓ Modelo: %s[/color]" % model_name
		else:
			text += "[color=#ef4444]✗ Modelo no encontrado: %s[/color]" % model_name

	_info_label.text = text
