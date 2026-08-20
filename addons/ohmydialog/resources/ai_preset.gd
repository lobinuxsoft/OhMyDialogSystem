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
@export_range(0.0, 2.0, 0.05) var temperature: float = 0.7

## Nucleus sampling: only consider tokens with cumulative probability >= top_p.
@export_range(0.0, 1.0, 0.05) var top_p: float = 0.9

## Only consider the top K most likely tokens.
@export_range(0, 100) var top_k: int = 40

## Minimum probability for a token to be considered (Min-P sampling).
@export_range(0.0, 1.0, 0.01) var min_p: float = 0.05

## Typical sampling parameter. Lower = more typical/predictable text.
@export_range(0.0, 1.0, 0.05) var typical_p: float = 1.0


@export_group("Output")

## Maximum number of tokens to generate per response.
@export_range(1, 4096) var max_tokens: int = 256

## Sequences that stop generation when encountered.
@export var stop_sequences: Array[String] = []

## Text injected where the assistant turn opens, before it writes anything.
## A reasoning model opens a <think> block on its first token and can spend the
## whole max_tokens budget inside it without ever answering; handing it a block
## that is already closed puts it straight into the reply.
@export_multiline var assistant_prefill: String = ""


@export_group("Repetition")

## Penalty for repeating tokens. Higher = less repetition.
@export_range(1.0, 2.0, 0.05) var repeat_penalty: float = 1.1

## How many recent tokens to consider for repetition penalty.
@export_range(0, 256) var repeat_last_n: int = 64

## Frequency penalty (OpenAI-style). Penalizes based on frequency.
@export_range(0.0, 2.0, 0.1) var frequency_penalty: float = 0.0

## Presence penalty (OpenAI-style). Penalizes if token appeared at all.
@export_range(0.0, 2.0, 0.1) var presence_penalty: float = 0.0


@export_group("Context")

## Maximum context size in tokens (model-dependent).
@export_range(512, 32768, 256) var context_size: int = 4096

## Number of tokens to reserve for the response in context window.
@export_range(64, 1024, 32) var response_reserve: int = 256


@export_group("Advanced")

## Seed for random number generation. -1 = random seed.
@export var seed: int = -1

## Mirostat sampling mode (0 = disabled, 1 = v1, 2 = v2).
@export_range(0, 2) var mirostat: int = 0

## Mirostat target entropy (tau). Only used if mirostat > 0.
@export_range(0.0, 10.0, 0.1) var mirostat_tau: float = 5.0

## Mirostat learning rate (eta). Only used if mirostat > 0.
@export_range(0.0, 1.0, 0.01) var mirostat_eta: float = 0.1


@export_group("Model Metadata")

## Original chat template from GGUF metadata (Jinja2 format, read-only reference).
@export_multiline var source_chat_template: String = ""

## Detected chat template format (chatml, llama2, llama3, mistral, vicuna, phi, gemma, or unknown).
@export var chat_template_format: String = ""

## Model architecture from GGUF (llama, qwen2, phi, gemma, etc.).
@export var model_architecture: String = ""

## BOS (Beginning of Sequence) token ID from model metadata. -1 if not found.
@export var bos_token_id: int = -1

## EOS (End of Sequence) token ID from model metadata. -1 if not found.
@export var eos_token_id: int = -1

## Recommended context length from model metadata. 0 if not found.
@export var recommended_context_length: int = 0

## Stop sequences derived from special tokens (populated from chat template format).
@export var derived_stop_sequences: Array[String] = []


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
		"assistant_prefill": assistant_prefill,
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
	preset.assistant_prefill = dict.get("assistant_prefill", "")
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


# ==================== GGUF Metadata Factory ====================


## Creates an AIPreset from GGUF metadata dictionary.
## [param metadata]: Dictionary from GGUFParser or HuggingFaceAPI metadata fetch
## [param base_type]: Base preset type to start from (defaults to BALANCED)
## [param model_name]: Optional model name for the preset
static func create_from_gguf_metadata(
	metadata: Dictionary,
	base_type: PresetType = PresetType.BALANCED,
	model_name: String = ""
) -> AIPreset:
	# Start from a base preset
	var preset := get_preset(base_type)
	preset.preset_type = PresetType.CUSTOM

	# Set preset name
	if not model_name.is_empty():
		preset.preset_name = "%s Preset" % model_name
	else:
		var name = metadata.get("_model_name", metadata.get("general.name", ""))
		if not name.is_empty():
			preset.preset_name = "%s Preset" % name
		else:
			preset.preset_name = "GGUF Custom Preset"

	# Extract metadata fields
	preset.source_chat_template = metadata.get("_chat_template", metadata.get("tokenizer.chat_template", ""))
	preset.chat_template_format = metadata.get("_chat_template_format", "")
	preset.model_architecture = metadata.get("_architecture", metadata.get("general.architecture", ""))
	preset.bos_token_id = metadata.get("_bos_token_id", metadata.get("tokenizer.ggml.bos_token_id", -1))
	preset.eos_token_id = metadata.get("_eos_token_id", metadata.get("tokenizer.ggml.eos_token_id", -1))

	# Get context length (check architecture-specific key first)
	var ctx_len = metadata.get("_context_length", 0)
	if ctx_len == 0 and not preset.model_architecture.is_empty():
		ctx_len = metadata.get("%s.context_length" % preset.model_architecture, 0)
	if ctx_len > 0:
		preset.recommended_context_length = ctx_len
		preset.context_size = mini(ctx_len, 32768)  # Clamp to reasonable max

	# A reasoning model needs its thinking channel closed up front
	preset.assistant_prefill = _derive_prefill_from_template(preset.source_chat_template)

	# Derive stop sequences from chat template format
	preset.derived_stop_sequences = _derive_stop_sequences_from_format(preset.chat_template_format)

	# Merge derived stop sequences with existing ones
	for seq in preset.derived_stop_sequences:
		if seq not in preset.stop_sequences:
			preset.stop_sequences.append(seq)

	# Generate description
	preset.description = _generate_metadata_description(preset)

	return preset


## Returns the prefill a model needs, or an empty string when it does not think.
## Reasoning templates carry an enable_thinking switch that the C chat-template
## API cannot set, so the closed block is written into the prompt instead.
static func _derive_prefill_from_template(template: String) -> String:
	if "enable_thinking" in template or "<think>" in template:
		return "<think>\n\n</think>\n\n"
	return ""


## Derives stop sequences from a known chat template format.
static func _derive_stop_sequences_from_format(format: String) -> Array[String]:
	var sequences: Array[String] = []

	match format:
		"chatml":
			sequences = ["<|im_end|>", "<|im_start|>"]
		"llama2", "llama3":
			sequences = ["[/INST]", "</s>"]
		"mistral":
			sequences = ["[/INST]", "</s>"]
		"vicuna":
			sequences = ["USER:", "ASSISTANT:"]
		"phi":
			sequences = ["<|end|>", "<|user|>"]
		"gemma":
			sequences = ["<end_of_turn>", "<start_of_turn>"]

	return sequences


## Generates a description string from preset metadata.
static func _generate_metadata_description(preset: AIPreset) -> String:
	var parts: Array[String] = []

	if not preset.model_architecture.is_empty():
		parts.append("Architecture: %s" % preset.model_architecture)

	if not preset.chat_template_format.is_empty() and preset.chat_template_format != "unknown":
		parts.append("Template: %s" % preset.chat_template_format)

	if preset.recommended_context_length > 0:
		parts.append("Context: %d tokens" % preset.recommended_context_length)

	if parts.is_empty():
		return "Generated from GGUF metadata"

	return "Generated from GGUF metadata. " + ", ".join(parts) + "."
