@tool
class_name WorldContextInspectorPlugin
extends EditorInspectorPlugin
## Custom inspector plugin for WorldContext resources.
##
## Replaces default property editors with a custom panel showing
## world info, token estimation, and organized editing fields.


## Properties to hide (we show them in custom panel instead).
const HIDDEN_PROPERTIES: Array[String] = [
	"world_id", "world_name", "setting", "time_period",
	"lore", "factions",
	"locations", "current_location",
	"important_npcs",
	"current_events", "rules", "dynamic_state",
	"tone", "forbidden_topics"
]


func _can_handle(object: Object) -> bool:
	return object is WorldContext


func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	# Hide our custom properties - we display them in the custom panel
	if name in HIDDEN_PROPERTIES:
		return true  # true = hide default editor
	return false  # false = use default editor


func _parse_begin(object: Object) -> void:
	var world := object as WorldContext
	if not world:
		return

	var panel := WorldContextEditorPanel.new(world)
	add_custom_control(panel)


## Full editor panel for WorldContext.
class WorldContextEditorPanel extends VBoxContainer:
	var _world: WorldContext
	var _token_label: RichTextLabel

	func _init(world: WorldContext) -> void:
		_world = world

	func _ready() -> void:
		add_theme_constant_override("separation", 8)
		_setup_ui()

	func _setup_ui() -> void:
		# === HEADER WITH TOKEN INFO ===
		var header_panel := PanelContainer.new()
		header_panel.add_theme_stylebox_override("panel", _create_header_style())

		var header_vbox := VBoxContainer.new()
		header_vbox.add_theme_constant_override("separation", 4)

		var title := Label.new()
		title.text = "World Context"
		title.add_theme_font_size_override("font_size", 14)
		title.add_theme_color_override("font_color", Color(0.7, 1.0, 0.85))
		header_vbox.add_child(title)

		_token_label = RichTextLabel.new()
		_token_label.bbcode_enabled = true
		_token_label.fit_content = true
		_token_label.scroll_active = false
		header_vbox.add_child(_token_label)

		header_panel.add_child(header_vbox)
		add_child(header_panel)

		# === WORLD IDENTITY SECTION ===
		_add_section("World Identity")
		_add_line_edit("ID", "world_id", "unique_world_id")
		_add_line_edit("Name", "world_name", "World Name")
		_add_text_edit("Setting", "setting", "Brief description of the setting...", 50)
		_add_time_period_picker()

		# === LORE & HISTORY SECTION ===
		_add_section("Lore & History")
		_add_text_edit("Lore", "lore", "Deep background lore and history...", 80)
		_add_dictionary_edit("Factions", "factions", "faction_id", "description")

		# === GEOGRAPHY SECTION ===
		_add_section("Geography")
		_add_dictionary_edit("Locations", "locations", "location_id", "description")
		_add_line_edit("Current Location", "current_location", "location_id or description")

		# === CHARACTERS SECTION ===
		_add_section("Characters")
		_add_dictionary_edit("Important NPCs", "important_npcs", "character_id", "brief description")

		# === CURRENT STATE SECTION ===
		_add_section("Current State")
		_add_string_array_edit("Current Events", "current_events", "Event happening now...")
		_add_string_array_edit("Rules", "rules", "World constraint or rule...")
		_add_dictionary_edit("Dynamic State", "dynamic_state", "variable_name", "value")

		# === TONE & STYLE SECTION ===
		_add_section("Tone & Style")
		_add_text_edit("Tone", "tone", "Overall tone of the world...", 40)
		_add_string_array_edit("Forbidden Topics", "forbidden_topics", "Topic to avoid...")

		# === PREVIEW SECTION ===
		_add_section("Preview")
		_add_prompt_preview()

		add_child(HSeparator.new())

		_update_token_display()


	func _create_header_style() -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.2, 0.18, 0.9)
		style.border_color = Color(0.3, 0.7, 0.5, 0.5)
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		style.set_content_margin_all(12)
		return style


	func _add_section(title: String) -> void:
		var label := Label.new()
		label.text = title
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.7))
		add_child(label)


	func _add_line_edit(label_text: String, property: String, placeholder: String = "") -> void:
		var hbox := HBoxContainer.new()

		var label := Label.new()
		label.text = label_text + ":"
		label.custom_minimum_size.x = 110
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

		add_child(hbox)


	func _add_text_edit(label_text: String, property: String, placeholder: String = "", min_height: int = 60) -> void:
		var label := Label.new()
		label.text = label_text + ":"
		add_child(label)

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
		add_child(edit)


	func _add_time_period_picker() -> void:
		var hbox := HBoxContainer.new()

		var label := Label.new()
		label.text = "Time Period:"
		label.custom_minimum_size.x = 110
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

		add_child(hbox)


	func _add_string_array_edit(label_text: String, property: String, placeholder: String) -> void:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 2)

		var header := HBoxContainer.new()
		var label := Label.new()
		label.text = label_text + ":"
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(label)

		var add_btn := Button.new()
		add_btn.text = "+"
		add_btn.custom_minimum_size.x = 24
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
				del_btn.text = "x"
				del_btn.custom_minimum_size.x = 24
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
		add_child(container)


	func _add_dictionary_edit(label_text: String, property: String, key_hint: String, value_hint: String) -> void:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 2)

		var header := HBoxContainer.new()
		var label := Label.new()
		label.text = label_text + ":"
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(label)

		var add_btn := Button.new()
		add_btn.text = "+"
		add_btn.custom_minimum_size.x = 24
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
			var keys := dict.keys()
			for key in keys:
				var item_hbox := HBoxContainer.new()

				var key_edit := LineEdit.new()
				key_edit.text = str(key)
				key_edit.placeholder_text = key_hint
				key_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				key_edit.custom_minimum_size.x = 80
				var old_key = key
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
				value_edit.text = str(dict[key])
				value_edit.placeholder_text = value_hint
				value_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				var k = key
				value_edit.text_changed.connect(func(new_value: String):
					var current_dict: Dictionary = _world.get(property)
					current_dict[k] = new_value
					_world.emit_changed()
					_update_token_display()
				)
				item_hbox.add_child(value_edit)

				var del_btn := Button.new()
				del_btn.text = "x"
				del_btn.custom_minimum_size.x = 24
				var dk = key
				del_btn.pressed.connect(func():
					var current_dict: Dictionary = _world.get(property)
					current_dict.erase(dk)
					_world.emit_changed()
					_update_token_display()
					rebuild_list.call()
				)
				item_hbox.add_child(del_btn)

				items_container.add_child(item_hbox)

		add_btn.pressed.connect(func():
			var dict: Dictionary = _world.get(property)
			var new_key := "new_key_%d" % dict.size()
			dict[new_key] = ""
			_world.emit_changed()
			rebuild_list.call()
		)

		rebuild_list.call()
		add_child(container)


	func _add_prompt_preview() -> void:
		var btn := Button.new()
		btn.text = "Show Context Prompt Preview"
		add_child(btn)

		var preview_container := VBoxContainer.new()
		preview_container.visible = false

		var preview_panel := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.15, 0.12, 0.9)
		style.set_border_width_all(1)
		style.border_color = Color(0.25, 0.45, 0.35, 0.5)
		style.set_corner_radius_all(4)
		style.set_content_margin_all(8)
		preview_panel.add_theme_stylebox_override("panel", style)

		var preview_label := RichTextLabel.new()
		preview_label.bbcode_enabled = true
		preview_label.fit_content = true
		preview_label.scroll_active = false
		preview_label.selection_enabled = true
		preview_panel.add_child(preview_label)
		preview_container.add_child(preview_panel)
		add_child(preview_container)

		btn.pressed.connect(func():
			preview_container.visible = not preview_container.visible
			btn.text = "Hide Context Prompt Preview" if preview_container.visible else "Show Context Prompt Preview"
			if preview_container.visible:
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
		var text := "[b]Token Estimate: ~%d[/b]\n" % tokens

		if tokens > model_ctx * 0.5:
			text += "[color=#ff6b6b]WARNING: Uses %.0f%% of model context (%d tokens)[/color]" % [usage_percent, model_ctx]
		elif tokens > model_ctx * 0.3:
			text += "[color=#ffd93d]CAUTION: Uses %.0f%% of context[/color]\n" % usage_percent
			text += "[color=#888]Model: %s (%d tokens)[/color]" % [model_name, model_ctx]
		else:
			text += "[color=#6bcb77]OK: %.0f%% of context[/color]\n" % usage_percent
			text += "[color=#888]Model: %s (%d tokens)[/color]" % [model_name, model_ctx]

		_token_label.text = text
