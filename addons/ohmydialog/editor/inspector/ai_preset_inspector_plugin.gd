@tool
class_name AIPresetInspectorPlugin
extends EditorInspectorPlugin
## Custom inspector plugin for AIPreset resources.
##
## Adds a wiki-styled header above Godot's default inspector.


func _can_handle(object: Object) -> bool:
	return object is AIPreset


func _parse_begin(object: Object) -> void:
	var preset := object as AIPreset
	if not preset:
		return

	var header := AIPresetHeader.new(preset)
	add_custom_control(header)


## Decorative header panel for AIPreset.
class AIPresetHeader extends PanelContainer:
	const ACCENT_COLOR := WikiInspectorTheme.AI_ORANGE

	var _preset: AIPreset
	var _info_label: RichTextLabel

	func _init(preset: AIPreset) -> void:
		_preset = preset

	func _ready() -> void:
		add_theme_stylebox_override("panel", WikiInspectorTheme.create_header_style(ACCENT_COLOR))
		_setup_ui()
		_preset.changed.connect(_update_info)

	func _exit_tree() -> void:
		if _preset and _preset.changed.is_connected(_update_info):
			_preset.changed.disconnect(_update_info)

	func _setup_ui() -> void:
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)

		# Title row
		var title_hbox := HBoxContainer.new()
		title_hbox.add_theme_constant_override("separation", 10)

		var icon := Label.new()
		icon.text = WikiInspectorTheme.ICON_SPARKLES
		icon.add_theme_font_size_override("font_size", 18)
		icon.add_theme_color_override("font_color", ACCENT_COLOR)
		title_hbox.add_child(icon)

		var title := Label.new()
		title.text = "AI PRESET"
		title.add_theme_font_size_override("font_size", 13)
		title.add_theme_color_override("font_color", ACCENT_COLOR)
		title_hbox.add_child(title)

		vbox.add_child(title_hbox)

		# Info label
		_info_label = RichTextLabel.new()
		_info_label.bbcode_enabled = true
		_info_label.fit_content = true
		_info_label.scroll_active = false
		vbox.add_child(_info_label)

		add_child(vbox)
		_update_info()

	func _update_info() -> void:
		if not _info_label or not _preset:
			return

		var type_name: String = AIPreset.PresetType.keys()[_preset.preset_type]
		_info_label.text = "[code]Type: %s | Temp: %.2f | Top-P: %.2f[/code]" % [
			type_name.capitalize(),
			_preset.temperature,
			_preset.top_p
		]
