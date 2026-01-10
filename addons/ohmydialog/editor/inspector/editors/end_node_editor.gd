@tool
class_name EndNodeEditor
extends BaseNodeEditor
## Wiki-style info panel for End nodes.
##
## Shows what happens when dialogue ends.


var _info_label: RichTextLabel


func _init(node_data: DialogueNodeData, graph: DialogueGraph = null) -> void:
	super._init(node_data, graph)
	ACCENT_COLOR = Color("#ef4444")
	ICON = "■"
	TITLE = "END NODE"


func _setup_info() -> void:
	_info_label = _add_info_label()
	_refresh_info()


func _refresh_info() -> void:
	if not _info_label:
		return

	var text := "[color=#484f58]Al llegar a este nodo:[/color]\n"
	text += "• Sesión de diálogo termina\n"
	text += "• Modelo IA se descarga\n"
	text += "\n[color=#484f58]Usa JumpNode para encadenar\ndiálogos sin descargar el modelo.[/color]"

	_info_label.text = text
