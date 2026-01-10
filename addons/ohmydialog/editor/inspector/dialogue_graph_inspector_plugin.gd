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
		container.add_theme_constant_override("separation", 6)

		# Add button full width at top
		var add_btn := Button.new()
		add_btn.text = "+"
		add_btn.custom_minimum_size.y = 28
		add_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_child(add_btn)

		var items_container := VBoxContainer.new()
		items_container.add_theme_constant_override("separation", 4)
		container.add_child(items_container)

		# Type options matching Godot's metadata types (same order as Add Metadata)
		const TYPE_OPTIONS := [
			"bool", "float", "int",
			"AABB", "Array", "Basis", "Color", "Dictionary", "NodePath",
			"PackedByteArray", "PackedColorArray", "PackedFloat32Array", "PackedFloat64Array",
			"PackedInt32Array", "PackedInt64Array", "PackedStringArray",
			"PackedVector2Array", "PackedVector3Array", "PackedVector4Array",
			"Plane", "Projection", "Quaternion", "Rect2", "Rect2i",
			"String", "StringName", "Transform2D", "Transform3D",
			"Vector2", "Vector2i", "Vector3", "Vector3i", "Vector4", "Vector4i"
		]
		const TYPE_COLORS := {
			"bool": Color("#a855f7"),         # Purple
			"float": Color("#f97316"),        # Orange
			"int": Color("#3b82f6"),          # Blue
			"String": Color("#10b981"),       # Green
			"StringName": Color("#10b981"),   # Green
			"Color": Color("#eab308"),        # Yellow
			"Vector2": Color("#06b6d4"),      # Cyan
			"Vector2i": Color("#06b6d4"),
			"Vector3": Color("#ec4899"),      # Pink
			"Vector3i": Color("#ec4899"),
			"Vector4": Color("#f472b6"),
			"Vector4i": Color("#f472b6"),
			"Array": Color("#6b7280"),        # Gray
			"Dictionary": Color("#6b7280"),
		}

		# Use Array wrapper for self-referencing callable
		var rebuild_ref: Array = [null]
		rebuild_ref[0] = func() -> void:
			for child in items_container.get_children():
				child.queue_free()

			var dict: Dictionary = _graph.get(property)
			for key in dict.keys():
				var value: Variant = dict[key]
				var item_panel := PanelContainer.new()
				var item_style := StyleBoxFlat.new()
				item_style.bg_color = WikiInspectorTheme.BG_TERTIARY
				item_style.corner_radius_top_left = 4
				item_style.corner_radius_top_right = 4
				item_style.corner_radius_bottom_left = 4
				item_style.corner_radius_bottom_right = 4
				item_style.content_margin_left = 8
				item_style.content_margin_right = 8
				item_style.content_margin_top = 4
				item_style.content_margin_bottom = 4
				item_panel.add_theme_stylebox_override("panel", item_style)

				var item_hbox := HBoxContainer.new()
				item_hbox.add_theme_constant_override("separation", 6)

				# Variable name
				var key_edit := LineEdit.new()
				key_edit.text = key
				key_edit.placeholder_text = "name"
				key_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				key_edit.custom_minimum_size.x = 60
				var current_key: String = key
				item_hbox.add_child(key_edit)

				# Type selector
				var type_btn := OptionButton.new()
				type_btn.custom_minimum_size.x = 55
				for t in TYPE_OPTIONS:
					type_btn.add_item(t)
				var current_type := _get_type_name(value)
				type_btn.select(TYPE_OPTIONS.find(current_type))
				type_btn.add_theme_color_override("font_color", TYPE_COLORS.get(current_type, WikiInspectorTheme.TEXT_PRIMARY))
				item_hbox.add_child(type_btn)

				# Value edit
				var value_edit := LineEdit.new()
				value_edit.text = str(value)
				value_edit.placeholder_text = "value"
				value_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				var k: String = key
				item_hbox.add_child(value_edit)

				# Auto-save function for this row
				var save_changes := func() -> void:
					if _is_updating:
						return
					var old_dict: Dictionary = _graph.get(property).duplicate()
					var new_key: String = key_edit.text
					var type_idx: int = type_btn.selected
					var new_value: Variant = _convert_value(value_edit.text, TYPE_OPTIONS[type_idx])

					# Check if anything changed
					if current_key == new_key and str(old_dict.get(current_key, "")) == str(new_value):
						return

					var new_dict: Dictionary = old_dict.duplicate()
					if current_key != new_key:
						new_dict.erase(current_key)
					new_dict[new_key] = new_value

					_undo_redo.create_action("Update variable")
					_undo_redo.add_do_property(_graph, property, new_dict)
					_undo_redo.add_undo_property(_graph, property, old_dict)
					_undo_redo.add_do_method(_graph, "emit_changed")
					_undo_redo.add_undo_method(_graph, "emit_changed")
					_undo_redo.commit_action()

				# Connect auto-save to focus lost and Enter
				key_edit.focus_exited.connect(save_changes)
				key_edit.text_submitted.connect(func(_t: String): save_changes.call())
				value_edit.focus_exited.connect(save_changes)
				value_edit.text_submitted.connect(func(_t: String): save_changes.call())
				type_btn.item_selected.connect(func(_idx: int): save_changes.call())

				# Update type color when changed
				type_btn.item_selected.connect(func(idx: int) -> void:
					var t: String = TYPE_OPTIONS[idx]
					type_btn.add_theme_color_override("font_color", TYPE_COLORS.get(t, WikiInspectorTheme.TEXT_PRIMARY))
				)

				# Delete button
				var del_btn := Button.new()
				del_btn.text = "🗑"
				del_btn.custom_minimum_size = Vector2(28, 28)
				del_btn.add_theme_color_override("font_color", WikiInspectorTheme.AI_RED)
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

				item_panel.add_child(item_hbox)
				items_container.add_child(item_panel)

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


	func _get_type_name(value: Variant) -> String:
		match typeof(value):
			TYPE_BOOL: return "bool"
			TYPE_INT: return "int"
			TYPE_FLOAT: return "float"
			TYPE_STRING: return "String"
			TYPE_STRING_NAME: return "StringName"
			TYPE_VECTOR2: return "Vector2"
			TYPE_VECTOR2I: return "Vector2i"
			TYPE_VECTOR3: return "Vector3"
			TYPE_VECTOR3I: return "Vector3i"
			TYPE_VECTOR4: return "Vector4"
			TYPE_VECTOR4I: return "Vector4i"
			TYPE_COLOR: return "Color"
			TYPE_RECT2: return "Rect2"
			TYPE_RECT2I: return "Rect2i"
			TYPE_AABB: return "AABB"
			TYPE_BASIS: return "Basis"
			TYPE_TRANSFORM2D: return "Transform2D"
			TYPE_TRANSFORM3D: return "Transform3D"
			TYPE_PLANE: return "Plane"
			TYPE_QUATERNION: return "Quaternion"
			TYPE_PROJECTION: return "Projection"
			TYPE_NODE_PATH: return "NodePath"
			TYPE_ARRAY: return "Array"
			TYPE_DICTIONARY: return "Dictionary"
			TYPE_PACKED_BYTE_ARRAY: return "PackedByteArray"
			TYPE_PACKED_INT32_ARRAY: return "PackedInt32Array"
			TYPE_PACKED_INT64_ARRAY: return "PackedInt64Array"
			TYPE_PACKED_FLOAT32_ARRAY: return "PackedFloat32Array"
			TYPE_PACKED_FLOAT64_ARRAY: return "PackedFloat64Array"
			TYPE_PACKED_STRING_ARRAY: return "PackedStringArray"
			TYPE_PACKED_VECTOR2_ARRAY: return "PackedVector2Array"
			TYPE_PACKED_VECTOR3_ARRAY: return "PackedVector3Array"
			TYPE_PACKED_COLOR_ARRAY: return "PackedColorArray"
			TYPE_PACKED_VECTOR4_ARRAY: return "PackedVector4Array"
			_: return "String"


	func _convert_value(text: String, type_name: String) -> Variant:
		var clean := text.replace("(", "").replace(")", "").replace(" ", "")
		var parts := clean.split(",")

		match type_name:
			"bool":
				return text.to_lower() == "true" or text == "1"
			"int":
				return text.to_int()
			"float":
				return text.to_float()
			"String":
				return text
			"StringName":
				return StringName(text)
			"NodePath":
				return NodePath(text)
			"Vector2":
				if parts.size() >= 2:
					return Vector2(parts[0].to_float(), parts[1].to_float())
				return Vector2.ZERO
			"Vector2i":
				if parts.size() >= 2:
					return Vector2i(parts[0].to_int(), parts[1].to_int())
				return Vector2i.ZERO
			"Vector3":
				if parts.size() >= 3:
					return Vector3(parts[0].to_float(), parts[1].to_float(), parts[2].to_float())
				return Vector3.ZERO
			"Vector3i":
				if parts.size() >= 3:
					return Vector3i(parts[0].to_int(), parts[1].to_int(), parts[2].to_int())
				return Vector3i.ZERO
			"Vector4":
				if parts.size() >= 4:
					return Vector4(parts[0].to_float(), parts[1].to_float(), parts[2].to_float(), parts[3].to_float())
				return Vector4.ZERO
			"Vector4i":
				if parts.size() >= 4:
					return Vector4i(parts[0].to_int(), parts[1].to_int(), parts[2].to_int(), parts[3].to_int())
				return Vector4i.ZERO
			"Color":
				if text.begins_with("#"):
					return Color.html(text)
				if parts.size() >= 4:
					return Color(parts[0].to_float(), parts[1].to_float(), parts[2].to_float(), parts[3].to_float())
				if parts.size() >= 3:
					return Color(parts[0].to_float(), parts[1].to_float(), parts[2].to_float())
				return Color.WHITE
			"Rect2":
				if parts.size() >= 4:
					return Rect2(parts[0].to_float(), parts[1].to_float(), parts[2].to_float(), parts[3].to_float())
				return Rect2()
			"Rect2i":
				if parts.size() >= 4:
					return Rect2i(parts[0].to_int(), parts[1].to_int(), parts[2].to_int(), parts[3].to_int())
				return Rect2i()
			"AABB":
				if parts.size() >= 6:
					return AABB(Vector3(parts[0].to_float(), parts[1].to_float(), parts[2].to_float()),
								Vector3(parts[3].to_float(), parts[4].to_float(), parts[5].to_float()))
				return AABB()
			"Plane":
				if parts.size() >= 4:
					return Plane(parts[0].to_float(), parts[1].to_float(), parts[2].to_float(), parts[3].to_float())
				return Plane()
			"Quaternion":
				if parts.size() >= 4:
					return Quaternion(parts[0].to_float(), parts[1].to_float(), parts[2].to_float(), parts[3].to_float())
				return Quaternion()
			"Basis":
				return Basis()  # Complex type, default
			"Transform2D":
				return Transform2D()  # Complex type, default
			"Transform3D":
				return Transform3D()  # Complex type, default
			"Projection":
				return Projection()  # Complex type, default
			"Array":
				return []
			"Dictionary":
				return {}
			"PackedByteArray":
				return PackedByteArray()
			"PackedInt32Array":
				return PackedInt32Array()
			"PackedInt64Array":
				return PackedInt64Array()
			"PackedFloat32Array":
				return PackedFloat32Array()
			"PackedFloat64Array":
				return PackedFloat64Array()
			"PackedStringArray":
				return PackedStringArray()
			"PackedVector2Array":
				return PackedVector2Array()
			"PackedVector3Array":
				return PackedVector3Array()
			"PackedVector4Array":
				return PackedVector4Array()
			"PackedColorArray":
				return PackedColorArray()
			_:
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
