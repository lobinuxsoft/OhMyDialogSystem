@tool
class_name DialogueNodeData
extends Resource
## Base class for dialogue graph nodes.
##
## Each node type has a specific subclass with typed @export properties.
## Use DialogueNodeData.create(type) to instantiate the correct subclass.
##
## @tutorial: See docs/Technical/dialogue-nodes.html for detailed node documentation.


## Types of nodes available in the dialogue system.
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
	JUMP_TO_FREE,    ## Escapes to free conversation mode
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


# ==================== Internal Properties (not shown in inspector) ====================

## Unique identifier for this node (UUID format).
@export_storage var node_id: String = ""

## Position in the visual editor (GraphEdit coordinates).
@export_storage var editor_position: Vector2 = Vector2.ZERO

## Size in the visual editor (for resizable nodes).
@export_storage var editor_size: Vector2 = Vector2.ZERO

## Number of output connection slots.
@export_storage var output_count: int = 1


# ==================== Abstract Properties (override in subclasses) ====================

## The type of this node. Override in subclasses.
var node_type: NodeType:
	get:
		return _get_node_type()


func _get_node_type() -> NodeType:
	push_error("DialogueNodeData._get_node_type() must be overridden in subclass")
	return NodeType.START


# ==================== Initialization ====================

func _init() -> void:
	if node_id.is_empty():
		node_id = _generate_uuid()
	output_count = _calculate_output_count()


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


# ==================== Factory ====================

## Creates a node of the specified type. Returns the appropriate subclass.
static func create(type: NodeType) -> DialogueNodeData:
	var node: DialogueNodeData
	match type:
		NodeType.START:
			node = preload("res://addons/ohmydialog/resources/nodes/start_node_data.gd").new()
		NodeType.END:
			node = preload("res://addons/ohmydialog/resources/nodes/end_node_data.gd").new()
		NodeType.AI_RESPONSE:
			node = preload("res://addons/ohmydialog/resources/nodes/ai_response_node_data.gd").new()
		NodeType.STATIC_RESPONSE:
			node = preload("res://addons/ohmydialog/resources/nodes/static_response_node_data.gd").new()
		NodeType.PLAYER_CHOICE:
			node = preload("res://addons/ohmydialog/resources/nodes/player_choice_node_data.gd").new()
		NodeType.CONDITION:
			node = preload("res://addons/ohmydialog/resources/nodes/condition_node_data.gd").new()
		NodeType.EVENT:
			node = preload("res://addons/ohmydialog/resources/nodes/event_node_data.gd").new()
		NodeType.SET_VARIABLE:
			node = preload("res://addons/ohmydialog/resources/nodes/set_variable_node_data.gd").new()
		NodeType.JUMP:
			node = preload("res://addons/ohmydialog/resources/nodes/jump_node_data.gd").new()
		NodeType.JUMP_TO_FREE:
			node = preload("res://addons/ohmydialog/resources/nodes/jump_to_free_node_data.gd").new()
		NodeType.RETURN_TO_GRAPH:
			node = preload("res://addons/ohmydialog/resources/nodes/return_to_graph_node_data.gd").new()
		_:
			push_error("Unknown node type: %d" % type)
			node = preload("res://addons/ohmydialog/resources/nodes/start_node_data.gd").new()
	return node


# ==================== Output Count ====================

## Calculates the number of output slots based on node type.
## Override in subclasses that need dynamic output counts (e.g., PlayerChoice).
func _calculate_output_count() -> int:
	return 1


## Updates output_count. Call after modifying data that affects outputs.
func refresh_output_count() -> void:
	output_count = _calculate_output_count()


# ==================== Validation ====================

## Validates the node data. Override in subclasses for specific validation.
## Returns an array of error messages (empty if valid).
func validate() -> Array[String]:
	var errors: Array[String] = []
	if node_id.is_empty():
		errors.append("Node ID is empty")
	return errors


## Returns true if the node data is valid.
func is_valid() -> bool:
	return validate().is_empty()


# ==================== Serialization ====================

## Serializes the node to a dictionary. Override in subclasses to add specific data.
func to_dict() -> Dictionary:
	return {
		"node_id": node_id,
		"node_type": node_type,
		"editor_position": {"x": editor_position.x, "y": editor_position.y},
		"editor_size": {"x": editor_size.x, "y": editor_size.y},
		"output_count": output_count
	}


## Creates a DialogueNodeData from a dictionary.
## Handles both new format (typed properties) and legacy format (data dictionary).
static func from_dict(dict: Dictionary) -> DialogueNodeData:
	var type: NodeType = dict.get("node_type", NodeType.START)
	var node := create(type)

	node.node_id = dict.get("node_id", node._generate_uuid())

	var pos: Dictionary = dict.get("editor_position", {})
	node.editor_position = Vector2(pos.get("x", 0), pos.get("y", 0))

	var sz: Dictionary = dict.get("editor_size", {})
	node.editor_size = Vector2(sz.get("x", 0), sz.get("y", 0))

	# Load type-specific data (handles legacy "data" dictionary format)
	node._load_from_dict(dict)

	node.output_count = dict.get("output_count", node._calculate_output_count())

	return node


## Override in subclasses to load type-specific properties from dictionary.
func _load_from_dict(dict: Dictionary) -> void:
	# Legacy format support: if "data" exists, migrate properties from it
	var data: Dictionary = dict.get("data", {})
	if not data.is_empty():
		_migrate_from_data_dict(data)


## Override in subclasses to migrate from legacy "data" dictionary format.
func _migrate_from_data_dict(_data: Dictionary) -> void:
	pass  # Override in subclasses


# ==================== Type Information ====================

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
