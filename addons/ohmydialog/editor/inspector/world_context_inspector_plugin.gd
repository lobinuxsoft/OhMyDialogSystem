@tool
class_name WorldContextInspectorPlugin
extends EditorInspectorPlugin
## Custom inspector plugin for WorldContext resources.
##
## Adds a wiki-styled header with token estimation above Godot's default inspector.


func _can_handle(object: Object) -> bool:
	return object is WorldContext


func _parse_begin(object: Object) -> void:
	var world := object as WorldContext
	if not world:
		return

	var header := WorldContextHeader.new(world)
	add_custom_control(header)


## Decorative header panel with token estimation for WorldContext.
class WorldContextHeader extends PanelContainer:
	const ACCENT_COLOR := WikiInspectorTheme.AI_GREEN

	var _world: WorldContext
	var _token_label: RichTextLabel

	func _init(world: WorldContext) -> void:
		_world = world

	func _ready() -> void:
		add_theme_stylebox_override("panel", WikiInspectorTheme.create_header_style(ACCENT_COLOR))
		_setup_ui()
		_world.changed.connect(_update_tokens)

	func _exit_tree() -> void:
		if _world and _world.changed.is_connected(_update_tokens):
			_world.changed.disconnect(_update_tokens)

	func _setup_ui() -> void:
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)

		# Title row
		var title_hbox := HBoxContainer.new()
		title_hbox.add_theme_constant_override("separation", 10)

		var icon := Label.new()
		icon.text = WikiInspectorTheme.ICON_GLOBE
		icon.add_theme_font_size_override("font_size", 18)
		icon.add_theme_color_override("font_color", ACCENT_COLOR)
		title_hbox.add_child(icon)

		var title := Label.new()
		title.text = "WORLD CONTEXT"
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
		if not _token_label or not _world:
			return

		var tokens := _world.estimate_tokens()
		var model_ctx := 4096
		var model_name := "unknown"

		var ai_service := AIService.get_singleton()
		if ai_service:
			var config := ai_service.get_current_config()
			if config:
				model_ctx = config.n_ctx
				model_name = config.display_name

		_token_label.text = WikiInspectorTheme.format_token_display(tokens, model_ctx, model_name)
