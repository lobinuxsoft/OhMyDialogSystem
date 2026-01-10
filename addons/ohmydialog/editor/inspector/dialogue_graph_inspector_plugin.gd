@tool
class_name DialogueGraphInspectorPlugin
extends EditorInspectorPlugin
## Custom inspector plugin for DialogueGraph resources.
##
## Provides a wiki-styled editor panel with neural network aesthetic.
## Uses WikiInspectorTheme for consistent styling across all inspectors.


func _can_handle(object: Object) -> bool:
	return object is DialogueGraph


func _parse_begin(object: Object) -> void:
	var graph := object as DialogueGraph
	if not graph:
		return

	var panel := DialogueGraphEditorPanel.new(graph)
	add_custom_control(panel)


func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	# Hide all default properties - we handle everything in our custom panel
	return true


## Full editor panel for DialogueGraph with wiki-style aesthetics.
class DialogueGraphEditorPanel extends VBoxContainer:
	const ACCENT_COLOR := WikiInspectorTheme.AI_PURPLE

	var _graph: DialogueGraph
	var _stats_label: RichTextLabel
	var _sections: Dictionary = {}
	var _undo_redo: EditorUndoRedoManager
	var _property_controls: Dictionary = {}  # property_name -> Control
	var _is_updating: bool = false  # Prevent infinite loops

	func _init(graph: DialogueGraph) -> void:
		_graph = graph
		_undo_redo = EditorInterface.get_editor_undo_redo()

	func _ready() -> void:
		add_theme_constant_override("separation", 0)
		_setup_ui()
		# Connect to resource changes for Undo/Redo updates
		_graph.changed.connect(_on_resource_changed)

	func _exit_tree() -> void:
		if _graph and _graph.changed.is_connected(_on_resource_changed):
			_graph.changed.disconnect(_on_resource_changed)

	func _on_resource_changed() -> void:
		if _is_updating:
			return
		_is_updating = true
		_refresh_controls()
		_update_stats_display()
		_is_updating = false

	func _refresh_controls() -> void:
		for property in _property_controls:
			var control_or_callable: Variant = _property_controls[property]
			var value: Variant = _graph.get(property)
			# Arrays and Dicts store rebuild Callable instead of Control
			if control_or_callable is Array and control_or_callable.size() > 0 and control_or_callable[0] is Callable:
				(control_or_callable[0] as Callable).call()
			elif control_or_callable is LineEdit:
				if control_or_callable.text != value:
					control_or_callable.text = value
			elif control_or_callable is TextEdit:
				if control_or_callable.text != value:
					control_or_callable.text = value
			elif control_or_callable is EditorResourcePicker:
				if control_or_callable.edited_resource != value:
					control_or_callable.edited_resource = value

	func _setup_ui() -> void:
		# === MAIN HEADER ===
		var header := _create_main_header()
		add_child(header)

		# === SECTIONS ===
		var identity_content := _create_section("Graph Identity")
		_add_line_edit(identity_content, "ID", "graph_id", "unique_graph_id")
		_add_line_edit(identity_content, "Name", "display_name", "Display Name")
		_add_text_edit(identity_content, "Description", "description", "Graph description...", 60)

		var context_content := _create_section("Context")
		_add_resource_picker(context_content, "Character", "default_character", "CharacterIdentity")
		_add_resource_picker(context_content, "World", "world_context", "WorldContext")

		var variables_content := _create_section("Local Variables")
		_add_variable_dictionary_edit(variables_content, "Variables", "local_variables")

		var stats_content := _create_section("Statistics")
		_add_stats_display(stats_content)

		_update_stats_display()


	func _create_main_header() -> PanelContainer:
		var header_panel := PanelContainer.new()
		header_panel.add_theme_stylebox_override("panel", WikiInspectorTheme.create_header_style(ACCENT_COLOR))

		var header_vbox := VBoxContainer.new()
		header_vbox.add_theme_constant_override("separation", 6)

		# Title with large icon
		var title_hbox := HBoxContainer.new()
		title_hbox.add_theme_constant_override("separation", 10)

		var icon_label := Label.new()
		icon_label.text = WikiInspectorTheme.ICON_BRAIN
		icon_label.add_theme_font_size_override("font_size", 18)
		icon_label.add_theme_color_override("font_color", ACCENT_COLOR)
		title_hbox.add_child(icon_label)

		var title := RichTextLabel.new()
		title.bbcode_enabled = true
		title.fit_content = true
		title.scroll_active = false
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.text = "[b]DIALOGUE GRAPH[/b]"
		title.add_theme_font_size_override("normal_font_size", 13)
		title.add_theme_color_override("default_color", ACCENT_COLOR)
		title_hbox.add_child(title)

		header_vbox.add_child(title_hbox)

		_stats_label = RichTextLabel.new()
		_stats_label.bbcode_enabled = true
		_stats_label.fit_content = true
		_stats_label.scroll_active = false
		header_vbox.add_child(_stats_label)

		header_panel.add_child(header_vbox)
		return header_panel


	func _create_section(title: String, expanded: bool = false) -> VBoxContainer:
		var section_container := VBoxContainer.new()
		section_container.add_theme_constant_override("separation", 0)

		# Section header
		var header_panel := PanelContainer.new()
		header_panel.add_theme_stylebox_override("panel", WikiInspectorTheme.create_section_header_style())
		header_panel.mouse_filter = Control.MOUSE_FILTER_STOP

		var header_hbox := HBoxContainer.new()
		header_hbox.add_theme_constant_override("separation", 8)
		header_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
		header_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Arrow indicator
		var arrow := Label.new()
		arrow.text = "▼" if expanded else "▶"
		arrow.add_theme_font_size_override("font_size", 16)
		arrow.add_theme_color_override("font_color", ACCENT_COLOR)
		arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header_hbox.add_child(arrow)

		# Title
		var title_label := Label.new()
		title_label.text = title
		title_label.add_theme_font_size_override("font_size", 12)
		title_label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_PRIMARY)
		title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header_hbox.add_child(title_label)

		header_panel.add_child(header_hbox)
		section_container.add_child(header_panel)

		# Content container
		var content_panel := PanelContainer.new()
		content_panel.add_theme_stylebox_override("panel", WikiInspectorTheme.create_content_style())
		content_panel.visible = expanded

		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 10)
		content_panel.add_child(content)
		section_container.add_child(content_panel)

		_sections[title] = {
			"arrow": arrow,
			"content_panel": content_panel,
			"header_panel": header_panel,
			"expanded": expanded
		}

		# Click to toggle
		header_panel.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				var section: Dictionary = _sections[title]
				section.expanded = not section.expanded
				section.content_panel.visible = section.expanded
				section.arrow.text = "▼" if section.expanded else "▶"
		)

		# Hover effect
		header_panel.mouse_entered.connect(func():
			header_panel.add_theme_stylebox_override("panel", WikiInspectorTheme.create_section_header_style(true))
		)
		header_panel.mouse_exited.connect(func():
			header_panel.add_theme_stylebox_override("panel", WikiInspectorTheme.create_section_header_style(false))
		)

		add_child(section_container)
		return content


	func _add_line_edit(parent: Control, label_text: String, property: String, placeholder: String = "") -> void:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)

		var label := Label.new()
		label.text = label_text
		label.custom_minimum_size.x = 80
		label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
		hbox.add_child(label)

		var edit := LineEdit.new()
		edit.text = _graph.get(property)
		edit.placeholder_text = placeholder
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit.text_submitted.connect(func(new_text: String):
			if _is_updating:
				return
			var old_value: String = _graph.get(property)
			if old_value == new_text:
				return
			_undo_redo.create_action("Change %s" % property)
			_undo_redo.add_do_property(_graph, property, new_text)
			_undo_redo.add_undo_property(_graph, property, old_value)
			_undo_redo.add_do_method(_graph, "emit_changed")
			_undo_redo.add_undo_method(_graph, "emit_changed")
			_undo_redo.commit_action()
		)
		edit.focus_exited.connect(func():
			if _is_updating:
				return
			var new_text: String = edit.text
			var old_value: String = _graph.get(property)
			if old_value == new_text:
				return
			_undo_redo.create_action("Change %s" % property)
			_undo_redo.add_do_property(_graph, property, new_text)
			_undo_redo.add_undo_property(_graph, property, old_value)
			_undo_redo.add_do_method(_graph, "emit_changed")
			_undo_redo.add_undo_method(_graph, "emit_changed")
			_undo_redo.commit_action()
		)
		hbox.add_child(edit)
		_property_controls[property] = edit

		parent.add_child(hbox)


	func _add_text_edit(parent: Control, label_text: String, property: String, placeholder: String = "", min_height: int = 80) -> void:
		var label := Label.new()
		label.text = label_text
		label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
		parent.add_child(label)

		var edit := TextEdit.new()
		edit.text = _graph.get(property)
		edit.placeholder_text = placeholder
		edit.custom_minimum_size.y = min_height
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		var last_text: String = edit.text
		edit.focus_exited.connect(func():
			if _is_updating:
				return
			var new_text: String = edit.text
			if last_text == new_text:
				return
			_undo_redo.create_action("Change %s" % property)
			_undo_redo.add_do_property(_graph, property, new_text)
			_undo_redo.add_undo_property(_graph, property, last_text)
			_undo_redo.add_do_method(_graph, "emit_changed")
			_undo_redo.add_undo_method(_graph, "emit_changed")
			_undo_redo.commit_action()
			last_text = new_text
		)
		_property_controls[property] = edit
		parent.add_child(edit)


	func _add_resource_picker(parent: Control, label_text: String, property: String, base_type: String) -> void:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)

		var label := Label.new()
		label.text = label_text
		label.custom_minimum_size.x = 80
		label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
		hbox.add_child(label)

		var picker := EditorResourcePicker.new()
		picker.base_type = base_type
		picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		picker.edited_resource = _graph.get(property)
		picker.resource_changed.connect(func(res: Resource):
			if _is_updating:
				return
			var old_value: Resource = _graph.get(property)
			_undo_redo.create_action("Change %s" % property)
			_undo_redo.add_do_property(_graph, property, res)
			_undo_redo.add_undo_property(_graph, property, old_value)
			_undo_redo.add_do_method(_graph, "emit_changed")
			_undo_redo.add_undo_method(_graph, "emit_changed")
			_undo_redo.commit_action()
		)
		hbox.add_child(picker)
		_property_controls[property] = picker

		parent.add_child(hbox)


	func _add_variable_dictionary_edit(parent: Control, label_text: String, property: String) -> void:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 4)

		var header := HBoxContainer.new()
		var label := Label.new()
		label.text = label_text
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
		header.add_child(label)

		var add_btn := Button.new()
		add_btn.text = "+"
		add_btn.custom_minimum_size = Vector2(24, 24)
		header.add_child(add_btn)
		container.add_child(header)

		var items_container := VBoxContainer.new()
		items_container.add_theme_constant_override("separation", 2)
		container.add_child(items_container)

		# Use Array wrapper for self-referencing callable
		var rebuild_ref: Array = [null]
		rebuild_ref[0] = func() -> void:
			for child in items_container.get_children():
				child.queue_free()

			var dict: Dictionary = _graph.get(property)
			for key in dict.keys():
				var item_hbox := HBoxContainer.new()
				item_hbox.add_theme_constant_override("separation", 4)

				var key_edit := LineEdit.new()
				key_edit.text = key
				key_edit.placeholder_text = "var_name"
				key_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				key_edit.custom_minimum_size.x = 100
				var current_key: String = key
				key_edit.focus_exited.connect(func() -> void:
					if _is_updating:
						return
					var new_key: String = key_edit.text
					if current_key == new_key:
						return
					var old_dict: Dictionary = _graph.get(property).duplicate()
					var new_dict: Dictionary = old_dict.duplicate()
					var value: Variant = new_dict.get(current_key, "")
					new_dict.erase(current_key)
					new_dict[new_key] = value
					_undo_redo.create_action("Rename variable")
					_undo_redo.add_do_property(_graph, property, new_dict)
					_undo_redo.add_undo_property(_graph, property, old_dict)
					_undo_redo.add_do_method(_graph, "emit_changed")
					_undo_redo.add_undo_method(_graph, "emit_changed")
					_undo_redo.commit_action()
					current_key = new_key
				)
				item_hbox.add_child(key_edit)

				# Type indicator
				var type_label := Label.new()
				type_label.text = "="
				type_label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_MUTED)
				item_hbox.add_child(type_label)

				var value_edit := LineEdit.new()
				value_edit.text = str(dict[key])
				value_edit.placeholder_text = "value"
				value_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				var k: String = key
				value_edit.focus_exited.connect(func() -> void:
					if _is_updating:
						return
					var new_value_str: String = value_edit.text
					var current_dict: Dictionary = _graph.get(property)
					# Try to preserve type
					var new_value: Variant = _parse_value(new_value_str)
					if str(current_dict.get(k, "")) == new_value_str:
						return
					var old_dict: Dictionary = current_dict.duplicate()
					var new_dict: Dictionary = old_dict.duplicate()
					new_dict[k] = new_value
					_undo_redo.create_action("Edit variable value")
					_undo_redo.add_do_property(_graph, property, new_dict)
					_undo_redo.add_undo_property(_graph, property, old_dict)
					_undo_redo.add_do_method(_graph, "emit_changed")
					_undo_redo.add_undo_method(_graph, "emit_changed")
					_undo_redo.commit_action()
				)
				item_hbox.add_child(value_edit)

				var del_btn := Button.new()
				del_btn.text = "×"
				del_btn.custom_minimum_size = Vector2(24, 24)
				del_btn.pressed.connect(func() -> void:
					if _is_updating:
						return
					var old_dict: Dictionary = _graph.get(property).duplicate()
					var new_dict: Dictionary = old_dict.duplicate()
					new_dict.erase(k)
					_undo_redo.create_action("Remove variable")
					_undo_redo.add_do_property(_graph, property, new_dict)
					_undo_redo.add_undo_property(_graph, property, old_dict)
					_undo_redo.add_do_method(_graph, "emit_changed")
					_undo_redo.add_undo_method(_graph, "emit_changed")
					_undo_redo.commit_action()
				)
				item_hbox.add_child(del_btn)

				items_container.add_child(item_hbox)

		add_btn.pressed.connect(func() -> void:
			if _is_updating:
				return
			var old_dict: Dictionary = _graph.get(property).duplicate()
			var new_dict: Dictionary = old_dict.duplicate()
			var new_key := "var_%d" % new_dict.size()
			new_dict[new_key] = ""
			_undo_redo.create_action("Add variable")
			_undo_redo.add_do_property(_graph, property, new_dict)
			_undo_redo.add_undo_property(_graph, property, old_dict)
			_undo_redo.add_do_method(_graph, "emit_changed")
			_undo_redo.add_undo_method(_graph, "emit_changed")
			_undo_redo.commit_action()
		)

		(rebuild_ref[0] as Callable).call()
		_property_controls[property] = rebuild_ref
		parent.add_child(container)


	func _parse_value(text: String) -> Variant:
		# Try to preserve types
		if text.to_lower() == "true":
			return true
		elif text.to_lower() == "false":
			return false
		elif text.is_valid_int():
			return text.to_int()
		elif text.is_valid_float():
			return text.to_float()
		return text


	func _add_stats_display(parent: Control) -> void:
		var stats_panel := PanelContainer.new()
		stats_panel.add_theme_stylebox_override("panel", WikiInspectorTheme.create_preview_style(WikiInspectorTheme.AI_PURPLE_DIM))

		var stats := RichTextLabel.new()
		stats.bbcode_enabled = true
		stats.fit_content = true
		stats.scroll_active = false
		stats.selection_enabled = true

		stats_panel.add_child(stats)
		parent.add_child(stats_panel)

		# Store for updates
		_stats_label = stats


	func _update_stats_display() -> void:
		if not _stats_label:
			return

		var node_count := _graph.nodes.size()
		var connection_count := _graph.connections.size()
		var variable_count := _graph.local_variables.size()

		# Count node types
		var type_counts: Dictionary = {}
		for node_id in _graph.nodes:
			var node: DialogueNodeData = _graph.nodes[node_id]
			var type_name: String = DialogueNodeData.NodeType.keys()[node.node_type]
			type_counts[type_name] = type_counts.get(type_name, 0) + 1

		var text := "[code]"
		text += "Nodes: %d\n" % node_count
		text += "Connections: %d\n" % connection_count
		text += "Variables: %d\n" % variable_count
		text += "─────────────────\n"

		for type_name in type_counts:
			text += "%s: %d\n" % [type_name, type_counts[type_name]]

		text += "[/code]"
		_stats_label.text = text
