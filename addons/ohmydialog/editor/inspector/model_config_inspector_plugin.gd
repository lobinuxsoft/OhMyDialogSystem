@tool
class_name ModelConfigInspectorPlugin
extends EditorInspectorPlugin
## Custom inspector plugin for ModelConfig resources.
##
## Adds a wiki-styled header with model status above Godot's default inspector.


func _can_handle(object: Object) -> bool:
	return object is ModelConfig


func _parse_begin(object: Object) -> void:
	var config := object as ModelConfig
	if not config:
		return

	var header := ModelConfigHeader.new(config)
	add_custom_control(header)


## Decorative header panel with model status for ModelConfig.
class ModelConfigHeader extends PanelContainer:
	const ACCENT_COLOR := WikiInspectorTheme.AI_YELLOW

	var _config: ModelConfig
	var _status_label: RichTextLabel

	func _init(config: ModelConfig) -> void:
		_config = config

	func _ready() -> void:
		add_theme_stylebox_override("panel", WikiInspectorTheme.create_header_style(ACCENT_COLOR))
		_setup_ui()
		_config.changed.connect(_update_status)
		EditorInterface.get_inspector().property_edited.connect(_on_property_edited)

	func _exit_tree() -> void:
		if _config and _config.changed.is_connected(_update_status):
			_config.changed.disconnect(_update_status)
		var inspector := EditorInterface.get_inspector()
		if inspector and inspector.property_edited.is_connected(_on_property_edited):
			inspector.property_edited.disconnect(_on_property_edited)

	func _on_property_edited(_property: String) -> void:
		_update_status()

	func _setup_ui() -> void:
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)

		# Title row
		var title_hbox := HBoxContainer.new()
		title_hbox.add_theme_constant_override("separation", 10)

		var icon := Label.new()
		icon.text = WikiInspectorTheme.ICON_GEAR
		icon.add_theme_font_size_override("font_size", 18)
		icon.add_theme_color_override("font_color", ACCENT_COLOR)
		title_hbox.add_child(icon)

		var title := Label.new()
		title.text = "MODEL CONFIG"
		title.add_theme_font_size_override("font_size", 13)
		title.add_theme_color_override("font_color", ACCENT_COLOR)
		title_hbox.add_child(title)

		vbox.add_child(title_hbox)

		# Status label
		_status_label = RichTextLabel.new()
		_status_label.bbcode_enabled = true
		_status_label.fit_content = true
		_status_label.scroll_active = false
		vbox.add_child(_status_label)

		add_child(vbox)
		_update_status()

	func _update_status() -> void:
		if not _status_label or not _config:
			return

		var downloaded := _config.is_downloaded()
		var status_color := WikiInspectorTheme.AI_GREEN if downloaded else WikiInspectorTheme.AI_RED
		var status_text := "Downloaded" if downloaded else "Not Downloaded"

		_status_label.text = "[code]Status: [color=#%s]%s[/color] | Context: %d | Size: %.1f MB[/code]" % [
			status_color.to_html(false),
			status_text,
			_config.n_ctx,
			_config.size_mb
		]
