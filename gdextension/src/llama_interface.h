#ifndef LLAMA_INTERFACE_H
#define LLAMA_INTERFACE_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/string.hpp>

#include "llama.h"

#include <chrono>
#include <string>
#include <vector>

namespace godot {

/// LlamaInterface: Wrapper for llama.cpp model loading and inference.
/// Exposes llama.cpp functionality to GDScript and C#.
class LlamaInterface : public RefCounted {
	GDCLASS(LlamaInterface, RefCounted);

private:
	// Model and context
	llama_model *m_model = nullptr;
	llama_context *m_context = nullptr;
	String m_model_path;
	bool m_backend_initialized = false;

	// Sampling parameters
	float m_temperature = 0.8f;
	float m_top_p = 0.95f;
	int32_t m_top_k = 40;
	int32_t m_max_tokens = 256;
	float m_repeat_penalty = 1.1f;
	float m_frequency_penalty = 0.0f;
	float m_presence_penalty = 0.0f;
	int32_t m_repeat_last_n = 64;
	float m_min_p = 0.05f;
	uint32_t m_seed = LLAMA_DEFAULT_SEED;

	// Stop sequences
	std::vector<std::string> m_stop_sequences;

	// Timeout configuration
	int64_t m_timeout_ms = 0; // 0 = no timeout
	bool m_generation_timed_out = false;

	// Internal methods
	void _cleanup();
	llama_sampler *_create_sampler() const;
	bool _check_stop_sequence(const std::string &text) const;

protected:
	static void _bind_methods();

public:
	LlamaInterface();
	~LlamaInterface();

	// ==================== Model Management ====================

	/// Load a GGUF model from the specified path.
	/// @param path Path to the .gguf model file (supports user:// and res://)
	/// @param params Optional parameters: n_ctx (int), n_gpu_layers (int), use_mmap (bool), use_mlock (bool)
	/// @return OK on success, or an error code
	Error load_model(const String &path, const Dictionary &params = Dictionary());

	/// Unload the currently loaded model and free resources.
	void unload_model();

	/// Check if a model is currently loaded.
	/// @return true if a model is loaded, false otherwise
	bool is_model_loaded() const;

	/// Get information about the currently loaded model.
	/// @return Dictionary with model info, or empty if no model is loaded
	Dictionary get_model_info() const;

	/// Get the path of the currently loaded model.
	/// @return Model path or empty string if no model is loaded
	String get_model_path() const;

	// ==================== Text Generation ====================

	/// Generate text synchronously from a prompt.
	/// @param prompt The input text to continue from
	/// @return Generated text, or empty string on error
	String generate(const String &prompt);

	// ==================== Sampling Parameters ====================

	/// Set the temperature for sampling (0.0 = greedy, higher = more random)
	void set_temperature(float temperature);
	float get_temperature() const;

	/// Set top-p (nucleus) sampling threshold
	void set_top_p(float top_p);
	float get_top_p() const;

	/// Set top-k sampling (0 = disabled)
	void set_top_k(int32_t top_k);
	int32_t get_top_k() const;

	/// Set maximum tokens to generate
	void set_max_tokens(int32_t max_tokens);
	int32_t get_max_tokens() const;

	/// Set repeat penalty (1.0 = disabled)
	void set_repeat_penalty(float penalty);
	float get_repeat_penalty() const;

	/// Set frequency penalty
	void set_frequency_penalty(float penalty);
	float get_frequency_penalty() const;

	/// Set presence penalty
	void set_presence_penalty(float penalty);
	float get_presence_penalty() const;

	/// Set how many tokens back to apply repeat penalty
	void set_repeat_last_n(int32_t n);
	int32_t get_repeat_last_n() const;

	/// Set minimum probability threshold
	void set_min_p(float min_p);
	float get_min_p() const;

	/// Set random seed for reproducibility (0xFFFFFFFF = random)
	void set_seed(int64_t seed);
	int64_t get_seed() const;

	// ==================== Stop Sequences ====================

	/// Set sequences that stop generation when encountered
	void set_stop_sequences(const PackedStringArray &sequences);
	PackedStringArray get_stop_sequences() const;

	/// Clear all stop sequences
	void clear_stop_sequences();

	// ==================== Timeout ====================

	/// Set generation timeout in milliseconds (0 = no timeout)
	void set_timeout(int64_t timeout_ms);
	int64_t get_timeout() const;

	/// Check if the last generation timed out
	bool has_generation_timed_out() const;
};

} // namespace godot

#endif // LLAMA_INTERFACE_H
