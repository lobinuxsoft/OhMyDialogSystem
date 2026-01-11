@tool
class_name ReturnToGraphEditor
extends BaseNodeEditor
## Wiki-style info panel for Return to Graph nodes.
##
## Shows return target info.


var _info_label: RichTextLabel


func _init(node_data: DialogueNodeData, graph: DialogueGraph = null) -> void:
	super._init(node_data, graph)
	ACCENT_COLOR = Color("#14b8a6")
	ICON = "↩"
	TITLE = "RETURN TO GRAPH"


func _setup_info() -> void:
	_info_label = _add_info_label()
	_refresh_info()


func _refresh_info() -> void:
	if not _info_label or not _node_data:
		return

	var return_node := _node_data as ReturnToGraphNodeData
	if not return_node:
		return

	var text := "[color=#484f58]Sale del modo libre y retorna\nal flujo del grafo.[/color]\n\n"

	# Return node
	if return_node.return_node_id.is_empty():
		text += "[b]Destino:[/b] continuar flujo normal"
	else:
		text += "[b]Destino:[/b] nodo %s" % return_node.return_node_id

	_info_label.text = text
