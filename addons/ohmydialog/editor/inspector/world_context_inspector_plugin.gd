@tool
class_name WorldContextInspectorPlugin
extends EditorInspectorPlugin
## Custom inspector plugin for WorldContext resources.
##
## Adds a visual summary panel showing world info and token estimation.


func _can_handle(object: Object) -> bool:
	return object is WorldContext


func _parse_begin(object: Object) -> void:
	var world := object as WorldContext
	if not world:
		return

	var panel := WorldContextSummaryPanel.new(world)
	add_custom_control(panel)


## Visual summary panel for WorldContext.
class WorldContextSummaryPanel extends VBoxContainer:
	var _world: WorldContext
	var _info_label: RichTextLabel
	var _preview_button: Button
	var _preview_container: VBoxContainer
	var _preview_label: RichTextLabel
	var _preview_visible: bool = false


	func _init(world: WorldContext) -> void:
		_world = world


	func _ready() -> void:
		add_theme_constant_override("separation", 8)
		_setup_ui()
		_update_info()

		# Listen for changes
		if _world.changed.is_connected(_update_info):
			return
		_world.changed.connect(_update_info)


	func _setup_ui() -> void:
		# Main info panel
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", _create_panel_style())

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)

		# Header
		var header := Label.new()
		header.text = "World Summary"
		header.add_theme_font_size_override("font_size", 14)
		header.add_theme_color_override("font_color", Color(0.7, 1.0, 0.85))
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
		_preview_button.text = "Show Context Prompt Preview"
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
		style.bg_color = Color(0.15, 0.2, 0.18, 0.9)
		style.border_color = Color(0.3, 0.7, 0.5, 0.5)
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		style.set_content_margin_all(12)
		return style


	func _create_preview_style() -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.15, 0.12, 0.9)
		style.border_color = Color(0.25, 0.45, 0.35, 0.5)
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		style.set_content_margin_all(8)
		return style


	func _update_info() -> void:
		if not _info_label or not _world:
			return

		var tokens := _world.estimate_tokens()
		var period_name := WorldContext.TimePeriod.keys()[_world.time_period].to_lower().replace("_", " ")

		var text := ""

		# Name and ID
		if not _world.world_name.is_empty():
			text += "[b]%s[/b]" % _world.world_name
			if not _world.world_id.is_empty():
				text += " [color=#888](%s)[/color]" % _world.world_id
			text += "\n"

		# Time period
		text += "[color=#aaa]Era:[/color] %s\n" % period_name.capitalize()

		# Current location
		if not _world.current_location.is_empty():
			text += "[color=#aaa]Location:[/color] %s\n" % _world.current_location

		# Locations count
		if not _world.locations.is_empty():
			text += "[color=#aaa]Locations:[/color] %d defined\n" % _world.locations.size()

		# Factions count
		if not _world.factions.is_empty():
			text += "[color=#aaa]Factions:[/color] %d groups\n" % _world.factions.size()

		# Important NPCs count
		if not _world.important_npcs.is_empty():
			text += "[color=#aaa]NPCs:[/color] %d notable\n" % _world.important_npcs.size()

		# Current events count
		if not _world.current_events.is_empty():
			text += "[color=#aaa]Events:[/color] %d active\n" % _world.current_events.size()

		# Rules count
		if not _world.rules.is_empty():
			text += "[color=#aaa]Rules:[/color] %d constraints\n" % _world.rules.size()

		# Dynamic state count
		if not _world.dynamic_state.is_empty():
			text += "[color=#aaa]State vars:[/color] %d tracked\n" % _world.dynamic_state.size()

		# Forbidden topics count
		if not _world.forbidden_topics.is_empty():
			text += "[color=#aaa]Forbidden:[/color] %d topics\n" % _world.forbidden_topics.size()

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
			text += "Consider reducing lore/setting detail.[/color]"
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
		_preview_button.text = "Hide Context Prompt Preview" if _preview_visible else "Show Context Prompt Preview"

		if _preview_visible:
			_update_preview()


	func _update_preview() -> void:
		if not _preview_label or not _world:
			return

		var prompt := _world.to_context_prompt()
		# Escape BBCode and show as monospace
		prompt = prompt.replace("[", "[lb]").replace("]", "[rb]")
		_preview_label.text = "[code]%s[/code]" % prompt
