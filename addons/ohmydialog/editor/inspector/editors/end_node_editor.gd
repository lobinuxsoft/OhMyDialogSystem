@tool
class_name EndNodeEditor
extends BaseNodeEditor
## Inspector editor for END nodes.
##
## The END node has no configurable properties.
## When reached, the dialogue ends and any loaded AI model is unloaded.


func _setup_ui() -> void:
	_add_header("End Node")
	_add_separator()

	# Info text
	var info := Label.new()
	info.text = "When this node is reached:\n• Dialogue session ends\n• AI model is unloaded (if loaded)\n\nUse JumpTo node if you want to\nchain dialogues without unloading."
	info.add_theme_font_size_override("font_size", 11)
	info.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	add_child(info)
