@tool
class_name ModelManagerWindow
extends Window
## Window for managing AI models in the editor.
##
## Provides interface for downloading, loading, and managing LLM models.
## Owns the ModelRegistry (editor only) and uses AIService for runtime operations.

## Emitted when a model is loaded
signal model_loaded(config: ModelConfig)

## Emitted when a model is unloaded
signal model_unloaded()

# UI References - Main
@onready var _status_label: Label = %StatusLabel
@onready var _download_panel: PanelContainer = %DownloadPanel
@onready var _download_label: Label = %DownloadLabel
@onready var _download_progress: ProgressBar = %DownloadProgress
@onready var _cancel_download_btn: Button = %CancelDownloadBtn
@onready var _tab_container: TabContainer = %TabContainer

# UI References - Models List
@onready var _models_tree: Tree = %ModelsTree
@onready var _refresh_btn: Button = %RefreshBtn
@onready var _model_details: RichTextLabel = %ModelDetails

# UI References - Action Buttons
@onready var _download_model_btn: Button = %DownloadModelBtn
@onready var _load_model_btn: Button = %LoadModelBtn
@onready var _delete_model_btn: Button = %DeleteModelBtn
@onready var _generate_preset_btn: Button = %GeneratePresetBtn
@onready var _browse_hf_btn: Button = %BrowseHFBtn

# Sub-scenes
@onready var _generation_tab: GenerationTab = %Generation
@onready var _hf_dialog: HFBrowserDialog = %HFBrowserDialog

# Sort options
enum SortBy { NAME, SIZE, CONTEXT, STATUS }

# Internal
var _ai_service: AIService
var _registry: ModelRegistry  # Editor-only model registry
var _downloader: ModelDownloader
var _current_sort: SortBy = SortBy.NAME
var _sort_ascending: bool = true
var _selected_model_id: String = ""
var _link_icon: Texture2D
var _hf_api: HuggingFaceAPI  # For fetching GGUF metadata

const BUTTON_ID_OPEN_URL := 0
const BUTTON_ID_GENERATE_PRESET := 1
const REGISTRY_PATH := "user://ohmydialog_registry.tres"


func _ready() -> void:
	close_requested.connect(_on_close_requested)
	call_deferred("_connect_ai_service")

	_link_icon = EditorInterface.get_editor_theme().get_icon("ExternalLink", "EditorIcons")
	_setup_models_tree()

	# Models Tab signals
	_models_tree.column_title_clicked.connect(_on_column_title_clicked)
	_refresh_btn.pressed.connect(_on_refresh_pressed)
	_models_tree.item_selected.connect(_on_model_tree_selected)
	_models_tree.button_clicked.connect(_on_models_tree_button_clicked)
	_download_model_btn.pressed.connect(_on_download_model_pressed)
	_load_model_btn.pressed.connect(_on_load_model_pressed)
	_delete_model_btn.pressed.connect(_on_delete_model_pressed)
	_generate_preset_btn.pressed.connect(_on_generate_preset_pressed)
	_browse_hf_btn.pressed.connect(_on_browse_hf_pressed)
	_cancel_download_btn.pressed.connect(_on_cancel_download_pressed)

	# Sub-scene signals
	_generation_tab.unload_requested.connect(_on_generation_unload_requested)
	_hf_dialog.model_selected.connect(_on_hf_model_selected)

	# Enable clickable links in model details
	_model_details.meta_clicked.connect(_on_model_details_link_clicked)

	_download_panel.hide()
	_update_ui_state()


func _connect_ai_service() -> void:
	_ai_service = AIService.get_singleton()
	if not _ai_service:
		push_warning("ModelManagerWindow: AIService not available")
		_status_label.text = "AIService not available"
		return

	# Load or create registry (editor only)
	_load_registry()

	# Connect AIService signals
	_ai_service.model_loaded.connect(_on_model_loaded_internal)
	_ai_service.model_load_failed.connect(_on_model_load_failed)
	_ai_service.model_unloaded.connect(_on_model_unloaded_internal)

	# Create downloader (editor only)
	_downloader = ModelDownloader.new()
	add_child(_downloader)
	_downloader.download_progress.connect(_on_download_progress)
	_downloader.download_completed.connect(_on_download_completed)
	_downloader.download_failed.connect(_on_download_failed)

	# Initialize sub-scenes
	_generation_tab.set_ai_service(_ai_service)
	_hf_dialog.initialize()

	_populate_models_tree()
	_update_ui_state()


func _load_registry() -> void:
	if ResourceLoader.exists(REGISTRY_PATH):
		_registry = load(REGISTRY_PATH) as ModelRegistry
	else:
		_registry = ModelRegistry.new()


func _save_registry() -> Error:
	return ResourceSaver.save(_registry, REGISTRY_PATH)


## Shows the window
func show_window() -> void:
	if _ai_service:
		_populate_models_tree()
		_update_ui_state()
		_generation_tab.update_ui_state()
		_generation_tab.update_loaded_model_info()
	popup_centered()


## Returns all available models from the registry
func get_available_models() -> Array[ModelConfig]:
	if _registry:
		return _registry.get_all_models()
	return []


## Returns a model by ID from the registry
func get_model_by_id(id: String) -> ModelConfig:
	if _registry:
		return _registry.get_model_by_id(id)
	return null


func _setup_models_tree() -> void:
	_models_tree.columns = 4
	_models_tree.set_column_title(0, "Model")
	_models_tree.set_column_title(1, "Size")
	_models_tree.set_column_title(2, "Context")
	_models_tree.set_column_title(3, "Status")
	_models_tree.column_titles_visible = true
	_models_tree.set_column_expand(0, true)
	_models_tree.set_column_expand(1, false)
	_models_tree.set_column_expand(2, false)
	_models_tree.set_column_expand(3, false)
	_models_tree.set_column_custom_minimum_width(1, 80)
	_models_tree.set_column_custom_minimum_width(2, 80)
	_models_tree.set_column_custom_minimum_width(3, 100)


func _update_column_titles() -> void:
	var titles = ["Model", "Size", "Context", "Status"]
	var arrows = ["", "", "", ""]
	var arrow = " ↑" if _sort_ascending else " ↓"
	arrows[_current_sort] = arrow

	for i in range(4):
		_models_tree.set_column_title(i, titles[i] + arrows[i])


func _populate_models_tree() -> void:
	_models_tree.clear()
	var root = _models_tree.create_item()
	_models_tree.hide_root = true
	_update_column_titles()

	if not _registry:
		return

	var models = _registry.get_all_models()
	models = _sort_models(models)

	for model in models:
		var item = _models_tree.create_item(root)

		item.set_text(0, model.display_name)
		item.set_metadata(0, model.id)

		# Add link button in column 0 (if model has documentation_url)
		if not model.documentation_url.is_empty():
			item.add_button(0, _link_icon, BUTTON_ID_OPEN_URL, false, "Open documentation")

		item.set_text(1, "%.0f MB" % model.size_mb)
		item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_RIGHT)

		item.set_text(2, "%d" % model.n_ctx)
		item.set_text_alignment(2, HORIZONTAL_ALIGNMENT_RIGHT)

		var is_downloaded = model.is_downloaded()
		var is_loaded = _is_model_loaded(model)

		if is_loaded:
			item.set_text(3, "Loaded")
			item.set_custom_color(3, Color.GREEN)
		elif is_downloaded:
			item.set_text(3, "Ready")
			item.set_custom_color(3, Color.CYAN)
		else:
			item.set_text(3, "Not Downloaded")
			item.set_custom_color(3, Color.GRAY)

		if model.is_custom:
			item.set_custom_color(0, Color.YELLOW)


func _sort_models(models: Array[ModelConfig]) -> Array[ModelConfig]:
	var sorted = models.duplicate()
	var asc = _sort_ascending

	match _current_sort:
		SortBy.NAME:
			sorted.sort_custom(func(a, b):
				var cmp = a.display_name.naturalcasecmp_to(b.display_name) < 0
				return cmp if asc else not cmp
			)
		SortBy.SIZE:
			sorted.sort_custom(func(a, b):
				return a.size_mb < b.size_mb if asc else a.size_mb > b.size_mb
			)
		SortBy.CONTEXT:
			sorted.sort_custom(func(a, b):
				return a.n_ctx < b.n_ctx if asc else a.n_ctx > b.n_ctx
			)
		SortBy.STATUS:
			sorted.sort_custom(func(a, b):
				var a_val = 2 if _is_model_loaded(a) else (1 if a.is_downloaded() else 0)
				var b_val = 2 if _is_model_loaded(b) else (1 if b.is_downloaded() else 0)
				return a_val < b_val if asc else a_val > b_val
			)

	return sorted


func _is_model_loaded(model: ModelConfig) -> bool:
	if not _ai_service:
		return false
	var current = _ai_service.get_current_config()
	return _ai_service.is_model_loaded() and current != null and current.id == model.id


func _get_selected_model() -> ModelConfig:
	var selected = _models_tree.get_selected()
	if selected == null:
		return null

	var model_id = selected.get_metadata(0)
	if model_id == null or model_id.is_empty():
		return null

	return _registry.get_model_by_id(model_id) if _registry else null


func _update_model_details() -> void:
	var model = _get_selected_model()
	if model == null:
		_model_details.text = "[color=#8b949e]Select a model to see details[/color]"
		return

	var is_downloaded = model.is_downloaded()
	var file_size_actual = 0.0

	if is_downloaded:
		var file = FileAccess.open(model.get_effective_path(), FileAccess.READ)
		if file:
			file_size_actual = file.get_length() / (1024.0 * 1024.0)
			file.close()

	var text = "[color=#00d4ff][b]%s[/b][/color]\n" % model.display_name
	text += "[color=#21262d]━━━━━━━━━━━━━━━━━━━━━━[/color]\n\n"

	if not model.description.is_empty():
		text += "[color=#8b949e]%s[/color]\n\n" % model.description

	text += "[color=#a855f7]Status:[/color] "
	if _is_model_loaded(model):
		text += "[color=#10b981][b]● LOADED[/b][/color]\n"
	elif is_downloaded:
		text += "[color=#00d4ff]● Ready[/color]\n"
	else:
		text += "[color=#484f58]○ Not Downloaded[/color]\n"

	text += "\n[color=#10b981][b]Specifications[/b][/color]\n"

	if is_downloaded and file_size_actual > 0:
		text += "[color=#8b949e]File Size:[/color] [color=#00d4ff]%.1f MB[/color]\n" % file_size_actual
	else:
		text += "[color=#8b949e]Est. Size:[/color] ~%.0f MB\n" % model.size_mb

	text += "[color=#8b949e]Context Window:[/color] [color=#00d4ff]%d[/color] tokens\n" % model.n_ctx
	text += "[color=#8b949e]Est. RAM Usage:[/color] ~%.0f MB\n" % (model.size_mb * 1.2)
	text += "[color=#8b949e]GPU Layers:[/color] %d\n" % model.n_gpu_layers

	text += "\n[color=#a855f7][b]Default Sampling[/b][/color]\n"
	text += "[color=#8b949e]Temperature:[/color] %.2f\n" % model.default_temperature
	text += "[color=#8b949e]Top P:[/color] %.2f\n" % model.default_top_p
	text += "[color=#8b949e]Top K:[/color] %d\n" % model.default_top_k
	text += "[color=#8b949e]Max Tokens:[/color] %d\n" % model.default_max_tokens

	if model.is_custom:
		text += "\n[color=#f97316][b]⚠ CUSTOM MODEL[/b][/color]\n"

		# Check for known incompatible architectures
		var model_name_lower = model.display_name.to_lower()
		var doc_url_lower = model.documentation_url.to_lower()
		if "bitnet" in model_name_lower or "bitnet" in doc_url_lower:
			text += "[color=#ef4444][b]⚠ INCOMPATIBLE:[/b] BitNet models require bitnet.cpp runtime[/color]\n"
		elif "rwkv" in model_name_lower:
			text += "[color=#ef4444][b]⚠ INCOMPATIBLE:[/b] RWKV models require specialized runtime[/color]\n"
		elif "mamba" in model_name_lower:
			text += "[color=#f97316][b]⚠ WARNING:[/b] Mamba models may have limited support[/color]\n"

	# Show documentation link if available
	if not model.documentation_url.is_empty():
		text += "\n[color=#3b82f6][url=%s]View on HuggingFace ↗[/url][/color]\n" % model.documentation_url

	# Show file metadata link for custom models (contains chat template, tokenizer info, etc.)
	if not model.file_metadata_url.is_empty():
		text += "[color=#10b981][url=%s]View GGUF Metadata ↗[/url][/color]\n" % model.file_metadata_url

	# Show generate preset link
	text += "[color=#a855f7][url=generate_preset]Generate AI Preset ↗[/url][/color]\n"

	# Show metadata info if available
	if model.has_metadata():
		text += "\n[color=#f97316][b]GGUF Metadata[/b][/color]\n"
		if not model.architecture.is_empty():
			text += "[color=#8b949e]Architecture:[/color] %s\n" % model.architecture
		if not model.chat_template_format.is_empty():
			text += "[color=#8b949e]Template Format:[/color] %s\n" % model.chat_template_format
		if model.ai_preset != null:
			text += "[color=#8b949e]Preset:[/color] [color=#10b981]%s[/color]\n" % model.ai_preset.preset_name

	_model_details.text = text
	_selected_model_id = model.id


func _update_ui_state() -> void:
	if not _ai_service:
		_download_model_btn.disabled = true
		_load_model_btn.disabled = true
		_delete_model_btn.disabled = true
		_generate_preset_btn.disabled = true
		return

	var model = _get_selected_model()
	var is_loaded = _ai_service.is_model_loaded()
	var is_downloading = _downloader != null and _downloader.is_downloading()

	if model != null:
		var model_downloaded = model.is_downloaded()
		var model_is_loaded = _is_model_loaded(model)

		_download_model_btn.disabled = model_downloaded or is_downloading
		_load_model_btn.disabled = not model_downloaded or model_is_loaded or is_downloading
		_delete_model_btn.disabled = not model_downloaded and not model.is_custom
		# Generate preset is always available for selected models with download URL
		_generate_preset_btn.disabled = model.download_url.is_empty() and not model_is_loaded
	else:
		_download_model_btn.disabled = true
		_load_model_btn.disabled = true
		_delete_model_btn.disabled = true
		_generate_preset_btn.disabled = true

	var current_config = _ai_service.get_current_config()
	if is_loaded and current_config != null:
		_status_label.text = "Loaded: %s" % current_config.display_name
		_status_label.add_theme_color_override("font_color", Color.GREEN)
	elif is_downloading:
		_status_label.text = "Downloading..."
		_status_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		_status_label.text = "No model loaded"
		_status_label.remove_theme_color_override("font_color")


# ==================== Signal Handlers - Main ====================

func _on_close_requested() -> void:
	hide()


func _on_column_title_clicked(column: int, _mouse_button_index: int) -> void:
	var new_sort = column as SortBy
	if new_sort == _current_sort:
		_sort_ascending = not _sort_ascending
	else:
		_current_sort = new_sort
		_sort_ascending = true
	_populate_models_tree()


func _on_models_tree_button_clicked(item: TreeItem, _column: int, id: int, _mouse_button_index: int) -> void:
	if id == BUTTON_ID_OPEN_URL:
		var model_id = item.get_metadata(0) as String
		if not model_id.is_empty() and _registry:
			var model = _registry.get_model_by_id(model_id)
			if model and not model.documentation_url.is_empty():
				OS.shell_open(model.documentation_url)


func _on_model_details_link_clicked(meta: Variant) -> void:
	var url = str(meta)
	if url == "generate_preset":
		_on_generate_preset_pressed()
	elif url.begins_with("http"):
		OS.shell_open(url)


func _on_refresh_pressed() -> void:
	_populate_models_tree()
	_update_ui_state()


func _on_model_tree_selected() -> void:
	_update_model_details()
	_update_ui_state()


func _on_download_model_pressed() -> void:
	var model = _get_selected_model()
	if model == null:
		return

	var err = _downloader.download_model(model)
	if err == OK:
		_download_panel.show()
		_download_label.text = "Downloading %s..." % model.display_name
		_download_progress.value = 0

	_update_ui_state()


func _on_load_model_pressed() -> void:
	var model = _get_selected_model()
	if model == null:
		return

	_status_label.text = "Loading %s..." % model.display_name
	_status_label.add_theme_color_override("font_color", Color.YELLOW)

	var err = _ai_service.load_model(model)
	if err == OK:
		_generation_tab.apply_model_defaults(model)
		_tab_container.current_tab = 1
	else:
		_status_label.text = "Failed to load model"
		_status_label.add_theme_color_override("font_color", Color.RED)

	_populate_models_tree()
	_update_ui_state()
	_generation_tab.update_ui_state()
	_generation_tab.update_loaded_model_info()


func _on_delete_model_pressed() -> void:
	var model = _get_selected_model()
	if model == null:
		return

	if _is_model_loaded(model):
		_ai_service.unload_model()

	var path = model.get_effective_path()
	if FileAccess.file_exists(path):
		var err = DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		if err != OK:
			push_error("Failed to delete file: %s" % error_string(err))
			return

	if model.is_custom and _registry:
		_registry.remove_custom_model(model.id)
		_save_registry()

	_populate_models_tree()
	_update_model_details()
	_update_ui_state()


func _on_generate_preset_pressed() -> void:
	var model = _get_selected_model()
	if model == null:
		return

	_status_label.text = "Generating AI Preset for %s..." % model.display_name
	_status_label.add_theme_color_override("font_color", Color.YELLOW)
	_generate_preset_btn.disabled = true

	# Check if model is loaded - use LlamaInterface metadata if available
	var current_config = _ai_service.get_current_config() if _ai_service else null
	if _ai_service and _ai_service.is_model_loaded() and current_config != null and current_config.id == model.id:
		# Model is loaded, get metadata from llama.cpp
		var info = _ai_service.get_model_info()
		var metadata := {
			"_architecture": info.get("architecture", ""),
			"_chat_template": info.get("chat_template", ""),
			"_context_length": info.get("n_ctx_train", info.get("n_ctx", 0))
		}
		# Detect template format if we have a chat template
		if not metadata["_chat_template"].is_empty():
			var parser = GGUFParser.new()
			parser.metadata["tokenizer.chat_template"] = metadata["_chat_template"]
			metadata["_chat_template_format"] = parser.detect_chat_template_format()
		_finish_preset_generation(model, metadata)
	elif not model.download_url.is_empty():
		# Model not loaded, fetch metadata via HTTP Range request
		_ensure_hf_api()
		# Disconnect any existing connections first to avoid duplicates
		if _hf_api.metadata_fetched.is_connected(_on_preset_metadata_fetched):
			_hf_api.metadata_fetched.disconnect(_on_preset_metadata_fetched)
		if _hf_api.metadata_fetch_failed.is_connected(_on_preset_metadata_failed):
			_hf_api.metadata_fetch_failed.disconnect(_on_preset_metadata_failed)
		_hf_api.metadata_fetched.connect(_on_preset_metadata_fetched.bind(model), CONNECT_ONE_SHOT)
		_hf_api.metadata_fetch_failed.connect(_on_preset_metadata_failed.bind(model), CONNECT_ONE_SHOT)

		# Extract model_id and filename from download_url
		# URL format: https://huggingface.co/{model_id}/resolve/main/{filename}
		var url_parts = model.download_url.replace("https://huggingface.co/", "").split("/resolve/main/")
		if url_parts.size() == 2:
			var model_id = url_parts[0]
			var filename = url_parts[1]
			_hf_api.fetch_gguf_metadata(model_id, filename)
		else:
			_on_preset_metadata_failed("", "", "Invalid download URL format", model)
	else:
		# No way to get metadata, create default preset
		var metadata: Dictionary = {}
		_finish_preset_generation(model, metadata)


func _on_preset_metadata_fetched(model_id: String, filename: String, metadata: Dictionary, model: ModelConfig) -> void:
	_finish_preset_generation(model, metadata)


func _on_preset_metadata_failed(model_id: String, filename: String, error: String, model: ModelConfig) -> void:
	push_warning("ModelManagerWindow: Failed to fetch metadata for %s: %s" % [model.display_name, error])
	# Create preset without metadata
	var metadata: Dictionary = {}
	_finish_preset_generation(model, metadata)


func _finish_preset_generation(model: ModelConfig, metadata: Dictionary) -> void:
	# Populate model config with metadata
	if not metadata.is_empty():
		model.populate_from_metadata(metadata)

	# Create AI Preset
	var preset = model.create_ai_preset()

	# Save preset to res://presets/ directory BEFORE assigning to model
	var presets_dir = "res://presets"
	if not DirAccess.dir_exists_absolute(presets_dir):
		DirAccess.make_dir_absolute(presets_dir)

	var preset_path = "%s/%s_preset.tres" % [presets_dir, model.id.replace("-", "_")]
	var err = ResourceSaver.save(preset, preset_path)

	_generate_preset_btn.disabled = false

	if err == OK:
		# Load the saved preset to get a proper resource with path
		var saved_preset = load(preset_path) as AIPreset
		if saved_preset:
			model.ai_preset = saved_preset
		else:
			model.ai_preset = preset
			preset.resource_path = preset_path
		_status_label.text = "AI Preset generated: %s" % preset.preset_name
		_status_label.add_theme_color_override("font_color", Color.GREEN)
		_update_model_details()
	else:
		_status_label.text = "Failed to save preset: %s" % error_string(err)
		_status_label.add_theme_color_override("font_color", Color.RED)


func _ensure_hf_api() -> void:
	if _hf_api == null:
		_hf_api = HuggingFaceAPI.new()


func _on_browse_hf_pressed() -> void:
	_hf_dialog.show_dialog()


func _on_cancel_download_pressed() -> void:
	_downloader.cancel_download()
	_download_panel.hide()
	_update_ui_state()


# ==================== Signal Handlers - Sub-scenes ====================

func _on_generation_unload_requested() -> void:
	_ai_service.unload_model()
	_populate_models_tree()
	_update_ui_state()
	_generation_tab.update_ui_state()
	_generation_tab.update_loaded_model_info()


func _on_hf_model_selected(config: ModelConfig) -> void:
	if _registry:
		_registry.add_custom_model(config)
		_save_registry()
	_populate_models_tree()
	_status_label.text = "Added: %s" % config.display_name
	_status_label.add_theme_color_override("font_color", Color(0, 0.831, 1))


# ==================== Signal Handlers - Download & AIService ====================

func _on_download_progress(_model_id: String, progress: float) -> void:
	_download_progress.value = progress * 100.0
	var downloaded_mb = _downloader.get_downloaded_bytes() / (1024.0 * 1024.0)
	var total_mb = _downloader.get_total_bytes() / (1024.0 * 1024.0)
	_download_label.text = "Downloading... %.1f / %.1f MB" % [downloaded_mb, total_mb]


func _on_download_completed(_model_id: String) -> void:
	_download_panel.hide()
	_populate_models_tree()
	_update_model_details()
	_update_ui_state()
	_status_label.text = "Download complete!"
	_status_label.add_theme_color_override("font_color", Color.GREEN)


func _on_download_failed(_model_id: String, error: String) -> void:
	_download_panel.hide()
	_status_label.text = "Download failed: %s" % error
	_status_label.add_theme_color_override("font_color", Color.RED)
	_update_ui_state()


func _on_model_loaded_internal(config: ModelConfig) -> void:
	_populate_models_tree()
	_update_ui_state()
	_generation_tab.update_ui_state()
	_generation_tab.update_loaded_model_info()
	model_loaded.emit(config)


func _on_model_load_failed(_config: ModelConfig, error: Error) -> void:
	_status_label.text = "Load failed: %s" % error_string(error)
	_status_label.add_theme_color_override("font_color", Color.RED)
	_update_ui_state()


func _on_model_unloaded_internal() -> void:
	_populate_models_tree()
	_update_ui_state()
	_generation_tab.update_ui_state()
	_generation_tab.update_loaded_model_info()
	model_unloaded.emit()
