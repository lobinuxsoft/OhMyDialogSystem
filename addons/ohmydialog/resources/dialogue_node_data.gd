@tool
class_name DialogueNodeData
extends Resource
## Data resource for a single dialogue graph node.
##
## Stores the serialized data for each node in a DialogueGraph.
## The `data` dictionary contents vary depending on the node type.
##
## @tutorial: See docs/Technical/dialogue-nodes.html for detailed node documentation.


## Types of nodes available in the dialogue system.
## Each type has different behavior and data requirements.
enum NodeType {
	START,           ## Entry point of the dialogue graph
	END,             ## Terminates dialogue execution
	AI_RESPONSE,     ## Generates dynamic response via LLM
	STATIC_RESPONSE, ## Displays pre-written text
	PLAYER_CHOICE,   ## Presents options to the player
	CONDITION,       ## Branches based on expression evaluation
	EVENT,           ## Emits a signal/event to the game
	SET_VARIABLE,    ## Modifies a dialogue variable
	JUMP,            ## Jumps to another graph or node
	JUMP_TO_FREE,    ## Escapes to free conversation mode (hybrid system)
	RETURN_TO_GRAPH  ## Returns from free mode to graph execution
}


## Operations available for SET_VARIABLE nodes.
enum VariableOperation {
	SET,      ## Sets the variable to the value
	ADD,      ## Adds value to current (numeric)
	SUBTRACT, ## Subtracts value from current (numeric)
	MULTIPLY, ## Multiplies current by value (numeric)
	DIVIDE,   ## Divides current by value (numeric)
	TOGGLE    ## Toggles boolean value
}


## Comparison operators for CONDITION nodes.
enum ComparisonOperator {
	EQUAL,         ## ==
	NOT_EQUAL,     ## !=
	GREATER,       ## >
	GREATER_EQUAL, ## >=
	LESS,          ## <
	LESS_EQUAL,    ## <=
	CONTAINS,      ## String/Array contains
	IS_EMPTY,      ## String/Array is empty
	IS_TRUE,       ## Boolean is true
	IS_FALSE       ## Boolean is false
}


## Unique identifier for this node (UUID format).
@export var node_id: String = ""

## The type of this node, determines behavior and data structure.
@export var node_type: NodeType = NodeType.START

## Position in the visual editor (GraphEdit coordinates).
@export var editor_position: Vector2 = Vector2.ZERO

## Size in the visual editor (for resizable nodes).
@export var editor_size: Vector2 = Vector2.ZERO

## Type-specific data. Structure varies by node_type.
## See _get_default_data() for the expected structure of each type.
@export var data: Dictionary = {}

## Number of output connection slots. Calculated based on node_type and data.
@export var output_count: int = 1


func _init(p_node_type: NodeType = NodeType.START) -> void:
	node_type = p_node_type
	if node_id.is_empty():
		node_id = _generate_uuid()
	data = _get_default_data(node_type)
	output_count = _calculate_output_count()


## Override _set to emit changed signal when properties are modified in Inspector.
func _set(property: StringName, value: Variant) -> bool:
	# Handle data sub-properties (e.g., "data/speaker")
	var prop_str := String(property)
	if prop_str.begins_with("data/"):
		var key := prop_str.substr(5)  # Remove "data/" prefix
		data[key] = value
		emit_changed()
		return true

	# For normal properties, let Godot handle it but emit changed
	match property:
		&"node_id", &"node_type", &"editor_position", &"editor_size", &"data", &"output_count":
			# Godot will set the property, we just need to know it changed
			call_deferred("emit_changed")
			return false  # Let Godot handle the actual set

	return false


## Generates a UUID v4 string for node identification.
func _generate_uuid() -> String:
	var uuid := ""
	for i in range(32):
		if i == 8 or i == 12 or i == 16 or i == 20:
			uuid += "-"
		if i == 12:
			uuid += "4"  # Version 4
		elif i == 16:
			uuid += ["8", "9", "a", "b"].pick_random()  # Variant
		else:
			uuid += "0123456789abcdef"[randi() % 16]
	return uuid


## Returns default data dictionary for the given node type.
## This documents the expected structure for each node type.
func _get_default_data(type: NodeType) -> Dictionary:
	match type:
		NodeType.START:
			return {
				"trigger": ""  # Event name that starts this dialogue (empty = manual)
			}
		NodeType.END:
			return {
				"reason": ""  # Optional reason/tag for analytics
			}
		NodeType.AI_RESPONSE:
			return {
				"character_id": "",     # Reference to CharacterIdentity resource
				"prompt_template": "",  # Template with {variables} for prompt
				"emotion_hint": "",     # Suggested emotion (happy, sad, angry, etc.)
				"max_tokens": 256       # Maximum response length
			}
		NodeType.STATIC_RESPONSE:
			return {
				"speaker": "",   # Character name to display
				"text": "",      # The dialogue text
				"emotion": ""    # Emotion tag for animations/portraits
			}
		NodeType.PLAYER_CHOICE:
			return {
				"prompt": "",    # Optional question/context shown to player
				"choices": []    # Array of {text: String, condition: String, metadata: Dictionary}
			}
		NodeType.CONDITION:
			return {
				"variable": "",                          # Variable name to check
				"operator": ComparisonOperator.EQUAL,    # Comparison operator
				"value": null,                           # Value to compare against
				"expression": ""                         # Alternative: raw GDScript expression
			}
		NodeType.EVENT:
			return {
				"event_name": "",   # Signal/event name to emit
				"event_data": {}    # Dictionary of data to pass with event
			}
		NodeType.SET_VARIABLE:
			return {
				"variable": "",                    # Variable name to modify
				"operation": VariableOperation.SET, # Operation to perform
				"value": null                      # Value for the operation
			}
		NodeType.JUMP:
			return {
				"target_graph_id": "",  # DialogueGraph resource path or ID
				"target_node_id": ""    # Specific node ID (empty = start node)
			}
		NodeType.JUMP_TO_FREE:
			return {
				"context_prompt": "",      # Additional context for free conversation
				"return_keywords": [],     # Keywords that trigger return to graph
				"return_condition": "",    # Expression that triggers return
				"max_exchanges": 0         # Max back-and-forth before auto-return (0 = unlimited)
			}
		NodeType.RETURN_TO_GRAPH:
			return {
				"return_node_id": ""  # Node to return to (empty = continue from jump point)
			}
		_:
			return {}


## Calculates the number of output slots based on node type and data.
func _calculate_output_count() -> int:
	match node_type:
		NodeType.START:
			return 1
		NodeType.END:
			return 0  # Terminal node
		NodeType.AI_RESPONSE:
			return 1
		NodeType.STATIC_RESPONSE:
			return 1
		NodeType.PLAYER_CHOICE:
			var choices: Array = data.get("choices", [])
			return maxi(1, choices.size())  # At least 1 output
		NodeType.CONDITION:
			return 2  # TRUE and FALSE branches
		NodeType.EVENT:
			return 1
		NodeType.SET_VARIABLE:
			return 1
		NodeType.JUMP:
			return 0  # Jumps elsewhere
		NodeType.JUMP_TO_FREE:
			return 1  # Continues after return
		NodeType.RETURN_TO_GRAPH:
			return 0  # Returns to previous context
		_:
			return 1


## Updates output_count based on current data. Call after modifying choices.
func refresh_output_count() -> void:
	output_count = _calculate_output_count()


## Validates the node data for completeness and correctness.
## Returns an array of error messages (empty if valid).
func validate() -> Array[String]:
	var errors: Array[String] = []

	if node_id.is_empty():
		errors.append("Node ID is empty")

	match node_type:
		NodeType.AI_RESPONSE:
			if data.get("character_id", "").is_empty():
				errors.append("AI_RESPONSE requires a character_id")
		NodeType.STATIC_RESPONSE:
			if data.get("text", "").is_empty():
				errors.append("STATIC_RESPONSE requires text content")
		NodeType.PLAYER_CHOICE:
			var choices: Array = data.get("choices", [])
			if choices.is_empty():
				errors.append("PLAYER_CHOICE requires at least one choice")
		NodeType.CONDITION:
			if data.get("variable", "").is_empty() and data.get("expression", "").is_empty():
				errors.append("CONDITION requires either a variable or expression")
		NodeType.EVENT:
			if data.get("event_name", "").is_empty():
				errors.append("EVENT requires an event_name")
		NodeType.SET_VARIABLE:
			if data.get("variable", "").is_empty():
				errors.append("SET_VARIABLE requires a variable name")
		NodeType.JUMP:
			if data.get("target_graph_id", "").is_empty():
				errors.append("JUMP requires a target_graph_id")
		NodeType.JUMP_TO_FREE:
			# No strict requirements - can have no return conditions for unlimited free mode
			pass
		NodeType.RETURN_TO_GRAPH:
			# No strict requirements - empty return_node_id means continue from jump
			pass

	return errors


## Returns true if the node data is valid.
func is_valid() -> bool:
	return validate().is_empty()


## Serializes the node to a dictionary for JSON/storage.
func to_dict() -> Dictionary:
	return {
		"node_id": node_id,
		"node_type": node_type,
		"editor_position": {"x": editor_position.x, "y": editor_position.y},
		"editor_size": {"x": editor_size.x, "y": editor_size.y},
		"data": data.duplicate(true),
		"output_count": output_count
	}


## Creates a DialogueNodeData from a dictionary.
static func from_dict(dict: Dictionary) -> DialogueNodeData:
	var node := DialogueNodeData.new()
	node.node_id = dict.get("node_id", node._generate_uuid())
	node.node_type = dict.get("node_type", NodeType.START)

	var pos: Dictionary = dict.get("editor_position", {})
	node.editor_position = Vector2(pos.get("x", 0), pos.get("y", 0))

	var sz: Dictionary = dict.get("editor_size", {})
	node.editor_size = Vector2(sz.get("x", 0), sz.get("y", 0))

	node.data = dict.get("data", {}).duplicate(true)
	node.output_count = dict.get("output_count", node._calculate_output_count())

	return node


## Returns a human-readable name for this node's type.
func get_type_name() -> String:
	return DialogueNodeData.get_type_name_static(node_type)


## Returns the suggested color for this node in the editor.
func get_type_color() -> Color:
	return DialogueNodeData.get_type_color_static(node_type)


## Returns a human-readable name for the node type.
static func get_type_name_static(type: NodeType) -> String:
	match type:
		NodeType.START: return "Start"
		NodeType.END: return "End"
		NodeType.AI_RESPONSE: return "AI Response"
		NodeType.STATIC_RESPONSE: return "Static Response"
		NodeType.PLAYER_CHOICE: return "Player Choice"
		NodeType.CONDITION: return "Condition"
		NodeType.EVENT: return "Event"
		NodeType.SET_VARIABLE: return "Set Variable"
		NodeType.JUMP: return "Jump"
		NodeType.JUMP_TO_FREE: return "Jump to Free"
		NodeType.RETURN_TO_GRAPH: return "Return to Graph"
		_: return "Unknown"


## Returns the suggested color for this node type in the editor.
## Colors match the documentation in docs/Technical/dialogue-nodes.html
static func get_type_color_static(type: NodeType) -> Color:
	match type:
		NodeType.START: return Color("#10b981")           # Green
		NodeType.END: return Color("#ef4444")             # Red
		NodeType.AI_RESPONSE: return Color("#3b82f6")     # Blue
		NodeType.STATIC_RESPONSE: return Color("#6b7280") # Gray
		NodeType.PLAYER_CHOICE: return Color("#eab308")   # Yellow
		NodeType.CONDITION: return Color("#f97316")       # Orange
		NodeType.EVENT: return Color("#a855f7")           # Purple
		NodeType.SET_VARIABLE: return Color("#06b6d4")    # Cyan
		NodeType.JUMP: return Color("#22c55e")            # Light Green
		NodeType.JUMP_TO_FREE: return Color("#8b5cf6")    # Violet
		NodeType.RETURN_TO_GRAPH: return Color("#14b8a6") # Teal
		_: return Color.WHITE
