extends Control
## Test scene for LlamaInterface functionality.
##
## Allows testing model loading, text generation, and sampling parameters.
## Run this scene directly to test the LLM integration.

# UI References - Toolbar
@onready var download_selector: OptionButton = %DownloadSelector
@onready var download_btn: Button = %DownloadBtn
@onready var load_selector: OptionButton = %LoadSelector
@onready var load_btn: Button = %LoadBtn
@onready var unload_btn: Button = %UnloadBtn
@onready var manage_btn: Button = %ManageBtn
@onready var status_label: Label = %StatusLabel

# UI References - Download Progress
@onready var download_panel: PanelContainer = %DownloadPanel
@onready var download_label: Label = %DownloadLabel
@onready var download_progress: ProgressBar = %DownloadProgress
@onready var cancel_download_btn: Button = %CancelDownloadBtn

# UI References - Model Management Panel
@onready var manage_panel: PanelContainer = %ManagePanel
@onready var models_list: VBoxContainer = %ModelsList
@onready var delete_selected_btn: Button = %DeleteSelectedBtn
@onready var close_manage_btn: Button = %CloseManageBtn

# UI References - Main Content
@onready var prompt_input: TextEdit = %PromptInput
@onready var generate_btn: Button = %GenerateBtn
@onready var clear_btn: Button = %ClearBtn
@onready var time_label: Label = %TimeLabel
@onready var output_display: TextEdit = %OutputDisplay

# UI References - Sampling Parameters
@onready var temperature_slider: HSlider = %TemperatureSlider
@onready var temperature_value: Label = %TemperatureValue
@onready var top_p_slider: HSlider = %TopPSlider
@onready var top_p_value: Label = %TopPValue
@onready var top_k_spinbox: SpinBox = %TopKSpinBox
@onready var max_tokens_spinbox: SpinBox = %MaxTokensSpinBox
@onready var repeat_penalty_slider: HSlider = %RepeatPenaltySlider
@onready var repeat_penalty_value: Label = %RepeatPenaltyValue
@onready var min_p_slider: HSlider = %MinPSlider
@onready var min_p_value: Label = %MinPValue
@onready var seed_spinbox: SpinBox = %SeedSpinBox
@onready var stop_sequences_input: TextEdit = %StopSequencesInput

# UI References - Model Info
@onready var model_info_display: RichTextLabel = %ModelInfoDisplay

# UI References - Custom Model Warning
@onready var custom_warning: PanelContainer = %CustomWarning

# Internal
var _model_manager: ModelManager
var _generation_thread: Thread
var _is_generating: bool = false
var _models_to_delete: Array[String] = []


func _ready() -> void:
	# Initialize ModelManager
	_model_manager = ModelManager.new()
	add_child(_model_manager)

	# Connect signals
	_model_manager.model_loaded.connect(_on_model_loaded)
	_model_manager.model_load_failed.connect(_on_model_load_failed)
	_model_manager.model_unloaded.connect(_on_model_unloaded)
	_model_manager.download_progress.connect(_on_download_progress)
	_model_manager.download_completed.connect(_on_download_completed)
	_model_manager.download_failed.connect(_on_download_failed)

	# Populate selectors
	_populate_selectors()

	# Connect UI signals
	download_selector.item_selected.connect(_on_download_selector_changed)
	download_btn.pressed.connect(_on_download_pressed)
	load_selector.item_selected.connect(_on_load_selector_changed)
	load_btn.pressed.connect(_on_load_pressed)
	unload_btn.pressed.connect(_on_unload_pressed)
	manage_btn.pressed.connect(_on_manage_pressed)
	generate_btn.pressed.connect(_on_generate_pressed)
	clear_btn.pressed.connect(_on_clear_pressed)
	cancel_download_btn.pressed.connect(_on_cancel_download_pressed)
	delete_selected_btn.pressed.connect(_on_delete_selected_pressed)
	close_manage_btn.pressed.connect(_on_close_manage_pressed)

	# Connect slider value changed
	temperature_slider.value_changed.connect(_on_temperature_changed)
	top_p_slider.value_changed.connect(_on_top_p_changed)
	repeat_penalty_slider.value_changed.connect(_on_repeat_penalty_changed)
	min_p_slider.value_changed.connect(_on_min_p_changed)

	# Initial UI state
	_update_ui_state()
	download_panel.hide()
	manage_panel.hide()
	custom_warning.hide()


func _exit_tree() -> void:
	# Wait for generation thread
	if _generation_thread != null and _generation_thread.is_started():
		_generation_thread.wait_to_finish()


func _populate_selectors() -> void:
	# Populate download selector (all models not yet downloaded)
	download_selector.clear()
	var models = _model_manager.get_available_models()
	var download_idx = 0
	for model in models:
		if not model.is_downloaded():
			var text = "%s (~%.0f MB)" % [model.display_name, model.size_mb]
			download_selector.add_item(text, download_idx)
			download_selector.set_item_metadata(download_idx, model.id)
			download_idx += 1

	if download_selector.item_count == 0:
		download_selector.add_item("All models downloaded", 0)
		download_selector.disabled = true
		download_btn.disabled = true
	else:
		download_selector.disabled = false

	# Populate load selector (only downloaded models)
	load_selector.clear()
	var load_idx = 0
	for model in models:
		if model.is_downloaded():
			load_selector.add_item(model.display_name, load_idx)
			load_selector.set_item_metadata(load_idx, model.id)
			load_idx += 1

	if load_selector.item_count == 0:
		load_selector.add_item("No models downloaded", 0)
		load_selector.disabled = true
		load_btn.disabled = true
	else:
		load_selector.disabled = _model_manager.is_model_loaded()
		load_btn.disabled = _model_manager.is_model_loaded()


func _populate_manage_list() -> void:
	# Clear existing
	for child in models_list.get_children():
		child.queue_free()

	_models_to_delete.clear()

	# Add downloaded models with checkboxes
	var models = _model_manager.get_available_models()
	for model in models:
		if model.is_downloaded():
			var hbox = HBoxContainer.new()

			var checkbox = CheckBox.new()
			checkbox.text = model.display_name
			checkbox.set_meta("model_id", model.id)
			checkbox.set_meta("model_path", model.get_effective_path())
			checkbox.toggled.connect(_on_model_checkbox_toggled.bind(model.id))
			hbox.add_child(checkbox)

			var size_label = Label.new()
			var file = FileAccess.open(model.get_effective_path(), FileAccess.READ)
			if file:
				var size_mb = file.get_length() / (1024.0 * 1024.0)
				size_label.text = " (%.1f MB)" % size_mb
				file.close()
			size_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			hbox.add_child(size_label)

			models_list.add_child(hbox)

	delete_selected_btn.disabled = true


func _get_selected_download_model() -> ModelConfig:
	var idx = download_selector.selected
	if idx < 0 or download_selector.disabled:
		return null

	var model_id = download_selector.get_item_metadata(idx)
	if model_id == null:
		return null
	return _model_manager.registry.get_model_by_id(model_id)


func _get_selected_load_model() -> ModelConfig:
	var idx = load_selector.selected
	if idx < 0 or load_selector.disabled:
		return null

	var model_id = load_selector.get_item_metadata(idx)
	if model_id == null:
		return null
	return _model_manager.registry.get_model_by_id(model_id)


func _update_ui_state() -> void:
	var is_loaded = _model_manager.is_model_loaded()
	var is_downloading = _model_manager.is_downloading()

	# Selectors
	download_selector.disabled = is_downloading or download_selector.item_count == 0
	load_selector.disabled = is_loaded or is_downloading or load_selector.item_count == 0

	# Buttons
	download_btn.disabled = is_downloading or download_selector.item_count == 0 or _get_selected_download_model() == null
	load_btn.disabled = is_loaded or is_downloading or load_selector.item_count == 0 or _get_selected_load_model() == null
	unload_btn.disabled = not is_loaded
	manage_btn.disabled = is_downloading
	generate_btn.disabled = not is_loaded or _is_generating

	# Custom warning
	var model = _get_selected_load_model()
	if model != null and model.is_custom:
		custom_warning.show()
	else:
		custom_warning.hide()

	# Status
	if is_loaded and _model_manager.current_config != null:
		status_label.text = "Loaded: %s" % _model_manager.current_config.display_name
		status_label.add_theme_color_override("font_color", Color.GREEN)
	elif is_downloading:
		status_label.text = "Downloading..."
		status_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		status_label.text = "No model loaded"
		status_label.remove_theme_color_override("font_color")


func _update_model_info() -> void:
	if not _model_manager.is_model_loaded():
		model_info_display.text = "No model loaded"
		return

	var info = _model_manager.get_model_info()
	var text = "[b]Model Information[/b]\n\n"

	if info.has("description"):
		text += "[color=gray]%s[/color]\n\n" % info["description"]

	if info.has("n_params"):
		var params = info["n_params"]
		var params_str = "%.1fB" % (params / 1_000_000_000.0) if params >= 1_000_000_000 else "%.1fM" % (params / 1_000_000.0)
		text += "Parameters: %s\n" % params_str

	if info.has("n_ctx"):
		text += "Context: %d tokens\n" % info["n_ctx"]

	if info.has("vocab_size"):
		text += "Vocabulary: %d tokens\n" % info["vocab_size"]

	if info.has("n_layer"):
		text += "Layers: %d\n" % info["n_layer"]

	model_info_display.text = text


func _apply_sampling_params() -> void:
	var llama = _model_manager.get_llama()
	if llama == null:
		return

	llama.temperature = temperature_slider.value
	llama.top_p = top_p_slider.value
	llama.top_k = int(top_k_spinbox.value)
	llama.max_tokens = int(max_tokens_spinbox.value)
	llama.repeat_penalty = repeat_penalty_slider.value
	llama.min_p = min_p_slider.value

	# Seed: -1 means random
	if seed_spinbox.value < 0:
		llama.seed = 0xFFFFFFFF
	else:
		llama.seed = int(seed_spinbox.value)

	# Stop sequences
	var stop_text = stop_sequences_input.text.strip_edges()
	if stop_text.is_empty():
		llama.clear_stop_sequences()
	else:
		var sequences = stop_text.split("\n", false)
		var packed = PackedStringArray(sequences)
		llama.set_stop_sequences(packed)


# Signal handlers - Selectors
func _on_download_selector_changed(_index: int) -> void:
	_update_ui_state()


func _on_load_selector_changed(_index: int) -> void:
	_update_ui_state()


# Signal handlers - Download
func _on_download_pressed() -> void:
	var model = _get_selected_download_model()
	if model == null:
		return

	var err = _model_manager.download_model(model)
	if err == OK:
		download_panel.show()
		download_label.text = "Downloading %s..." % model.display_name
		download_progress.value = 0

	_update_ui_state()


func _on_cancel_download_pressed() -> void:
	_model_manager.cancel_download()
	download_panel.hide()
	_update_ui_state()


func _on_download_progress(model_id: String, progress: float) -> void:
	download_progress.value = progress * 100.0
	var downloaded_mb = _model_manager.downloader.get_downloaded_bytes() / (1024.0 * 1024.0)
	var total_mb = _model_manager.downloader.get_total_bytes() / (1024.0 * 1024.0)
	download_label.text = "Downloading... %.1f / %.1f MB" % [downloaded_mb, total_mb]


func _on_download_completed(_model_id: String) -> void:
	download_panel.hide()
	_populate_selectors()  # Refresh both selectors
	_update_ui_state()
	status_label.text = "Download complete!"
	status_label.add_theme_color_override("font_color", Color.GREEN)


func _on_download_failed(_model_id: String, error: String) -> void:
	download_panel.hide()
	status_label.text = "Download failed: %s" % error
	status_label.add_theme_color_override("font_color", Color.RED)
	_update_ui_state()


# Signal handlers - Load/Unload
func _on_load_pressed() -> void:
	var model = _get_selected_load_model()
	if model == null:
		return

	status_label.text = "Loading..."
	status_label.add_theme_color_override("font_color", Color.YELLOW)

	# Load model (this is synchronous, will block briefly)
	var err = _model_manager.load_model(model)
	if err == OK:
		# Apply model's default sampling params to UI
		temperature_slider.value = model.default_temperature
		top_p_slider.value = model.default_top_p
		top_k_spinbox.value = model.default_top_k
		max_tokens_spinbox.value = model.default_max_tokens
		repeat_penalty_slider.value = model.default_repeat_penalty
		min_p_slider.value = model.default_min_p

	_update_ui_state()
	_update_model_info()


func _on_unload_pressed() -> void:
	_model_manager.unload_model()
	_update_ui_state()
	_update_model_info()


func _on_model_loaded(_config: ModelConfig) -> void:
	_update_ui_state()
	_update_model_info()


func _on_model_load_failed(_config: ModelConfig, error: Error) -> void:
	status_label.text = "Load failed: %s" % error_string(error)
	status_label.add_theme_color_override("font_color", Color.RED)
	_update_ui_state()


func _on_model_unloaded() -> void:
	_update_ui_state()
	_update_model_info()


# Signal handlers - Generation
func _on_generate_pressed() -> void:
	if _is_generating or not _model_manager.is_model_loaded():
		return

	var prompt = prompt_input.text.strip_edges()
	if prompt.is_empty():
		output_display.text = "[Error: Please enter a prompt]"
		return

	_is_generating = true
	generate_btn.disabled = true
	generate_btn.text = "Generating..."
	time_label.text = ""
	output_display.text = "Generating..."

	# Apply current sampling params
	_apply_sampling_params()

	# Run generation in thread
	_generation_thread = Thread.new()
	_generation_thread.start(_generate_threaded.bind(prompt))


func _generate_threaded(prompt: String) -> void:
	var start_time = Time.get_ticks_msec()

	var llama = _model_manager.get_llama()
	var result = llama.generate(prompt)

	var elapsed = Time.get_ticks_msec() - start_time

	call_deferred("_on_generation_complete", result, elapsed)


func _on_generation_complete(result: String, elapsed_ms: int) -> void:
	# Clean up thread
	if _generation_thread != null:
		_generation_thread.wait_to_finish()
		_generation_thread = null

	_is_generating = false
	generate_btn.disabled = false
	generate_btn.text = "Generate"

	output_display.text = result
	time_label.text = "Generated in %.2fs" % (elapsed_ms / 1000.0)

	_update_ui_state()


func _on_clear_pressed() -> void:
	output_display.text = ""
	time_label.text = ""


# Signal handlers - Model Management
func _on_manage_pressed() -> void:
	_populate_manage_list()
	manage_panel.show()


func _on_close_manage_pressed() -> void:
	manage_panel.hide()
	_models_to_delete.clear()


func _on_model_checkbox_toggled(toggled: bool, model_id: String) -> void:
	if toggled:
		if not _models_to_delete.has(model_id):
			_models_to_delete.append(model_id)
	else:
		_models_to_delete.erase(model_id)

	delete_selected_btn.disabled = _models_to_delete.is_empty()
	delete_selected_btn.text = "Delete Selected (%d)" % _models_to_delete.size() if not _models_to_delete.is_empty() else "Delete Selected"


func _on_delete_selected_pressed() -> void:
	if _models_to_delete.is_empty():
		return

	# Unload model if it's being deleted
	if _model_manager.is_model_loaded() and _model_manager.current_config != null:
		if _models_to_delete.has(_model_manager.current_config.id):
			_model_manager.unload_model()

	# Delete files
	var deleted_count = 0
	for model_id in _models_to_delete:
		var model = _model_manager.registry.get_model_by_id(model_id)
		if model != null:
			var path = model.get_effective_path()
			if FileAccess.file_exists(path):
				var err = DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
				if err == OK:
					deleted_count += 1
					print("Deleted model: %s" % path)
				else:
					push_error("Failed to delete: %s - %s" % [path, error_string(err)])

	_models_to_delete.clear()
	manage_panel.hide()
	_populate_selectors()
	_update_ui_state()

	status_label.text = "Deleted %d model(s)" % deleted_count
	status_label.add_theme_color_override("font_color", Color.YELLOW)


# Slider value display updates
func _on_temperature_changed(value: float) -> void:
	temperature_value.text = "%.2f" % value


func _on_top_p_changed(value: float) -> void:
	top_p_value.text = "%.2f" % value


func _on_repeat_penalty_changed(value: float) -> void:
	repeat_penalty_value.text = "%.2f" % value


func _on_min_p_changed(value: float) -> void:
	min_p_value.text = "%.2f" % value
