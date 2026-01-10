@tool
class_name HFBrowserDialog
extends Window
## Dialog for browsing and selecting models from HuggingFace.
##
## Allows searching GGUF models and selecting specific quantization files.

## Emitted when a model config is created and ready to add
signal model_selected(config: ModelConfig)

# UI References
@onready var _search_input: LineEdit = %SearchInput
@onready var _search_btn: Button = %SearchBtn
@onready var _results_tree: Tree = %ResultsTree
@onready var _files_tree: Tree = %FilesTree
@onready var _status_label: Label = %StatusLabel
@onready var _add_btn: Button = %AddBtn
@onready var _close_btn: Button = %CloseBtn

# Internal state
var _hf_api: HuggingFaceAPI
var _search_results: Array[Dictionary] = []
var _selected_model_id: String = ""
var _selected_file: Dictionary = {}
var _link_icon: Texture2D

const BUTTON_ID_OPEN_URL := 0


func _ready() -> void:
	_link_icon = EditorInterface.get_editor_theme().get_icon("ExternalLink", "EditorIcons")

	_setup_results_tree()
	_setup_files_tree()

	_search_btn.pressed.connect(_on_search_pressed)
	_search_input.text_submitted.connect(_on_search_submitted)
	_results_tree.item_selected.connect(_on_result_selected)
	_results_tree.button_clicked.connect(_on_results_tree_button_clicked)
	_files_tree.item_selected.connect(_on_file_selected)
	_files_tree.button_clicked.connect(_on_files_tree_button_clicked)
	_add_btn.pressed.connect(_on_add_pressed)
	_close_btn.pressed.connect(_on_close_pressed)
	close_requested.connect(_on_close_pressed)

	_add_btn.disabled = true


func _exit_tree() -> void:
	if _hf_api != null:
		_hf_api.cleanup()


## Initializes the HuggingFace API
func initialize() -> void:
	_hf_api = HuggingFaceAPI.new()
	_hf_api.search_completed.connect(_on_search_completed)
	_hf_api.search_failed.connect(_on_search_failed)
	_hf_api.model_details_completed.connect(_on_model_details_completed)
	_hf_api.model_details_failed.connect(_on_model_details_failed)


## Shows the dialog
func show_dialog() -> void:
	popup_centered(Vector2i(900, 600))
	_search_input.grab_focus()


func _setup_results_tree() -> void:
	_results_tree.columns = 3
	_results_tree.set_column_title(0, "Model")
	_results_tree.set_column_title(1, "Downloads")
	_results_tree.set_column_title(2, "Likes")
	_results_tree.column_titles_visible = true
	_results_tree.set_column_expand(0, true)
	_results_tree.set_column_expand(1, false)
	_results_tree.set_column_expand(2, false)
	_results_tree.set_column_custom_minimum_width(1, 80)
	_results_tree.set_column_custom_minimum_width(2, 60)


func _setup_files_tree() -> void:
	_files_tree.columns = 3
	_files_tree.set_column_title(0, "File")
	_files_tree.set_column_title(1, "Size")
	_files_tree.set_column_title(2, "Quant")
	_files_tree.column_titles_visible = true
	_files_tree.set_column_expand(0, true)
	_files_tree.set_column_expand(1, false)
	_files_tree.set_column_expand(2, false)
	_files_tree.set_column_custom_minimum_width(1, 80)
	_files_tree.set_column_custom_minimum_width(2, 70)


func _do_search() -> void:
	if not _hf_api:
		_status_label.text = "HuggingFace API not initialized"
		return

	var query = _search_input.text.strip_edges()
	if query.is_empty():
		query = "instruct gguf"

	_status_label.text = "Searching..."
	_search_btn.disabled = true
	_results_tree.clear()
	_files_tree.clear()
	_selected_model_id = ""
	_selected_file = {}
	_add_btn.disabled = true

	_hf_api.search_models(query, 100)


func _format_number(n: int) -> String:
	if n >= 1000000:
		return "%.1fM" % (n / 1000000.0)
	elif n >= 1000:
		return "%.1fK" % (n / 1000.0)
	return str(n)


func _on_search_pressed() -> void:
	_do_search()


func _on_search_submitted(_text: String) -> void:
	_do_search()


func _on_search_completed(results: Array[Dictionary]) -> void:
	_search_btn.disabled = false
	_search_results = results

	_results_tree.clear()
	var root = _results_tree.create_item()
	_results_tree.hide_root = true

	if results.is_empty():
		_status_label.text = "No GGUF models found"
		return

	_status_label.text = "Found %d models" % results.size()

	for result in results:
		var item = _results_tree.create_item(root)
		item.set_text(0, result.get("name", ""))
		item.set_metadata(0, result.get("id", ""))
		# Add link button in column 0 (next to model name)
		item.add_button(0, _link_icon, BUTTON_ID_OPEN_URL, false, "Open in HuggingFace")

		var downloads = result.get("downloads", 0)
		item.set_text(1, _format_number(downloads))
		item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_RIGHT)

		item.set_text(2, str(result.get("likes", 0)))
		item.set_text_alignment(2, HORIZONTAL_ALIGNMENT_RIGHT)


func _on_search_failed(error: String) -> void:
	_search_btn.disabled = false
	_status_label.text = "Search failed: %s" % error


func _on_result_selected() -> void:
	var selected = _results_tree.get_selected()
	if selected == null:
		return

	var model_id = selected.get_metadata(0) as String
	if model_id.is_empty():
		return

	_selected_model_id = model_id
	_selected_file = {}
	_add_btn.disabled = true

	_files_tree.clear()
	_status_label.text = "Loading files for %s..." % model_id

	_hf_api.get_model_files(model_id)


func _on_model_details_completed(model_id: String, files: Array[Dictionary]) -> void:
	if model_id != _selected_model_id:
		return

	_files_tree.clear()
	var root = _files_tree.create_item()
	_files_tree.hide_root = true

	if files.is_empty():
		_status_label.text = "No GGUF files found (or all files > 4GB)"
		return

	_status_label.text = "Found %d GGUF files" % files.size()

	for file_info in files:
		var item = _files_tree.create_item(root)

		var filename = file_info.get("filename", "")
		item.set_text(0, filename)
		item.set_metadata(0, file_info)
		# Add link button to open file page on HuggingFace
		item.add_button(0, _link_icon, BUTTON_ID_OPEN_URL, false, "Open file in HuggingFace")

		var size_mb = file_info.get("size_mb", 0.0)
		if size_mb >= 1024:
			item.set_text(1, "%.1f GB" % (size_mb / 1024.0))
		else:
			item.set_text(1, "%.0f MB" % size_mb)
		item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_RIGHT)

		var quant = file_info.get("quantization", "")
		item.set_text(2, quant)

		if file_info.get("is_preferred", false):
			item.set_custom_color(2, Color(0, 0.831, 1))


func _on_model_details_failed(model_id: String, error: String) -> void:
	if model_id != _selected_model_id:
		return

	_status_label.text = "Failed to load files: %s" % error


func _on_file_selected() -> void:
	var selected = _files_tree.get_selected()
	if selected == null:
		_add_btn.disabled = true
		_selected_file = {}
		return

	_selected_file = selected.get_metadata(0) as Dictionary
	_add_btn.disabled = _selected_file.is_empty()


func _on_results_tree_button_clicked(item: TreeItem, _column: int, id: int, _mouse_button_index: int) -> void:
	if id == BUTTON_ID_OPEN_URL:
		var model_id = item.get_metadata(0) as String
		if not model_id.is_empty():
			OS.shell_open("https://huggingface.co/%s" % model_id)


func _on_files_tree_button_clicked(item: TreeItem, _column: int, id: int, _mouse_button_index: int) -> void:
	if id == BUTTON_ID_OPEN_URL:
		var file_info = item.get_metadata(0) as Dictionary
		var filename = file_info.get("filename", "")
		if not _selected_model_id.is_empty() and not filename.is_empty():
			# URL format: https://huggingface.co/{model_id}/blob/main/{filename}
			OS.shell_open("https://huggingface.co/%s/blob/main/%s" % [_selected_model_id, filename])


func _on_add_pressed() -> void:
	if _selected_model_id.is_empty() or _selected_file.is_empty():
		return

	var config = _hf_api.create_model_config(_selected_model_id, _selected_file)
	model_selected.emit(config)
	hide()


func _on_close_pressed() -> void:
	hide()
