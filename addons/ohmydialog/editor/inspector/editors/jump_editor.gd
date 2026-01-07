@tool
class_name JumpEditor
extends BaseNodeEditor
## Inspector editor for JUMP nodes.
##
## Shows target graph and node ID fields.


func _setup_ui() -> void:
	_add_header("Jump Node")
	_add_separator()
	_add_line_edit("Target Graph", "target_graph_id", "res://path/to/graph.tres")
	_add_line_edit("Target Node", "target_node_id", "Node ID (empty = start)")
