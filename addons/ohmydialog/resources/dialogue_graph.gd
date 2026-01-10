@tool
@icon("res://addons/ohmydialog/icons/dialogue_graph.svg")
class_name DialogueGraph
extends Resource
## A complete dialogue graph containing nodes and connections.
##
## DialogueGraph stores the structure of a conversation including all nodes,
## their connections, and references to character/world context. It supports
## the hybrid dialogue system with scripted, free, and mixed modes.
##
## @tutorial: See docs/API/resources.html for detailed documentation.


## Emitted when a node is added to the graph.
signal node_added(node: DialogueNodeData)

## Emitted when a node is removed from the graph.
signal node_removed(node_id: String)

## Emitted when a connection is created between nodes.
signal connection_added(from_node: String, from_slot: int, to_node: String, to_slot: int)

## Emitted when a connection is removed.
signal connection_removed(from_node: String, from_slot: int, to_node: String, to_slot: int)


@export_group("Graph Identity")

## Unique identifier for this dialogue graph.
@export var graph_id: String = ""

## Human-readable name displayed in the editor.
@export var display_name: String = ""

## Description of what this dialogue is about.
## Example: "Main quest dialogue with the blacksmith about the legendary sword."
@export_multiline var description: String = ""


@export_group("Context")

## Default character identity for AI responses in this graph.
## Individual nodes can override this.
@export var default_character: CharacterIdentity = null

## World context to use for this dialogue.
## Provides setting, lore, and current events to the LLM.
@export var world_context: WorldContext = null

## AI generation preset for this dialogue.
## Controls temperature, sampling parameters, and stop sequences.
@export var ai_preset: AIPreset = null

## Path to the GGUF model file for AI responses in this dialogue.
## If empty, uses the currently loaded model from AIService.
@export_file("*.gguf") var model_path: String = "":
	set(value):
		model_path = value
		emit_changed()


@export_group("Variables")

## Local variables scoped to this dialogue graph.
## These are reset each time the dialogue starts.
## Example: {"talked_about_sword": false, "bribe_amount": 0}
@export var local_variables: Dictionary = {}


# ==================== Internal Data (not shown in inspector) ====================

## Dictionary of node_id -> DialogueNodeData.
## Contains all nodes in this graph.
@export_storage var nodes: Dictionary = {}

## Array of connection dictionaries.
## Each connection: {from_node: String, from_slot: int, to_node: String, to_slot: int}
@export_storage var connections: Array[Dictionary] = []

## The node_id of the start node (entry point of the dialogue).
@export_storage var start_node_id: String = ""

## Metadata for the visual editor (zoom, scroll position, etc.)
## Not used at runtime, only for editor state persistence.
@export_storage var editor_metadata: Dictionary = {}


# ==================== Node Management ====================


## Adds a node to the graph.
## Returns the node_id of the added node.
func add_node(node: DialogueNodeData) -> String:
	if node.node_id.is_empty():
		push_error("DialogueGraph: Cannot add node with empty node_id")
		return ""

	if nodes.has(node.node_id):
		push_warning("DialogueGraph: Node %s already exists, replacing" % node.node_id)

	nodes[node.node_id] = node

	# If this is a START node and we don't have a start_node_id, set it
	if node.node_type == DialogueNodeData.NodeType.START and start_node_id.is_empty():
		start_node_id = node.node_id

	node_added.emit(node)
	return node.node_id


## Creates and adds a new node of the specified type.
## Returns the created node.
func create_node(type: DialogueNodeData.NodeType, position: Vector2 = Vector2.ZERO) -> DialogueNodeData:
	var node := DialogueNodeData.create(type)
	node.editor_position = position
	add_node(node)
	return node


## Removes a node and all its connections from the graph.
func remove_node(node_id: String) -> void:
	if not nodes.has(node_id):
		push_warning("DialogueGraph: Node %s not found" % node_id)
		return

	# Remove all connections involving this node
	var connections_to_remove: Array[Dictionary] = []
	for conn in connections:
		if conn.from_node == node_id or conn.to_node == node_id:
			connections_to_remove.append(conn)

	for conn in connections_to_remove:
		disconnect_nodes(conn.from_node, conn.from_slot, conn.to_node, conn.to_slot)

	# Remove the node
	nodes.erase(node_id)

	# Clear start_node_id if we removed the start node
	if start_node_id == node_id:
		start_node_id = ""
		_find_new_start_node()

	node_removed.emit(node_id)


## Returns a node by its ID, or null if not found.
func get_node(node_id: String) -> DialogueNodeData:
	return nodes.get(node_id, null)


## Returns true if the graph contains a node with the given ID.
func has_node(node_id: String) -> bool:
	return nodes.has(node_id)


## Returns all nodes of a specific type.
func get_nodes_by_type(type: DialogueNodeData.NodeType) -> Array[DialogueNodeData]:
	var result: Array[DialogueNodeData] = []
	for node_id in nodes:
		var node: DialogueNodeData = nodes[node_id]
		if node.node_type == type:
			result.append(node)
	return result


## Returns the start node, or null if not set.
func get_start_node() -> DialogueNodeData:
	if start_node_id.is_empty():
		return null
	return get_node(start_node_id)


## Finds and sets a new start node if the current one is missing.
func _find_new_start_node() -> void:
	var start_nodes := get_nodes_by_type(DialogueNodeData.NodeType.START)
	if start_nodes.size() > 0:
		start_node_id = start_nodes[0].node_id


# ==================== Connection Management ====================


## Creates a connection between two nodes.
## Returns true if the connection was created successfully.
func connect_nodes(from_node: String, from_slot: int, to_node: String, to_slot: int = 0) -> bool:
	# Validate nodes exist
	if not nodes.has(from_node):
		push_error("DialogueGraph: Source node %s not found" % from_node)
		return false
	if not nodes.has(to_node):
		push_error("DialogueGraph: Target node %s not found" % to_node)
		return false

	# Check if connection already exists
	for conn in connections:
		if conn.from_node == from_node and conn.from_slot == from_slot \
		   and conn.to_node == to_node and conn.to_slot == to_slot:
			push_warning("DialogueGraph: Connection already exists")
			return false

	# Validate slot is within range
	var source_node: DialogueNodeData = nodes[from_node]
	if from_slot >= source_node.output_count:
		push_error("DialogueGraph: Slot %d out of range for node %s (has %d outputs)" % [from_slot, from_node, source_node.output_count])
		return false

	# Create connection
	var connection := {
		"from_node": from_node,
		"from_slot": from_slot,
		"to_node": to_node,
		"to_slot": to_slot
	}
	connections.append(connection)

	connection_added.emit(from_node, from_slot, to_node, to_slot)
	return true


## Removes a specific connection.
func disconnect_nodes(from_node: String, from_slot: int, to_node: String, to_slot: int = 0) -> void:
	for i in range(connections.size() - 1, -1, -1):
		var conn: Dictionary = connections[i]
		if conn.from_node == from_node and conn.from_slot == from_slot \
		   and conn.to_node == to_node and conn.to_slot == to_slot:
			connections.remove_at(i)
			connection_removed.emit(from_node, from_slot, to_node, to_slot)
			return


## Removes all connections from a specific output slot.
func disconnect_slot(node_id: String, slot: int) -> void:
	for i in range(connections.size() - 1, -1, -1):
		var conn: Dictionary = connections[i]
		if conn.from_node == node_id and conn.from_slot == slot:
			connections.remove_at(i)
			connection_removed.emit(conn.from_node, conn.from_slot, conn.to_node, conn.to_slot)


## Returns all connections from a node's output slot.
func get_connections_from(node_id: String, slot: int = -1) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for conn in connections:
		if conn.from_node == node_id:
			if slot == -1 or conn.from_slot == slot:
				result.append(conn)
	return result


## Returns all connections to a node.
func get_connections_to(node_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for conn in connections:
		if conn.to_node == node_id:
			result.append(conn)
	return result


## Returns the next node(s) from a given node and slot.
## For most nodes, returns a single node. For CONDITION nodes, slot matters.
func get_next_nodes(node_id: String, slot: int = 0) -> Array[DialogueNodeData]:
	var result: Array[DialogueNodeData] = []
	var conns := get_connections_from(node_id, slot)
	for conn in conns:
		var node := get_node(conn.to_node)
		if node:
			result.append(node)
	return result


## Returns the single next node, or null if none/multiple.
## Use for linear flow (non-branching nodes).
func get_next_node(node_id: String, slot: int = 0) -> DialogueNodeData:
	var next_nodes := get_next_nodes(node_id, slot)
	if next_nodes.size() == 1:
		return next_nodes[0]
	return null


# ==================== Validation ====================


## Validates the entire graph structure.
## Returns an array of error messages (empty if valid).
func validate() -> Array[String]:
	var errors: Array[String] = []

	# Check basic requirements
	if graph_id.is_empty():
		errors.append("Graph ID is empty")

	if nodes.is_empty():
		errors.append("Graph has no nodes")
		return errors

	# Check for start node
	if start_node_id.is_empty():
		errors.append("No start node defined")
	elif not nodes.has(start_node_id):
		errors.append("Start node '%s' not found in graph" % start_node_id)

	# Validate each node
	for node_id in nodes:
		var node: DialogueNodeData = nodes[node_id]
		var node_errors := node.validate()
		for err in node_errors:
			errors.append("Node '%s': %s" % [node_id, err])

	# Validate connections reference existing nodes
	for conn in connections:
		if not nodes.has(conn.from_node):
			errors.append("Connection references missing node: %s" % conn.from_node)
		if not nodes.has(conn.to_node):
			errors.append("Connection references missing node: %s" % conn.to_node)

	# Check for orphan nodes (except START)
	for node_id in nodes:
		var node: DialogueNodeData = nodes[node_id]
		if node.node_type != DialogueNodeData.NodeType.START:
			var incoming := get_connections_to(node_id)
			if incoming.is_empty():
				errors.append("Node '%s' has no incoming connections (orphan)" % node_id)

	# Check for dead ends (nodes with outputs but no connections, except END)
	for node_id in nodes:
		var node: DialogueNodeData = nodes[node_id]
		if node.output_count > 0 and node.node_type != DialogueNodeData.NodeType.END:
			var outgoing := get_connections_from(node_id)
			if outgoing.is_empty():
				errors.append("Node '%s' has no outgoing connections (dead end)" % node_id)

	return errors


## Returns true if the graph is valid.
func is_valid() -> bool:
	return validate().is_empty()


# ==================== Serialization ====================


## Serializes the graph to a dictionary for JSON/storage.
func to_dict() -> Dictionary:
	var nodes_dict := {}
	for node_id in nodes:
		nodes_dict[node_id] = nodes[node_id].to_dict()

	var result := {
		"graph_id": graph_id,
		"display_name": display_name,
		"description": description,
		"nodes": nodes_dict,
		"connections": connections.duplicate(true),
		"start_node_id": start_node_id,
		"local_variables": local_variables.duplicate(),
		"editor_metadata": editor_metadata.duplicate()
	}

	# Serialize ai_preset if present
	if ai_preset:
		result["ai_preset"] = ai_preset.to_dict()

	# Serialize model_path if set
	if not model_path.is_empty():
		result["model_path"] = model_path

	return result


## Creates a DialogueGraph from a dictionary.
static func from_dict(dict: Dictionary) -> DialogueGraph:
	var graph := DialogueGraph.new()
	graph.graph_id = dict.get("graph_id", "")
	graph.display_name = dict.get("display_name", "")
	graph.description = dict.get("description", "")
	graph.start_node_id = dict.get("start_node_id", "")
	graph.local_variables = dict.get("local_variables", {}).duplicate()
	graph.editor_metadata = dict.get("editor_metadata", {}).duplicate()

	# Reconstruct ai_preset if present
	if dict.has("ai_preset"):
		graph.ai_preset = AIPreset.from_dict(dict["ai_preset"])

	# Reconstruct model_path if present
	graph.model_path = dict.get("model_path", "")

	# Reconstruct nodes
	var nodes_dict: Dictionary = dict.get("nodes", {})
	for node_id in nodes_dict:
		var node := DialogueNodeData.from_dict(nodes_dict[node_id])
		graph.nodes[node_id] = node

	# Reconstruct connections
	var conns: Array = dict.get("connections", [])
	for conn in conns:
		graph.connections.append({
			"from_node": conn.get("from_node", ""),
			"from_slot": conn.get("from_slot", 0),
			"to_node": conn.get("to_node", ""),
			"to_slot": conn.get("to_slot", 0)
		})

	return graph


# ==================== Utilities ====================


## Returns a short summary of the graph for debugging.
func get_summary() -> String:
	return "%s (%s) - %d nodes, %d connections" % [
		display_name if not display_name.is_empty() else "Unnamed Graph",
		graph_id if not graph_id.is_empty() else "no-id",
		nodes.size(),
		connections.size()
	]


## Clears all nodes and connections from the graph.
func clear() -> void:
	nodes.clear()
	connections.clear()
	start_node_id = ""


## Duplicates the graph with new node IDs.
func duplicate_graph() -> DialogueGraph:
	var new_graph := DialogueGraph.new()
	new_graph.graph_id = graph_id + "_copy"
	new_graph.display_name = display_name + " (Copy)"
	new_graph.description = description
	new_graph.default_character = default_character
	new_graph.world_context = world_context
	new_graph.ai_preset = ai_preset
	new_graph.model_path = model_path
	new_graph.local_variables = local_variables.duplicate()
	new_graph.editor_metadata = editor_metadata.duplicate()

	# Create mapping of old IDs to new IDs
	var id_map: Dictionary = {}

	# Duplicate nodes with new IDs (via serialization to preserve typed properties)
	for old_id in nodes:
		var old_node: DialogueNodeData = nodes[old_id]
		var new_node := DialogueNodeData.from_dict(old_node.to_dict())
		# Generate a new node_id for the duplicate
		new_node.node_id = new_node._generate_uuid()

		id_map[old_id] = new_node.node_id
		new_graph.nodes[new_node.node_id] = new_node

	# Update start_node_id
	if id_map.has(start_node_id):
		new_graph.start_node_id = id_map[start_node_id]

	# Duplicate connections with new IDs
	for conn in connections:
		if id_map.has(conn.from_node) and id_map.has(conn.to_node):
			new_graph.connections.append({
				"from_node": id_map[conn.from_node],
				"from_slot": conn.from_slot,
				"to_node": id_map[conn.to_node],
				"to_slot": conn.to_slot
			})

	return new_graph
