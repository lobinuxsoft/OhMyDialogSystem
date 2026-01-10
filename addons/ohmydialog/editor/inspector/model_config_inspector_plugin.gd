@tool
class_name ModelConfigInspectorPlugin
extends EditorInspectorPlugin
## Custom inspector plugin for ModelConfig resources.
##
## Provides a wiki-styled editor panel with neural network aesthetic.
## Uses WikiInspectorTheme for consistent styling across all inspectors.


func _can_handle(object: Object) -> bool:
	return object is ModelConfig


func _parse_begin(object: Object) -> void:
	var config := object as ModelConfig
	if not config:
		return

	var panel := ModelConfigEditorPanel.new(config)
	add_custom_control(panel)


## Full editor panel for ModelConfig with wiki-style aesthetics.
class ModelConfigEditorPanel extends VBoxContainer:
	const ACCENT_COLOR := WikiInspectorTheme.AI_ORANGE

	var _config: ModelConfig
	var _sections: Dictionary = {}

	func _init(config: ModelConfig) -> void:
		_config = config

	func _ready() -> void:
		add_theme_constant_override("separation", 0)
		_setup_ui()

	func _setup_ui() -> void:
		# === MAIN HEADER ===
		var header := _create_main_header()
		add_child(header)

		# === SECTIONS ===
		var info_content := _create_section("Model Info", WikiInspectorTheme.ICON_DIAMOND_EMPTY, true)
		_add_line_edit(info_content, "ID", "id", "model-id")
		_add_line_edit(info_content, "Display Name", "display_name", "Model Name")
		_add_text_edit(info_content, "Description", "description", "Model description...", 60)
		_add_file_picker(info_content, "Model Path", "model_path", "*.gguf")
		_add_line_edit(info_content, "Download URL", "download_url", "https://huggingface.co/...")
		_add_spin_box(info_content, "Size (MB)", "size_mb", 0.0, 50000.0, 0.1)
		_add_check_box(info_content, "Is Custom", "is_custom")
		_add_check_box(info_content, "Include in Export", "include_in_export")

		var sampling_content := _create_section("Default Sampling", WikiInspectorTheme.ICON_DIAMOND_DOT, true)
		_add_slider(sampling_content, "Temperature", "default_temperature", 0.0, 2.0, 0.01)
		_add_slider(sampling_content, "Top P", "default_top_p", 0.0, 1.0, 0.01)
		_add_spin_box_int(sampling_content, "Top K", "default_top_k", 0, 100)
		_add_spin_box_int(sampling_content, "Max Tokens", "default_max_tokens", 1, 4096)
		_add_slider(sampling_content, "Repeat Penalty", "default_repeat_penalty", 1.0, 2.0, 0.01)
		_add_slider(sampling_content, "Min P", "default_min_p", 0.0, 1.0, 0.01)

		var context_content := _create_section("Context Settings", WikiInspectorTheme.ICON_GEAR, false)
		_add_spin_box_int(context_content, "Context Size", "n_ctx", 512, 131072)
		_add_spin_box_int(context_content, "GPU Layers", "n_gpu_layers", 0, 999)
		_add_spin_box_int(context_content, "Batch Size", "n_batch", 1, 4096)

		var status_content := _create_section("Status", WikiInspectorTheme.ICON_CIRCLE_DOT, false)
		_add_status_display(status_content)


	func _create_main_header() -> PanelContainer:
		var header_panel := PanelContainer.new()
		header_panel.add_theme_stylebox_override("panel", WikiInspectorTheme.create_header_style(ACCENT_COLOR))

		var header_vbox := VBoxContainer.new()
		header_vbox.add_theme_constant_override("separation", 6)

		# Title with large icon
		var title_hbox := HBoxContainer.new()
		title_hbox.add_theme_constant_override("separation", 10)

		var icon_label := Label.new()
		icon_label.text = WikiInspectorTheme.ICON_GEAR
		icon_label.add_theme_font_size_override("font_size", 18)
		icon_label.add_theme_color_override("font_color", ACCENT_COLOR)
		title_hbox.add_child(icon_label)

		var title := RichTextLabel.new()
		title.bbcode_enabled = true
		title.fit_content = true
		title.scroll_active = false
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.text = "[b]MODEL CONFIG[/b]"
		title.add_theme_font_size_override("normal_font_size", 13)
		title.add_theme_color_override("default_color", ACCENT_COLOR)
		title_hbox.add_child(title)

		header_vbox.add_child(title_hbox)

		# Model summary
		var summary_label := RichTextLabel.new()
		summary_label.bbcode_enabled = true
		summary_label.fit_content = true
		summary_label.scroll_active = false
		_update_summary(summary_label)
		header_vbox.add_child(summary_label)

		header_panel.add_child(header_vbox)
		return header_panel


	func _update_summary(label: RichTextLabel) -> void:
		var status := "downloaded" if _config.is_downloaded() else "not downloaded"
		var status_color := WikiInspectorTheme.AI_GREEN if _config.is_downloaded() else WikiInspectorTheme.AI_RED
		label.text = "[color=#8b949e]%s[/color] | [color=%s]%s[/color] | [color=#8b949e]%d ctx[/color]" % [
			_config.display_name if not _config.display_name.is_empty() else "Unnamed",
			status_color.to_html(),
			status,
			_config.n_ctx
		]


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
		arrow.add_theme_color_override("font_color", WikiInspectorTheme.AI_PURPLE)
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
		label.custom_minimum_size.x = 100
		label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
		hbox.add_child(label)

		var edit := LineEdit.new()
		edit.text = _config.get(property)
		edit.placeholder_text = placeholder
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit.text_changed.connect(func(new_text: String):
			_config.set(property, new_text)
			_config.emit_changed()
		)
		hbox.add_child(edit)

		parent.add_child(hbox)


	func _add_text_edit(parent: Control, label_text: String, property: String, placeholder: String = "", min_height: int = 80) -> void:
		var label := Label.new()
		label.text = label_text
		label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
		parent.add_child(label)

		var edit := TextEdit.new()
		edit.text = _config.get(property)
		edit.placeholder_text = placeholder
		edit.custom_minimum_size.y = min_height
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		edit.text_changed.connect(func():
			_config.set(property, edit.text)
			_config.emit_changed()
		)
		parent.add_child(edit)


	func _add_file_picker(parent: Control, label_text: String, property: String, filter: String) -> void:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)

		var label := Label.new()
		label.text = label_text
		label.custom_minimum_size.x = 100
		label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
		hbox.add_child(label)

		var edit := LineEdit.new()
		edit.text = _config.get(property)
		edit.placeholder_text = "res://models/..."
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit.text_changed.connect(func(new_text: String):
			_config.set(property, new_text)
			_config.emit_changed()
		)
		hbox.add_child(edit)

		var btn := Button.new()
		btn.text = "..."
		btn.custom_minimum_size = Vector2(30, 0)
		btn.pressed.connect(func():
			var dialog := EditorFileDialog.new()
			dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
			dialog.add_filter(filter)
			dialog.file_selected.connect(func(path: String):
				edit.text = path
				_config.set(property, path)
				_config.emit_changed()
				dialog.queue_free()
			)
			dialog.canceled.connect(func():
				dialog.queue_free()
			)
			EditorInterface.get_base_control().add_child(dialog)
			dialog.popup_centered_ratio(0.6)
		)
		hbox.add_child(btn)

		parent.add_child(hbox)


	func _add_spin_box(parent: Control, label_text: String, property: String, min_val: float, max_val: float, step: float) -> void:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)

		var label := Label.new()
		label.text = label_text
		label.custom_minimum_size.x = 100
		label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
		hbox.add_child(label)

		var spin := SpinBox.new()
		spin.min_value = min_val
		spin.max_value = max_val
		spin.step = step
		spin.value = _config.get(property)
		spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spin.value_changed.connect(func(new_val: float):
			_config.set(property, new_val)
			_config.emit_changed()
		)
		hbox.add_child(spin)

		parent.add_child(hbox)


	func _add_spin_box_int(parent: Control, label_text: String, property: String, min_val: int, max_val: int) -> void:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)

		var label := Label.new()
		label.text = label_text
		label.custom_minimum_size.x = 100
		label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
		hbox.add_child(label)

		var spin := SpinBox.new()
		spin.min_value = min_val
		spin.max_value = max_val
		spin.step = 1
		spin.value = _config.get(property)
		spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spin.value_changed.connect(func(new_val: float):
			_config.set(property, int(new_val))
			_config.emit_changed()
		)
		hbox.add_child(spin)

		parent.add_child(hbox)


	func _add_slider(parent: Control, label_text: String, property: String, min_val: float, max_val: float, step: float) -> void:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)

		var label := Label.new()
		label.text = label_text
		label.custom_minimum_size.x = 100
		label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
		hbox.add_child(label)

		var slider := HSlider.new()
		slider.min_value = min_val
		slider.max_value = max_val
		slider.step = step
		slider.value = _config.get(property)
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(slider)

		var value_label := Label.new()
		value_label.text = "%.2f" % _config.get(property)
		value_label.custom_minimum_size.x = 50
		value_label.add_theme_color_override("font_color", ACCENT_COLOR)
		hbox.add_child(value_label)

		slider.value_changed.connect(func(new_val: float):
			_config.set(property, new_val)
			_config.emit_changed()
			value_label.text = "%.2f" % new_val
		)

		parent.add_child(hbox)


	func _add_check_box(parent: Control, label_text: String, property: String) -> void:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)

		var label := Label.new()
		label.text = label_text
		label.custom_minimum_size.x = 100
		label.add_theme_color_override("font_color", WikiInspectorTheme.TEXT_SECONDARY)
		hbox.add_child(label)

		var check := CheckBox.new()
		check.button_pressed = _config.get(property)
		check.toggled.connect(func(pressed: bool):
			_config.set(property, pressed)
			_config.emit_changed()
		)
		hbox.add_child(check)

		parent.add_child(hbox)


	func _add_status_display(parent: Control) -> void:
		var status_panel := PanelContainer.new()
		status_panel.add_theme_stylebox_override("panel", WikiInspectorTheme.create_preview_style(WikiInspectorTheme.AI_CYAN_DIM))

		var status_label := RichTextLabel.new()
		status_label.bbcode_enabled = true
		status_label.fit_content = true
		status_label.scroll_active = false

		var downloaded := _config.is_downloaded()
		var status_text := "[b]Status:[/b] "
		if downloaded:
			status_text += "[color=#10b981]Downloaded[/color]\n"
		else:
			status_text += "[color=#ef4444]Not Downloaded[/color]\n"

		status_text += "[b]Effective Path:[/b] [color=#8b949e]%s[/color]\n" % _config.get_effective_path()
		status_text += "[b]Filename:[/b] [color=#8b949e]%s[/color]" % _config.get_filename()

		status_label.text = status_text
		status_panel.add_child(status_label)
		parent.add_child(status_panel)
