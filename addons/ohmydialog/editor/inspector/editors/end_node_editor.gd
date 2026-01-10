@tool
class_name EndNodeEditor
extends BaseNodeEditor
## Inspector editor for END nodes.
##
## The END node has no configurable properties.
## When reached, the dialogue ends and any loaded AI model is unloaded.


func _init(node_data: DialogueNodeData, graph: DialogueGraph = null) -> void:
	super(node_data, graph)
	ACCENT_COLOR = Color("#ef4444")  # End node red


func _setup_ui() -> void:
	_create_main_header("End Node", "■")

	var info_section := _create_section("Information")
	var info := Label.new()
	info.text = "When this node is reached:\n• Dialogue session ends\n• AI model is unloaded (if loaded)\n\nUse JumpTo node if you want to\nchain dialogues without unloading."
	info.add_theme_font_size_override("font_size", 11)
	info.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
	info_section.add_child(info)
