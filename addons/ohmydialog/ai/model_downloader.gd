class_name ModelDownloader
extends Node
## Downloads GGUF models from HuggingFace during development.
##
## Handles large file downloads with progress tracking.
## Models are saved to user://models/ directory.

## Emitted when download starts
signal download_started(model_id: String)

## Emitted periodically with download progress
signal download_progress(model_id: String, downloaded_bytes: int, total_bytes: int)

## Emitted when download completes successfully
signal download_completed(model_id: String, local_path: String)

## Emitted when download fails
signal download_failed(model_id: String, error_message: String)

## Emitted when download is cancelled
signal download_cancelled(model_id: String)

const DOWNLOAD_DIR = "user://models/"
const USER_AGENT = "OhMyDialogSystem/1.0 (Godot GDExtension)"

var _http_request: HTTPRequest
var _current_config: ModelConfig
var _target_path: String
var _is_downloading: bool = false
var _downloaded_bytes: int = 0
var _total_bytes: int = 0


func _ready() -> void:
	_ensure_download_directory()


func _ensure_download_directory() -> void:
	if not DirAccess.dir_exists_absolute(DOWNLOAD_DIR):
		DirAccess.make_dir_recursive_absolute(DOWNLOAD_DIR)


## Starts downloading a model from its configured URL
func download_model(config: ModelConfig) -> Error:
	if _is_downloading:
		push_error("ModelDownloader: Already downloading a model")
		return ERR_BUSY

	if config == null:
		push_error("ModelDownloader: Config is null")
		return ERR_INVALID_PARAMETER

	if config.download_url.is_empty():
		push_error("ModelDownloader: No download URL configured")
		return ERR_INVALID_PARAMETER

	_current_config = config
	_target_path = DOWNLOAD_DIR + config.get_filename()
	_downloaded_bytes = 0
	_total_bytes = int(config.size_mb * 1024 * 1024)  # Estimate from config

	# Create HTTPRequest if needed
	if _http_request == null:
		_http_request = HTTPRequest.new()
		_http_request.use_threads = true
		_http_request.download_file = _target_path
		add_child(_http_request)
		_http_request.request_completed.connect(_on_request_completed)

	# Configure for large downloads
	_http_request.download_file = _target_path
	_http_request.timeout = 0  # No timeout for large files

	# Start request
	var headers = [
		"User-Agent: %s" % USER_AGENT
	]

	var err = _http_request.request(config.download_url, headers)
	if err != OK:
		push_error("ModelDownloader: Failed to start request: %s" % error_string(err))
		return err

	_is_downloading = true
	download_started.emit(config.id)
	print("ModelDownloader: Starting download of %s" % config.display_name)

	return OK


## Cancels the current download
func cancel_download() -> void:
	if not _is_downloading:
		return

	if _http_request != null:
		_http_request.cancel_request()

	_cleanup_partial_download()

	var model_id = _current_config.id if _current_config else ""
	_is_downloading = false
	_current_config = null

	download_cancelled.emit(model_id)
	print("ModelDownloader: Download cancelled")


## Returns true if a download is in progress
func is_downloading() -> bool:
	return _is_downloading


## Returns download progress as 0.0 to 1.0
func get_progress() -> float:
	if not _is_downloading or _total_bytes <= 0:
		return 0.0

	return clampf(float(_downloaded_bytes) / float(_total_bytes), 0.0, 1.0)


## Returns the currently downloading model config, or null
func get_current_model() -> ModelConfig:
	return _current_config


## Returns downloaded bytes
func get_downloaded_bytes() -> int:
	return _downloaded_bytes


## Returns total bytes (estimated or actual)
func get_total_bytes() -> int:
	return _total_bytes


func _process(_delta: float) -> void:
	if not _is_downloading or _http_request == null:
		return

	# Update progress from HTTPRequest
	var body_size = _http_request.get_body_size()
	var downloaded = _http_request.get_downloaded_bytes()

	if body_size > 0:
		_total_bytes = body_size

	if downloaded != _downloaded_bytes:
		_downloaded_bytes = downloaded
		download_progress.emit(
			_current_config.id if _current_config else "",
			_downloaded_bytes,
			_total_bytes
		)


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	var model_id = _current_config.id if _current_config else ""
	var model_name = _current_config.display_name if _current_config else "unknown"

	_is_downloading = false

	if result != HTTPRequest.RESULT_SUCCESS:
		var error_msg = _get_result_error_message(result)
		push_error("ModelDownloader: Download failed - %s" % error_msg)
		_cleanup_partial_download()
		download_failed.emit(model_id, error_msg)
		_current_config = null
		return

	if response_code != 200:
		var error_msg = "HTTP error %d" % response_code
		if response_code == 404:
			error_msg = "Model file not found (404). The URL may have changed."
		elif response_code == 403:
			error_msg = "Access denied (403). The model may require authentication."
		elif response_code >= 500:
			error_msg = "Server error (%d). Please try again later." % response_code

		push_error("ModelDownloader: %s" % error_msg)
		_cleanup_partial_download()
		download_failed.emit(model_id, error_msg)
		_current_config = null
		return

	# Verify file was saved
	if not FileAccess.file_exists(_target_path):
		var error_msg = "File was not saved to disk"
		push_error("ModelDownloader: %s" % error_msg)
		download_failed.emit(model_id, error_msg)
		_current_config = null
		return

	print("ModelDownloader: Successfully downloaded %s to %s" % [model_name, _target_path])
	download_completed.emit(model_id, _target_path)
	_current_config = null


func _cleanup_partial_download() -> void:
	if _target_path.is_empty():
		return

	if FileAccess.file_exists(_target_path):
		var err = DirAccess.remove_absolute(_target_path)
		if err != OK:
			push_warning("ModelDownloader: Could not remove partial download: %s" % _target_path)


func _get_result_error_message(result: int) -> String:
	match result:
		HTTPRequest.RESULT_CHUNKED_BODY_SIZE_MISMATCH:
			return "Chunked body size mismatch"
		HTTPRequest.RESULT_CANT_CONNECT:
			return "Cannot connect to server"
		HTTPRequest.RESULT_CANT_RESOLVE:
			return "Cannot resolve hostname"
		HTTPRequest.RESULT_CONNECTION_ERROR:
			return "Connection error"
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			return "TLS handshake failed"
		HTTPRequest.RESULT_NO_RESPONSE:
			return "No response from server"
		HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED:
			return "Body size limit exceeded"
		HTTPRequest.RESULT_BODY_DECOMPRESS_FAILED:
			return "Failed to decompress body"
		HTTPRequest.RESULT_REQUEST_FAILED:
			return "Request failed"
		HTTPRequest.RESULT_DOWNLOAD_FILE_CANT_OPEN:
			return "Cannot open download file"
		HTTPRequest.RESULT_DOWNLOAD_FILE_WRITE_ERROR:
			return "Error writing to download file"
		HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED:
			return "Too many redirects"
		HTTPRequest.RESULT_TIMEOUT:
			return "Request timed out"
		_:
			return "Unknown error (%d)" % result
