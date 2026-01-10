@tool
class_name DialogueGraphEditor
extends Control
## Main visual editor for DialogueGraph resources.
##
## This editor uses GraphEdit to provide a node-based interface for creating
## and editing dialogue graphs. It supports all 11 node types defined in
## DialogueNodeData and handles connections, selection, and serialization.


## Emitted when the graph has been modified.
signal graph_modified

## Emitted when a node is selected.
signal node_selected(node_data: DialogueNodeData)

## Emitted when selection is cleared.
signal selection_cleared


## The currently edited DialogueGraph resource.
var current_graph: DialogueGraph

## Reference to the GraphEdit control.
@onready var graph_edit: GraphEdit = %GraphEdit

## Reference to the toolbar buttons.
@onready var new_button: Button = %NewButton
@onready var save_button: Button = %SaveButton
@onready var clear_button: Button = %ClearButton
@onready var add_node_button: MenuButton = %AddNodeButton
@onready var validate_button: Button = %ValidateButton
@onready var graph_name_label: Label = %GraphNameLabel

## Reference to the context menu.
@onready var context_menu: PopupMenu = %ContextMenu
@onready var add_node_submenu: PopupMenu = %AddNodeSubmenu

## Reference to save file dialog.
@onready var save_file_dialog: FileDialog = %SaveFileDialog

## Currently selected visual node.
var _selected_node: BaseDialogueNode

## Map of node_id -> BaseDialogueNode for quick lookup.
var _visual_nodes: Dictionary = {}

## Position where context menu was opened (for adding nodes).
var _context_menu_position: Vector2

## Reference to inspector plugin for context updates.
var _inspector_plugin: DialogueNodeInspectorPlugin


## Sets the inspector plugin reference for context updates.
func set_inspector_plugin(plugin: DialogueNodeInspectorPlugin) -> void:
	_inspector_plugin = plugin


func _ready() -> void:
	if not Engine.is_editor_hint():
		return

	# Ensure all nodes are available
	if not is_instance_valid(graph_edit):
		push_error("DialogueGraphEditor: GraphEdit not found!")
		return

	_setup_graph_edit()
	_setup_toolbar()
	_setup_context_menu()
	_update_ui_state()


func _setup_graph_edit() -> void:
	graph_edit.right_disconnects = true
	graph_edit.minimap_enabled = true
	graph_edit.show_zoom_label = true
	graph_edit.snapping_distance = 20
	graph_edit.snapping_enabled = true

	# Connect signals
	graph_edit.connection_request.connect(_on_connection_request)
	graph_edit.disconnection_request.connect(_on_disconnection_request)
	graph_edit.node_selected.connect(_on_node_selected)
	graph_edit.node_deselected.connect(_on_node_deselected)
	graph_edit.delete_nodes_request.connect(_on_delete_nodes_request)
	graph_edit.popup_request.connect(_on_popup_request)
	graph_edit.end_node_move.connect(_on_end_node_move)


func _setup_toolbar() -> void:
	if not new_button or not save_button or not clear_button or not validate_button:
		push_error("DialogueGraphEditor: Toolbar buttons not found!")
		return

	# Connect button signals (check if not already connected)
	if not new_button.pressed.is_connected(_on_new_pressed):
		new_button.pressed.connect(_on_new_pressed)
	if not save_button.pressed.is_connected(_on_save_pressed):
		save_button.pressed.connect(_on_save_pressed)
	if not clear_button.pressed.is_connected(_on_clear_pressed):
		clear_button.pressed.connect(_on_clear_pressed)
	if not validate_button.pressed.is_connected(_on_validate_pressed):
		validate_button.pressed.connect(_on_validate_pressed)

	# Connect file dialog
	if save_file_dialog and not save_file_dialog.file_selected.is_connected(_on_save_file_selected):
		save_file_dialog.file_selected.connect(_on_save_file_selected)

	# Setup add node menu
	var popup := add_node_button.get_popup()
	popup.clear()

	for i in DialogueNodeData.NodeType.size():
		var type_name := DialogueNodeData.get_type_name_static(i)
		popup.add_item(type_name, i)
		# Add icon color indicator
		var color := DialogueNodeData.get_type_color_static(i)
		popup.set_item_icon(popup.get_item_index(i), _create_color_icon(color))

	popup.id_pressed.connect(_on_add_node_menu_id_pressed)


func _setup_context_menu() -> void:
	context_menu.clear()

	# Add Node submenu
	add_node_submenu.clear()
	for i in DialogueNodeData.NodeType.size():
		var type_name := DialogueNodeData.get_type_name_static(i)
		add_node_submenu.add_item(type_name, i)
	add_node_submenu.id_pressed.connect(_on_add_node_submenu_id_pressed)

	context_menu.add_submenu_node_item("Add Node", add_node_submenu)
	context_menu.add_separator()
	context_menu.add_item("Delete Selected", 100)
	context_menu.add_item("Duplicate Selected", 101)
	context_menu.add_separator()
	context_menu.add_item("Validate Graph", 102)
	context_menu.add_item("Center View", 103)

	context_menu.id_pressed.connect(_on_context_menu_id_pressed)


## Creates a simple colored texture for menu icons.
func _create_color_icon(color: Color) -> ImageTexture:
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


## Loads a DialogueGraph for editing.
func edit_graph(graph: DialogueGraph) -> void:
	# Skip if already editing the same graph (prevents race condition)
	if current_graph == graph and graph != null:
		return

	current_graph = graph

	# Update inspector plugin with current graph for variable lookups
	if _inspector_plugin:
		_inspector_plugin.set_current_graph(graph)

	_rebuild_visual_graph()
	_update_ui_state()


## Clears the current graph from the editor.
func clear_graph() -> void:
	current_graph = null
	_clear_visual_nodes()
	_update_ui_state()


## Updates UI elements based on current state.
func _update_ui_state() -> void:
	var has_graph := current_graph != null

	save_button.disabled = not has_graph
	add_node_button.disabled = not has_graph
	validate_button.disabled = not has_graph

	if has_graph:
		var name := current_graph.display_name
		if name.is_empty():
			name = current_graph.graph_id
		if name.is_empty():
			name = "Unnamed Graph"
		graph_name_label.text = name
	else:
		graph_name_label.text = "No graph loaded"


## Rebuilds all visual nodes from the current DialogueGraph.
func _rebuild_visual_graph() -> void:
	_clear_visual_nodes()

	if not current_graph:
		return

	# Create visual nodes
	for node_id in current_graph.nodes:
		var node_data: DialogueNodeData = current_graph.nodes[node_id]
		_create_visual_node(node_data)

	# GraphEdit needs multiple frames to fully process new children
	# Using call_deferred twice to ensure nodes are ready
	call_deferred("_deferred_rebuild_connections")


## Deferred connection rebuild - gives GraphEdit time to process nodes.
func _deferred_rebuild_connections() -> void:
	# Extra defer to ensure GraphEdit has fully processed the nodes
	call_deferred("_rebuild_connections")


## Rebuilds visual connections from graph data.
func _rebuild_connections() -> void:
	if not current_graph:
		return

	for conn in current_graph.connections:
		var from_node: String = conn.from_node
		var to_node: String = conn.to_node

		# Verify both nodes exist visually
		if _visual_nodes.has(from_node) and _visual_nodes.has(to_node):
			graph_edit.connect_node(
				from_node,
				conn.from_slot,
				to_node,
				conn.to_slot
			)

	# Force GraphEdit to redraw connections (workaround for Godot rendering bug)
	_force_graph_redraw()


## Forces GraphEdit to redraw by toggling zoom (Godot workaround).
func _force_graph_redraw() -> void:
	# Use a timer to delay the zoom toggle - GraphEdit needs time
	var timer := get_tree().create_timer(0.05)
	timer.timeout.connect(_do_zoom_toggle)


## Actually toggles the zoom to force redraw.
func _do_zoom_toggle() -> void:
	var current_zoom := graph_edit.zoom
	graph_edit.zoom = current_zoom * 1.01
	await get_tree().process_frame
	graph_edit.zoom = current_zoom


## Clears all visual nodes from the graph edit.
func _clear_visual_nodes() -> void:
	graph_edit.clear_connections()

	for node_id in _visual_nodes:
		var visual_node: BaseDialogueNode = _visual_nodes[node_id]
		visual_node.queue_free()

	_visual_nodes.clear()
	_selected_node = null


## Creates a visual node for the given DialogueNodeData.
func _create_visual_node(node_data: DialogueNodeData) -> BaseDialogueNode:
	var visual_node := DialogueNodeFactory.create_node(node_data, current_graph)
	if visual_node:
		graph_edit.add_child(visual_node)
		_visual_nodes[node_data.node_id] = visual_node
	return visual_node


## Adds a new node of the specified type at the given position.
func _add_node(type: DialogueNodeData.NodeType, position: Vector2) -> DialogueNodeData:
	if not current_graph:
		return null

	# Convert screen position to graph position
	var graph_pos := (position + graph_edit.scroll_offset) / graph_edit.zoom

	# Create the node data
	var node_data := current_graph.create_node(type, graph_pos)

	# Create visual representation
	_create_visual_node(node_data)

	graph_modified.emit()
	return node_data


## Removes a node by its ID.
func _remove_node(node_id: String) -> void:
	if not current_graph:
		return

	# Remove visual node
	if _visual_nodes.has(node_id):
		var visual_node: BaseDialogueNode = _visual_nodes[node_id]

		# Remove connections involving this node
		for conn in graph_edit.get_connection_list():
			if conn.from_node == node_id or conn.to_node == node_id:
				graph_edit.disconnect_node(
					conn.from_node,
					conn.from_port,
					conn.to_node,
					conn.to_port
				)

		visual_node.queue_free()
		_visual_nodes.erase(node_id)

	# Remove from data
	current_graph.remove_node(node_id)

	if _selected_node and _selected_node.node_data.node_id == node_id:
		_selected_node = null
		selection_cleared.emit()

	graph_modified.emit()


# ==================== Signal Handlers ====================


func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	if not current_graph:
		return

	# Try to create connection in data
	if current_graph.connect_nodes(String(from_node), from_port, String(to_node), to_port):
		# Visual connection
		graph_edit.connect_node(from_node, from_port, to_node, to_port)
		graph_modified.emit()


func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	if not current_graph:
		return

	# Remove from data
	current_graph.disconnect_nodes(String(from_node), from_port, String(to_node), to_port)

	# Remove visual connection
	graph_edit.disconnect_node(from_node, from_port, to_node, to_port)
	graph_modified.emit()


func _on_node_selected(node: Node) -> void:
	if node is BaseDialogueNode:
		_selected_node = node
		node_selected.emit(node.node_data)
		# Show node data in the Inspector
		EditorInterface.inspect_object(node.node_data)


func _on_node_deselected(node: Node) -> void:
	if node == _selected_node:
		_selected_node = null
		selection_cleared.emit()
		# Clear inspector (show graph instead)
		if current_graph:
			EditorInterface.inspect_object(current_graph)


func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	for node_name in nodes:
		_remove_node(String(node_name))


func _on_popup_request(position: Vector2) -> void:
	_context_menu_position = position
	context_menu.position = get_screen_position() + position
	context_menu.popup()


func _on_end_node_move() -> void:
	# Sync all node positions back to data
	for node_id in _visual_nodes:
		var visual_node: BaseDialogueNode = _visual_nodes[node_id]
		visual_node.sync_position()
	graph_modified.emit()


func _on_new_pressed() -> void:
	var new_graph := DialogueGraph.new()
	new_graph.graph_id = "graph_%d" % Time.get_unix_time_from_system()
	new_graph.display_name = "New Dialogue"

	# Add a start node
	var start_node := new_graph.create_node(DialogueNodeData.NodeType.START, Vector2(100, 200))
	new_graph.start_node_id = start_node.node_id

	edit_graph(new_graph)

	# Immediately prompt to save the new graph
	_show_save_dialog()


func _on_clear_pressed() -> void:
	clear_graph()


func _on_save_pressed() -> void:
	if not current_graph:
		push_warning("DialogueGraphEditor: No graph to save")
		return

	# If the resource has a path, save it directly
	if not current_graph.resource_path.is_empty():
		_save_graph_to_path(current_graph.resource_path)
	else:
		# No path - show Save As dialog
		_show_save_dialog()


## Shows the save file dialog.
func _show_save_dialog() -> void:
	if not save_file_dialog:
		push_error("DialogueGraphEditor: Save file dialog not found!")
		return

	# Set suggested filename
	var suggested_name := "new_dialogue.tres"
	if current_graph and not current_graph.display_name.is_empty():
		suggested_name = current_graph.display_name.to_snake_case() + ".tres"

	save_file_dialog.current_file = suggested_name
	save_file_dialog.popup_centered()


## Called when user selects a file in the save dialog.
func _on_save_file_selected(path: String) -> void:
	_save_graph_to_path(path)


## Saves the current graph to the specified path.
func _save_graph_to_path(path: String) -> void:
	if not current_graph:
		return

	# Ensure .tres extension
	if not path.ends_with(".tres") and not path.ends_with(".res"):
		path += ".tres"

	var err := ResourceSaver.save(current_graph, path)
	if err == OK:
		current_graph.resource_path = path
		_update_ui_state()

		# Refresh the FileSystem dock to show the new file
		if Engine.is_editor_hint():
			EditorInterface.get_resource_filesystem().scan()
	else:
		push_error("DialogueGraphEditor: Failed to save graph: %s" % error_string(err))


func _on_validate_pressed() -> void:
	if not current_graph:
		return

	var errors := current_graph.validate()
	if errors.is_empty():
		print("DialogueGraphEditor: Graph is valid!")
	else:
		push_warning("DialogueGraphEditor: Validation found %d issues:" % errors.size())
		for err in errors:
			push_warning("  - %s" % err)


func _on_add_node_menu_id_pressed(id: int) -> void:
	# Add at center of visible area
	var center := graph_edit.size / 2
	_add_node(id as DialogueNodeData.NodeType, center)


func _on_add_node_submenu_id_pressed(id: int) -> void:
	_add_node(id as DialogueNodeData.NodeType, _context_menu_position)


func _on_context_menu_id_pressed(id: int) -> void:
	match id:
		100:  # Delete Selected
			if _selected_node:
				_remove_node(_selected_node.node_data.node_id)
		101:  # Duplicate Selected
			_duplicate_selected()
		102:  # Validate Graph
			_on_validate_pressed()
		103:  # Center View
			graph_edit.scroll_offset = Vector2.ZERO


func _duplicate_selected() -> void:
	if not _selected_node or not current_graph:
		return

	var original := _selected_node.node_data
	# Duplicate via serialization to preserve typed properties
	var new_data := DialogueNodeData.from_dict(original.to_dict())
	new_data.node_id = new_data._generate_uuid()
	new_data.editor_position = original.editor_position + Vector2(50, 50)

	current_graph.add_node(new_data)
	_create_visual_node(new_data)
	graph_modified.emit()
