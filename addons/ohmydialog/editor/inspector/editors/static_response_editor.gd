@tool
class_name StaticResponseEditor
extends BaseNodeEditor
## Wiki-style info panel for Static Response nodes.
##
## Shows text preview, character count, and validation.


var _info_label: RichTextLabel


func _init(node_data: DialogueNodeData, graph: DialogueGraph = null) -> void:
	super._init(node_data, graph)
	ACCENT_COLOR = Color("#6b7280")
	ICON = "💬"
	TITLE = "STATIC RESPONSE"


func _setup_info() -> void:
	_info_label = _add_info_label()
	_refresh_info()


func _refresh_info() -> void:
	if not _info_label or not _node_data:
		return

	var static_node := _node_data as StaticResponseNodeData
	if not static_node:
		return

	var text := ""

	# Speaker info
	if static_node.speaker.is_empty():
		text += "[color=#f97316]⚠ Sin speaker definido[/color]\n"
	else:
		text += "[b]Speaker:[/b] %s\n" % static_node.speaker

	# Text stats
	var char_count := static_node.text.length()
	var word_count := static_node.text.split(" ", false).size() if char_count > 0 else 0

	if char_count == 0:
		text += "[color=#ef4444]✗ Texto vacío[/color]"
	else:
		text += "[color=#10b981]✓ %d caracteres, ~%d palabras[/color]" % [char_count, word_count]

	# Emotion
	if not static_node.emotion.is_empty():
		text += "\n[color=#484f58]Emoción: %s[/color]" % static_node.emotion

	# Variables detection
	var var_count := static_node.text.count("{")
	if var_count > 0:
		text += "\n[color=#06b6d4]%d variable(s) para sustituir[/color]" % var_count

	_info_label.text = text
