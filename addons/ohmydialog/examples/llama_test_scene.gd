extends Control
## Test scene for LlamaInterface functionality.
##
## Allows testing model loading, text generation, and sampling parameters.
## Run this scene directly to test the LLM integration.

# UI References - Tabs
@onready var tab_container: TabContainer = %TabContainer

# UI References - Models Tab
@onready var models_tree: Tree = %ModelsTree
@onready var sort_option: OptionButton = %SortOption
@onready var model_details: RichTextLabel = %ModelDetails
@onready var download_model_btn: Button = %DownloadModelBtn
@onready var load_model_btn: Button = %LoadModelBtn
@onready var delete_model_btn: Button = %DeleteModelBtn

# UI References - Generation Tab
@onready var status_label: Label = %StatusLabel
@onready var unload_btn: Button = %UnloadBtn
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
@onready var loaded_model_info: RichTextLabel = %LoadedModelInfo

# UI References - Download Progress
@onready var download_panel: PanelContainer = %DownloadPanel
@onready var download_label: Label = %DownloadLabel
@onready var download_progress: ProgressBar = %DownloadProgress
@onready var cancel_download_btn: Button = %CancelDownloadBtn

# Sort options
enum SortBy { NAME, SIZE, CONTEXT, STATUS }

# Internal
var _model_manager: ModelManager
var _generation_thread: Thread
var _is_generating: bool = false
var _current_sort: SortBy = SortBy.NAME
var _selected_model_id: String = ""


func _ready() -> void:
	# Initialize ModelManager
	_model_manager = ModelManager.new()
	add_child(_model_manager)

	# Connect ModelManager signals
	_model_manager.model_loaded.connect(_on_model_loaded)
	_model_manager.model_load_failed.connect(_on_model_load_failed)
	_model_manager.model_unloaded.connect(_on_model_unloaded)
	_model_manager.download_progress.connect(_on_download_progress)
	_model_manager.download_completed.connect(_on_download_completed)
	_model_manager.download_failed.connect(_on_download_failed)

	# Setup Tree
	_setup_models_tree()

	# Setup sort options
	sort_option.add_item("Name", SortBy.NAME)
	sort_option.add_item("Size", SortBy.SIZE)
	sort_option.add_item("Context", SortBy.CONTEXT)
	sort_option.add_item("Status", SortBy.STATUS)
	sort_option.selected = 0

	# Connect UI signals
	sort_option.item_selected.connect(_on_sort_changed)
	models_tree.item_selected.connect(_on_model_tree_selected)
	download_model_btn.pressed.connect(_on_download_model_pressed)
	load_model_btn.pressed.connect(_on_load_model_pressed)
	delete_model_btn.pressed.connect(_on_delete_model_pressed)
	unload_btn.pressed.connect(_on_unload_pressed)
	generate_btn.pressed.connect(_on_generate_pressed)
	clear_btn.pressed.connect(_on_clear_pressed)
	cancel_download_btn.pressed.connect(_on_cancel_download_pressed)

	# Connect slider value changed
	temperature_slider.value_changed.connect(_on_temperature_changed)
	top_p_slider.value_changed.connect(_on_top_p_changed)
	repeat_penalty_slider.value_changed.connect(_on_repeat_penalty_changed)
	min_p_slider.value_changed.connect(_on_min_p_changed)

	# Populate models
	_populate_models_tree()

	# Initial UI state
	_update_ui_state()
	download_panel.hide()


func _exit_tree() -> void:
	if _generation_thread != null and _generation_thread.is_started():
		_generation_thread.wait_to_finish()


func _setup_models_tree() -> void:
	models_tree.columns = 4
	models_tree.set_column_title(0, "Model")
	models_tree.set_column_title(1, "Size")
	models_tree.set_column_title(2, "Context")
	models_tree.set_column_title(3, "Status")
	models_tree.column_titles_visible = true
	models_tree.set_column_expand(0, true)
	models_tree.set_column_expand(1, false)
	models_tree.set_column_expand(2, false)
	models_tree.set_column_expand(3, false)
	models_tree.set_column_custom_minimum_width(1, 80)
	models_tree.set_column_custom_minimum_width(2, 80)
	models_tree.set_column_custom_minimum_width(3, 100)


func _populate_models_tree() -> void:
	models_tree.clear()
	var root = models_tree.create_item()
	models_tree.hide_root = true

	var models = _model_manager.get_available_models()

	# Sort models
	models = _sort_models(models)

	for model in models:
		var item = models_tree.create_item(root)

		# Column 0: Name
		item.set_text(0, model.display_name)
		item.set_metadata(0, model.id)

		# Column 1: Size
		item.set_text(1, "%.0f MB" % model.size_mb)
		item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_RIGHT)

		# Column 2: Context
		item.set_text(2, "%d" % model.n_ctx)
		item.set_text_alignment(2, HORIZONTAL_ALIGNMENT_RIGHT)

		# Column 3: Status
		var is_downloaded = model.is_downloaded()
		var is_loaded = _model_manager.is_model_loaded() and _model_manager.current_config != null and _model_manager.current_config.id == model.id

		if is_loaded:
			item.set_text(3, "Loaded")
			item.set_custom_color(3, Color.GREEN)
		elif is_downloaded:
			item.set_text(3, "Downloaded")
			item.set_custom_color(3, Color.CYAN)
		else:
			item.set_text(3, "Not Downloaded")
			item.set_custom_color(3, Color.GRAY)

		# Highlight if custom
		if model.is_custom:
			item.set_custom_color(0, Color.YELLOW)


func _sort_models(models: Array[ModelConfig]) -> Array[ModelConfig]:
	var sorted = models.duplicate()

	match _current_sort:
		SortBy.NAME:
			sorted.sort_custom(func(a, b): return a.display_name.naturalcasecmp_to(b.display_name) < 0)
		SortBy.SIZE:
			sorted.sort_custom(func(a, b): return a.size_mb < b.size_mb)
		SortBy.CONTEXT:
			sorted.sort_custom(func(a, b): return a.n_ctx > b.n_ctx)
		SortBy.STATUS:
			sorted.sort_custom(func(a, b):
				var a_downloaded = 1 if a.is_downloaded() else 0
				var b_downloaded = 1 if b.is_downloaded() else 0
				return a_downloaded > b_downloaded
			)

	return sorted


func _get_selected_model() -> ModelConfig:
	var selected = models_tree.get_selected()
	if selected == null:
		return null

	var model_id = selected.get_metadata(0)
	if model_id == null or model_id.is_empty():
		return null

	return _model_manager.registry.get_model_by_id(model_id)


func _update_model_details() -> void:
	var model = _get_selected_model()
	if model == null:
		model_details.text = "Select a model to see details"
		return

	var is_downloaded = model.is_downloaded()
	var file_size_actual = 0.0

	if is_downloaded:
		var file = FileAccess.open(model.get_effective_path(), FileAccess.READ)
		if file:
			file_size_actual = file.get_length() / (1024.0 * 1024.0)
			file.close()

	var text = "[b]%s[/b]\n\n" % model.display_name

	# Description
	if not model.description.is_empty():
		text += "[color=gray]%s[/color]\n\n" % model.description

	# Status
	text += "[b]Status:[/b] "
	if _model_manager.is_model_loaded() and _model_manager.current_config != null and _model_manager.current_config.id == model.id:
		text += "[color=green]Loaded[/color]\n"
	elif is_downloaded:
		text += "[color=cyan]Downloaded[/color]\n"
	else:
		text += "[color=gray]Not Downloaded[/color]\n"

	text += "\n[b]Specifications:[/b]\n"

	# Size
	if is_downloaded and file_size_actual > 0:
		text += "  File Size: %.1f MB\n" % file_size_actual
	else:
		text += "  Est. Size: ~%.0f MB\n" % model.size_mb

	# Context
	text += "  Context Window: %d tokens\n" % model.n_ctx

	# Estimate memory (rough: ~1.1x file size for Q8, varies by quantization)
	var est_memory = model.size_mb * 1.2
	text += "  Est. RAM Usage: ~%.0f MB\n" % est_memory

	# GPU layers
	text += "  GPU Layers: %d\n" % model.n_gpu_layers

	# Batch size
	text += "  Batch Size: %d\n" % model.n_batch

	text += "\n[b]Default Sampling:[/b]\n"
	text += "  Temperature: %.2f\n" % model.default_temperature
	text += "  Top P: %.2f\n" % model.default_top_p
	text += "  Top K: %d\n" % model.default_top_k
	text += "  Max Tokens: %d\n" % model.default_max_tokens

	if model.is_custom:
		text += "\n[color=yellow][b]Custom Model[/b][/color]\n"
		text += "[color=yellow]Use at your own responsibility.[/color]"

	model_details.text = text
	_selected_model_id = model.id


func _update_loaded_model_info() -> void:
	if not _model_manager.is_model_loaded():
		loaded_model_info.text = "No model loaded.\nGo to Models tab to load one."
		return

	var config = _model_manager.current_config
	var info = _model_manager.get_model_info()

	var text = "[b]%s[/b]\n" % config.display_name

	if info.has("n_params"):
		var params = info["n_params"]
		var params_str = "%.2fB" % (params / 1_000_000_000.0) if params >= 1_000_000_000 else "%.0fM" % (params / 1_000_000.0)
		text += "Parameters: %s\n" % params_str

	if info.has("n_ctx"):
		text += "Context: %d tokens\n" % info["n_ctx"]

	if info.has("vocab_size"):
		text += "Vocabulary: %d\n" % info["vocab_size"]

	if info.has("n_layer"):
		text += "Layers: %d\n" % info["n_layer"]

	loaded_model_info.text = text


func _update_ui_state() -> void:
	var model = _get_selected_model()
	var is_loaded = _model_manager.is_model_loaded()
	var is_downloading = _model_manager.is_downloading()

	# Models tab buttons
	if model != null:
		var model_downloaded = model.is_downloaded()
		var model_is_loaded = is_loaded and _model_manager.current_config != null and _model_manager.current_config.id == model.id

		download_model_btn.disabled = model_downloaded or is_downloading
		load_model_btn.disabled = not model_downloaded or model_is_loaded or is_downloading
		delete_model_btn.disabled = not model_downloaded or model_is_loaded
	else:
		download_model_btn.disabled = true
		load_model_btn.disabled = true
		delete_model_btn.disabled = true

	# Generation tab
	unload_btn.disabled = not is_loaded
	generate_btn.disabled = not is_loaded or _is_generating

	# Status
	if is_loaded and _model_manager.current_config != null:
		status_label.text = "Model: %s" % _model_manager.current_config.display_name
		status_label.add_theme_color_override("font_color", Color.GREEN)
	elif is_downloading:
		status_label.text = "Downloading..."
		status_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		status_label.text = "No model loaded"
		status_label.remove_theme_color_override("font_color")


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

	if seed_spinbox.value < 0:
		llama.seed = 0xFFFFFFFF
	else:
		llama.seed = int(seed_spinbox.value)

	var stop_text = stop_sequences_input.text.strip_edges()
	if stop_text.is_empty():
		llama.clear_stop_sequences()
	else:
		var sequences = stop_text.split("\n", false)
		llama.set_stop_sequences(PackedStringArray(sequences))


# Signal handlers - Models Tab
func _on_sort_changed(index: int) -> void:
	_current_sort = sort_option.get_item_id(index) as SortBy
	_populate_models_tree()


func _on_model_tree_selected() -> void:
	_update_model_details()
	_update_ui_state()


func _on_download_model_pressed() -> void:
	var model = _get_selected_model()
	if model == null:
		return

	var err = _model_manager.download_model(model)
	if err == OK:
		download_panel.show()
		download_label.text = "Downloading %s..." % model.display_name
		download_progress.value = 0

	_update_ui_state()


func _on_load_model_pressed() -> void:
	var model = _get_selected_model()
	if model == null:
		return

	status_label.text = "Loading %s..." % model.display_name
	status_label.add_theme_color_override("font_color", Color.YELLOW)

	var err = _model_manager.load_model(model)
	if err == OK:
		# Apply model's defaults to UI
		temperature_slider.value = model.default_temperature
		top_p_slider.value = model.default_top_p
		top_k_spinbox.value = model.default_top_k
		max_tokens_spinbox.value = model.default_max_tokens
		repeat_penalty_slider.value = model.default_repeat_penalty
		min_p_slider.value = model.default_min_p

		# Switch to generation tab
		tab_container.current_tab = 1

	_populate_models_tree()
	_update_ui_state()
	_update_loaded_model_info()


func _on_delete_model_pressed() -> void:
	var model = _get_selected_model()
	if model == null:
		return

	var path = model.get_effective_path()
	if FileAccess.file_exists(path):
		var err = DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		if err == OK:
			print("Deleted model: %s" % path)
			_populate_models_tree()
			_update_model_details()
			_update_ui_state()
		else:
			push_error("Failed to delete: %s" % error_string(err))


func _on_cancel_download_pressed() -> void:
	_model_manager.cancel_download()
	download_panel.hide()
	_update_ui_state()


# Signal handlers - Generation Tab
func _on_unload_pressed() -> void:
	_model_manager.unload_model()
	_populate_models_tree()
	_update_ui_state()
	_update_loaded_model_info()


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

	_apply_sampling_params()

	_generation_thread = Thread.new()
	_generation_thread.start(_generate_threaded.bind(prompt))


func _generate_threaded(prompt: String) -> void:
	var start_time = Time.get_ticks_msec()
	var llama = _model_manager.get_llama()
	var result = llama.generate(prompt)
	var elapsed = Time.get_ticks_msec() - start_time
	call_deferred("_on_generation_complete", result, elapsed)


func _on_generation_complete(result: String, elapsed_ms: int) -> void:
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


# Signal handlers - ModelManager
func _on_download_progress(_model_id: String, progress: float) -> void:
	download_progress.value = progress * 100.0
	var downloaded_mb = _model_manager.downloader.get_downloaded_bytes() / (1024.0 * 1024.0)
	var total_mb = _model_manager.downloader.get_total_bytes() / (1024.0 * 1024.0)
	download_label.text = "Downloading... %.1f / %.1f MB" % [downloaded_mb, total_mb]


func _on_download_completed(_model_id: String) -> void:
	download_panel.hide()
	_populate_models_tree()
	_update_model_details()
	_update_ui_state()
	status_label.text = "Download complete!"
	status_label.add_theme_color_override("font_color", Color.GREEN)


func _on_download_failed(_model_id: String, error: String) -> void:
	download_panel.hide()
	status_label.text = "Download failed: %s" % error
	status_label.add_theme_color_override("font_color", Color.RED)
	_update_ui_state()


func _on_model_loaded(_config: ModelConfig) -> void:
	_populate_models_tree()
	_update_ui_state()
	_update_loaded_model_info()


func _on_model_load_failed(_config: ModelConfig, error: Error) -> void:
	status_label.text = "Load failed: %s" % error_string(error)
	status_label.add_theme_color_override("font_color", Color.RED)
	_update_ui_state()


func _on_model_unloaded() -> void:
	_populate_models_tree()
	_update_ui_state()
	_update_loaded_model_info()


# Slider updates
func _on_temperature_changed(value: float) -> void:
	temperature_value.text = "%.2f" % value

func _on_top_p_changed(value: float) -> void:
	top_p_value.text = "%.2f" % value

func _on_repeat_penalty_changed(value: float) -> void:
	repeat_penalty_value.text = "%.2f" % value

func _on_min_p_changed(value: float) -> void:
	min_p_value.text = "%.2f" % value
