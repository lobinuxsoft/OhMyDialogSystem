class_name ModelManager
extends Node
## Central manager for LLM model operations.
##
## Handles model loading/unloading, provides access to LlamaInterface,
## and manages model downloads through ModelDownloader.

## Emitted when a model is successfully loaded
signal model_loaded(config: ModelConfig)

## Emitted when model loading fails
signal model_load_failed(config: ModelConfig, error: Error)

## Emitted when model is unloaded
signal model_unloaded()

## Emitted when download progress updates
signal download_progress(model_id: String, progress: float)

## Emitted when download completes
signal download_completed(model_id: String)

## Emitted when download fails
signal download_failed(model_id: String, error: String)

## The LlamaInterface instance for inference
var llama: LlamaInterface

## Currently loaded model configuration
var current_config: ModelConfig

## Model downloader instance
var downloader: ModelDownloader

## Model registry with available models
var registry: ModelRegistry

var _is_loading: bool = false


func _ready() -> void:
	llama = LlamaInterface.new()

	downloader = ModelDownloader.new()
	add_child(downloader)
	downloader.download_progress.connect(_on_download_progress)
	downloader.download_completed.connect(_on_download_completed)
	downloader.download_failed.connect(_on_download_failed)

	# Load or create registry
	_load_registry()


func _load_registry() -> void:
	var registry_path = "user://ohmydialog_registry.tres"

	if ResourceLoader.exists(registry_path):
		registry = load(registry_path) as ModelRegistry
	else:
		registry = ModelRegistry.new()


## Saves the current registry to user://
func save_registry() -> Error:
	var registry_path = "user://ohmydialog_registry.tres"
	return ResourceSaver.save(registry, registry_path)


## Loads a model from the given configuration
func load_model(config: ModelConfig) -> Error:
	if config == null:
		push_error("ModelManager: Config is null")
		return ERR_INVALID_PARAMETER

	if _is_loading:
		push_error("ModelManager: Already loading a model")
		return ERR_BUSY

	# Check if model file exists
	var model_path = config.get_effective_path()
	if not FileAccess.file_exists(model_path):
		push_error("ModelManager: Model file not found at %s" % model_path)
		model_load_failed.emit(config, ERR_FILE_NOT_FOUND)
		return ERR_FILE_NOT_FOUND

	# Unload current model if any
	if is_model_loaded():
		unload_model()

	_is_loading = true
	print("ModelManager: Loading model %s from %s" % [config.display_name, model_path])

	var err = llama.load_model(model_path, config.get_load_params())

	_is_loading = false

	if err != OK:
		push_error("ModelManager: Failed to load model: %s" % error_string(err))
		model_load_failed.emit(config, err)
		return err

	# Apply default sampling parameters
	config.apply_defaults_to(llama)

	current_config = config
	print("ModelManager: Model loaded successfully")
	model_loaded.emit(config)

	return OK


## Loads a model by its ID from the registry
func load_model_by_id(id: String) -> Error:
	var config = registry.get_model_by_id(id)
	if config == null:
		push_error("ModelManager: Model not found in registry: %s" % id)
		return ERR_DOES_NOT_EXIST

	return load_model(config)


## Unloads the currently loaded model
func unload_model() -> void:
	if not is_model_loaded():
		return

	llama.unload_model()
	current_config = null
	model_unloaded.emit()
	print("ModelManager: Model unloaded")


## Returns true if a model is currently loaded
func is_model_loaded() -> bool:
	return llama != null and llama.is_model_loaded()


## Returns the LlamaInterface for direct access (for generation)
func get_llama() -> LlamaInterface:
	return llama


## Returns the currently loaded model configuration
func get_current_config() -> ModelConfig:
	return current_config


## Returns all available models from the registry
func get_available_models() -> Array[ModelConfig]:
	return registry.get_all_models()


## Downloads a model using the downloader
func download_model(config: ModelConfig) -> Error:
	return downloader.download_model(config)


## Cancels the current download
func cancel_download() -> void:
	downloader.cancel_download()


## Returns true if a download is in progress
func is_downloading() -> bool:
	return downloader.is_downloading()


## Returns download progress (0.0 to 1.0)
func get_download_progress() -> float:
	return downloader.get_progress()


## Adds a custom model to the registry
func add_custom_model(config: ModelConfig) -> void:
	registry.add_custom_model(config)
	save_registry()


## Removes a custom model from the registry
func remove_custom_model(id: String) -> bool:
	var result = registry.remove_custom_model(id)
	if result:
		save_registry()
	return result


## Gets model info dictionary (from loaded model)
func get_model_info() -> Dictionary:
	if not is_model_loaded():
		return {}
	return llama.get_model_info()


func _on_download_progress(model_id: String, downloaded_bytes: int, total_bytes: int) -> void:
	var progress = 0.0
	if total_bytes > 0:
		progress = float(downloaded_bytes) / float(total_bytes)
	download_progress.emit(model_id, progress)


func _on_download_completed(model_id: String, _local_path: String) -> void:
	download_completed.emit(model_id)


func _on_download_failed(model_id: String, error_message: String) -> void:
	download_failed.emit(model_id, error_message)
