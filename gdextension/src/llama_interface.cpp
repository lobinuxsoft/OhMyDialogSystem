#include "llama_interface.h"

#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/project_settings.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot {

LlamaInterface::LlamaInterface() {
}

LlamaInterface::~LlamaInterface() {
	_cleanup();
}

void LlamaInterface::_cleanup() {
	if (m_context != nullptr) {
		llama_free(m_context);
		m_context = nullptr;
	}
	if (m_model != nullptr) {
		llama_model_free(m_model);
		m_model = nullptr;
	}
	if (m_backend_initialized) {
		llama_backend_free();
		m_backend_initialized = false;
	}
	m_model_path = "";
}

void LlamaInterface::_bind_methods() {
	ClassDB::bind_method(D_METHOD("load_model", "path", "params"), &LlamaInterface::load_model, DEFVAL(Dictionary()));
	ClassDB::bind_method(D_METHOD("unload_model"), &LlamaInterface::unload_model);
	ClassDB::bind_method(D_METHOD("is_model_loaded"), &LlamaInterface::is_model_loaded);
	ClassDB::bind_method(D_METHOD("get_model_info"), &LlamaInterface::get_model_info);
	ClassDB::bind_method(D_METHOD("get_model_path"), &LlamaInterface::get_model_path);
}

Error LlamaInterface::load_model(const String &path, const Dictionary &params) {
	// Unload previous model if any
	if (is_model_loaded()) {
		unload_model();
	}

	// Resolve Godot path to filesystem path
	String resolved_path = path;
	if (path.begins_with("res://") || path.begins_with("user://")) {
		resolved_path = ProjectSettings::get_singleton()->globalize_path(path);
	}

	// Check if file exists
	if (!FileAccess::file_exists(path)) {
		UtilityFunctions::push_error("LlamaInterface: Model file not found: ", path);
		return ERR_FILE_NOT_FOUND;
	}

	// Initialize backend
	llama_backend_init();
	m_backend_initialized = true;

	// Configure model parameters
	llama_model_params model_params = llama_model_default_params();

	if (params.has("n_gpu_layers")) {
		model_params.n_gpu_layers = static_cast<int32_t>(static_cast<int>(params["n_gpu_layers"]));
	}
	if (params.has("use_mmap")) {
		model_params.use_mmap = static_cast<bool>(params["use_mmap"]);
	}
	if (params.has("use_mlock")) {
		model_params.use_mlock = static_cast<bool>(params["use_mlock"]);
	}
	if (params.has("vocab_only")) {
		model_params.vocab_only = static_cast<bool>(params["vocab_only"]);
	}

	// Load model
	CharString path_utf8 = resolved_path.utf8();
	m_model = llama_model_load_from_file(path_utf8.get_data(), model_params);

	if (m_model == nullptr) {
		UtilityFunctions::push_error("LlamaInterface: Failed to load model from: ", path);
		_cleanup();
		return ERR_CANT_OPEN;
	}

	// Configure context parameters
	llama_context_params ctx_params = llama_context_default_params();

	if (params.has("n_ctx")) {
		ctx_params.n_ctx = static_cast<uint32_t>(static_cast<int>(params["n_ctx"]));
	}
	if (params.has("n_batch")) {
		ctx_params.n_batch = static_cast<uint32_t>(static_cast<int>(params["n_batch"]));
	}
	if (params.has("n_threads")) {
		ctx_params.n_threads = static_cast<int32_t>(static_cast<int>(params["n_threads"]));
	}
	if (params.has("n_threads_batch")) {
		ctx_params.n_threads_batch = static_cast<int32_t>(static_cast<int>(params["n_threads_batch"]));
	}

	// Create context
	m_context = llama_init_from_model(m_model, ctx_params);

	if (m_context == nullptr) {
		UtilityFunctions::push_error("LlamaInterface: Failed to create context for model: ", path);
		_cleanup();
		return ERR_CANT_CREATE;
	}

	m_model_path = path;
	UtilityFunctions::print("LlamaInterface: Model loaded successfully: ", path);

	return OK;
}

void LlamaInterface::unload_model() {
	if (!is_model_loaded()) {
		return;
	}
	_cleanup();
	UtilityFunctions::print("LlamaInterface: Model unloaded");
}

bool LlamaInterface::is_model_loaded() const {
	return m_model != nullptr && m_context != nullptr;
}

Dictionary LlamaInterface::get_model_info() const {
	Dictionary info;

	if (!is_model_loaded()) {
		return info;
	}

	// Model description
	char desc_buf[256];
	int32_t desc_len = llama_model_desc(m_model, desc_buf, sizeof(desc_buf));
	if (desc_len > 0) {
		info["description"] = String::utf8(desc_buf);
	}

	// Model path
	info["path"] = m_model_path;

	// Model size
	info["size_bytes"] = static_cast<int64_t>(llama_model_size(m_model));
	info["n_params"] = static_cast<int64_t>(llama_model_n_params(m_model));

	// Architecture info
	info["n_ctx_train"] = llama_model_n_ctx_train(m_model);
	info["n_embd"] = llama_model_n_embd(m_model);
	info["n_layer"] = llama_model_n_layer(m_model);
	info["n_head"] = llama_model_n_head(m_model);

	// Context info
	info["n_ctx"] = static_cast<int32_t>(llama_n_ctx(m_context));
	info["n_batch"] = static_cast<int32_t>(llama_n_batch(m_context));

	// Vocabulary info
	const llama_vocab *vocab = llama_model_get_vocab(m_model);
	if (vocab != nullptr) {
		info["vocab_size"] = llama_vocab_n_tokens(vocab);
		info["vocab_type"] = static_cast<int>(llama_vocab_type(vocab));

		// Special tokens
		llama_token bos = llama_vocab_bos(vocab);
		llama_token eos = llama_vocab_eos(vocab);
		if (bos != LLAMA_TOKEN_NULL) {
			info["bos_token"] = static_cast<int>(bos);
		}
		if (eos != LLAMA_TOKEN_NULL) {
			info["eos_token"] = static_cast<int>(eos);
		}
	}

	// Model characteristics
	info["has_encoder"] = llama_model_has_encoder(m_model);
	info["has_decoder"] = llama_model_has_decoder(m_model);
	info["is_recurrent"] = llama_model_is_recurrent(m_model);

	// Rope type
	info["rope_type"] = static_cast<int>(llama_model_rope_type(m_model));

	return info;
}

String LlamaInterface::get_model_path() const {
	return m_model_path;
}

} // namespace godot
