@tool
class_name ModelConfig
extends Resource
## Configuration resource for a GGUF language model.
##
## Stores model metadata, download URL, and default sampling parameters.
## Can be used for both predefined and custom models.

## Unique identifier for this model (e.g., "qwen2.5-0.5b-instruct")
@export var id: String = ""

## Human-readable display name
@export var display_name: String = ""

## Description of the model's characteristics
@export_multiline var description: String = ""

## Path to the GGUF model file (res:// for export, user:// for dev)
@export_file("*.gguf") var model_path: String = ""

## HuggingFace download URL for development
@export var download_url: String = ""

## Estimated file size in MB (for download progress)
@export var size_mb: float = 0.0

## Whether this is a custom/user-added model (shows warning)
@export var is_custom: bool = false

## Whether to include this model in exported builds
@export var include_in_export: bool = false

@export_group("Default Sampling Parameters")

## Temperature for sampling (0.0 = greedy, higher = more random)
@export_range(0.0, 2.0, 0.01) var default_temperature: float = 0.7

## Top-p (nucleus) sampling threshold
@export_range(0.0, 1.0, 0.01) var default_top_p: float = 0.95

## Top-k sampling (0 = disabled)
@export_range(0, 100) var default_top_k: int = 40

## Maximum tokens to generate
@export_range(1, 4096) var default_max_tokens: int = 256

## Repeat penalty (1.0 = disabled)
@export_range(1.0, 2.0, 0.01) var default_repeat_penalty: float = 1.1

## Minimum probability threshold
@export_range(0.0, 1.0, 0.01) var default_min_p: float = 0.05

@export_group("Context Settings")

## Context size in tokens
@export var n_ctx: int = 2048

## Number of layers to offload to GPU (0 = CPU only)
@export var n_gpu_layers: int = 0

## Batch size for prompt processing
@export var n_batch: int = 512


## Returns parameters dictionary for LlamaInterface.load_model()
func get_load_params() -> Dictionary:
	return {
		"n_ctx": n_ctx,
		"n_gpu_layers": n_gpu_layers,
		"n_batch": n_batch
	}


## Applies default sampling parameters to a LlamaInterface instance
func apply_defaults_to(llama: LlamaInterface) -> void:
	llama.temperature = default_temperature
	llama.top_p = default_top_p
	llama.top_k = default_top_k
	llama.max_tokens = default_max_tokens
	llama.repeat_penalty = default_repeat_penalty
	llama.min_p = default_min_p


## Checks if the model file exists (either in res:// or user://)
func is_downloaded() -> bool:
	return FileAccess.file_exists(get_effective_path())


## Returns the effective path where the model can be found
## Checks res://models/ (project directory, included in exports)
func get_effective_path() -> String:
	if model_path.is_empty():
		# Default path based on id
		return "res://models/%s.gguf" % id

	return model_path


## Returns the filename for this model (for downloads)
func get_filename() -> String:
	if download_url.is_empty():
		return "%s.gguf" % id

	# Extract filename from URL
	var parts = download_url.split("/")
	if parts.size() > 0:
		return parts[-1]

	return "%s.gguf" % id
