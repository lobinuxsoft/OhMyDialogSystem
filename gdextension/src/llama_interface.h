#ifndef LLAMA_INTERFACE_H
#define LLAMA_INTERFACE_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>

#include "llama.h"

namespace godot {

/// LlamaInterface: Wrapper for llama.cpp model loading and inference.
/// Exposes llama.cpp functionality to GDScript and C#.
class LlamaInterface : public RefCounted {
	GDCLASS(LlamaInterface, RefCounted);

private:
	llama_model *m_model = nullptr;
	llama_context *m_context = nullptr;
	String m_model_path;
	bool m_backend_initialized = false;

	void _cleanup();

protected:
	static void _bind_methods();

public:
	LlamaInterface();
	~LlamaInterface();

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
};

} // namespace godot

#endif // LLAMA_INTERFACE_H
