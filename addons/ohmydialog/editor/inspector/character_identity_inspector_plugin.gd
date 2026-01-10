@tool
class_name CharacterIdentityInspectorPlugin
extends EditorInspectorPlugin
## Custom inspector plugin for CharacterIdentity resources.
##
## Provides a wiki-styled editor panel with neural network aesthetic.
## Uses WikiInspectorTheme for consistent styling across all inspectors.


func _can_handle(object: Object) -> bool:
	return object is CharacterIdentity


func _parse_begin(object: Object) -> void:
	var character := object as CharacterIdentity
	if not character:
		return

	var panel := CharacterIdentityEditorPanel.new(character)
	add_custom_control(panel)


func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	# Hide all default properties - we handle everything in our custom panel
	return true


## Full editor panel for CharacterIdentity with wiki-style aesthetics.
class CharacterIdentityEditorPanel extends VBoxContainer:
	const ACCENT_COLOR := WikiInspectorTheme.AI_CYAN

	var _character: CharacterIdentity
	var _token_label: RichTextLabel
	var _preview_label: RichTextLabel
	var _sections: Dictionary = {}
	var _undo_redo: EditorUndoRedoManager
	var _property_controls: Dictionary = {}  # property_name -> Control
	var _is_updating: bool = false  # Prevent infinite loops

	func _init(character: CharacterIdentity) -> void:
		_character = character
		_undo_redo = EditorInterface.get_editor_undo_redo()

	func _ready() -> void:
		add_theme_constant_override("separation", 0)
		_setup_ui()
		# Connect to resource changes for Undo/Redo updates
		_character.changed.connect(_on_resource_changed)

	func _exit_tree() -> void:
		if _character and _character.changed.is_connected(_on_resource_changed):
			_character.changed.disconnect(_on_resource_changed)

	func _on_resource_changed() -> void:
		if _is_updating:
			return
		_is_updating = true
		_refresh_controls()
		_update_token_display()
		_is_updating = false

	func _refresh_controls() -> void:
		for property in _property_controls:
			var control_or_callable: Variant = _property_controls[property]
			var value: Variant = _character.get(property)
			# Arrays and Dicts store rebuild Callable instead of Control
			if control_or_callable is Array and control_or_callable.size() > 0 and control_or_callable[0] is Callable:
				(control_or_callable[0] as Callable).call()
			elif control_or_callable is LineEdit:
				if control_or_callable.text != value:
					control_or_callable.text = value
			elif control_or_callable is TextEdit:
				if control_or_callable.text != value:
					control_or_callable.text = value
			elif control_or_callable is OptionButton:
				if control_or_callable.selected != value:
					control_or_callable.select(value)
			elif control_or_callable is EditorResourcePicker:
				if control_or_callable.edited_resource != value:
					control_or_callable.edited_resource = value

	func _setup_ui() -> void:
		# === MAIN HEADER ===
		var header := _create_main_header()
		add_child(header)

		# === SECTIONS ===
		var identity_content := _create_section("Identity")
		_add_line_edit(identity_content, "ID", "character_id", "unique_id")
		_add_line_edit(identity_content, "Name", "character_name", "Display Name")
		_add_resource_picker(identity_content, "Portrait", "portrait", "Texture2D")

		var personality_content := _create_section("Personality")
		_add_text_edit(personality_content, "Personality", "personality", "Core traits and behavior...", 80)
		_add_text_edit(personality_content, "Background", "background", "History and origin...", 80)
		_add_speech_style_picker(personality_content)
		_add_text_edit(personality_content, "Speech Patterns", "speech_patterns", "Verbal tics, catchphrases...", 60)

		var knowledge_content := _create_section("Knowledge & Secrets")
		_add_string_array_edit(knowledge_content, "Knowledge", "knowledge", "Topic...")
		_add_string_array_edit(knowledge_content, "Secrets", "secrets", "Secret...")

		var motivation_content := _create_section("Motivation")
		_add_string_array_edit(motivation_content, "Goals", "goals", "Goal...")
		_add_string_array_edit(motivation_content, "Fears", "fears", "Fear...")

		var relationships_content := _create_section("Relationships")
		_add_dictionary_edit(relationships_content, "Relationships", "relationships", "character_id", "relationship")

		var examples_content := _create_section("Examples")
		_add_string_array_edit(examples_content, "Example Dialogues", "example_dialogues", "Example line...")

		var preview_content := _create_section("Preview")
		_add_prompt_preview(preview_content)

		_update_token_display()


	func _create_main_header() -> PanelContainer:
		var header_panel := PanelContainer.new()
		header_panel.add_theme_stylebox_override("panel", WikiInspectorTheme.create_header_style(ACCENT_COLOR))

		var header_vbox := VBoxContainer.new()
		header_vbox.add_theme_constant_override("separation", 6)

		# Title with large icon
		var title_hbox := HBoxContainer.new()
		title_hbox.add_theme_constant_override("separation", 10)

		var icon_label := Label.new()
		icon_label.text = WikiInspectorTheme.ICON_DIAMOND
		icon_label.add_theme_font_size_override("font_size", 18)
		icon_label.add_theme_color_override("font_color", ACCENT_COLOR)
		title_hbox.add_child(icon_label)

		var title := RichTextLabel.new()
		title.bbcode_enabled = true
		title.fit_content = true
		title.scroll_active = false
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.text = "[b]CHARACTER IDENTITY[/b]"
		title.add_theme_font_size_override("normal_font_size", 13)
		title.add_theme_color_override("default_color", ACCENT_COLOR)
		title_hbox.add_child(title)

		header_vbox.add_child(title_hbox)

		_token_label = RichTextLabel.new()
		_token_label.bbcode_enabled = true
		_token_label.fit_content = true
		_token_label.scroll_active = false
		header_vbox.add_child(_token_label)

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

		# Arrow indicator (larger for better visibility)
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
		edit.text = _character.get(property)
		edit.placeholder_text = placeholder
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit.text_submitted.connect(func(new_text: String):
			if _is_updating:
				return
			var old_value: String = _character.get(property)
			if old_value == new_text:
				return
			_undo_redo.create_action("Change %s" % property)
			_undo_redo.add_do_property(_character, property, new_text)
			_undo_redo.add_undo_property(_character, property, old_value)
			_undo_redo.add_do_method(_character, "emit_changed")
			_undo_redo.add_undo_method(_character, "emit_changed")
			_undo_redo.commit_action()
		)
		edit.focus_exited.connect(func():
			if _is_updating:
				return
			var new_text: String = edit.text
			var old_value: String = _character.get(property)
			if old_value == new_text:
				return
			_undo_redo.create_action("Change %s" % property)
			_undo_redo.add_do_property(_character, property, new_text)
			_undo_redo.add_undo_property(_character, property, old_value)
			_undo_redo.add_do_method(_character, "emit_changed")
			_undo_redo.add_undo_method(_character, "emit_changed")
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
		edit.text = _character.get(property)
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
			_undo_redo.add_do_property(_character, property, new_text)
			_undo_redo.add_undo_property(_character, property, last_text)
			_undo_redo.add_do_method(_character, "emit_changed")
			_undo_redo.add_undo_method(_character, "emit_changed")
			_undo_redo.commit_action()
			last_text = new_text
		)
		_property_controls[property] = edit
		parent.add_child(edit)


	func _add_speech_style_picker(parent: Control) -> void:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)

		var label := Label.new()
		label.text = "Speech Style"
		label.custom_minimum_size.x = 80
		label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
		hbox.add_child(label)

		var option := OptionButton.new()
		for style in CharacterIdentity.SpeechStyle.keys():
			option.add_item(style.capitalize().replace("_", " "))
		option.select(_character.speech_style)
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option.item_selected.connect(func(index: int):
			if _is_updating:
				return
			var old_value: int = _character.speech_style
			if old_value == index:
				return
			_undo_redo.create_action("Change speech_style")
			_undo_redo.add_do_property(_character, "speech_style", index)
			_undo_redo.add_undo_property(_character, "speech_style", old_value)
			_undo_redo.add_do_method(_character, "emit_changed")
			_undo_redo.add_undo_method(_character, "emit_changed")
			_undo_redo.commit_action()
		)
		hbox.add_child(option)
		_property_controls["speech_style"] = option

		parent.add_child(hbox)


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
		picker.edited_resource = _character.get(property)
		picker.resource_changed.connect(func(res: Resource):
			if _is_updating:
				return
			var old_value: Resource = _character.get(property)
			_undo_redo.create_action("Change %s" % property)
			_undo_redo.add_do_property(_character, property, res)
			_undo_redo.add_undo_property(_character, property, old_value)
			_undo_redo.add_do_method(_character, "emit_changed")
			_undo_redo.add_undo_method(_character, "emit_changed")
			_undo_redo.commit_action()
		)
		hbox.add_child(picker)
		_property_controls[property] = picker

		parent.add_child(hbox)


	func _add_string_array_edit(parent: Control, label_text: String, property: String, placeholder: String) -> void:
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

			var arr: Array = _character.get(property)
			for i in arr.size():
				var item_hbox := HBoxContainer.new()
				item_hbox.add_theme_constant_override("separation", 4)

				var item_edit := LineEdit.new()
				item_edit.text = arr[i]
				item_edit.placeholder_text = placeholder
				item_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				var idx := i
				item_edit.text_submitted.connect(func(new_text: String) -> void:
					if _is_updating:
						return
					var old_arr: Array = _character.get(property).duplicate()
					var new_arr: Array = old_arr.duplicate()
					new_arr[idx] = new_text
					_undo_redo.create_action("Edit %s item" % property)
					_undo_redo.add_do_property(_character, property, new_arr)
					_undo_redo.add_undo_property(_character, property, old_arr)
					_undo_redo.add_do_method(_character, "emit_changed")
					_undo_redo.add_undo_method(_character, "emit_changed")
					_undo_redo.commit_action()
				)
				item_edit.focus_exited.connect(func() -> void:
					if _is_updating:
						return
					var current_arr: Array = _character.get(property)
					if idx < current_arr.size() and current_arr[idx] != item_edit.text:
						var old_arr: Array = current_arr.duplicate()
						var new_arr: Array = old_arr.duplicate()
						new_arr[idx] = item_edit.text
						_undo_redo.create_action("Edit %s item" % property)
						_undo_redo.add_do_property(_character, property, new_arr)
						_undo_redo.add_undo_property(_character, property, old_arr)
						_undo_redo.add_do_method(_character, "emit_changed")
						_undo_redo.add_undo_method(_character, "emit_changed")
						_undo_redo.commit_action()
				)
				item_hbox.add_child(item_edit)

				var del_btn := Button.new()
				del_btn.text = "×"
				del_btn.custom_minimum_size = Vector2(24, 24)
				del_btn.pressed.connect(func() -> void:
					if _is_updating:
						return
					var old_arr: Array = _character.get(property).duplicate()
					var new_arr: Array = old_arr.duplicate()
					new_arr.remove_at(idx)
					_undo_redo.create_action("Remove %s item" % property)
					_undo_redo.add_do_property(_character, property, new_arr)
					_undo_redo.add_undo_property(_character, property, old_arr)
					_undo_redo.add_do_method(_character, "emit_changed")
					_undo_redo.add_undo_method(_character, "emit_changed")
					_undo_redo.commit_action()
				)
				item_hbox.add_child(del_btn)

				items_container.add_child(item_hbox)

		add_btn.pressed.connect(func() -> void:
			if _is_updating:
				return
			var old_arr: Array = _character.get(property).duplicate()
			var new_arr: Array = old_arr.duplicate()
			new_arr.append("")
			_undo_redo.create_action("Add %s item" % property)
			_undo_redo.add_do_property(_character, property, new_arr)
			_undo_redo.add_undo_property(_character, property, old_arr)
			_undo_redo.add_do_method(_character, "emit_changed")
			_undo_redo.add_undo_method(_character, "emit_changed")
			_undo_redo.commit_action()
		)

		(rebuild_ref[0] as Callable).call()
		_property_controls[property] = rebuild_ref
		parent.add_child(container)


	func _add_dictionary_edit(parent: Control, label_text: String, property: String, key_hint: String, value_hint: String) -> void:
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

			var dict: Dictionary = _character.get(property)
			for key in dict.keys():
				var item_hbox := HBoxContainer.new()
				item_hbox.add_theme_constant_override("separation", 4)

				var key_edit := LineEdit.new()
				key_edit.text = key
				key_edit.placeholder_text = key_hint
				key_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				key_edit.custom_minimum_size.x = 80
				var current_key: String = key
				key_edit.focus_exited.connect(func() -> void:
					if _is_updating:
						return
					var new_key: String = key_edit.text
					if current_key == new_key:
						return
					var old_dict: Dictionary = _character.get(property).duplicate()
					var new_dict: Dictionary = old_dict.duplicate()
					var value: Variant = new_dict.get(current_key, "")
					new_dict.erase(current_key)
					new_dict[new_key] = value
					_undo_redo.create_action("Rename %s key" % property)
					_undo_redo.add_do_property(_character, property, new_dict)
					_undo_redo.add_undo_property(_character, property, old_dict)
					_undo_redo.add_do_method(_character, "emit_changed")
					_undo_redo.add_undo_method(_character, "emit_changed")
					_undo_redo.commit_action()
					current_key = new_key
				)
				item_hbox.add_child(key_edit)

				var value_edit := LineEdit.new()
				value_edit.text = dict[key]
				value_edit.placeholder_text = value_hint
				value_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				var k: String = key
				value_edit.focus_exited.connect(func() -> void:
					if _is_updating:
						return
					var new_value: String = value_edit.text
					var current_dict: Dictionary = _character.get(property)
					if current_dict.get(k, "") == new_value:
						return
					var old_dict: Dictionary = current_dict.duplicate()
					var new_dict: Dictionary = old_dict.duplicate()
					new_dict[k] = new_value
					_undo_redo.create_action("Edit %s value" % property)
					_undo_redo.add_do_property(_character, property, new_dict)
					_undo_redo.add_undo_property(_character, property, old_dict)
					_undo_redo.add_do_method(_character, "emit_changed")
					_undo_redo.add_undo_method(_character, "emit_changed")
					_undo_redo.commit_action()
				)
				item_hbox.add_child(value_edit)

				var del_btn := Button.new()
				del_btn.text = "×"
				del_btn.custom_minimum_size = Vector2(24, 24)
				del_btn.pressed.connect(func() -> void:
					if _is_updating:
						return
					var old_dict: Dictionary = _character.get(property).duplicate()
					var new_dict: Dictionary = old_dict.duplicate()
					new_dict.erase(k)
					_undo_redo.create_action("Remove %s entry" % property)
					_undo_redo.add_do_property(_character, property, new_dict)
					_undo_redo.add_undo_property(_character, property, old_dict)
					_undo_redo.add_do_method(_character, "emit_changed")
					_undo_redo.add_undo_method(_character, "emit_changed")
					_undo_redo.commit_action()
				)
				item_hbox.add_child(del_btn)

				items_container.add_child(item_hbox)

		add_btn.pressed.connect(func() -> void:
			if _is_updating:
				return
			var old_dict: Dictionary = _character.get(property).duplicate()
			var new_dict: Dictionary = old_dict.duplicate()
			new_dict["new_%d" % new_dict.size()] = ""
			_undo_redo.create_action("Add %s entry" % property)
			_undo_redo.add_do_property(_character, property, new_dict)
			_undo_redo.add_undo_property(_character, property, old_dict)
			_undo_redo.add_do_method(_character, "emit_changed")
			_undo_redo.add_undo_method(_character, "emit_changed")
			_undo_redo.commit_action()
		)

		(rebuild_ref[0] as Callable).call()
		_property_controls[property] = rebuild_ref
		parent.add_child(container)


	func _add_prompt_preview(parent: Control) -> void:
		# Title label
		var title := Label.new()
		title.text = "System Prompt"
		title.add_theme_color_override("font_color", WikiInspectorTheme.AI_PURPLE)
		title.add_theme_font_size_override("font_size", 11)
		parent.add_child(title)

		var preview_panel := PanelContainer.new()
		preview_panel.add_theme_stylebox_override("panel", WikiInspectorTheme.create_preview_style(WikiInspectorTheme.AI_PURPLE_DIM))

		var preview_label := RichTextLabel.new()
		preview_label.bbcode_enabled = true
		preview_label.fit_content = true
		preview_label.scroll_active = false
		preview_label.selection_enabled = true

		# Generate preview immediately
		var prompt := _character.to_system_prompt()
		prompt = prompt.replace("[", "[lb]").replace("]", "[rb]")
		preview_label.text = "[code]%s[/code]" % prompt

		preview_panel.add_child(preview_label)
		parent.add_child(preview_panel)

		# Store reference for updates
		_preview_label = preview_label


	func _update_token_display() -> void:
		if not _token_label:
			return

		var tokens := _character.estimate_tokens()
		var model_ctx := 4096
		var model_name := "unknown"

		var ai_service := AIService.get_singleton()
		if ai_service:
			var config := ai_service.get_current_config()
			if config:
				model_ctx = config.n_ctx
				model_name = config.display_name

		_token_label.text = WikiInspectorTheme.format_token_display(tokens, model_ctx, model_name)

		# Update preview if visible
		if _preview_label:
			var prompt := _character.to_system_prompt()
			prompt = prompt.replace("[", "[lb]").replace("]", "[rb]")
			_preview_label.text = "[code]%s[/code]" % prompt
