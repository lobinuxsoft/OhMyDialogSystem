@tool
class_name CharacterIdentityInspectorPlugin
extends EditorInspectorPlugin
## Custom inspector plugin for CharacterIdentity resources.
##
## Adds a wiki-styled header with token estimation above Godot's default inspector.


func _can_handle(object: Object) -> bool:
	return object is CharacterIdentity


func _parse_begin(object: Object) -> void:
	var character := object as CharacterIdentity
	if not character:
		return

	var header := CharacterIdentityHeader.new(character)
	add_custom_control(header)


## Decorative header panel with token estimation for CharacterIdentity.
class CharacterIdentityHeader extends PanelContainer:
	const ACCENT_COLOR := WikiInspectorTheme.AI_CYAN

	var _character: CharacterIdentity
	var _token_label: RichTextLabel

	func _init(character: CharacterIdentity) -> void:
		_character = character

	func _ready() -> void:
		add_theme_stylebox_override("panel", WikiInspectorTheme.create_header_style(ACCENT_COLOR))
		_setup_ui()
		_character.changed.connect(_update_tokens)

	func _exit_tree() -> void:
		if _character and _character.changed.is_connected(_update_tokens):
			_character.changed.disconnect(_update_tokens)

	func _setup_ui() -> void:
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)

		# Title row
		var title_hbox := HBoxContainer.new()
		title_hbox.add_theme_constant_override("separation", 10)

		var icon := Label.new()
		icon.text = WikiInspectorTheme.ICON_DIAMOND
		icon.add_theme_font_size_override("font_size", 18)
		icon.add_theme_color_override("font_color", ACCENT_COLOR)
		title_hbox.add_child(icon)

		var title := Label.new()
		title.text = "CHARACTER IDENTITY"
		title.add_theme_font_size_override("font_size", 13)
		title.add_theme_color_override("font_color", ACCENT_COLOR)
		title_hbox.add_child(title)

		vbox.add_child(title_hbox)

		# Token estimation
		_token_label = RichTextLabel.new()
		_token_label.bbcode_enabled = true
		_token_label.fit_content = true
		_token_label.scroll_active = false
		vbox.add_child(_token_label)

		add_child(vbox)
		_update_tokens()

	func _update_tokens() -> void:
		if not _token_label or not _character:
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
