@tool
class_name CharacterIdentityInspectorPlugin
extends EditorInspectorPlugin
## Custom inspector plugin for CharacterIdentity resources.
##
## Replaces default property editors with a custom panel showing
## character info, token estimation, and organized editing fields.

# Wiki color palette
const COLOR_AI_BLUE := Color("#3b82f6")
const COLOR_AI_BLUE_DIM := Color("#2563eb")
const COLOR_AI_BLUE_DARK := Color("#1e3a5f")
const COLOR_BG_DARK := Color("#1a1d24")
const COLOR_BG_SECTION := Color("#252830")
const COLOR_TEXT_DIM := Color("#9ca3af")
const COLOR_TEXT := Color("#e5e7eb")

## Properties to hide (we show them in custom panel instead).
const HIDDEN_PROPERTIES: Array[String] = [
	"character_id", "character_name", "portrait",
	"personality", "background", "speech_style", "speech_patterns",
	"knowledge", "secrets",
	"goals", "fears",
	"relationships",
	"example_dialogues"
]


func _can_handle(object: Object) -> bool:
	return object is CharacterIdentity


func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	if name in HIDDEN_PROPERTIES:
		return true
	return false


func _parse_begin(object: Object) -> void:
	var character := object as CharacterIdentity
	if not character:
		return

	var panel := CharacterIdentityEditorPanel.new(character)
	add_custom_control(panel)


## Full editor panel for CharacterIdentity.
class CharacterIdentityEditorPanel extends VBoxContainer:
	var _character: CharacterIdentity
	var _token_label: RichTextLabel
	var _sections: Dictionary = {}

	func _init(character: CharacterIdentity) -> void:
		_character = character

	func _ready() -> void:
		add_theme_constant_override("separation", 0)
		_setup_ui()

	func _setup_ui() -> void:
		# === MAIN HEADER ===
		var header_panel := PanelContainer.new()
		header_panel.add_theme_stylebox_override("panel", _create_main_header_style())

		var header_vbox := VBoxContainer.new()
		header_vbox.add_theme_constant_override("separation", 4)

		var title := Label.new()
		title.text = "Character Identity"
		title.add_theme_font_size_override("font_size", 13)
		title.add_theme_color_override("font_color", CharacterIdentityInspectorPlugin.COLOR_AI_BLUE)
		header_vbox.add_child(title)

		_token_label = RichTextLabel.new()
		_token_label.bbcode_enabled = true
		_token_label.fit_content = true
		_token_label.scroll_active = false
		header_vbox.add_child(_token_label)

		header_panel.add_child(header_vbox)
		add_child(header_panel)

		# === SECTIONS ===
		var identity_content := _create_section("Identity", true)
		_add_line_edit(identity_content, "ID", "character_id", "unique_id")
		_add_line_edit(identity_content, "Name", "character_name", "Display Name")
		_add_resource_picker(identity_content, "Portrait", "portrait", "Texture2D")

		var personality_content := _create_section("Personality", true)
		_add_text_edit(personality_content, "Personality", "personality", "Core traits and behavior...", 80)
		_add_text_edit(personality_content, "Background", "background", "History and origin...", 80)
		_add_speech_style_picker(personality_content)
		_add_text_edit(personality_content, "Speech Patterns", "speech_patterns", "Verbal tics, catchphrases...", 60)

		var knowledge_content := _create_section("Knowledge & Secrets", true)
		_add_string_array_edit(knowledge_content, "Knowledge", "knowledge", "Topic...")
		_add_string_array_edit(knowledge_content, "Secrets", "secrets", "Secret...")

		var motivation_content := _create_section("Motivation", false)
		_add_string_array_edit(motivation_content, "Goals", "goals", "Goal...")
		_add_string_array_edit(motivation_content, "Fears", "fears", "Fear...")

		var relationships_content := _create_section("Relationships", false)
		_add_dictionary_edit(relationships_content, "Relationships", "relationships", "character_id", "relationship")

		var examples_content := _create_section("Examples", false)
		_add_string_array_edit(examples_content, "Example Dialogues", "example_dialogues", "Example line...")

		var preview_content := _create_section("Preview", false)
		_add_prompt_preview(preview_content)

		_update_token_display()


	func _create_main_header_style() -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = CharacterIdentityInspectorPlugin.COLOR_AI_BLUE_DARK
		style.border_color = CharacterIdentityInspectorPlugin.COLOR_AI_BLUE
		style.set_border_width_all(1)
		style.border_width_left = 3
		style.set_corner_radius_all(2)
		style.set_content_margin_all(10)
		return style


	func _create_section_header_style(is_hovered: bool = false) -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = CharacterIdentityInspectorPlugin.COLOR_BG_SECTION if not is_hovered else CharacterIdentityInspectorPlugin.COLOR_BG_SECTION.lightened(0.1)
		style.set_corner_radius_all(0)
		style.set_content_margin_all(0)
		style.content_margin_left = 4
		style.content_margin_right = 4
		style.content_margin_top = 6
		style.content_margin_bottom = 6
		return style


	func _create_section(title: String, expanded: bool = true) -> VBoxContainer:
		var section_container := VBoxContainer.new()
		section_container.add_theme_constant_override("separation", 0)

		# Section header (looks like Godot's foldable sections)
		var header_panel := PanelContainer.new()
		header_panel.add_theme_stylebox_override("panel", _create_section_header_style())

		var header_hbox := HBoxContainer.new()
		header_hbox.add_theme_constant_override("separation", 6)

		# Arrow indicator
		var arrow := Label.new()
		arrow.text = "▼" if expanded else "▶"
		arrow.add_theme_font_size_override("font_size", 10)
		arrow.add_theme_color_override("font_color", CharacterIdentityInspectorPlugin.COLOR_TEXT_DIM)
		header_hbox.add_child(arrow)

		# Title
		var title_label := Label.new()
		title_label.text = title
		title_label.add_theme_font_size_override("font_size", 13)
		title_label.add_theme_color_override("font_color", CharacterIdentityInspectorPlugin.COLOR_TEXT)
		header_hbox.add_child(title_label)

		header_panel.add_child(header_hbox)
		section_container.add_child(header_panel)

		# Content container with indent
		var content_panel := PanelContainer.new()
		var content_style := StyleBoxFlat.new()
		content_style.bg_color = CharacterIdentityInspectorPlugin.COLOR_BG_DARK
		content_style.set_content_margin_all(0)
		content_style.content_margin_left = 16
		content_style.content_margin_right = 8
		content_style.content_margin_top = 8
		content_style.content_margin_bottom = 8
		content_panel.add_theme_stylebox_override("panel", content_style)
		content_panel.visible = expanded

		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 8)
		content_panel.add_child(content)
		section_container.add_child(content_panel)

		_sections[title] = {
			"arrow": arrow,
			"content_panel": content_panel,
			"header_panel": header_panel,
			"expanded": expanded
		}

		# Make header clickable
		header_panel.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				var section: Dictionary = _sections[title]
				section.expanded = not section.expanded
				section.content_panel.visible = section.expanded
				section.arrow.text = "▼" if section.expanded else "▶"
		)

		# Hover effect
		header_panel.mouse_entered.connect(func():
			header_panel.add_theme_stylebox_override("panel", _create_section_header_style(true))
		)
		header_panel.mouse_exited.connect(func():
			header_panel.add_theme_stylebox_override("panel", _create_section_header_style(false))
		)

		add_child(section_container)
		return content


	func _add_line_edit(parent: Control, label_text: String, property: String, placeholder: String = "") -> void:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)

		var label := Label.new()
		label.text = label_text
		label.custom_minimum_size.x = 90
		label.add_theme_color_override("font_color", CharacterIdentityInspectorPlugin.COLOR_TEXT_DIM)
		hbox.add_child(label)

		var edit := LineEdit.new()
		edit.text = _character.get(property)
		edit.placeholder_text = placeholder
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit.text_changed.connect(func(new_text: String):
			_character.set(property, new_text)
			_character.emit_changed()
			_update_token_display()
		)
		hbox.add_child(edit)

		parent.add_child(hbox)


	func _add_text_edit(parent: Control, label_text: String, property: String, placeholder: String = "", min_height: int = 80) -> void:
		var label := Label.new()
		label.text = label_text
		label.add_theme_color_override("font_color", CharacterIdentityInspectorPlugin.COLOR_TEXT_DIM)
		parent.add_child(label)

		var edit := TextEdit.new()
		edit.text = _character.get(property)
		edit.placeholder_text = placeholder
		edit.custom_minimum_size.y = min_height
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		edit.text_changed.connect(func():
			_character.set(property, edit.text)
			_character.emit_changed()
			_update_token_display()
		)
		parent.add_child(edit)


	func _add_speech_style_picker(parent: Control) -> void:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)

		var label := Label.new()
		label.text = "Speech Style"
		label.custom_minimum_size.x = 90
		label.add_theme_color_override("font_color", CharacterIdentityInspectorPlugin.COLOR_TEXT_DIM)
		hbox.add_child(label)

		var option := OptionButton.new()
		for style in CharacterIdentity.SpeechStyle.keys():
			option.add_item(style.capitalize().replace("_", " "))
		option.select(_character.speech_style)
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option.item_selected.connect(func(index: int):
			_character.speech_style = index as CharacterIdentity.SpeechStyle
			_character.emit_changed()
			_update_token_display()
		)
		hbox.add_child(option)

		parent.add_child(hbox)


	func _add_resource_picker(parent: Control, label_text: String, property: String, base_type: String) -> void:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)

		var label := Label.new()
		label.text = label_text
		label.custom_minimum_size.x = 90
		label.add_theme_color_override("font_color", CharacterIdentityInspectorPlugin.COLOR_TEXT_DIM)
		hbox.add_child(label)

		var picker := EditorResourcePicker.new()
		picker.base_type = base_type
		picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		picker.edited_resource = _character.get(property)
		picker.resource_changed.connect(func(res: Resource):
			_character.set(property, res)
			_character.emit_changed()
		)
		hbox.add_child(picker)

		parent.add_child(hbox)


	func _add_string_array_edit(parent: Control, label_text: String, property: String, placeholder: String) -> void:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 4)

		var header := HBoxContainer.new()
		var label := Label.new()
		label.text = label_text
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_color_override("font_color", CharacterIdentityInspectorPlugin.COLOR_TEXT_DIM)
		header.add_child(label)

		var add_btn := Button.new()
		add_btn.text = "+"
		add_btn.custom_minimum_size = Vector2(24, 24)
		header.add_child(add_btn)
		container.add_child(header)

		var items_container := VBoxContainer.new()
		items_container.add_theme_constant_override("separation", 2)
		container.add_child(items_container)

		var rebuild_list: Callable
		rebuild_list = func():
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
				item_edit.text_changed.connect(func(new_text: String):
					var current_arr: Array = _character.get(property)
					current_arr[idx] = new_text
					_character.emit_changed()
					_update_token_display()
				)
				item_hbox.add_child(item_edit)

				var del_btn := Button.new()
				del_btn.text = "×"
				del_btn.custom_minimum_size = Vector2(24, 24)
				del_btn.pressed.connect(func():
					var current_arr: Array = _character.get(property)
					current_arr.remove_at(idx)
					_character.emit_changed()
					_update_token_display()
					rebuild_list.call()
				)
				item_hbox.add_child(del_btn)

				items_container.add_child(item_hbox)

		add_btn.pressed.connect(func():
			var arr: Array = _character.get(property)
			arr.append("")
			_character.emit_changed()
			rebuild_list.call()
		)

		rebuild_list.call()
		parent.add_child(container)


	func _add_dictionary_edit(parent: Control, label_text: String, property: String, key_hint: String, value_hint: String) -> void:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 4)

		var header := HBoxContainer.new()
		var label := Label.new()
		label.text = label_text
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_color_override("font_color", CharacterIdentityInspectorPlugin.COLOR_TEXT_DIM)
		header.add_child(label)

		var add_btn := Button.new()
		add_btn.text = "+"
		add_btn.custom_minimum_size = Vector2(24, 24)
		header.add_child(add_btn)
		container.add_child(header)

		var items_container := VBoxContainer.new()
		items_container.add_theme_constant_override("separation", 2)
		container.add_child(items_container)

		var rebuild_list: Callable
		rebuild_list = func():
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
				var old_key: String = key
				key_edit.text_changed.connect(func(new_key: String):
					var current_dict: Dictionary = _character.get(property)
					var value = current_dict.get(old_key, "")
					current_dict.erase(old_key)
					current_dict[new_key] = value
					old_key = new_key
					_character.emit_changed()
					_update_token_display()
				)
				item_hbox.add_child(key_edit)

				var value_edit := LineEdit.new()
				value_edit.text = dict[key]
				value_edit.placeholder_text = value_hint
				value_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				var k: String = key
				value_edit.text_changed.connect(func(new_value: String):
					var current_dict: Dictionary = _character.get(property)
					current_dict[k] = new_value
					_character.emit_changed()
					_update_token_display()
				)
				item_hbox.add_child(value_edit)

				var del_btn := Button.new()
				del_btn.text = "×"
				del_btn.custom_minimum_size = Vector2(24, 24)
				del_btn.pressed.connect(func():
					var current_dict: Dictionary = _character.get(property)
					current_dict.erase(k)
					_character.emit_changed()
					_update_token_display()
					rebuild_list.call()
				)
				item_hbox.add_child(del_btn)

				items_container.add_child(item_hbox)

		add_btn.pressed.connect(func():
			var dict: Dictionary = _character.get(property)
			dict["new_%d" % dict.size()] = ""
			_character.emit_changed()
			rebuild_list.call()
		)

		rebuild_list.call()
		parent.add_child(container)


	func _add_prompt_preview(parent: Control) -> void:
		var btn := Button.new()
		btn.text = "Show System Prompt"
		parent.add_child(btn)

		var preview_panel := PanelContainer.new()
		preview_panel.visible = false
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.09, 0.12)
		style.set_border_width_all(1)
		style.border_color = CharacterIdentityInspectorPlugin.COLOR_AI_BLUE_DIM
		style.set_corner_radius_all(4)
		style.set_content_margin_all(8)
		preview_panel.add_theme_stylebox_override("panel", style)

		var preview_label := RichTextLabel.new()
		preview_label.bbcode_enabled = true
		preview_label.fit_content = true
		preview_label.scroll_active = false
		preview_label.selection_enabled = true
		preview_panel.add_child(preview_label)
		parent.add_child(preview_panel)

		btn.pressed.connect(func():
			preview_panel.visible = not preview_panel.visible
			btn.text = "Hide System Prompt" if preview_panel.visible else "Show System Prompt"
			if preview_panel.visible:
				var prompt := _character.to_system_prompt()
				prompt = prompt.replace("[", "[lb]").replace("]", "[rb]")
				preview_label.text = "[code]%s[/code]" % prompt
		)


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

		var usage_percent := (tokens * 100.0) / model_ctx
		var text := "[b]~%d tokens[/b] " % tokens

		if tokens > model_ctx * 0.5:
			text += "[color=#ef4444](%.0f%% - WARNING)[/color]" % usage_percent
		elif tokens > model_ctx * 0.3:
			text += "[color=#eab308](%.0f%% - caution)[/color]" % usage_percent
		else:
			text += "[color=#10b981](%.0f%% OK)[/color]" % usage_percent

		text += "\n[color=#6b7280]Model: %s (%d ctx)[/color]" % [model_name, model_ctx]

		_token_label.text = text
