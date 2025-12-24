@tool
class_name ModelRegistry
extends Resource
## Registry of available language models for OhMyDialogSystem.
##
## Contains predefined models (recommended) and supports custom models.
## Use [method get_model_by_id] to retrieve a specific model configuration.

## Predefined models with tested configurations
const PREDEFINED_MODELS: Array[Dictionary] = [
	{
		"id": "smollm-135m-instruct",
		"display_name": "SmolLM 135M Instruct",
		"description": "Ultra-light model (~100MB). Very fast inference, suitable for testing and simple completions. Limited quality for complex tasks.",
		"size_mb": 145.0,
		"download_url": "https://huggingface.co/QuantFactory/SmolLM-135M-Instruct-GGUF/resolve/main/SmolLM-135M-Instruct.Q8_0.gguf",
		"default_temperature": 0.7,
		"default_top_p": 0.95,
		"default_top_k": 40,
		"default_max_tokens": 128,
		"default_repeat_penalty": 1.1,
		"default_min_p": 0.05,
		"n_ctx": 2048,
		"n_gpu_layers": 0,
		"n_batch": 512
	},
	{
		"id": "qwen2.5-0.5b-instruct",
		"display_name": "Qwen2.5 0.5B Instruct (Recommended)",
		"description": "Balanced model (~490MB). Good quality with reasonable size. Excellent instruction following. Supports multiple languages including Spanish.",
		"size_mb": 531.0,
		"download_url": "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q8_0.gguf",
		"default_temperature": 0.7,
		"default_top_p": 0.95,
		"default_top_k": 40,
		"default_max_tokens": 256,
		"default_repeat_penalty": 1.1,
		"default_min_p": 0.05,
		"n_ctx": 4096,
		"n_gpu_layers": 0,
		"n_batch": 512
	},
	{
		"id": "tinyllama-1.1b-chat",
		"display_name": "TinyLlama 1.1B Chat",
		"description": "Higher quality model (~670MB). Better coherence and creativity for dialogue generation. Good balance of quality vs size.",
		"size_mb": 670.0,
		"download_url": "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q8_0.gguf",
		"default_temperature": 0.7,
		"default_top_p": 0.95,
		"default_top_k": 40,
		"default_max_tokens": 256,
		"default_repeat_penalty": 1.1,
		"default_min_p": 0.05,
		"n_ctx": 2048,
		"n_gpu_layers": 0,
		"n_batch": 512
	}
]

## ID of the currently active model for runtime use
@export var active_model_id: String = "qwen2.5-0.5b-instruct"

## Custom model configurations added by the user
@export var custom_models: Array[ModelConfig] = []


## Returns all available models (predefined + custom)
func get_all_models() -> Array[ModelConfig]:
	var models: Array[ModelConfig] = []

	# Add predefined models
	for data in PREDEFINED_MODELS:
		models.append(_create_config_from_dict(data))

	# Add custom models
	for custom in custom_models:
		if custom != null:
			models.append(custom)

	return models


## Returns a model by its ID, or null if not found
func get_model_by_id(id: String) -> ModelConfig:
	# Check predefined models
	for data in PREDEFINED_MODELS:
		if data["id"] == id:
			return _create_config_from_dict(data)

	# Check custom models
	for custom in custom_models:
		if custom != null and custom.id == id:
			return custom

	return null


## Returns the currently active model configuration
func get_active_model() -> ModelConfig:
	return get_model_by_id(active_model_id)


## Sets the active model by ID
func set_active_model(id: String) -> bool:
	var model = get_model_by_id(id)
	if model != null:
		active_model_id = id
		return true
	return false


## Adds a custom model to the registry
func add_custom_model(config: ModelConfig) -> void:
	if config == null:
		return

	config.is_custom = true

	# Remove existing with same ID
	remove_custom_model(config.id)

	custom_models.append(config)


## Removes a custom model by ID
func remove_custom_model(id: String) -> bool:
	for i in range(custom_models.size() - 1, -1, -1):
		if custom_models[i] != null and custom_models[i].id == id:
			custom_models.remove_at(i)
			return true
	return false


## Creates a ModelConfig from a dictionary
func _create_config_from_dict(data: Dictionary) -> ModelConfig:
	var config = ModelConfig.new()

	config.id = data.get("id", "")
	config.display_name = data.get("display_name", "")
	config.description = data.get("description", "")
	config.size_mb = data.get("size_mb", 0.0)
	config.download_url = data.get("download_url", "")
	config.is_custom = data.get("is_custom", false)
	config.include_in_export = data.get("include_in_export", false)

	# Sampling params
	config.default_temperature = data.get("default_temperature", 0.7)
	config.default_top_p = data.get("default_top_p", 0.95)
	config.default_top_k = data.get("default_top_k", 40)
	config.default_max_tokens = data.get("default_max_tokens", 256)
	config.default_repeat_penalty = data.get("default_repeat_penalty", 1.1)
	config.default_min_p = data.get("default_min_p", 0.05)

	# Context settings
	config.n_ctx = data.get("n_ctx", 2048)
	config.n_gpu_layers = data.get("n_gpu_layers", 0)
	config.n_batch = data.get("n_batch", 512)

	return config


## Creates a custom ModelConfig from URL (helper for adding custom models)
static func create_custom_config(id: String, display_name: String, url: String, size_mb: float = 0.0) -> ModelConfig:
	var config = ModelConfig.new()
	config.id = id
	config.display_name = display_name
	config.download_url = url
	config.size_mb = size_mb
	config.is_custom = true
	config.description = "Custom model added by user. Use at your own responsibility."
	return config
