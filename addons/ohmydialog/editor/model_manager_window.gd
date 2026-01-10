@tool
class_name ModelManagerWindow
extends Window
## Window for managing AI models in the editor.
##
## Provides interface for downloading, loading, and managing LLM models.
## Uses sub-scenes for Generation tab and HuggingFace browser.

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
@onready var _browse_hf_btn: Button = %BrowseHFBtn

# Sub-scenes
@onready var _generation_tab: GenerationTab = %Generation
@onready var _hf_dialog: HFBrowserDialog = %HFBrowserDialog

# Sort options
enum SortBy { NAME, SIZE, CONTEXT, STATUS }

# Internal
var _ai_service: AIService
var _model_manager: ModelManager
var _current_sort: SortBy = SortBy.NAME
var _sort_ascending: bool = true
var _selected_model_id: String = ""
var _link_icon: Texture2D

const BUTTON_ID_OPEN_URL := 0


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

	_model_manager = _ai_service.get_model_manager()
	if not _model_manager:
		push_warning("ModelManagerWindow: ModelManager not available")
		_status_label.text = "ModelManager not available"
		return

	# Connect ModelManager signals
	_model_manager.model_loaded.connect(_on_model_loaded_internal)
	_model_manager.model_load_failed.connect(_on_model_load_failed)
	_model_manager.model_unloaded.connect(_on_model_unloaded_internal)
	_model_manager.download_progress.connect(_on_download_progress)
	_model_manager.download_completed.connect(_on_download_completed)
	_model_manager.download_failed.connect(_on_download_failed)

	# Initialize sub-scenes
	_generation_tab.set_model_manager(_model_manager)
	_hf_dialog.initialize()

	_populate_models_tree()
	_update_ui_state()


## Shows the window
func show_window() -> void:
	if _model_manager:
		_populate_models_tree()
		_update_ui_state()
		_generation_tab.update_ui_state()
		_generation_tab.update_loaded_model_info()
	popup_centered()


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

	if not _model_manager:
		return

	var models = _model_manager.get_available_models()
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
	return _model_manager.is_model_loaded() and _model_manager.current_config != null and _model_manager.current_config.id == model.id


func _get_selected_model() -> ModelConfig:
	var selected = _models_tree.get_selected()
	if selected == null:
		return null

	var model_id = selected.get_metadata(0)
	if model_id == null or model_id.is_empty():
		return null

	return _model_manager.registry.get_model_by_id(model_id)


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

	_model_details.text = text
	_selected_model_id = model.id


func _update_ui_state() -> void:
	if not _model_manager:
		_download_model_btn.disabled = true
		_load_model_btn.disabled = true
		_delete_model_btn.disabled = true
		return

	var model = _get_selected_model()
	var is_loaded = _model_manager.is_model_loaded()
	var is_downloading = _model_manager.is_downloading()

	if model != null:
		var model_downloaded = model.is_downloaded()
		var model_is_loaded = _is_model_loaded(model)

		_download_model_btn.disabled = model_downloaded or is_downloading
		_load_model_btn.disabled = not model_downloaded or model_is_loaded or is_downloading
		_delete_model_btn.disabled = not model_downloaded and not model.is_custom
	else:
		_download_model_btn.disabled = true
		_load_model_btn.disabled = true
		_delete_model_btn.disabled = true

	if is_loaded and _model_manager.current_config != null:
		_status_label.text = "Loaded: %s" % _model_manager.current_config.display_name
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
		if not model_id.is_empty():
			var model = _model_manager.registry.get_model_by_id(model_id)
			if model and not model.documentation_url.is_empty():
				OS.shell_open(model.documentation_url)


func _on_model_details_link_clicked(meta: Variant) -> void:
	var url = str(meta)
	if url.begins_with("http"):
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

	var err = _model_manager.download_model(model)
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

	var err = _model_manager.load_model(model)
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
		_model_manager.unload_model()

	var path = model.get_effective_path()
	if FileAccess.file_exists(path):
		var err = DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		if err != OK:
			push_error("Failed to delete file: %s" % error_string(err))
			return

	if model.is_custom:
		_model_manager.remove_custom_model(model.id)
	else:
		# Notify that a built-in model file was deleted
		_model_manager.notify_models_changed()

	_populate_models_tree()
	_update_model_details()
	_update_ui_state()


func _on_browse_hf_pressed() -> void:
	_hf_dialog.show_dialog()


func _on_cancel_download_pressed() -> void:
	_model_manager.cancel_download()
	_download_panel.hide()
	_update_ui_state()


# ==================== Signal Handlers - Sub-scenes ====================

func _on_generation_unload_requested() -> void:
	_model_manager.unload_model()
	_populate_models_tree()
	_update_ui_state()
	_generation_tab.update_ui_state()
	_generation_tab.update_loaded_model_info()


func _on_hf_model_selected(config: ModelConfig) -> void:
	_model_manager.add_custom_model(config)
	_populate_models_tree()
	_status_label.text = "Added: %s" % config.display_name
	_status_label.add_theme_color_override("font_color", Color(0, 0.831, 1))


# ==================== Signal Handlers - ModelManager ====================

func _on_download_progress(_model_id: String, progress: float) -> void:
	_download_progress.value = progress * 100.0
	var downloaded_mb = _model_manager.downloader.get_downloaded_bytes() / (1024.0 * 1024.0)
	var total_mb = _model_manager.downloader.get_total_bytes() / (1024.0 * 1024.0)
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
