@tool
class_name GGUFParser
extends RefCounted
## Parses GGUF file headers to extract model metadata without downloading the full file.
##
## GGUF format spec: https://github.com/ggerganov/ggml/blob/master/docs/gguf.md
## This parser only reads the header section containing metadata, not the tensor data.


## Magic number for GGUF files ("GGUF" in little-endian)
const GGUF_MAGIC := 0x46554747

## GGUF value types
enum ValueType {
	UINT8 = 0,
	INT8 = 1,
	UINT16 = 2,
	INT16 = 3,
	UINT32 = 4,
	INT32 = 5,
	FLOAT32 = 6,
	BOOL = 7,
	STRING = 8,
	ARRAY = 9,
	UINT64 = 10,
	INT64 = 11,
	FLOAT64 = 12
}

## Keys we're interested in extracting
const KEYS_OF_INTEREST := [
	"general.architecture",
	"general.name",
	"general.file_type",
	"tokenizer.chat_template",
	"tokenizer.ggml.bos_token_id",
	"tokenizer.ggml.eos_token_id",
]

## Architecture-specific context length key suffix
const CONTEXT_LENGTH_SUFFIX := ".context_length"


## Result of parsing - contains all extracted metadata
var metadata: Dictionary = {}

## Parsing errors encountered
var errors: Array[String] = []

## Current position in the data buffer
var _pos: int = 0

## Data buffer being parsed
var _data: PackedByteArray


## Parses GGUF header from raw bytes.
## [param data]: Raw bytes from the beginning of a GGUF file (at least 10MB recommended)
## Returns true if parsing succeeded, false otherwise
func parse(data: PackedByteArray) -> bool:
	_data = data
	_pos = 0
	metadata.clear()
	errors.clear()

	if data.size() < 24:
		errors.append("Data too small to be a valid GGUF file (min 24 bytes for header)")
		return false

	# Read magic number
	var magic := _read_uint32()
	if magic != GGUF_MAGIC:
		errors.append("Invalid GGUF magic number: 0x%08X (expected 0x%08X)" % [magic, GGUF_MAGIC])
		return false

	# Read version
	var version := _read_uint32()
	if version < 2 or version > 3:
		errors.append("Unsupported GGUF version: %d (supported: 2-3)" % version)
		return false

	metadata["_version"] = version

	# Read tensor count (we don't need this but must skip it)
	var tensor_count := _read_uint64()
	metadata["_tensor_count"] = tensor_count

	# Read key-value count
	var kv_count := _read_uint64()
	metadata["_kv_count"] = kv_count

	# Parse key-value pairs
	for i in range(kv_count):
		if not _parse_kv_pair():
			# If we hit an error mid-parse, we might still have useful data
			break

	return errors.is_empty()


## Parses a single key-value pair from the current position.
## Returns true if successful, false if there was an error
func _parse_kv_pair() -> bool:
	if _pos >= _data.size():
		errors.append("Unexpected end of data while reading KV pair")
		return false

	# Read key (string)
	var key := _read_string()
	if key.is_empty():
		return false

	# Read value type
	var value_type := _read_uint32()

	# Check if this is a key we care about
	var should_store := _is_key_of_interest(key)

	# Read value based on type
	var value = _read_value(value_type, should_store)

	if should_store and value != null:
		metadata[key] = value

	return true


## Checks if a key is one we want to extract
func _is_key_of_interest(key: String) -> bool:
	if key in KEYS_OF_INTEREST:
		return true

	# Check for architecture-specific context length
	if key.ends_with(CONTEXT_LENGTH_SUFFIX):
		return true

	return false


## Reads a value of the specified type.
## [param type_id]: The GGUF value type
## [param store]: If false, skip reading large data (like arrays) to save memory
func _read_value(type_id: int, store: bool) -> Variant:
	match type_id:
		ValueType.UINT8:
			return _read_uint8()
		ValueType.INT8:
			return _read_int8()
		ValueType.UINT16:
			return _read_uint16()
		ValueType.INT16:
			return _read_int16()
		ValueType.UINT32:
			return _read_uint32()
		ValueType.INT32:
			return _read_int32()
		ValueType.FLOAT32:
			return _read_float32()
		ValueType.BOOL:
			return _read_uint8() != 0
		ValueType.STRING:
			return _read_string()
		ValueType.ARRAY:
			return _read_array(store)
		ValueType.UINT64:
			return _read_uint64()
		ValueType.INT64:
			return _read_int64()
		ValueType.FLOAT64:
			return _read_float64()
		_:
			errors.append("Unknown value type: %d at position %d" % [type_id, _pos])
			return null


## Reads an array value.
## [param store]: If false, skip the array contents and return null
func _read_array(store: bool) -> Variant:
	var element_type := _read_uint32()
	var count := _read_uint64()

	# Skip large arrays we don't need (like tokenizer vocabulary)
	if not store or count > 1000:
		_skip_array_contents(element_type, count)
		return null

	var result: Array = []
	for i in range(count):
		var value = _read_value(element_type, true)
		if value != null:
			result.append(value)

	return result


## Skips array contents without storing them
func _skip_array_contents(element_type: int, count: int) -> void:
	var element_size := _get_fixed_type_size(element_type)

	if element_size > 0:
		# Fixed size elements - can skip directly
		_pos += element_size * count
	else:
		# Variable size elements (strings, nested arrays) - must read each
		for i in range(count):
			_read_value(element_type, false)


## Returns the fixed size of a type, or 0 if variable size
func _get_fixed_type_size(type_id: int) -> int:
	match type_id:
		ValueType.UINT8, ValueType.INT8, ValueType.BOOL:
			return 1
		ValueType.UINT16, ValueType.INT16:
			return 2
		ValueType.UINT32, ValueType.INT32, ValueType.FLOAT32:
			return 4
		ValueType.UINT64, ValueType.INT64, ValueType.FLOAT64:
			return 8
		_:
			return 0  # Variable size (STRING, ARRAY)


# ==================== Binary Reading Helpers ====================

func _read_uint8() -> int:
	if _pos >= _data.size():
		return 0
	var value := _data[_pos]
	_pos += 1
	return value


func _read_int8() -> int:
	var value := _read_uint8()
	return value if value < 128 else value - 256


func _read_uint16() -> int:
	if _pos + 2 > _data.size():
		return 0
	var value := _data[_pos] | (_data[_pos + 1] << 8)
	_pos += 2
	return value


func _read_int16() -> int:
	var value := _read_uint16()
	return value if value < 32768 else value - 65536


func _read_uint32() -> int:
	if _pos + 4 > _data.size():
		return 0
	var value := _data[_pos] | (_data[_pos + 1] << 8) | (_data[_pos + 2] << 16) | (_data[_pos + 3] << 24)
	_pos += 4
	return value


func _read_int32() -> int:
	var value := _read_uint32()
	return value if value < 2147483648 else value - 4294967296


func _read_uint64() -> int:
	if _pos + 8 > _data.size():
		return 0
	# GDScript integers are 64-bit, but we need to handle the unsigned case
	var low := _read_uint32()
	var high := _read_uint32()
	return low | (high << 32)


func _read_int64() -> int:
	return _read_uint64()  # GDScript handles sign automatically for 64-bit


func _read_float32() -> float:
	if _pos + 4 > _data.size():
		return 0.0
	var bytes := _data.slice(_pos, _pos + 4)
	_pos += 4
	return bytes.decode_float(0)


func _read_float64() -> float:
	if _pos + 8 > _data.size():
		return 0.0
	var bytes := _data.slice(_pos, _pos + 8)
	_pos += 8
	return bytes.decode_double(0)


func _read_string() -> String:
	var length := _read_uint64()

	if length == 0:
		return ""

	if _pos + length > _data.size():
		errors.append("String length %d exceeds available data at position %d" % [length, _pos])
		return ""

	var bytes := _data.slice(_pos, _pos + length)
	_pos += length

	return bytes.get_string_from_utf8()


# ==================== Convenience Methods ====================


## Gets the model architecture (e.g., "llama", "qwen2", "phi")
func get_architecture() -> String:
	return metadata.get("general.architecture", "")


## Gets the model name
func get_model_name() -> String:
	return metadata.get("general.name", "")


## Gets the chat template (Jinja2 format)
func get_chat_template() -> String:
	return metadata.get("tokenizer.chat_template", "")


## Gets the BOS token ID (-1 if not found)
func get_bos_token_id() -> int:
	return metadata.get("tokenizer.ggml.bos_token_id", -1)


## Gets the EOS token ID (-1 if not found)
func get_eos_token_id() -> int:
	return metadata.get("tokenizer.ggml.eos_token_id", -1)


## Gets the context length for the model's architecture
func get_context_length() -> int:
	var arch := get_architecture()
	if arch.is_empty():
		return 0

	var key := "%s%s" % [arch, CONTEXT_LENGTH_SUFFIX]
	return metadata.get(key, 0)


## Gets the file type (quantization type as integer)
func get_file_type() -> int:
	return metadata.get("general.file_type", 0)


## Returns all extracted metadata as a dictionary
func get_all_metadata() -> Dictionary:
	return metadata.duplicate()


## Detects the chat template format from the raw template string.
## Returns format identifier: "chatml", "llama", "mistral", "vicuna", or "unknown"
func detect_chat_template_format() -> String:
	var template := get_chat_template()

	if template.is_empty():
		return "unknown"

	# ChatML format (Qwen, OpenHermes, etc.)
	if "<|im_start|>" in template:
		return "chatml"

	# Llama 2/3 format
	if "[INST]" in template and "<<SYS>>" in template:
		return "llama2"

	# Llama 3 format (no <<SYS>>)
	if "[INST]" in template and "<<SYS>>" not in template:
		return "llama3"

	# Mistral format
	if "<s>[INST]" in template and "<<SYS>>" not in template:
		return "mistral"

	# Vicuna format
	if "USER:" in template and "ASSISTANT:" in template:
		return "vicuna"

	# Phi format
	if "<|user|>" in template and "<|assistant|>" in template:
		return "phi"

	# Gemma format
	if "<start_of_turn>" in template:
		return "gemma"

	return "unknown"
