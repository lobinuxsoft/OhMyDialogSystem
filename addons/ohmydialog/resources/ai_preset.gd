@tool
@icon("res://addons/ohmydialog/icons/ai_preset.svg")
class_name AIPreset
extends Resource
## Stores LLM generation parameters as reusable presets.
##
## AIPresets allow quick switching between different generation styles
## (creative, consistent, balanced) without reconfiguring parameters.
##
## Properties are hidden from Godot's native inspector and displayed
## via a custom inspector plugin instead.


## Predefined preset types.
enum PresetType {
	CUSTOM,      ## User-defined settings
	CREATIVE,    ## High temperature, more randomness
	BALANCED,    ## Default balanced settings
	CONSISTENT,  ## Low temperature, deterministic
	ROLEPLAY,    ## Optimized for character dialogue
	TECHNICAL    ## Precise, factual responses
}


# === PROPERTY STORAGE (no @export - hidden from native inspector) ===

# Identity

## Human-readable name for this preset.
var preset_name: String = "Custom"

## Description of when to use this preset.
var description: String = ""

## The preset type for quick identification.
var preset_type: PresetType = PresetType.CUSTOM

# Temperature & Sampling

## Controls randomness in generation. Higher = more creative, lower = more deterministic.
var temperature: float = 0.7

## Nucleus sampling: only consider tokens with cumulative probability >= top_p.
var top_p: float = 0.9

## Only consider the top K most likely tokens.
var top_k: int = 40

## Minimum probability for a token to be considered (Min-P sampling).
var min_p: float = 0.05

## Typical sampling parameter. Lower = more typical/predictable text.
var typical_p: float = 1.0

# Output Control

## Maximum number of tokens to generate per response.
var max_tokens: int = 256

## Sequences that stop generation when encountered.
var stop_sequences: Array[String] = []

# Repetition Control

## Penalty for repeating tokens. Higher = less repetition.
var repeat_penalty: float = 1.1

## How many recent tokens to consider for repetition penalty.
var repeat_last_n: int = 64

## Frequency penalty (OpenAI-style). Penalizes based on frequency.
var frequency_penalty: float = 0.0

## Presence penalty (OpenAI-style). Penalizes if token appeared at all.
var presence_penalty: float = 0.0

# Context

## Maximum context size in tokens (model-dependent).
var context_size: int = 4096

## Number of tokens to reserve for the response in context window.
var response_reserve: int = 256

# Advanced

## Seed for random number generation. -1 = random seed.
var seed: int = -1

## Mirostat sampling mode (0 = disabled, 1 = v1, 2 = v2).
var mirostat: int = 0

## Mirostat target entropy (tau). Only used if mirostat > 0.
var mirostat_tau: float = 5.0

## Mirostat learning rate (eta). Only used if mirostat > 0.
var mirostat_eta: float = 0.1


# === PROPERTY SYSTEM (for saving/loading without showing in native inspector) ===

func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []

	# Identity
	properties.append({
		"name": "preset_name",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "description",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "preset_type",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ",".join(PresetType.keys()),
		"usage": PROPERTY_USAGE_STORAGE
	})

	# Temperature & Sampling
	properties.append({
		"name": "temperature",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.0,2.0,0.05",
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "top_p",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.0,1.0,0.05",
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "top_k",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,100",
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "min_p",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.0,1.0,0.01",
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "typical_p",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.0,1.0,0.05",
		"usage": PROPERTY_USAGE_STORAGE
	})

	# Output Control
	properties.append({
		"name": "max_tokens",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "1,4096",
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "stop_sequences",
		"type": TYPE_ARRAY,
		"hint": PROPERTY_HINT_TYPE_STRING,
		"hint_string": "%d:" % TYPE_STRING,
		"usage": PROPERTY_USAGE_STORAGE
	})

	# Repetition Control
	properties.append({
		"name": "repeat_penalty",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "1.0,2.0,0.05",
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "repeat_last_n",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,256",
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "frequency_penalty",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.0,2.0,0.1",
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "presence_penalty",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.0,2.0,0.1",
		"usage": PROPERTY_USAGE_STORAGE
	})

	# Context
	properties.append({
		"name": "context_size",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "512,32768,256",
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "response_reserve",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "64,1024,32",
		"usage": PROPERTY_USAGE_STORAGE
	})

	# Advanced
	properties.append({
		"name": "seed",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "mirostat",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,2",
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "mirostat_tau",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.0,10.0,0.1",
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "mirostat_eta",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.0,1.0,0.01",
		"usage": PROPERTY_USAGE_STORAGE
	})

	return properties


## Applies this preset's settings to a LlamaInterface instance.
func apply_to(llama: Object) -> void:
	if not llama:
		push_error("AIPreset: Cannot apply to null interface")
		return

	# Apply all settings via setter methods if available
	_set_if_method(llama, "set_temperature", temperature)
	_set_if_method(llama, "set_top_p", top_p)
	_set_if_method(llama, "set_top_k", top_k)
	_set_if_method(llama, "set_min_p", min_p)
	_set_if_method(llama, "set_typical_p", typical_p)
	_set_if_method(llama, "set_max_tokens", max_tokens)
	_set_if_method(llama, "set_repeat_penalty", repeat_penalty)
	_set_if_method(llama, "set_repeat_last_n", repeat_last_n)
	_set_if_method(llama, "set_frequency_penalty", frequency_penalty)
	_set_if_method(llama, "set_presence_penalty", presence_penalty)
	_set_if_method(llama, "set_context_size", context_size)
	_set_if_method(llama, "set_seed", seed)
	_set_if_method(llama, "set_mirostat", mirostat)
	_set_if_method(llama, "set_mirostat_tau", mirostat_tau)
	_set_if_method(llama, "set_mirostat_eta", mirostat_eta)

	# Apply stop sequences
	if llama.has_method("set_stop_sequences"):
		llama.set_stop_sequences(stop_sequences)
	elif llama.has_method("clear_stop_sequences") and llama.has_method("add_stop_sequence"):
		llama.clear_stop_sequences()
		for seq in stop_sequences:
			llama.add_stop_sequence(seq)


## Helper to safely call a setter method.
func _set_if_method(obj: Object, method: String, value: Variant) -> void:
	if obj.has_method(method):
		obj.call(method, value)


## Returns the preset as a dictionary (for serialization/API calls).
func to_dict() -> Dictionary:
	return {
		"temperature": temperature,
		"top_p": top_p,
		"top_k": top_k,
		"min_p": min_p,
		"typical_p": typical_p,
		"max_tokens": max_tokens,
		"stop_sequences": stop_sequences.duplicate(),
		"repeat_penalty": repeat_penalty,
		"repeat_last_n": repeat_last_n,
		"frequency_penalty": frequency_penalty,
		"presence_penalty": presence_penalty,
		"context_size": context_size,
		"response_reserve": response_reserve,
		"seed": seed,
		"mirostat": mirostat,
		"mirostat_tau": mirostat_tau,
		"mirostat_eta": mirostat_eta
	}


## Creates a preset from a dictionary.
static func from_dict(dict: Dictionary) -> AIPreset:
	var preset := AIPreset.new()
	preset.temperature = dict.get("temperature", 0.7)
	preset.top_p = dict.get("top_p", 0.9)
	preset.top_k = dict.get("top_k", 40)
	preset.min_p = dict.get("min_p", 0.05)
	preset.typical_p = dict.get("typical_p", 1.0)
	preset.max_tokens = dict.get("max_tokens", 256)
	preset.repeat_penalty = dict.get("repeat_penalty", 1.1)
	preset.repeat_last_n = dict.get("repeat_last_n", 64)
	preset.frequency_penalty = dict.get("frequency_penalty", 0.0)
	preset.presence_penalty = dict.get("presence_penalty", 0.0)
	preset.context_size = dict.get("context_size", 4096)
	preset.response_reserve = dict.get("response_reserve", 256)
	preset.seed = dict.get("seed", -1)
	preset.mirostat = dict.get("mirostat", 0)
	preset.mirostat_tau = dict.get("mirostat_tau", 5.0)
	preset.mirostat_eta = dict.get("mirostat_eta", 0.1)

	var stop_seqs: Array = dict.get("stop_sequences", [])
	for seq in stop_seqs:
		preset.stop_sequences.append(seq)

	return preset


## Returns true if this preset has been modified from defaults.
func is_valid() -> bool:
	return not preset_name.is_empty()


## Returns a short summary of the preset for debugging.
func get_summary() -> String:
	return "%s (%s) - temp:%.2f, top_p:%.2f" % [
		preset_name,
		PresetType.keys()[preset_type].to_lower(),
		temperature,
		top_p
	]


# ==================== Factory Methods for Built-in Presets ====================


## Creates a Creative preset (high temperature, diverse outputs).
static func create_creative() -> AIPreset:
	var preset := AIPreset.new()
	preset.preset_name = "Creative"
	preset.preset_type = PresetType.CREATIVE
	preset.description = "High creativity with diverse, imaginative responses. Good for storytelling and brainstorming."
	preset.temperature = 1.0
	preset.top_p = 0.95
	preset.top_k = 50
	preset.min_p = 0.02
	preset.repeat_penalty = 1.15
	preset.max_tokens = 512
	return preset


## Creates a Balanced preset (default settings).
static func create_balanced() -> AIPreset:
	var preset := AIPreset.new()
	preset.preset_name = "Balanced"
	preset.preset_type = PresetType.BALANCED
	preset.description = "Well-balanced settings suitable for most dialogue scenarios."
	preset.temperature = 0.7
	preset.top_p = 0.9
	preset.top_k = 40
	preset.min_p = 0.05
	preset.repeat_penalty = 1.1
	preset.max_tokens = 256
	return preset


## Creates a Consistent preset (low temperature, deterministic).
static func create_consistent() -> AIPreset:
	var preset := AIPreset.new()
	preset.preset_name = "Consistent"
	preset.preset_type = PresetType.CONSISTENT
	preset.description = "Low randomness for more predictable, consistent responses. Good for tutorials and scripted scenes."
	preset.temperature = 0.3
	preset.top_p = 0.8
	preset.top_k = 20
	preset.min_p = 0.1
	preset.repeat_penalty = 1.05
	preset.max_tokens = 256
	return preset


## Creates a Roleplay preset (optimized for character dialogue).
static func create_roleplay() -> AIPreset:
	var preset := AIPreset.new()
	preset.preset_name = "Roleplay"
	preset.preset_type = PresetType.ROLEPLAY
	preset.description = "Optimized for in-character dialogue with good personality expression."
	preset.temperature = 0.8
	preset.top_p = 0.92
	preset.top_k = 45
	preset.min_p = 0.04
	preset.repeat_penalty = 1.12
	preset.presence_penalty = 0.3
	preset.max_tokens = 384
	return preset


## Creates a Technical preset (precise, factual).
static func create_technical() -> AIPreset:
	var preset := AIPreset.new()
	preset.preset_name = "Technical"
	preset.preset_type = PresetType.TECHNICAL
	preset.description = "Very low randomness for precise, factual responses. Good for in-game encyclopedias or guides."
	preset.temperature = 0.2
	preset.top_p = 0.7
	preset.top_k = 10
	preset.min_p = 0.15
	preset.repeat_penalty = 1.0
	preset.max_tokens = 512
	return preset


## Gets a preset by type.
static func get_preset(type: PresetType) -> AIPreset:
	match type:
		PresetType.CREATIVE:
			return create_creative()
		PresetType.BALANCED:
			return create_balanced()
		PresetType.CONSISTENT:
			return create_consistent()
		PresetType.ROLEPLAY:
			return create_roleplay()
		PresetType.TECHNICAL:
			return create_technical()
		_:
			return create_balanced()
