@tool
@icon("res://addons/ohmydialog/icons/model_config.svg")
class_name ModelConfig
extends Resource
## Configuration resource for a GGUF language model.
##
## Stores model metadata, download URL, and default sampling parameters.
## Can be used for both predefined and custom models.
##
## Properties are hidden from Godot's native inspector and displayed
## via a custom inspector plugin instead.


# === PROPERTY STORAGE (no @export - hidden from native inspector) ===

## Unique identifier for this model (e.g., "qwen2.5-0.5b-instruct")
var id: String = ""

## Human-readable display name
var display_name: String = ""

## Description of the model's characteristics
var description: String = ""

## Path to the GGUF model file (res:// for export, user:// for dev)
var model_path: String = ""

## HuggingFace download URL for development
var download_url: String = ""

## Estimated file size in MB (for download progress)
var size_mb: float = 0.0

## Whether this is a custom/user-added model (shows warning)
var is_custom: bool = false

## Whether to include this model in exported builds
var include_in_export: bool = false

# Default Sampling Parameters

## Temperature for sampling (0.0 = greedy, higher = more random)
var default_temperature: float = 0.7

## Top-p (nucleus) sampling threshold
var default_top_p: float = 0.95

## Top-k sampling (0 = disabled)
var default_top_k: int = 40

## Maximum tokens to generate
var default_max_tokens: int = 256

## Repeat penalty (1.0 = disabled)
var default_repeat_penalty: float = 1.1

## Minimum probability threshold
var default_min_p: float = 0.05

# Context Settings

## Context size in tokens
var n_ctx: int = 2048

## Number of layers to offload to GPU (0 = CPU only)
var n_gpu_layers: int = 0

## Batch size for prompt processing
var n_batch: int = 512


# === PROPERTY SYSTEM (for saving/loading without showing in native inspector) ===

func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []

	# Model Info
	properties.append({
		"name": "id",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "display_name",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "description",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "model_path",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.gguf",
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "download_url",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "size_mb",
		"type": TYPE_FLOAT,
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "is_custom",
		"type": TYPE_BOOL,
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "include_in_export",
		"type": TYPE_BOOL,
		"usage": PROPERTY_USAGE_STORAGE
	})

	# Default Sampling Parameters
	properties.append({
		"name": "default_temperature",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.0,2.0,0.01",
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "default_top_p",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.0,1.0,0.01",
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "default_top_k",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,100",
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "default_max_tokens",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "1,4096",
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "default_repeat_penalty",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "1.0,2.0,0.01",
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "default_min_p",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.0,1.0,0.01",
		"usage": PROPERTY_USAGE_STORAGE
	})

	# Context Settings
	properties.append({
		"name": "n_ctx",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "n_gpu_layers",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "n_batch",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_STORAGE
	})

	return properties


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


## Returns the filename for this model (extracted from URL or ID-based)
func get_filename() -> String:
	if not download_url.is_empty():
		# Extract filename from URL
		var parts = download_url.split("/")
		if parts.size() > 0:
			return parts[-1]

	return "%s.gguf" % id


## Returns the effective path where the model can be found
## Checks res://models/ (project directory, included in exports)
func get_effective_path() -> String:
	if not model_path.is_empty():
		return model_path

	return "res://models/" + get_filename()


## Returns true if this model config has minimum required data.
func is_valid() -> bool:
	return not id.is_empty() and not display_name.is_empty()


## Returns a short summary of the model for debugging.
func get_summary() -> String:
	var status := "downloaded" if is_downloaded() else "not downloaded"
	return "%s (%s) - %s, %d ctx" % [
		display_name if not display_name.is_empty() else "Unnamed Model",
		id if not id.is_empty() else "no-id",
		status,
		n_ctx
	]
