@tool
class_name WorldContextInspectorPlugin
extends EditorInspectorPlugin
## Custom inspector plugin for WorldContext resources.
##
## Provides a wiki-styled editor panel with neural network aesthetic.
## Properties are stored via _get_property_list() with STORAGE only,
## so no native Godot properties appear in the inspector.

# === WIKI COLOR PALETTE (Neural Network Theme - Green Variant) ===
# Backgrounds
const COLOR_BG_PRIMARY := Color("#0a0d12")
const COLOR_BG_SECONDARY := Color("#0f1419")
const COLOR_BG_TERTIARY := Color("#161d26")
const COLOR_BG_CARD := Color("#121921")

# Text
const COLOR_TEXT_PRIMARY := Color("#e6edf3")
const COLOR_TEXT_SECONDARY := Color("#8b949e")
const COLOR_TEXT_MUTED := Color("#484f58")

# AI Accent Colors (Green theme for World)
const COLOR_AI_GREEN := Color("#10b981")
const COLOR_AI_GREEN_DIM := Color("#059669")
const COLOR_AI_PURPLE := Color("#a855f7")
const COLOR_AI_CYAN := Color("#00d4ff")
const COLOR_AI_ORANGE := Color("#f97316")

# Borders
const COLOR_BORDER := Color("#21262d")


func _can_handle(object: Object) -> bool:
	return object is WorldContext


func _parse_begin(object: Object) -> void:
	var world := object as WorldContext
	if not world:
		return

	var panel := WorldContextEditorPanel.new(world)
	add_custom_control(panel)


## Full editor panel for WorldContext with wiki-style aesthetics.
class WorldContextEditorPanel extends VBoxContainer:
	var _world: WorldContext
	var _token_label: RichTextLabel
	var _sections: Dictionary = {}

	func _init(world: WorldContext) -> void:
		_world = world

	func _ready() -> void:
		add_theme_constant_override("separation", 0)
		_setup_ui()

	func _setup_ui() -> void:
		# === MAIN HEADER ===
		var header_panel := PanelContainer.new()
		header_panel.add_theme_stylebox_override("panel", _create_header_style())

		var header_vbox := VBoxContainer.new()
		header_vbox.add_theme_constant_override("separation", 6)

		# Title with icon-like prefix
		var title_hbox := HBoxContainer.new()
		title_hbox.add_theme_constant_override("separation", 8)

		var icon_label := Label.new()
		icon_label.text = "◆"
		icon_label.add_theme_color_override("font_color", WorldContextInspectorPlugin.COLOR_AI_GREEN)
		title_hbox.add_child(icon_label)

		var title := Label.new()
		title.text = "WORLD CONTEXT"
		title.add_theme_font_size_override("font_size", 12)
		title.add_theme_color_override("font_color", WorldContextInspectorPlugin.COLOR_AI_GREEN)
		title_hbox.add_child(title)
		header_vbox.add_child(title_hbox)

		# Token display
		_token_label = RichTextLabel.new()
		_token_label.bbcode_enabled = true
		_token_label.fit_content = true
		_token_label.scroll_active = false
		header_vbox.add_child(_token_label)

		header_panel.add_child(header_vbox)
		add_child(header_panel)

		# === SECTIONS ===
		var identity_content := _create_section("World Identity", "◇", true)
		_add_line_edit(identity_content, "ID", "world_id", "unique_world_id")
		_add_line_edit(identity_content, "Name", "world_name", "World Name")
		_add_text_edit(identity_content, "Setting", "setting", "Brief description of the setting...", 80)
		_add_time_period_picker(identity_content)

		var lore_content := _create_section("Lore & History", "◈", true)
		_add_text_edit(lore_content, "Lore", "lore", "Deep background lore and history...", 100)
		_add_dictionary_edit(lore_content, "Factions", "factions", "faction_id", "description")

		var geography_content := _create_section("Geography", "◉", true)
		_add_dictionary_edit(geography_content, "Locations", "locations", "location_id", "description")
		_add_line_edit(geography_content, "Current Location", "current_location", "location_id or description")

		var characters_content := _create_section("Characters", "◎", false)
		_add_dictionary_edit(characters_content, "Important NPCs", "important_npcs", "character_id", "brief description")

		var state_content := _create_section("Current State", "◐", true)
		_add_string_array_edit(state_content, "Current Events", "current_events", "Event happening now...")
		_add_string_array_edit(state_content, "Rules", "rules", "World constraint or rule...")
		_add_dictionary_edit(state_content, "Dynamic State", "dynamic_state", "variable_name", "value")

		var tone_content := _create_section("Tone & Style", "◑", false)
		_add_text_edit(tone_content, "Tone", "tone", "Overall tone of the world...", 60)
		_add_string_array_edit(tone_content, "Forbidden Topics", "forbidden_topics", "Topic to avoid...")

		var preview_content := _create_section("Preview", "◒", false)
		_add_prompt_preview(preview_content)

		_update_token_display()


	func _create_header_style() -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = WorldContextInspectorPlugin.COLOR_BG_CARD
		style.border_color = WorldContextInspectorPlugin.COLOR_AI_GREEN
		style.set_border_width_all(1)
		style.border_width_left = 3
		style.border_width_top = 2
		style.set_corner_radius_all(4)
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.set_content_margin_all(12)
		return style


	func _create_section_header_style(is_hovered: bool = false) -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		var base_color := WorldContextInspectorPlugin.COLOR_BG_TERTIARY
		style.bg_color = base_color if not is_hovered else base_color.lightened(0.08)
		style.border_color = WorldContextInspectorPlugin.COLOR_BORDER
		style.set_border_width_all(0)
		style.border_width_bottom = 1
		style.set_corner_radius_all(0)
		style.set_content_margin_all(0)
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		return style


	func _create_section(title: String, icon: String, expanded: bool = true) -> VBoxContainer:
		var section_container := VBoxContainer.new()
		section_container.add_theme_constant_override("separation", 0)

		# Section header
		var header_panel := PanelContainer.new()
		header_panel.add_theme_stylebox_override("panel", _create_section_header_style())

		var header_hbox := HBoxContainer.new()
		header_hbox.add_theme_constant_override("separation", 8)

		# Arrow indicator
		var arrow := Label.new()
		arrow.text = "▼" if expanded else "▶"
		arrow.add_theme_font_size_override("font_size", 10)
		arrow.add_theme_color_override("font_color", WorldContextInspectorPlugin.COLOR_AI_PURPLE)
		header_hbox.add_child(arrow)

		# Icon
		var icon_label := Label.new()
		icon_label.text = icon
		icon_label.add_theme_font_size_override("font_size", 12)
		icon_label.add_theme_color_override("font_color", WorldContextInspectorPlugin.COLOR_AI_GREEN)
		header_hbox.add_child(icon_label)

		# Title
		var title_label := Label.new()
		title_label.text = title
		title_label.add_theme_font_size_override("font_size", 12)
		title_label.add_theme_color_override("font_color", WorldContextInspectorPlugin.COLOR_TEXT_PRIMARY)
		header_hbox.add_child(title_label)

		header_panel.add_child(header_hbox)
		section_container.add_child(header_panel)

		# Content container
		var content_panel := PanelContainer.new()
		var content_style := StyleBoxFlat.new()
		content_style.bg_color = WorldContextInspectorPlugin.COLOR_BG_SECONDARY
		content_style.set_content_margin_all(0)
		content_style.content_margin_left = 20
		content_style.content_margin_right = 10
		content_style.content_margin_top = 10
		content_style.content_margin_bottom = 10
		content_panel.add_theme_stylebox_override("panel", content_style)
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
		label.custom_minimum_size.x = 100
		label.add_theme_color_override("font_color", WorldContextInspectorPlugin.COLOR_TEXT_SECONDARY)
		hbox.add_child(label)

		var edit := LineEdit.new()
		edit.text = _world.get(property)
		edit.placeholder_text = placeholder
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit.text_changed.connect(func(new_text: String):
			_world.set(property, new_text)
			_world.emit_changed()
			_update_token_display()
		)
		hbox.add_child(edit)

		parent.add_child(hbox)


	func _add_text_edit(parent: Control, label_text: String, property: String, placeholder: String = "", min_height: int = 80) -> void:
		var label := Label.new()
		label.text = label_text
		label.add_theme_color_override("font_color", WorldContextInspectorPlugin.COLOR_TEXT_SECONDARY)
		parent.add_child(label)

		var edit := TextEdit.new()
		edit.text = _world.get(property)
		edit.placeholder_text = placeholder
		edit.custom_minimum_size.y = min_height
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		edit.text_changed.connect(func():
			_world.set(property, edit.text)
			_world.emit_changed()
			_update_token_display()
		)
		parent.add_child(edit)


	func _add_time_period_picker(parent: Control) -> void:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)

		var label := Label.new()
		label.text = "Time Period"
		label.custom_minimum_size.x = 100
		label.add_theme_color_override("font_color", WorldContextInspectorPlugin.COLOR_TEXT_SECONDARY)
		hbox.add_child(label)

		var option := OptionButton.new()
		for period in WorldContext.TimePeriod.keys():
			option.add_item(period.capitalize().replace("_", " "))
		option.select(_world.time_period)
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option.item_selected.connect(func(index: int):
			_world.time_period = index as WorldContext.TimePeriod
			_world.emit_changed()
			_update_token_display()
		)
		hbox.add_child(option)

		parent.add_child(hbox)


	func _add_string_array_edit(parent: Control, label_text: String, property: String, placeholder: String) -> void:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 4)

		var header := HBoxContainer.new()
		var label := Label.new()
		label.text = label_text
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_color_override("font_color", WorldContextInspectorPlugin.COLOR_TEXT_SECONDARY)
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

			var arr: Array = _world.get(property)
			for i in arr.size():
				var item_hbox := HBoxContainer.new()
				item_hbox.add_theme_constant_override("separation", 4)

				var item_edit := LineEdit.new()
				item_edit.text = arr[i]
				item_edit.placeholder_text = placeholder
				item_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				var idx := i
				item_edit.text_changed.connect(func(new_text: String):
					var current_arr: Array = _world.get(property)
					current_arr[idx] = new_text
					_world.emit_changed()
					_update_token_display()
				)
				item_hbox.add_child(item_edit)

				var del_btn := Button.new()
				del_btn.text = "×"
				del_btn.custom_minimum_size = Vector2(24, 24)
				del_btn.pressed.connect(func():
					var current_arr: Array = _world.get(property)
					current_arr.remove_at(idx)
					_world.emit_changed()
					_update_token_display()
					rebuild_list.call()
				)
				item_hbox.add_child(del_btn)

				items_container.add_child(item_hbox)

		add_btn.pressed.connect(func():
			var arr: Array = _world.get(property)
			arr.append("")
			_world.emit_changed()
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
		label.add_theme_color_override("font_color", WorldContextInspectorPlugin.COLOR_TEXT_SECONDARY)
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

			var dict: Dictionary = _world.get(property)
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
					var current_dict: Dictionary = _world.get(property)
					var value = current_dict.get(old_key, "")
					current_dict.erase(old_key)
					current_dict[new_key] = value
					old_key = new_key
					_world.emit_changed()
					_update_token_display()
				)
				item_hbox.add_child(key_edit)

				var value_edit := LineEdit.new()
				value_edit.text = dict[key]
				value_edit.placeholder_text = value_hint
				value_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				var k: String = key
				value_edit.text_changed.connect(func(new_value: String):
					var current_dict: Dictionary = _world.get(property)
					current_dict[k] = new_value
					_world.emit_changed()
					_update_token_display()
				)
				item_hbox.add_child(value_edit)

				var del_btn := Button.new()
				del_btn.text = "×"
				del_btn.custom_minimum_size = Vector2(24, 24)
				del_btn.pressed.connect(func():
					var current_dict: Dictionary = _world.get(property)
					current_dict.erase(k)
					_world.emit_changed()
					_update_token_display()
					rebuild_list.call()
				)
				item_hbox.add_child(del_btn)

				items_container.add_child(item_hbox)

		add_btn.pressed.connect(func():
			var dict: Dictionary = _world.get(property)
			dict["new_%d" % dict.size()] = ""
			_world.emit_changed()
			rebuild_list.call()
		)

		rebuild_list.call()
		parent.add_child(container)


	func _add_prompt_preview(parent: Control) -> void:
		var btn := Button.new()
		btn.text = "Show Context Prompt"
		parent.add_child(btn)

		var preview_panel := PanelContainer.new()
		preview_panel.visible = false
		var style := StyleBoxFlat.new()
		style.bg_color = WorldContextInspectorPlugin.COLOR_BG_PRIMARY
		style.set_border_width_all(1)
		style.border_color = WorldContextInspectorPlugin.COLOR_AI_GREEN_DIM
		style.set_corner_radius_all(4)
		style.set_content_margin_all(10)
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
			btn.text = "Hide Context Prompt" if preview_panel.visible else "Show Context Prompt"
			if preview_panel.visible:
				var prompt := _world.to_context_prompt()
				prompt = prompt.replace("[", "[lb]").replace("]", "[rb]")
				preview_label.text = "[code]%s[/code]" % prompt
		)


	func _update_token_display() -> void:
		if not _token_label:
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

		var usage_percent := (tokens * 100.0) / model_ctx
		var text := "[b]~%d tokens[/b] " % tokens

		if tokens > model_ctx * 0.5:
			text += "[color=#ef4444](%.0f%% - WARNING)[/color]" % usage_percent
		elif tokens > model_ctx * 0.3:
			text += "[color=#f97316](%.0f%% - caution)[/color]" % usage_percent
		else:
			text += "[color=#10b981](%.0f%% OK)[/color]" % usage_percent

		text += "\n[color=#484f58]Model: %s (%d ctx)[/color]" % [model_name, model_ctx]

		_token_label.text = text
