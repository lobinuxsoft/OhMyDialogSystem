@tool
class_name TokenCounter
extends RefCounted
## Counts tokens with a model's real vocabulary, without loading its weights.
##
## llama.cpp can load just the vocabulary (vocab_only): the tensors are never
## read from disk and no KV cache is allocated, so a handle costs megabytes
## instead of gigabytes. Parsing a vocabulary still costs a disk read, so
## handles are cached per model path.

## Vocab-only LlamaInterface per model path. A null entry marks a path that
## already failed, so a broken file is not retried on every refresh.
static var _handles: Dictionary = {}


## Returns the exact token count for text, or -1 when the vocabulary
## is unavailable and the caller must fall back to an approximation.
static func count(model_path: String, text: String) -> int:
	if text.is_empty():
		return 0

	var llama := _handle_for(model_path)
	if not llama:
		return -1

	return llama.count_tokens(text)


## Vocabulary to count with for a graph: the model the graph pins, or the
## loaded one when it pins none. Empty when neither is available.
static func path_for(graph: DialogueGraph) -> String:
	if graph and not graph.model_path.is_empty():
		return graph.model_path

	var ai_service := AIService.get_singleton()
	if ai_service and ai_service.is_model_loaded():
		var config := ai_service.get_current_config()
		if config:
			return config.get_effective_path()

	return ""


## Drops the cached vocabularies. Call when the models on disk change.
static func clear_cache() -> void:
	_handles.clear()


static func _handle_for(model_path: String) -> LlamaInterface:
	if model_path.is_empty():
		return null

	if _handles.has(model_path):
		return _handles[model_path] as LlamaInterface

	if not FileAccess.file_exists(model_path):
		return null

	var llama := LlamaInterface.new()

	# vocab_only skips every tensor; n_gpu_layers stays at 0 so no backend is touched.
	# n_ctx is set explicitly because vocab_only leaves n_ctx_train unpopulated, and
	# llama_init_from_model rejects a context when both are zero. It allocates nothing
	# here: the memory module is skipped in vocab_only mode.
	var err := llama.load_model(model_path, {
		"vocab_only": true,
		"n_gpu_layers": 0,
		"n_ctx": 512,
	})
	if err != OK:
		push_warning("TokenCounter: Could not load vocabulary from %s" % model_path)
		_handles[model_path] = null
		return null

	_handles[model_path] = llama

	return llama
