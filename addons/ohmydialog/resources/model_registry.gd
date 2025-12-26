@tool
class_name ModelRegistry
extends Resource
## Registry of available language models for OhMyDialogSystem.
##
## Contains predefined models (recommended) and supports custom models.
## Use [method get_model_by_id] to retrieve a specific model configuration.

## Predefined models optimized for dialogue systems and roleplay
## Organized by size: Tiny (<500MB), Small (500MB-1.5GB), Medium (1.5GB-3GB), Large (>3GB)
const PREDEFINED_MODELS: Array[Dictionary] = [
	# ===== TINY MODELS (<500MB) - For testing only =====
	{
		"id": "smollm2-360m-instruct",
		"display_name": "SmolLM2 360M Instruct",
		"description": "Ultra-light model for quick testing. Limited quality for complex dialogues.",
		"size_mb": 386.0,
		"download_url": "https://huggingface.co/unsloth/SmolLM2-360M-Instruct-GGUF/resolve/main/SmolLM2-360M-Instruct-Q8_0.gguf",
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
		"display_name": "Qwen2.5 0.5B Instruct",
		"description": "Smallest Qwen model. Good for testing with multilingual support (29+ languages). Fast inference.",
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
	# ===== SMALL MODELS (500MB-1.5GB) - Limited hardware =====
	{
		"id": "llama-3.2-1b-instruct",
		"display_name": "Llama 3.2 1B Instruct",
		"description": "Meta's smallest Llama 3. Optimized for dialogue with human-annotated training. Very fast.",
		"size_mb": 1320.0,
		"download_url": "https://huggingface.co/unsloth/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q8_0.gguf",
		"default_temperature": 0.7,
		"default_top_p": 0.9,
		"default_top_k": 40,
		"default_max_tokens": 256,
		"default_repeat_penalty": 1.1,
		"default_min_p": 0.05,
		"n_ctx": 8192,
		"n_gpu_layers": 0,
		"n_batch": 512
	},
	{
		"id": "qwen2.5-1.5b-instruct",
		"display_name": "Qwen2.5 1.5B Instruct",
		"description": "Mid-size Qwen. Excellent multilingual support and instruction following. Good for character roleplay.",
		"size_mb": 1890.0,
		"download_url": "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q8_0.gguf",
		"default_temperature": 0.7,
		"default_top_p": 0.95,
		"default_top_k": 40,
		"default_max_tokens": 256,
		"default_repeat_penalty": 1.1,
		"default_min_p": 0.05,
		"n_ctx": 8192,
		"n_gpu_layers": 0,
		"n_batch": 512
	},
	{
		"id": "smollm2-1.7b-instruct",
		"display_name": "SmolLM2 1.7B Instruct",
		"description": "HuggingFace's flagship small model. State-of-the-art for its size. Good balance of speed and quality.",
		"size_mb": 1820.0,
		"download_url": "https://huggingface.co/HuggingFaceTB/SmolLM2-1.7B-Instruct-GGUF/resolve/main/smollm2-1.7b-instruct-q8_0.gguf",
		"default_temperature": 0.7,
		"default_top_p": 0.95,
		"default_top_k": 40,
		"default_max_tokens": 256,
		"default_repeat_penalty": 1.1,
		"default_min_p": 0.05,
		"n_ctx": 8192,
		"n_gpu_layers": 0,
		"n_batch": 512
	},
	# ===== MEDIUM MODELS (1.5GB-3GB) - Recommended =====
	{
		"id": "qwen2.5-3b-instruct-q4",
		"display_name": "Qwen2.5 3B Instruct Q4 (Recommended)",
		"description": "Best balance for dialogue systems. Excellent Spanish support, optimized for roleplay and system prompts. 128K context.",
		"size_mb": 2100.0,
		"download_url": "https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf",
		"default_temperature": 0.7,
		"default_top_p": 0.95,
		"default_top_k": 40,
		"default_max_tokens": 256,
		"default_repeat_penalty": 1.1,
		"default_min_p": 0.05,
		"n_ctx": 8192,
		"n_gpu_layers": 0,
		"n_batch": 512
	},
	{
		"id": "llama-3.2-3b-instruct-q4",
		"display_name": "Llama 3.2 3B Instruct Q4",
		"description": "Meta's best small model. Human-annotated dialogue training. Outperforms larger models on dialogue tasks.",
		"size_mb": 2020.0,
		"download_url": "https://huggingface.co/unsloth/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf",
		"default_temperature": 0.7,
		"default_top_p": 0.9,
		"default_top_k": 40,
		"default_max_tokens": 256,
		"default_repeat_penalty": 1.1,
		"default_min_p": 0.05,
		"n_ctx": 8192,
		"n_gpu_layers": 0,
		"n_batch": 512
	},
	{
		"id": "gemma-2-2b-it",
		"display_name": "Gemma 2 2B IT",
		"description": "Google's instruction-tuned model. Strong reasoning and creative writing. Good for complex NPC personalities.",
		"size_mb": 2780.0,
		"download_url": "https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q8_0.gguf",
		"default_temperature": 0.7,
		"default_top_p": 0.95,
		"default_top_k": 40,
		"default_max_tokens": 256,
		"default_repeat_penalty": 1.1,
		"default_min_p": 0.05,
		"n_ctx": 8192,
		"n_gpu_layers": 0,
		"n_batch": 512
	},
	# ===== LARGE MODELS (>3GB) - Best quality =====
	{
		"id": "qwen2.5-3b-instruct-q8",
		"display_name": "Qwen2.5 3B Instruct Q8",
		"description": "Highest quality Qwen 3B. Best multilingual dialogue and character embodiment. Premium choice.",
		"size_mb": 3620.0,
		"download_url": "https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q8_0.gguf",
		"default_temperature": 0.7,
		"default_top_p": 0.95,
		"default_top_k": 40,
		"default_max_tokens": 256,
		"default_repeat_penalty": 1.1,
		"default_min_p": 0.05,
		"n_ctx": 8192,
		"n_gpu_layers": 0,
		"n_batch": 512
	},
	{
		"id": "llama-3.2-3b-instruct-q8",
		"display_name": "Llama 3.2 3B Instruct Q8",
		"description": "Highest quality Llama 3B. Best for complex dialogue, agentic tasks, and storytelling.",
		"size_mb": 3420.0,
		"download_url": "https://huggingface.co/unsloth/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q8_0.gguf",
		"default_temperature": 0.7,
		"default_top_p": 0.9,
		"default_top_k": 40,
		"default_max_tokens": 256,
		"default_repeat_penalty": 1.1,
		"default_min_p": 0.05,
		"n_ctx": 8192,
		"n_gpu_layers": 0,
		"n_batch": 512
	},
	{
		"id": "mistral-nemo-12b-q4",
		"display_name": "Mistral Nemo 12B Q4",
		"description": "Mistral's dialogue specialist. Excellent for real-time dialogue systems and complex NLP. Requires 8GB+ RAM.",
		"size_mb": 7200.0,
		"download_url": "https://huggingface.co/bartowski/Mistral-Nemo-Instruct-2407-GGUF/resolve/main/Mistral-Nemo-Instruct-2407-Q4_K_M.gguf",
		"default_temperature": 0.7,
		"default_top_p": 0.95,
		"default_top_k": 40,
		"default_max_tokens": 256,
		"default_repeat_penalty": 1.1,
		"default_min_p": 0.05,
		"n_ctx": 8192,
		"n_gpu_layers": 0,
		"n_batch": 512
	}
]

## ID of the currently active model for runtime use
@export var active_model_id: String = "qwen2.5-3b-instruct-q4"

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
