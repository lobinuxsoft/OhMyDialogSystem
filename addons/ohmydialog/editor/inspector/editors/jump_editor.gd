@tool
class_name JumpEditor
extends BaseNodeEditor
## Wiki-style info panel for Jump nodes.
##
## Shows target graph and node info.


var _info_label: RichTextLabel


func _init(node_data: DialogueNodeData, graph: DialogueGraph = null) -> void:
	super._init(node_data, graph)
	ACCENT_COLOR = Color("#22c55e")
	ICON = "↗"
	TITLE = "JUMP"


func _setup_info() -> void:
	_info_label = _add_info_label()
	_refresh_info()


func _refresh_info() -> void:
	if not _info_label or not _node_data:
		return

	var jump_node := _node_data as JumpNodeData
	if not jump_node:
		return

	var text := ""

	# Target graph
	if jump_node.target_graph_id.is_empty():
		text += "[color=#ef4444]✗ Sin grafo destino[/color]"
	else:
		var graph_name := jump_node.target_graph_id.get_file().get_basename()
		if ResourceLoader.exists(jump_node.target_graph_id):
			text += "[color=#10b981]✓ Grafo: %s[/color]" % graph_name
		else:
			text += "[color=#ef4444]✗ Grafo no encontrado: %s[/color]" % graph_name

	# Target node
	if not jump_node.target_node_id.is_empty():
		text += "\n[b]Nodo:[/b] %s" % jump_node.target_node_id
	else:
		text += "\n[color=#484f58]Nodo: inicio (default)[/color]"

	# Context preservation
	if jump_node.preserve_context:
		text += "\n[color=#10b981]✓ Contexto preservado[/color]"
	else:
		text += "\n[color=#484f58]Contexto se reinicia[/color]"

	_info_label.text = text
