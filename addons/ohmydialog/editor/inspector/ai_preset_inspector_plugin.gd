@tool
class_name AIPresetInspectorPlugin
extends EditorInspectorPlugin
## Custom inspector plugin for AIPreset resources.
##
## Provides a wiki-styled editor panel with neural network aesthetic.
## Uses WikiInspectorTheme for consistent styling across all inspectors.


func _can_handle(object: Object) -> bool:
	return object is AIPreset


func _parse_begin(object: Object) -> void:
	var preset := object as AIPreset
	if not preset:
		return

	var panel := AIPresetEditorPanel.new(preset)
	add_custom_control(panel)


## Full editor panel for AIPreset with wiki-style aesthetics.
class AIPresetEditorPanel extends VBoxContainer:
	const ACCENT_COLOR := WikiInspectorTheme.AI_PURPLE

	var _preset: AIPreset
	var _sections: Dictionary = {}
	var _undo_redo: EditorUndoRedoManager

	func _init(preset: AIPreset) -> void:
		_preset = preset
		_undo_redo = EditorInterface.get_editor_undo_redo()

	func _ready() -> void:
		add_theme_constant_override("separation", 0)
		_setup_ui()

	func _setup_ui() -> void:
		# === MAIN HEADER ===
		var header := _create_main_header()
		add_child(header)

		# === SECTIONS ===
		var identity_content := _create_section("Identity", WikiInspectorTheme.ICON_DIAMOND_EMPTY, true)
		_add_line_edit(identity_content, "Name", "preset_name", "Preset name")
		_add_text_edit(identity_content, "Description", "description", "When to use this preset...", 60)
		_add_preset_type_picker(identity_content)

		var sampling_content := _create_section("Temperature & Sampling", WikiInspectorTheme.ICON_BOLT, true)
		_add_slider(sampling_content, "Temperature", "temperature", 0.0, 2.0, 0.05)
		_add_slider(sampling_content, "Top P", "top_p", 0.0, 1.0, 0.05)
		_add_spin_box_int(sampling_content, "Top K", "top_k", 0, 100)
		_add_slider(sampling_content, "Min P", "min_p", 0.0, 1.0, 0.01)
		_add_slider(sampling_content, "Typical P", "typical_p", 0.0, 1.0, 0.05)

		var output_content := _create_section("Output Control", WikiInspectorTheme.ICON_DIAMOND_DOT, true)
		_add_spin_box_int(output_content, "Max Tokens", "max_tokens", 1, 4096)
		_add_string_array_edit(output_content, "Stop Sequences", "stop_sequences", "\\n, </s>, etc.")

		var repetition_content := _create_section("Repetition Control", WikiInspectorTheme.ICON_CIRCLE_DOT, false)
		_add_slider(repetition_content, "Repeat Penalty", "repeat_penalty", 1.0, 2.0, 0.05)
		_add_spin_box_int(repetition_content, "Repeat Last N", "repeat_last_n", 0, 256)
		_add_slider(repetition_content, "Frequency Penalty", "frequency_penalty", 0.0, 2.0, 0.1)
		_add_slider(repetition_content, "Presence Penalty", "presence_penalty", 0.0, 2.0, 0.1)

		var context_content := _create_section("Context", WikiInspectorTheme.ICON_CIRCLE_TARGET, false)
		_add_spin_box_int(context_content, "Context Size", "context_size", 512, 32768)
		_add_spin_box_int(context_content, "Response Reserve", "response_reserve", 64, 1024)

		var advanced_content := _create_section("Advanced", WikiInspectorTheme.ICON_GEAR, false)
		_add_spin_box_int(advanced_content, "Seed", "seed", -1, 999999999)
		_add_spin_box_int(advanced_content, "Mirostat", "mirostat", 0, 2)
		_add_slider(advanced_content, "Mirostat Tau", "mirostat_tau", 0.0, 10.0, 0.1)
		_add_slider(advanced_content, "Mirostat Eta", "mirostat_eta", 0.0, 1.0, 0.01)


	func _create_main_header() -> PanelContainer:
		var header_panel := PanelContainer.new()
		header_panel.add_theme_stylebox_override("panel", WikiInspectorTheme.create_header_style(ACCENT_COLOR))

		var header_vbox := VBoxContainer.new()
		header_vbox.add_theme_constant_override("separation", 6)

		# Title with large icon
		var title_hbox := HBoxContainer.new()
		title_hbox.add_theme_constant_override("separation", 10)

		var icon_label := Label.new()
		icon_label.text = WikiInspectorTheme.ICON_BOLT
		icon_label.add_theme_font_size_override("font_size", 18)
		icon_label.add_theme_color_override("font_color", ACCENT_COLOR)
		title_hbox.add_child(icon_label)

		var title := RichTextLabel.new()
		title.bbcode_enabled = true
		title.fit_content = true
		title.scroll_active = false
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.text = "[b]AI PRESET[/b]"
		title.add_theme_font_size_override("normal_font_size", 13)
		title.add_theme_color_override("default_color", ACCENT_COLOR)
		title_hbox.add_child(title)

		header_vbox.add_child(title_hbox)

		# Preset summary
		var summary_label := RichTextLabel.new()
		summary_label.bbcode_enabled = true
		summary_label.fit_content = true
		summary_label.scroll_active = false
		_update_summary(summary_label)
		header_vbox.add_child(summary_label)

		header_panel.add_child(header_vbox)
		return header_panel


	func _update_summary(label: RichTextLabel) -> void:
		var type_name: String = AIPreset.PresetType.keys()[_preset.preset_type].capitalize()
		var type_color: Color = _get_preset_type_color(_preset.preset_type)
		label.text = "[color=#8b949e]%s[/color] | [color=%s]%s[/color] | [color=#8b949e]temp: %.2f[/color]" % [
			_preset.preset_name if not _preset.preset_name.is_empty() else "Unnamed",
			type_color.to_html(),
			type_name,
			_preset.temperature
		]


	func _get_preset_type_color(type: AIPreset.PresetType) -> Color:
		match type:
			AIPreset.PresetType.CREATIVE:
				return WikiInspectorTheme.AI_PINK
			AIPreset.PresetType.BALANCED:
				return WikiInspectorTheme.AI_GREEN
			AIPreset.PresetType.CONSISTENT:
				return WikiInspectorTheme.AI_CYAN
			AIPreset.PresetType.ROLEPLAY:
				return WikiInspectorTheme.AI_PURPLE
			AIPreset.PresetType.TECHNICAL:
				return WikiInspectorTheme.AI_ORANGE
			_:
				return WikiInspectorTheme.TEXT_SECONDARY


	func _create_section(title: String, icon: String, expanded: bool = true) -> VBoxContainer:
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
		arrow.add_theme_font_size_override("font_size", 10)
		arrow.add_theme_color_override("font_color", WikiInspectorTheme.AI_CYAN)
		arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header_hbox.add_child(arrow)

		# Large icon
		var icon_label := Label.new()
		icon_label.text = icon
		icon_label.add_theme_font_size_override("font_size", 14)
		icon_label.add_theme_color_override("font_color", ACCENT_COLOR)
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header_hbox.add_child(icon_label)

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
		label.custom_minimum_size.x = 120
		label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
		hbox.add_child(label)

		var edit := LineEdit.new()
		edit.text = _preset.get(property)
		edit.placeholder_text = placeholder
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit.text_submitted.connect(func(new_text: String):
			var old_value: String = _preset.get(property)
			if old_value == new_text:
				return
			_undo_redo.create_action("Change %s" % property)
			_undo_redo.add_do_property(_preset, property, new_text)
			_undo_redo.add_undo_property(_preset, property, old_value)
			_undo_redo.commit_action()
		)
		edit.focus_exited.connect(func():
			var new_text: String = edit.text
			var old_value: String = _preset.get(property)
			if old_value == new_text:
				return
			_undo_redo.create_action("Change %s" % property)
			_undo_redo.add_do_property(_preset, property, new_text)
			_undo_redo.add_undo_property(_preset, property, old_value)
			_undo_redo.commit_action()
		)
		hbox.add_child(edit)

		parent.add_child(hbox)


	func _add_text_edit(parent: Control, label_text: String, property: String, placeholder: String = "", min_height: int = 80) -> void:
		var label := Label.new()
		label.text = label_text
		label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
		parent.add_child(label)

		var edit := TextEdit.new()
		edit.text = _preset.get(property)
		edit.placeholder_text = placeholder
		edit.custom_minimum_size.y = min_height
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		var last_text: String = edit.text
		edit.focus_exited.connect(func():
			var new_text: String = edit.text
			if last_text == new_text:
				return
			_undo_redo.create_action("Change %s" % property)
			_undo_redo.add_do_property(_preset, property, new_text)
			_undo_redo.add_undo_property(_preset, property, last_text)
			_undo_redo.commit_action()
			last_text = new_text
		)
		parent.add_child(edit)


	func _add_preset_type_picker(parent: Control) -> void:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)

		var label := Label.new()
		label.text = "Preset Type"
		label.custom_minimum_size.x = 120
		label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
		hbox.add_child(label)

		var option := OptionButton.new()
		for type in AIPreset.PresetType.keys():
			option.add_item(type.capitalize().replace("_", " "))
		option.select(_preset.preset_type)
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option.item_selected.connect(func(index: int):
			var old_value: int = _preset.preset_type
			if old_value == index:
				return
			_undo_redo.create_action("Change preset_type")
			_undo_redo.add_do_property(_preset, "preset_type", index)
			_undo_redo.add_undo_property(_preset, "preset_type", old_value)
			_undo_redo.commit_action()
		)
		hbox.add_child(option)

		parent.add_child(hbox)


	func _add_spin_box_int(parent: Control, label_text: String, property: String, min_val: int, max_val: int) -> void:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)

		var label := Label.new()
		label.text = label_text
		label.custom_minimum_size.x = 120
		label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
		hbox.add_child(label)

		var spin := SpinBox.new()
		spin.min_value = min_val
		spin.max_value = max_val
		spin.step = 1
		spin.value = _preset.get(property)
		spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var last_value: int = int(spin.value)
		spin.get_line_edit().focus_exited.connect(func():
			var new_val: int = int(spin.value)
			if last_value == new_val:
				return
			_undo_redo.create_action("Change %s" % property)
			_undo_redo.add_do_property(_preset, property, new_val)
			_undo_redo.add_undo_property(_preset, property, last_value)
			_undo_redo.commit_action()
			last_value = new_val
		)
		hbox.add_child(spin)

		parent.add_child(hbox)


	func _add_slider(parent: Control, label_text: String, property: String, min_val: float, max_val: float, step: float) -> void:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)

		var label := Label.new()
		label.text = label_text
		label.custom_minimum_size.x = 120
		label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
		hbox.add_child(label)

		var slider := HSlider.new()
		slider.min_value = min_val
		slider.max_value = max_val
		slider.step = step
		slider.value = _preset.get(property)
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(slider)

		var value_label := Label.new()
		value_label.text = "%.2f" % _preset.get(property)
		value_label.custom_minimum_size.x = 50
		value_label.add_theme_color_override("font_color", ACCENT_COLOR)
		hbox.add_child(value_label)

		var last_value: float = slider.value
		slider.value_changed.connect(func(new_val: float):
			value_label.text = "%.2f" % new_val
		)
		slider.drag_ended.connect(func(value_changed_flag: bool):
			if not value_changed_flag:
				return
			var new_val: float = slider.value
			if last_value == new_val:
				return
			_undo_redo.create_action("Change %s" % property)
			_undo_redo.add_do_property(_preset, property, new_val)
			_undo_redo.add_undo_property(_preset, property, last_value)
			_undo_redo.commit_action()
			last_value = new_val
		)

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

			var arr: Array = _preset.get(property)
			for i in arr.size():
				var item_hbox := HBoxContainer.new()
				item_hbox.add_theme_constant_override("separation", 4)

				var item_edit := LineEdit.new()
				item_edit.text = arr[i]
				item_edit.placeholder_text = placeholder
				item_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				var idx := i
				item_edit.text_submitted.connect(func(new_text: String) -> void:
					var old_arr: Array = _preset.get(property).duplicate()
					var new_arr: Array = old_arr.duplicate()
					new_arr[idx] = new_text
					_undo_redo.create_action("Edit %s item" % property)
					_undo_redo.add_do_property(_preset, property, new_arr)
					_undo_redo.add_undo_property(_preset, property, old_arr)
					_undo_redo.commit_action()
				)
				item_edit.focus_exited.connect(func() -> void:
					var current_arr: Array = _preset.get(property)
					if idx < current_arr.size() and current_arr[idx] != item_edit.text:
						var old_arr: Array = current_arr.duplicate()
						var new_arr: Array = old_arr.duplicate()
						new_arr[idx] = item_edit.text
						_undo_redo.create_action("Edit %s item" % property)
						_undo_redo.add_do_property(_preset, property, new_arr)
						_undo_redo.add_undo_property(_preset, property, old_arr)
						_undo_redo.commit_action()
				)
				item_hbox.add_child(item_edit)

				var del_btn := Button.new()
				del_btn.text = "×"
				del_btn.custom_minimum_size = Vector2(24, 24)
				del_btn.pressed.connect(func() -> void:
					var old_arr: Array = _preset.get(property).duplicate()
					var new_arr: Array = old_arr.duplicate()
					new_arr.remove_at(idx)
					_undo_redo.create_action("Remove %s item" % property)
					_undo_redo.add_do_property(_preset, property, new_arr)
					_undo_redo.add_undo_property(_preset, property, old_arr)
					_undo_redo.commit_action()
					(rebuild_ref[0] as Callable).call()
				)
				item_hbox.add_child(del_btn)

				items_container.add_child(item_hbox)

		add_btn.pressed.connect(func() -> void:
			var old_arr: Array = _preset.get(property).duplicate()
			var new_arr: Array = old_arr.duplicate()
			new_arr.append("")
			_undo_redo.create_action("Add %s item" % property)
			_undo_redo.add_do_property(_preset, property, new_arr)
			_undo_redo.add_undo_property(_preset, property, old_arr)
			_undo_redo.commit_action()
			(rebuild_ref[0] as Callable).call()
		)

		(rebuild_ref[0] as Callable).call()
		parent.add_child(container)
