@tool
class_name DialogueNodeInspectorPlugin
extends EditorInspectorPlugin
## Custom inspector plugin for DialogueNodeData.
##
## Shows type-specific fields instead of a generic dictionary.
## Metadata is handled by Godot's native inspector (not modified here).


## Current DialogueGraph being edited (set by DialogueGraphEditor).
var current_graph: DialogueGraph


## Sets the current graph context for variable lookups.
func set_current_graph(graph: DialogueGraph) -> void:
	current_graph = graph


func _can_handle(object: Object) -> bool:
	return object is DialogueNodeData


func _parse_begin(object: Object) -> void:
	var node_data := object as DialogueNodeData
	if not node_data:
		return

	# Add type-specific editor at the top
	var editor: Control = _create_editor_for_type(node_data)
	if editor:
		add_custom_control(editor)


func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	# Hide all default properties - we handle everything in our custom editors
	return true


func _create_editor_for_type(node_data: DialogueNodeData) -> Control:
	# Pass current_graph to editors that need variable access
	match node_data.node_type:
		DialogueNodeData.NodeType.START:
			return StartNodeEditor.new(node_data, current_graph)
		DialogueNodeData.NodeType.END:
			return EndNodeEditor.new(node_data, current_graph)
		DialogueNodeData.NodeType.STATIC_RESPONSE:
			return StaticResponseEditor.new(node_data, current_graph)
		DialogueNodeData.NodeType.AI_RESPONSE:
			return AIResponseEditor.new(node_data, current_graph)
		DialogueNodeData.NodeType.PLAYER_CHOICE:
			return PlayerChoiceEditor.new(node_data, current_graph)
		DialogueNodeData.NodeType.CONDITION:
			return ConditionEditor.new(node_data, current_graph)
		DialogueNodeData.NodeType.EVENT:
			return EventEditor.new(node_data, current_graph)
		DialogueNodeData.NodeType.SET_VARIABLE:
			return SetVariableEditor.new(node_data, current_graph)
		DialogueNodeData.NodeType.JUMP:
			return JumpEditor.new(node_data, current_graph)
		DialogueNodeData.NodeType.JUMP_TO_FREE:
			return JumpToFreeEditor.new(node_data, current_graph)
		DialogueNodeData.NodeType.RETURN_TO_GRAPH:
			return ReturnToGraphEditor.new(node_data, current_graph)
		_:
			return null
