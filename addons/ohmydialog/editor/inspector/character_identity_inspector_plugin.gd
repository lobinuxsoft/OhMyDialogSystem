@tool
class_name CharacterIdentityInspectorPlugin
extends EditorInspectorPlugin
## Custom inspector plugin for CharacterIdentity resources.
##
## Adds a visual summary panel showing character info and token estimation.


func _can_handle(object: Object) -> bool:
	return object is CharacterIdentity


func _parse_begin(object: Object) -> void:
	var character := object as CharacterIdentity
	if not character:
		return

	var panel := CharacterIdentitySummaryPanel.new(character)
	add_custom_control(panel)


## Visual summary panel for CharacterIdentity.
class CharacterIdentitySummaryPanel extends VBoxContainer:
	var _character: CharacterIdentity
	var _info_label: RichTextLabel
	var _preview_button: Button
	var _preview_container: VBoxContainer
	var _preview_label: RichTextLabel
	var _preview_visible: bool = false


	func _init(character: CharacterIdentity) -> void:
		_character = character


	func _ready() -> void:
		add_theme_constant_override("separation", 8)
		_setup_ui()
		_update_info()

		# Listen for changes
		if _character.changed.is_connected(_update_info):
			return
		_character.changed.connect(_update_info)


	func _setup_ui() -> void:
		# Main info panel
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", _create_panel_style())

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)

		# Header
		var header := Label.new()
		header.text = "Character Summary"
		header.add_theme_font_size_override("font_size", 14)
		header.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
		vbox.add_child(header)

		# Info label
		_info_label = RichTextLabel.new()
		_info_label.bbcode_enabled = true
		_info_label.fit_content = true
		_info_label.scroll_active = false
		_info_label.selection_enabled = true
		vbox.add_child(_info_label)

		panel.add_child(vbox)
		add_child(panel)

		# Preview button
		_preview_button = Button.new()
		_preview_button.text = "Show System Prompt Preview"
		_preview_button.pressed.connect(_toggle_preview)
		add_child(_preview_button)

		# Preview container (hidden by default)
		_preview_container = VBoxContainer.new()
		_preview_container.visible = false

		var preview_panel := PanelContainer.new()
		preview_panel.add_theme_stylebox_override("panel", _create_preview_style())

		_preview_label = RichTextLabel.new()
		_preview_label.bbcode_enabled = true
		_preview_label.fit_content = true
		_preview_label.scroll_active = false
		_preview_label.selection_enabled = true
		_preview_label.custom_minimum_size.y = 100

		preview_panel.add_child(_preview_label)
		_preview_container.add_child(preview_panel)
		add_child(_preview_container)

		# Separator
		add_child(HSeparator.new())


	func _create_panel_style() -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.18, 0.25, 0.9)
		style.border_color = Color(0.3, 0.5, 0.8, 0.5)
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		style.set_content_margin_all(12)
		return style


	func _create_preview_style() -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.12, 0.18, 0.9)
		style.border_color = Color(0.25, 0.35, 0.5, 0.5)
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		style.set_content_margin_all(8)
		return style


	func _update_info() -> void:
		if not _info_label or not _character:
			return

		var tokens := _character.estimate_tokens()
		var style_name: String = CharacterIdentity.SpeechStyle.keys()[_character.speech_style]
		style_name = style_name.to_lower().replace("_", " ")

		var text := ""

		# Name and ID
		if not _character.character_name.is_empty():
			text += "[b]%s[/b]" % _character.character_name
			if not _character.character_id.is_empty():
				text += " [color=#888](%s)[/color]" % _character.character_id
			text += "\n"

		# Speech style
		text += "[color=#aaa]Style:[/color] %s\n" % style_name.capitalize()

		# Knowledge count
		if not _character.knowledge.is_empty():
			text += "[color=#aaa]Knowledge:[/color] %d topics\n" % _character.knowledge.size()

		# Secrets count
		if not _character.secrets.is_empty():
			text += "[color=#aaa]Secrets:[/color] %d hidden\n" % _character.secrets.size()

		# Goals count
		if not _character.goals.is_empty():
			text += "[color=#aaa]Goals:[/color] %d defined\n" % _character.goals.size()

		# Relationships count
		if not _character.relationships.is_empty():
			text += "[color=#aaa]Relationships:[/color] %d characters\n" % _character.relationships.size()

		# Example dialogues count
		if not _character.example_dialogues.is_empty():
			text += "[color=#aaa]Examples:[/color] %d lines\n" % _character.example_dialogues.size()

		# Token estimation
		text += "\n"
		text += _get_token_status(tokens)

		_info_label.text = text

		# Update preview if visible
		if _preview_visible:
			_update_preview()


	func _get_token_status(tokens: int) -> String:
		var model_ctx := 4096
		var model_name := "unknown"

		var ai_service := AIService.get_singleton()
		if ai_service:
			var config := ai_service.get_current_config()
			if config:
				model_ctx = config.n_ctx
				model_name = config.display_name

		var usage_percent := (tokens * 100.0) / model_ctx

		var text := "[b]Token Estimate: ~%d[/b]\n" % tokens

		if tokens > model_ctx * 0.5:
			text += "[color=#ff6b6b]WARNING: Uses %.0f%% of model context (%d tokens)!\n" % [usage_percent, model_ctx]
			text += "Consider reducing personality/background detail.[/color]"
		elif tokens > model_ctx * 0.3:
			text += "[color=#ffd93d]CAUTION: Uses %.0f%% of model context.\n" % usage_percent
			text += "Model: %s (%d tokens)[/color]" % [model_name, model_ctx]
		else:
			text += "[color=#6bcb77]OK: %.0f%% of context\n" % usage_percent
			text += "Model: %s (%d tokens)[/color]" % [model_name, model_ctx]

		return text


	func _toggle_preview() -> void:
		_preview_visible = not _preview_visible
		_preview_container.visible = _preview_visible
		_preview_button.text = "Hide System Prompt Preview" if _preview_visible else "Show System Prompt Preview"

		if _preview_visible:
			_update_preview()


	func _update_preview() -> void:
		if not _preview_label or not _character:
			return

		var prompt := _character.to_system_prompt()
		# Escape BBCode and show as monospace
		prompt = prompt.replace("[", "[lb]").replace("]", "[rb]")
		_preview_label.text = "[code]%s[/code]" % prompt
