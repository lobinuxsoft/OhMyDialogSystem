@tool
@icon("res://addons/ohmydialog/icons/ai_preset.svg")
class_name AIPreset
extends Resource
## Stores LLM generation parameters as reusable presets.
##
## AIPresets allow quick switching between different generation styles
## (creative, consistent, balanced) without reconfiguring parameters.


## Predefined preset types.
enum PresetType {
	CUSTOM,      ## User-defined settings
	CREATIVE,    ## High temperature, more randomness
	BALANCED,    ## Default balanced settings
	CONSISTENT,  ## Low temperature, deterministic
	ROLEPLAY,    ## Optimized for character dialogue
	TECHNICAL    ## Precise, factual responses
}


@export_group("Identity")

## Human-readable name for this preset.
@export var preset_name: String = "Custom"

## Description of when to use this preset.
@export_multiline var description: String = ""

## The preset type for quick identification.
@export var preset_type: PresetType = PresetType.CUSTOM


@export_group("Temperature & Sampling")

## Controls randomness in generation. Higher = more creative, lower = more deterministic.
## Range: 0.0 to 2.0, Default: 0.7
@export_range(0.0, 2.0, 0.05) var temperature: float = 0.7

## Nucleus sampling: only consider tokens with cumulative probability >= top_p.
## Lower values = more focused, higher = more diverse.
## Range: 0.0 to 1.0, Default: 0.9
@export_range(0.0, 1.0, 0.05) var top_p: float = 0.9

## Only consider the top K most likely tokens.
## Lower = more focused, 0 = disabled.
## Range: 0 to 100, Default: 40
@export_range(0, 100, 1) var top_k: int = 40

## Minimum probability for a token to be considered (Min-P sampling).
## Range: 0.0 to 1.0, Default: 0.05
@export_range(0.0, 1.0, 0.01) var min_p: float = 0.05

## Typical sampling parameter. Lower = more typical/predictable text.
## Range: 0.0 to 1.0, Default: 1.0 (disabled)
@export_range(0.0, 1.0, 0.05) var typical_p: float = 1.0


@export_group("Output Control")

## Maximum number of tokens to generate per response.
## Range: 1 to 4096, Default: 256
@export_range(1, 4096, 1) var max_tokens: int = 256

## Sequences that stop generation when encountered.
@export var stop_sequences: Array[String] = []


@export_group("Repetition Control")

## Penalty for repeating tokens. Higher = less repetition.
## Range: 1.0 to 2.0, Default: 1.1
@export_range(1.0, 2.0, 0.05) var repeat_penalty: float = 1.1

## How many recent tokens to consider for repetition penalty.
## Range: 0 to 256, Default: 64
@export_range(0, 256, 1) var repeat_last_n: int = 64

## Frequency penalty (OpenAI-style). Penalizes based on frequency.
## Range: 0.0 to 2.0, Default: 0.0
@export_range(0.0, 2.0, 0.1) var frequency_penalty: float = 0.0

## Presence penalty (OpenAI-style). Penalizes if token appeared at all.
## Range: 0.0 to 2.0, Default: 0.0
@export_range(0.0, 2.0, 0.1) var presence_penalty: float = 0.0


@export_group("Context")

## Maximum context size in tokens (model-dependent).
## Range: 512 to 32768, Default: 4096
@export_range(512, 32768, 256) var context_size: int = 4096

## Number of tokens to reserve for the response in context window.
## Range: 64 to 1024, Default: 256
@export_range(64, 1024, 32) var response_reserve: int = 256


@export_group("Advanced")

## Seed for random number generation. -1 = random seed.
@export var seed: int = -1

## Mirostat sampling mode (0 = disabled, 1 = v1, 2 = v2).
@export_range(0, 2, 1) var mirostat: int = 0

## Mirostat target entropy (tau). Only used if mirostat > 0.
@export_range(0.0, 10.0, 0.1) var mirostat_tau: float = 5.0

## Mirostat learning rate (eta). Only used if mirostat > 0.
@export_range(0.0, 1.0, 0.01) var mirostat_eta: float = 0.1


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
