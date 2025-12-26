#include "llama_interface.h"

#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/project_settings.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <string>

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

llama_sampler *LlamaInterface::_create_sampler() const {
	llama_sampler *smpl = llama_sampler_chain_init(llama_sampler_chain_default_params());

	// Add penalties for repetition
	llama_sampler_chain_add(smpl, llama_sampler_init_penalties(
		m_repeat_last_n,
		m_repeat_penalty,
		m_frequency_penalty,
		m_presence_penalty
	));

	// Add top-k if enabled
	if (m_top_k > 0) {
		llama_sampler_chain_add(smpl, llama_sampler_init_top_k(m_top_k));
	}

	// Add min-p
	llama_sampler_chain_add(smpl, llama_sampler_init_min_p(m_min_p, 1));

	// Add top-p
	llama_sampler_chain_add(smpl, llama_sampler_init_top_p(m_top_p, 1));

	// Add temperature
	if (m_temperature > 0.0f) {
		llama_sampler_chain_add(smpl, llama_sampler_init_temp(m_temperature));
		llama_sampler_chain_add(smpl, llama_sampler_init_dist(m_seed));
	} else {
		// Greedy sampling when temperature is 0
		llama_sampler_chain_add(smpl, llama_sampler_init_greedy());
	}

	return smpl;
}

bool LlamaInterface::_check_stop_sequence(const std::string &text) const {
	for (const auto &stop : m_stop_sequences) {
		if (!stop.empty() && text.length() >= stop.length()) {
			if (text.rfind(stop) == text.length() - stop.length()) {
				return true;
			}
		}
	}
	return false;
}

void LlamaInterface::_bind_methods() {
	// Model management
	ClassDB::bind_method(D_METHOD("load_model", "path", "params"), &LlamaInterface::load_model, DEFVAL(Dictionary()));
	ClassDB::bind_method(D_METHOD("unload_model"), &LlamaInterface::unload_model);
	ClassDB::bind_method(D_METHOD("is_model_loaded"), &LlamaInterface::is_model_loaded);
	ClassDB::bind_method(D_METHOD("get_model_info"), &LlamaInterface::get_model_info);
	ClassDB::bind_method(D_METHOD("get_model_path"), &LlamaInterface::get_model_path);

	// Text generation
	ClassDB::bind_method(D_METHOD("generate", "prompt"), &LlamaInterface::generate);

	// Sampling parameters
	ClassDB::bind_method(D_METHOD("set_temperature", "temperature"), &LlamaInterface::set_temperature);
	ClassDB::bind_method(D_METHOD("get_temperature"), &LlamaInterface::get_temperature);
	ClassDB::bind_method(D_METHOD("set_top_p", "top_p"), &LlamaInterface::set_top_p);
	ClassDB::bind_method(D_METHOD("get_top_p"), &LlamaInterface::get_top_p);
	ClassDB::bind_method(D_METHOD("set_top_k", "top_k"), &LlamaInterface::set_top_k);
	ClassDB::bind_method(D_METHOD("get_top_k"), &LlamaInterface::get_top_k);
	ClassDB::bind_method(D_METHOD("set_max_tokens", "max_tokens"), &LlamaInterface::set_max_tokens);
	ClassDB::bind_method(D_METHOD("get_max_tokens"), &LlamaInterface::get_max_tokens);
	ClassDB::bind_method(D_METHOD("set_repeat_penalty", "penalty"), &LlamaInterface::set_repeat_penalty);
	ClassDB::bind_method(D_METHOD("get_repeat_penalty"), &LlamaInterface::get_repeat_penalty);
	ClassDB::bind_method(D_METHOD("set_frequency_penalty", "penalty"), &LlamaInterface::set_frequency_penalty);
	ClassDB::bind_method(D_METHOD("get_frequency_penalty"), &LlamaInterface::get_frequency_penalty);
	ClassDB::bind_method(D_METHOD("set_presence_penalty", "penalty"), &LlamaInterface::set_presence_penalty);
	ClassDB::bind_method(D_METHOD("get_presence_penalty"), &LlamaInterface::get_presence_penalty);
	ClassDB::bind_method(D_METHOD("set_repeat_last_n", "n"), &LlamaInterface::set_repeat_last_n);
	ClassDB::bind_method(D_METHOD("get_repeat_last_n"), &LlamaInterface::get_repeat_last_n);
	ClassDB::bind_method(D_METHOD("set_min_p", "min_p"), &LlamaInterface::set_min_p);
	ClassDB::bind_method(D_METHOD("get_min_p"), &LlamaInterface::get_min_p);
	ClassDB::bind_method(D_METHOD("set_seed", "seed"), &LlamaInterface::set_seed);
	ClassDB::bind_method(D_METHOD("get_seed"), &LlamaInterface::get_seed);

	// Stop sequences
	ClassDB::bind_method(D_METHOD("set_stop_sequences", "sequences"), &LlamaInterface::set_stop_sequences);
	ClassDB::bind_method(D_METHOD("get_stop_sequences"), &LlamaInterface::get_stop_sequences);
	ClassDB::bind_method(D_METHOD("clear_stop_sequences"), &LlamaInterface::clear_stop_sequences);

	// Timeout
	ClassDB::bind_method(D_METHOD("set_timeout", "timeout_ms"), &LlamaInterface::set_timeout);
	ClassDB::bind_method(D_METHOD("get_timeout"), &LlamaInterface::get_timeout);
	ClassDB::bind_method(D_METHOD("has_generation_timed_out"), &LlamaInterface::has_generation_timed_out);

	// Signals
	ADD_SIGNAL(MethodInfo("generation_timeout"));

	// Properties
	ADD_GROUP("Sampling", "");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "temperature", PROPERTY_HINT_RANGE, "0.0,2.0,0.01"), "set_temperature", "get_temperature");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "top_p", PROPERTY_HINT_RANGE, "0.0,1.0,0.01"), "set_top_p", "get_top_p");
	ADD_PROPERTY(PropertyInfo(Variant::INT, "top_k", PROPERTY_HINT_RANGE, "0,100,1"), "set_top_k", "get_top_k");
	ADD_PROPERTY(PropertyInfo(Variant::INT, "max_tokens", PROPERTY_HINT_RANGE, "1,4096,1"), "set_max_tokens", "get_max_tokens");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "repeat_penalty", PROPERTY_HINT_RANGE, "1.0,2.0,0.01"), "set_repeat_penalty", "get_repeat_penalty");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "min_p", PROPERTY_HINT_RANGE, "0.0,1.0,0.01"), "set_min_p", "get_min_p");
	ADD_PROPERTY(PropertyInfo(Variant::INT, "seed"), "set_seed", "get_seed");

	ADD_GROUP("Timeout", "");
	ADD_PROPERTY(PropertyInfo(Variant::INT, "timeout", PROPERTY_HINT_RANGE, "0,300000,100"), "set_timeout", "get_timeout");
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

// ==================== Text Generation ====================

String LlamaInterface::generate(const String &prompt) {
	// Reset timeout flag
	m_generation_timed_out = false;

	if (!is_model_loaded()) {
		UtilityFunctions::push_error("LlamaInterface: No model loaded");
		return String();
	}

	const llama_vocab *vocab = llama_model_get_vocab(m_model);
	if (vocab == nullptr) {
		UtilityFunctions::push_error("LlamaInterface: Failed to get vocabulary");
		return String();
	}

	// Convert prompt to UTF-8
	CharString prompt_utf8 = prompt.utf8();
	const char *prompt_cstr = prompt_utf8.get_data();
	int prompt_len = prompt_utf8.length();

	// Tokenize the prompt
	int n_tokens = -llama_tokenize(vocab, prompt_cstr, prompt_len, nullptr, 0, true, true);
	if (n_tokens < 0) {
		n_tokens = -n_tokens;
	}

	std::vector<llama_token> tokens(n_tokens);
	int tokenized = llama_tokenize(vocab, prompt_cstr, prompt_len, tokens.data(), tokens.size(), true, true);
	if (tokenized < 0) {
		UtilityFunctions::push_error("LlamaInterface: Failed to tokenize prompt");
		return String();
	}
	tokens.resize(tokenized);

	// Check context size
	int n_ctx = llama_n_ctx(m_context);
	if ((int)tokens.size() + m_max_tokens > n_ctx) {
		UtilityFunctions::push_warning("LlamaInterface: Prompt + max_tokens exceeds context size, truncating");
	}

	// Clear the memory/KV cache for fresh generation
	llama_memory_clear(llama_get_memory(m_context), true);

	// Create sampler
	llama_sampler *smpl = _create_sampler();

	// Create batch for prompt
	llama_batch batch = llama_batch_get_one(tokens.data(), tokens.size());

	// Decode prompt
	if (llama_decode(m_context, batch) != 0) {
		UtilityFunctions::push_error("LlamaInterface: Failed to decode prompt");
		llama_sampler_free(smpl);
		return String();
	}

	// Generation loop
	std::string generated_text;
	int n_decoded = 0;

	// Start time for timeout check
	auto start_time = std::chrono::steady_clock::now();

	while (n_decoded < m_max_tokens) {
		// Check timeout
		if (m_timeout_ms > 0) {
			auto current_time = std::chrono::steady_clock::now();
			auto elapsed_ms = std::chrono::duration_cast<std::chrono::milliseconds>(current_time - start_time).count();
			if (elapsed_ms >= m_timeout_ms) {
				m_generation_timed_out = true;
				UtilityFunctions::push_warning("LlamaInterface: Generation timed out after ", elapsed_ms, "ms");
				emit_signal("generation_timeout");
				break;
			}
		}

		// Sample next token
		llama_token new_token = llama_sampler_sample(smpl, m_context, -1);

		// Check for end of generation
		if (llama_vocab_is_eog(vocab, new_token)) {
			break;
		}

		// Convert token to text
		char buf[256];
		int n = llama_token_to_piece(vocab, new_token, buf, sizeof(buf), 0, true);
		if (n < 0) {
			UtilityFunctions::push_error("LlamaInterface: Failed to convert token to text");
			break;
		}

		std::string piece(buf, n);
		generated_text += piece;

		// Check for stop sequences
		if (_check_stop_sequence(generated_text)) {
			// Remove the stop sequence from output
			for (const auto &stop : m_stop_sequences) {
				size_t pos = generated_text.rfind(stop);
				if (pos != std::string::npos && pos == generated_text.length() - stop.length()) {
					generated_text = generated_text.substr(0, pos);
					break;
				}
			}
			break;
		}

		// Prepare batch for next token
		batch = llama_batch_get_one(&new_token, 1);

		// Decode
		if (llama_decode(m_context, batch) != 0) {
			UtilityFunctions::push_error("LlamaInterface: Failed to decode token");
			break;
		}

		n_decoded++;
	}

	// Cleanup
	llama_sampler_free(smpl);

	return String::utf8(generated_text.c_str());
}

// ==================== Sampling Parameters ====================

void LlamaInterface::set_temperature(float temperature) {
	m_temperature = temperature > 0.0f ? temperature : 0.0f;
}

float LlamaInterface::get_temperature() const {
	return m_temperature;
}

void LlamaInterface::set_top_p(float top_p) {
	m_top_p = top_p > 0.0f && top_p <= 1.0f ? top_p : 0.95f;
}

float LlamaInterface::get_top_p() const {
	return m_top_p;
}

void LlamaInterface::set_top_k(int32_t top_k) {
	m_top_k = top_k >= 0 ? top_k : 0;
}

int32_t LlamaInterface::get_top_k() const {
	return m_top_k;
}

void LlamaInterface::set_max_tokens(int32_t max_tokens) {
	m_max_tokens = max_tokens > 0 ? max_tokens : 1;
}

int32_t LlamaInterface::get_max_tokens() const {
	return m_max_tokens;
}

void LlamaInterface::set_repeat_penalty(float penalty) {
	m_repeat_penalty = penalty >= 1.0f ? penalty : 1.0f;
}

float LlamaInterface::get_repeat_penalty() const {
	return m_repeat_penalty;
}

void LlamaInterface::set_frequency_penalty(float penalty) {
	m_frequency_penalty = penalty >= 0.0f ? penalty : 0.0f;
}

float LlamaInterface::get_frequency_penalty() const {
	return m_frequency_penalty;
}

void LlamaInterface::set_presence_penalty(float penalty) {
	m_presence_penalty = penalty >= 0.0f ? penalty : 0.0f;
}

float LlamaInterface::get_presence_penalty() const {
	return m_presence_penalty;
}

void LlamaInterface::set_repeat_last_n(int32_t n) {
	m_repeat_last_n = n >= 0 ? n : 64;
}

int32_t LlamaInterface::get_repeat_last_n() const {
	return m_repeat_last_n;
}

void LlamaInterface::set_min_p(float min_p) {
	m_min_p = min_p >= 0.0f && min_p <= 1.0f ? min_p : 0.05f;
}

float LlamaInterface::get_min_p() const {
	return m_min_p;
}

void LlamaInterface::set_seed(int64_t seed) {
	m_seed = static_cast<uint32_t>(seed);
}

int64_t LlamaInterface::get_seed() const {
	return static_cast<int64_t>(m_seed);
}

// ==================== Stop Sequences ====================

void LlamaInterface::set_stop_sequences(const PackedStringArray &sequences) {
	m_stop_sequences.clear();
	for (int i = 0; i < sequences.size(); i++) {
		CharString utf8 = sequences[i].utf8();
		m_stop_sequences.push_back(std::string(utf8.get_data()));
	}
}

PackedStringArray LlamaInterface::get_stop_sequences() const {
	PackedStringArray result;
	for (const auto &stop : m_stop_sequences) {
		result.push_back(String::utf8(stop.c_str()));
	}
	return result;
}

void LlamaInterface::clear_stop_sequences() {
	m_stop_sequences.clear();
}

// ==================== Timeout ====================

void LlamaInterface::set_timeout(int64_t timeout_ms) {
	m_timeout_ms = timeout_ms >= 0 ? timeout_ms : 0;
}

int64_t LlamaInterface::get_timeout() const {
	return m_timeout_ms;
}

bool LlamaInterface::has_generation_timed_out() const {
	return m_generation_timed_out;
}

} // namespace godot
