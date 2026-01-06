@tool
class_name DialogueNodeFactory
extends RefCounted
## Factory for creating visual dialogue nodes based on their type.
##
## This factory encapsulates the mapping between DialogueNodeData.NodeType
## and the corresponding visual node classes.


## Creates and returns the appropriate visual node for the given data.
static func create_node(node_data: DialogueNodeData) -> BaseDialogueNode:
	var visual_node: BaseDialogueNode

	match node_data.node_type:
		DialogueNodeData.NodeType.START:
			visual_node = StartNode.new()
		DialogueNodeData.NodeType.END:
			visual_node = EndNode.new()
		DialogueNodeData.NodeType.AI_RESPONSE:
			visual_node = AIResponseNode.new()
		DialogueNodeData.NodeType.STATIC_RESPONSE:
			visual_node = StaticResponseNode.new()
		DialogueNodeData.NodeType.PLAYER_CHOICE:
			visual_node = PlayerChoiceNode.new()
		DialogueNodeData.NodeType.CONDITION:
			visual_node = ConditionNode.new()
		DialogueNodeData.NodeType.EVENT:
			visual_node = EventNode.new()
		DialogueNodeData.NodeType.SET_VARIABLE:
			visual_node = SetVariableNode.new()
		DialogueNodeData.NodeType.JUMP:
			visual_node = JumpNode.new()
		DialogueNodeData.NodeType.JUMP_TO_FREE:
			visual_node = JumpToFreeNode.new()
		DialogueNodeData.NodeType.RETURN_TO_GRAPH:
			visual_node = ReturnToGraphNode.new()
		_:
			push_error("DialogueNodeFactory: Unknown node type %d" % node_data.node_type)
			return null

	visual_node.setup(node_data)
	return visual_node
