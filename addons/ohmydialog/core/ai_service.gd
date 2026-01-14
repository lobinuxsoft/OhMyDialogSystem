@tool
class_name AIService
extends Node
## Central singleton for AI runtime operations in OhMyDialogSystem.
##
## Provides global access to LLM inference via LlamaInterface.
## Handles model loading/unloading at runtime.
## Model registry and downloads are handled by ModelManagerWindow (editor only).

## Emitted when a model is successfully loaded
signal model_loaded(config: ModelConfig)

## Emitted when model is unloaded
signal model_unloaded()

## Emitted when model loading fails
signal model_load_failed(config: ModelConfig, error: Error)

## Internal singleton instance
static var _instance: AIService

## The LlamaInterface instance for inference
var _llama: LlamaInterface

## Currently loaded model configuration
var _current_config: ModelConfig

## Whether a model is currently being loaded
var _is_loading: bool = false


## Returns the singleton instance
static func get_singleton() -> AIService:
	return _instance


func _enter_tree() -> void:
	if _instance != null and _instance != self:
		push_warning("AIService: Multiple instances detected, freeing duplicate")
		queue_free()
		return

	_instance = self
	Engine.register_singleton("AIService", self)

	_llama = LlamaInterface.new()


func _exit_tree() -> void:
	if _instance == self:
		Engine.unregister_singleton("AIService")
		_instance = null

	if _llama and _llama.is_model_loaded():
		_llama.unload_model()
	_llama = null
	_current_config = null


## Returns the LlamaInterface for direct generation access
func get_llama() -> LlamaInterface:
	return _llama


## Returns true if a model is currently loaded and ready
func is_model_loaded() -> bool:
	return _llama != null and _llama.is_model_loaded()


## Returns the currently loaded model configuration
func get_current_config() -> ModelConfig:
	return _current_config


## Loads a model from the given configuration
func load_model(config: ModelConfig) -> Error:
	if config == null:
		push_error("AIService: Config is null")
		return ERR_INVALID_PARAMETER

	if _is_loading:
		push_error("AIService: Already loading a model")
		return ERR_BUSY

	# Check if model file exists
	var model_path = config.get_effective_path()
	if not FileAccess.file_exists(model_path):
		push_error("AIService: Model file not found at %s" % model_path)
		model_load_failed.emit(config, ERR_FILE_NOT_FOUND)
		return ERR_FILE_NOT_FOUND

	# Unload current model if any
	if is_model_loaded():
		unload_model()

	_is_loading = true
	print("AIService: Loading model %s from %s" % [config.display_name, model_path])

	var err = _llama.load_model(model_path, config.get_load_params())

	_is_loading = false

	if err != OK:
		push_error("AIService: Failed to load model: %s" % error_string(err))
		model_load_failed.emit(config, err)
		return err

	# Apply default sampling parameters
	config.apply_defaults_to(_llama)

	_current_config = config
	print("AIService: Model loaded successfully")
	model_loaded.emit(config)

	return OK


## Unloads the currently loaded model
func unload_model() -> void:
	if not is_model_loaded():
		return

	_llama.unload_model()
	_current_config = null
	model_unloaded.emit()
	print("AIService: Model unloaded")


## Gets model info dictionary (from loaded model)
func get_model_info() -> Dictionary:
	if not is_model_loaded():
		return {}
	return _llama.get_model_info()


## Gets system info string (CPU features, backend capabilities)
func get_system_info() -> String:
	if _llama:
		return _llama.get_system_info()
	return ""
