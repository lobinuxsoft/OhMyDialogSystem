@tool
class_name AIService
extends Node
## Central singleton for AI operations in OhMyDialogSystem.
##
## Provides global access to model management and LLM inference.
## Works in both editor and runtime contexts.

## Emitted when a model is loaded successfully
signal model_loaded(config: ModelConfig)

## Emitted when model is unloaded
signal model_unloaded()

## Emitted when model loading fails
signal model_load_failed(config: ModelConfig, error: Error)

## Internal singleton instance
static var _instance: AIService

## The ModelManager instance handling model operations
var _model_manager: ModelManager


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

	_setup_model_manager()


func _exit_tree() -> void:
	if _instance == self:
		Engine.unregister_singleton("AIService")
		_instance = null

	if _model_manager:
		_model_manager.queue_free()
		_model_manager = null


func _setup_model_manager() -> void:
	_model_manager = ModelManager.new()
	_model_manager.name = "ModelManager"
	add_child(_model_manager)

	# Forward signals
	_model_manager.model_loaded.connect(_on_model_loaded)
	_model_manager.model_unloaded.connect(_on_model_unloaded)
	_model_manager.model_load_failed.connect(_on_model_load_failed)


## Ensures a model is loaded before proceeding.
## Returns true if model is ready, false if not available.
## Note: Dialog prompting will be handled by UI layer (issue #166)
func ensure_model_loaded() -> bool:
	if is_model_loaded():
		return true

	# Check if there's a default/last-used model we can auto-load
	var models = _model_manager.get_available_models()
	for config in models:
		if config.is_downloaded():
			var err = _model_manager.load_model(config)
			if err == OK:
				return true

	# No model available - UI layer should show dialog
	return false


## Returns the LlamaInterface for direct generation access
func get_llama() -> LlamaInterface:
	if _model_manager:
		return _model_manager.get_llama()
	return null


## Returns true if a model is currently loaded and ready
func is_model_loaded() -> bool:
	return _model_manager != null and _model_manager.is_model_loaded()


## Returns the ModelManager for advanced operations
func get_model_manager() -> ModelManager:
	return _model_manager


## Returns the currently loaded model configuration
func get_current_config() -> ModelConfig:
	if _model_manager:
		return _model_manager.get_current_config()
	return null


## Loads a specific model configuration
func load_model(config: ModelConfig) -> Error:
	if _model_manager:
		return _model_manager.load_model(config)
	return ERR_UNCONFIGURED


## Unloads the current model
func unload_model() -> void:
	if _model_manager:
		_model_manager.unload_model()


func _on_model_loaded(config: ModelConfig) -> void:
	model_loaded.emit(config)


func _on_model_unloaded() -> void:
	model_unloaded.emit()


func _on_model_load_failed(config: ModelConfig, error: Error) -> void:
	model_load_failed.emit(config, error)
