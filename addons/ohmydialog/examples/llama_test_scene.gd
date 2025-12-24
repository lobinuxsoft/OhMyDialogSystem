extends Control
## Test scene for LlamaInterface functionality.
##
## Allows testing model loading, text generation, and sampling parameters.
## Run this scene directly to test the LLM integration.

# UI References - Toolbar
@onready var model_selector: OptionButton = %ModelSelector
@onready var download_btn: Button = %DownloadBtn
@onready var load_btn: Button = %LoadBtn
@onready var unload_btn: Button = %UnloadBtn
@onready var status_label: Label = %StatusLabel

# UI References - Download Progress
@onready var download_panel: PanelContainer = %DownloadPanel
@onready var download_label: Label = %DownloadLabel
@onready var download_progress: ProgressBar = %DownloadProgress
@onready var cancel_download_btn: Button = %CancelDownloadBtn

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

	# Populate model selector
	_populate_model_selector()

	# Connect UI signals
	model_selector.item_selected.connect(_on_model_selected)
	download_btn.pressed.connect(_on_download_pressed)
	load_btn.pressed.connect(_on_load_pressed)
	unload_btn.pressed.connect(_on_unload_pressed)
	generate_btn.pressed.connect(_on_generate_pressed)
	clear_btn.pressed.connect(_on_clear_pressed)
	cancel_download_btn.pressed.connect(_on_cancel_download_pressed)

	# Connect slider value changed
	temperature_slider.value_changed.connect(_on_temperature_changed)
	top_p_slider.value_changed.connect(_on_top_p_changed)
	repeat_penalty_slider.value_changed.connect(_on_repeat_penalty_changed)
	min_p_slider.value_changed.connect(_on_min_p_changed)

	# Initial UI state
	_update_ui_state()
	download_panel.hide()
	custom_warning.hide()


func _exit_tree() -> void:
	# Wait for generation thread
	if _generation_thread != null and _generation_thread.is_started():
		_generation_thread.wait_to_finish()


func _populate_model_selector() -> void:
	model_selector.clear()

	var models = _model_manager.get_available_models()
	for i in range(models.size()):
		var model = models[i]
		var suffix = ""
		if model.is_downloaded():
			suffix = " [Downloaded]"
		elif model.is_custom:
			suffix = " [Custom]"

		model_selector.add_item(model.display_name + suffix, i)
		model_selector.set_item_metadata(i, model.id)

	# Select recommended model by default
	for i in range(model_selector.item_count):
		if model_selector.get_item_metadata(i) == "qwen2.5-0.5b-instruct":
			model_selector.select(i)
			break


func _get_selected_model() -> ModelConfig:
	var idx = model_selector.selected
	if idx < 0:
		return null

	var model_id = model_selector.get_item_metadata(idx)
	return _model_manager.registry.get_model_by_id(model_id)


func _update_ui_state() -> void:
	var model = _get_selected_model()
	var is_loaded = _model_manager.is_model_loaded()
	var is_downloading = _model_manager.is_downloading()

	# Model selector
	model_selector.disabled = is_loaded or is_downloading

	# Buttons
	if model != null:
		download_btn.disabled = model.is_downloaded() or is_downloading or is_loaded
		load_btn.disabled = not model.is_downloaded() or is_downloading or is_loaded
	else:
		download_btn.disabled = true
		load_btn.disabled = true

	unload_btn.disabled = not is_loaded
	generate_btn.disabled = not is_loaded or _is_generating

	# Custom warning
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


# Signal handlers
func _on_model_selected(_index: int) -> void:
	_update_ui_state()


func _on_download_pressed() -> void:
	var model = _get_selected_model()
	if model == null:
		return

	var err = _model_manager.download_model(model)
	if err == OK:
		download_panel.show()
		download_label.text = "Downloading %s..." % model.display_name
		download_progress.value = 0

	_update_ui_state()


func _on_load_pressed() -> void:
	var model = _get_selected_model()
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
	_populate_model_selector()  # Refresh to show [Downloaded]
	_update_ui_state()


func _on_download_failed(_model_id: String, error: String) -> void:
	download_panel.hide()
	status_label.text = "Download failed: %s" % error
	status_label.add_theme_color_override("font_color", Color.RED)
	_update_ui_state()


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


# Slider value display updates
func _on_temperature_changed(value: float) -> void:
	temperature_value.text = "%.2f" % value


func _on_top_p_changed(value: float) -> void:
	top_p_value.text = "%.2f" % value


func _on_repeat_penalty_changed(value: float) -> void:
	repeat_penalty_value.text = "%.2f" % value


func _on_min_p_changed(value: float) -> void:
	min_p_value.text = "%.2f" % value
