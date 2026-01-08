@tool
class_name StartNodeEditor
extends BaseNodeEditor
## Inspector editor for START nodes.
##
## Shows the trigger field for event-based dialogue starts.
## Also allows selecting which AI model to use for this dialogue.


func _setup_ui() -> void:
	_add_header("Start Node")
	_add_separator()
	_add_line_edit("Trigger", "trigger", "Event name (empty = manual)")
	_add_separator()
	_add_header("AI Model")
	_add_model_selector("Model", "model_path")


## Creates a model selector dropdown showing only downloaded models.
func _add_model_selector(label_text: String, data_key: String) -> OptionButton:
	var hbox := HBoxContainer.new()

	var label := Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size.x = 100
	hbox.add_child(label)

	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# First option: No AI model
	option.add_item("(Ninguno - Sin IA)")
	option.set_item_metadata(0, "")

	# Get downloaded models from AIService
	var downloaded_models := _get_downloaded_models()
	for i in range(downloaded_models.size()):
		var config: ModelConfig = downloaded_models[i]
		option.add_item(config.display_name)
		option.set_item_metadata(i + 1, config.get_effective_path())

	# Select current value
	var current_path: String = str(_node_data.data.get(data_key, ""))
	if current_path.is_empty():
		option.select(0)
	else:
		var found := false
		for i in range(1, option.item_count):
			if option.get_item_metadata(i) == current_path:
				option.select(i)
				found = true
				break
		if not found:
			# Model path exists but not in list - show as custom entry
			option.add_item("(Custom: %s)" % current_path.get_file())
			option.set_item_metadata(option.item_count - 1, current_path)
			option.select(option.item_count - 1)

	option.item_selected.connect(func(index: int):
		var path: String = option.get_item_metadata(index)
		_node_data.data[data_key] = path
		_emit_changed()
	)

	hbox.add_child(option)
	add_child(hbox)
	return option


## Returns an array of downloaded ModelConfig from AIService.
func _get_downloaded_models() -> Array[ModelConfig]:
	var downloaded: Array[ModelConfig] = []

	var ai_service := AIService.get_singleton()
	if not ai_service:
		return downloaded

	var manager := ai_service.get_model_manager()
	if not manager:
		return downloaded

	for config in manager.get_available_models():
		if config.is_downloaded():
			downloaded.append(config)

	return downloaded
