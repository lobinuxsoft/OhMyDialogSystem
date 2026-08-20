@tool
class_name GenerationTab
extends VBoxContainer
## Tab for testing text generation with loaded models.
##
## Provides UI for prompt input, sampling parameters, and output display.

## Emitted when user requests to unload the current model
signal unload_requested()

# UI References - Status
@onready var _status_label: Label = %GenStatusLabel
@onready var _unload_btn: Button = %UnloadBtn

# UI References - Prompt/Output
@onready var _prompt_input: TextEdit = %PromptInput
@onready var _generate_btn: Button = %GenerateBtn
@onready var _clear_btn: Button = %ClearBtn
@onready var _time_label: Label = %TimeLabel
@onready var _output_display: TextEdit = %OutputDisplay

# UI References - Preset Section
@onready var _preset_name_label: Label = %PresetNameLabel
@onready var _chat_template_preview: TextEdit = %ChatTemplatePreview
@onready var _load_preset_btn: Button = %LoadPresetBtn
@onready var _save_preset_btn: Button = %SavePresetBtn
@onready var _save_as_preset_btn: Button = %SaveAsPresetBtn
@onready var _reset_preset_btn: Button = %ResetPresetBtn
@onready var _save_preset_dialog: FileDialog = %SavePresetDialog
@onready var _load_preset_dialog: FileDialog = %LoadPresetDialog

# UI References - Sampling Parameters
@onready var _temperature_slider: HSlider = %TemperatureSlider
@onready var _temperature_value: Label = %TemperatureValue
@onready var _top_p_slider: HSlider = %TopPSlider
@onready var _top_p_value: Label = %TopPValue
@onready var _top_k_spinbox: SpinBox = %TopKSpinBox
@onready var _max_tokens_spinbox: SpinBox = %MaxTokensSpinBox
@onready var _repeat_penalty_slider: HSlider = %RepeatPenaltySlider
@onready var _repeat_penalty_value: Label = %RepeatPenaltyValue
@onready var _min_p_slider: HSlider = %MinPSlider
@onready var _min_p_value: Label = %MinPValue
@onready var _seed_spinbox: SpinBox = %SeedSpinBox
@onready var _stop_sequences_input: TextEdit = %StopSequencesInput
@onready var _loaded_model_info: RichTextLabel = %LoadedModelInfo

# UI References - Test Context Section
@onready var _character_label: Label = %CharacterLabel
@onready var _load_character_btn: Button = %LoadCharacterBtn
@onready var _clear_character_btn: Button = %ClearCharacterBtn
@onready var _world_label: Label = %WorldLabel
@onready var _load_world_btn: Button = %LoadWorldBtn
@onready var _clear_world_btn: Button = %ClearWorldBtn
@onready var _use_context_check: CheckBox = %UseContextCheck
@onready var _load_character_dialog: FileDialog = %LoadCharacterDialog
@onready var _load_world_dialog: FileDialog = %LoadWorldDialog

# UI References - Context Usage
@onready var _character_tokens_label: Label = %CharacterTokensLabel
@onready var _world_tokens_label: Label = %WorldTokensLabel
@onready var _prompt_tokens_label: Label = %PromptTokensLabel
@onready var _template_tokens_label: Label = %TemplateTokensLabel
@onready var _reserve_tokens_label: Label = %ReserveTokensLabel
@onready var _total_tokens_label: Label = %TotalTokensLabel
@onready var _context_progress_bar: ProgressBar = %ContextProgressBar
@onready var _context_percent_label: Label = %ContextPercentLabel

# Internal state
var _ai_service: AIService
var _generation_thread: Thread
var _is_generating: bool = false

# Preset state
var _current_preset: AIPreset = null
var _original_preset_values: Dictionary = {}  # For reset functionality

# Test context state
var _test_character: CharacterIdentity = null
var _test_world: WorldContext = null
var _prompt_builder: PromptBuilder = null

# Token estimation constant (~4 characters per token)
const CHARS_PER_TOKEN := 4.0
const RESPONSE_RESERVE := 256  # Default tokens reserved for response


func _ready() -> void:
	_unload_btn.pressed.connect(_on_unload_pressed)
	_generate_btn.pressed.connect(_on_generate_pressed)
	_clear_btn.pressed.connect(_on_clear_pressed)

	_temperature_slider.value_changed.connect(_on_temperature_changed)
	_top_p_slider.value_changed.connect(_on_top_p_changed)
	_repeat_penalty_slider.value_changed.connect(_on_repeat_penalty_changed)
	_min_p_slider.value_changed.connect(_on_min_p_changed)

	# Preset buttons
	_load_preset_btn.pressed.connect(_on_load_preset_pressed)
	_save_preset_btn.pressed.connect(_on_save_preset_pressed)
	_save_as_preset_btn.pressed.connect(_on_save_as_preset_pressed)
	_reset_preset_btn.pressed.connect(_on_reset_preset_pressed)
	_save_preset_dialog.file_selected.connect(_on_save_preset_dialog_file_selected)
	_load_preset_dialog.file_selected.connect(_on_load_preset_dialog_file_selected)

	# Test context buttons
	_load_character_btn.pressed.connect(_on_load_character_pressed)
	_clear_character_btn.pressed.connect(_on_clear_character_pressed)
	_load_world_btn.pressed.connect(_on_load_world_pressed)
	_clear_world_btn.pressed.connect(_on_clear_world_pressed)
	_load_character_dialog.file_selected.connect(_on_load_character_dialog_file_selected)
	_load_world_dialog.file_selected.connect(_on_load_world_dialog_file_selected)

	# Context usage updates
	_prompt_input.text_changed.connect(_on_prompt_text_changed)
	_use_context_check.toggled.connect(_on_use_context_toggled)
	_max_tokens_spinbox.value_changed.connect(_on_max_tokens_changed_for_context)

	_setup_sampling_tooltips()
	_setup_progress_bar_style()
	update_ui_state()
	_update_preset_ui()
	_update_context_usage()


func _exit_tree() -> void:
	# Cancel any ongoing generation
	if _is_generating and _ai_service != null:
		var llama = _ai_service.get_llama()
		if llama != null and llama.is_generating():
			llama.cancel_generation()

	# Wait for thread to finish
	if _generation_thread != null and _generation_thread.is_started():
		_generation_thread.wait_to_finish()
		_generation_thread = null

	# Clear references to avoid dangling pointers
	if _prompt_builder != null:
		_prompt_builder.set_llama_interface(null)
		_prompt_builder = null

	_test_character = null
	_test_world = null
	_current_preset = null
	_ai_service = null
	_original_preset_values.clear()


## Sets the AIService reference for generation
func set_ai_service(service: AIService) -> void:
	_ai_service = service
	update_ui_state()
	update_loaded_model_info()
	_update_context_usage()


## Applies model defaults to sampling parameter UI
func apply_model_defaults(model: ModelConfig) -> void:
	# Check if model has an associated AI preset
	if model.ai_preset != null:
		set_preset(model.ai_preset)
		return

	# Fallback to model's default sampling values
	_current_preset = null
	_original_preset_values.clear()
	_update_preset_ui()

	_temperature_slider.value = model.default_temperature
	_top_p_slider.value = model.default_top_p
	_top_k_spinbox.value = model.default_top_k
	_max_tokens_spinbox.value = model.default_max_tokens
	_repeat_penalty_slider.value = model.default_repeat_penalty
	_min_p_slider.value = model.default_min_p

	_update_context_usage()


## Updates UI state based on model status
func update_ui_state() -> void:
	if not _ai_service:
		_unload_btn.disabled = true
		_generate_btn.disabled = true
		_status_label.text = "No model loaded"
		_status_label.remove_theme_color_override("font_color")
		_clear_llama_reference()
		return

	var is_loaded = _ai_service.is_model_loaded()

	_unload_btn.disabled = not is_loaded
	_generate_btn.disabled = not is_loaded or _is_generating

	var current_config = _ai_service.get_current_config()
	if is_loaded and current_config != null:
		_status_label.text = "Model: %s" % current_config.display_name
		_status_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		_status_label.text = "No model loaded"
		_status_label.remove_theme_color_override("font_color")
		_clear_llama_reference()


## Clears llama reference from PromptBuilder to avoid dangling pointers
func _clear_llama_reference() -> void:
	if _prompt_builder != null:
		_prompt_builder.set_llama_interface(null)


## Updates the loaded model info panel
func update_loaded_model_info() -> void:
	if not _ai_service or not _ai_service.is_model_loaded():
		_loaded_model_info.text = "[color=#8b949e]No model loaded.[/color]\n[color=#484f58]Go to Models tab to load one.[/color]"
		return

	var config = _ai_service.get_current_config()
	var info = _ai_service.get_model_info()

	var text = "[color=#00d4ff][b]%s[/b][/color]\n" % config.display_name
	text += "[color=#21262d]━━━━━━━━━━━━━━━━━━━━━━[/color]\n\n"

	if info.has("n_params"):
		var params = info["n_params"]
		var params_str = "%.2fB" % (params / 1_000_000_000.0) if params >= 1_000_000_000 else "%.0fM" % (params / 1_000_000.0)
		text += "[color=#a855f7]Parameters:[/color] %s\n" % params_str

	if info.has("n_ctx"):
		text += "[color=#a855f7]Context:[/color] %d tokens\n" % info["n_ctx"]

	if info.has("vocab_size"):
		text += "[color=#a855f7]Vocabulary:[/color] %d tokens\n" % info["vocab_size"]

	if info.has("n_layer"):
		text += "[color=#a855f7]Layers:[/color] %d\n" % info["n_layer"]

	text += "\n[color=#10b981][b]Configuration[/b][/color]\n"

	# Show actual GPU layers from loaded model info
	if info.has("n_gpu_layers") and info.has("n_layer"):
		var gpu_layers: int = info["n_gpu_layers"]
		var total_layers: int = info["n_layer"]
		var backend_name: String = info.get("gpu_backend_name", "")

		if gpu_layers > 0 and not backend_name.is_empty() and backend_name != "CPU":
			text += "[color=#8b949e]GPU Layers:[/color] [color=#10b981]%d/%d[/color] on %s\n" % [gpu_layers, total_layers, backend_name]
		else:
			text += "[color=#8b949e]GPU Layers:[/color] [color=#f97316]CPU only[/color]\n"
	else:
		text += "[color=#8b949e]GPU Layers:[/color] %d\n" % config.n_gpu_layers

	text += "[color=#8b949e]Batch Size:[/color] %d\n" % config.n_batch

	var path = config.get_effective_path()
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var size_mb = file.get_length() / (1024.0 * 1024.0)
			file.close()
			text += "[color=#8b949e]File Size:[/color] %.1f MB\n" % size_mb

	var est_ram = config.size_mb * 1.2
	text += "[color=#8b949e]Est. RAM:[/color] ~%.0f MB\n" % est_ram

	_loaded_model_info.text = text


func _setup_sampling_tooltips() -> void:
	_temperature_slider.tooltip_text = "Controls randomness in generation.\n0.0 = Deterministic\n0.7 = Balanced\n1.0+ = Creative"
	_top_p_slider.tooltip_text = "Nucleus sampling threshold.\n0.9 = Focused\n0.95 = Balanced\n1.0 = All tokens"
	_top_k_spinbox.tooltip_text = "Limits to K most likely tokens.\n0 = Disabled\n40 = Balanced"
	_max_tokens_spinbox.tooltip_text = "Maximum tokens to generate.\n256 = Short\n512 = Medium\n1024+ = Long"
	_repeat_penalty_slider.tooltip_text = "Penalizes repeated tokens.\n1.0 = None\n1.1 = Light\n1.5+ = Strong"
	_min_p_slider.tooltip_text = "Filters low probability tokens.\n0.05 = Light\n0.1 = Moderate"
	_seed_spinbox.tooltip_text = "Random seed.\n-1 = Random each time"
	_stop_sequences_input.tooltip_text = "Stop sequences (one per line)."


func _apply_sampling_params() -> void:
	var llama = _ai_service.get_llama()
	if llama == null:
		return

	llama.temperature = _temperature_slider.value
	llama.top_p = _top_p_slider.value
	llama.top_k = int(_top_k_spinbox.value)
	llama.max_tokens = int(_max_tokens_spinbox.value)
	llama.repeat_penalty = _repeat_penalty_slider.value
	llama.min_p = _min_p_slider.value

	if _seed_spinbox.value < 0:
		llama.seed = 0xFFFFFFFF
	else:
		llama.seed = int(_seed_spinbox.value)

	var stop_text = _stop_sequences_input.text.strip_edges()
	if stop_text.is_empty():
		llama.clear_stop_sequences()
	else:
		var sequences = stop_text.split("\n", false)
		llama.set_stop_sequences(PackedStringArray(sequences))


func _on_unload_pressed() -> void:
	unload_requested.emit()


func _on_generate_pressed() -> void:
	if _is_generating or not _ai_service or not _ai_service.is_model_loaded():
		return

	var user_input = _prompt_input.text.strip_edges()
	if user_input.is_empty():
		_output_display.text = "[Error: Please enter a prompt]"
		return

	_is_generating = true
	_generate_btn.disabled = true
	_generate_btn.text = "Generating..."
	_time_label.text = ""
	_output_display.text = "Generating..."

	_apply_sampling_params()

	# Build prompt with context if enabled
	var final_prompt: String
	if is_using_context():
		final_prompt = _build_prompt_with_context(user_input)
	else:
		final_prompt = user_input

	_generation_thread = Thread.new()
	_generation_thread.start(_generate_threaded.bind(final_prompt))


## Builds a prompt with Character and World context using PromptBuilder
func _build_prompt_with_context(user_input: String) -> String:
	if _prompt_builder == null:
		_prompt_builder = PromptBuilder.new()

	# Set llama interface for native template application
	var llama = _ai_service.get_llama()
	if llama != null:
		_prompt_builder.set_llama_interface(llama)

	if _current_preset != null:
		_current_preset.apply_to_builder(_prompt_builder)

	# Build the full prompt
	var memories: Array[String] = []  # Empty for now, could add memory system later
	var history: Array[Dictionary] = []  # Empty conversation history for testing
	var max_context = 4096
	var current_config = _ai_service.get_current_config()
	if current_config != null:
		max_context = current_config.n_ctx

	return _prompt_builder.build_prompt(
		_test_character,
		_test_world,
		memories,
		history,
		user_input,
		max_context
	)


func _generate_threaded(prompt: String) -> void:
	var start_time = Time.get_ticks_msec()
	var llama = _ai_service.get_llama()
	var result = llama.generate(prompt)
	var elapsed = Time.get_ticks_msec() - start_time
	call_deferred("_on_generation_complete", result, elapsed)


func _on_generation_complete(result: String, elapsed_ms: int) -> void:
	if _generation_thread != null:
		_generation_thread.wait_to_finish()
		_generation_thread = null

	_is_generating = false
	_generate_btn.disabled = false
	_generate_btn.text = "Generate"

	_output_display.text = result
	_time_label.text = "Generated in %.2fs" % (elapsed_ms / 1000.0)

	update_ui_state()


func _on_clear_pressed() -> void:
	_output_display.text = ""
	_time_label.text = ""


func _on_temperature_changed(value: float) -> void:
	_temperature_value.text = "%.2f" % value


func _on_top_p_changed(value: float) -> void:
	_top_p_value.text = "%.2f" % value


func _on_repeat_penalty_changed(value: float) -> void:
	_repeat_penalty_value.text = "%.2f" % value


func _on_min_p_changed(value: float) -> void:
	_min_p_value.text = "%.2f" % value


# ==================== Preset Management ====================


## Updates the preset section UI
func _update_preset_ui() -> void:
	if _current_preset == null:
		_preset_name_label.text = "None"
		_chat_template_preview.text = ""
		_save_preset_btn.disabled = true
		_save_as_preset_btn.disabled = true
		_reset_preset_btn.disabled = true
		return

	_preset_name_label.text = _current_preset.preset_name
	_save_preset_btn.disabled = _current_preset.resource_path.is_empty()
	_save_as_preset_btn.disabled = false
	_reset_preset_btn.disabled = false

	# Show chat template format info
	var template_text = ""
	if not _current_preset.chat_template_format.is_empty():
		template_text = "Format: %s\n" % _current_preset.chat_template_format
	if not _current_preset.model_architecture.is_empty():
		template_text += "Architecture: %s\n" % _current_preset.model_architecture
	if not _current_preset.source_chat_template.is_empty():
		# Show first 200 chars of template
		var preview = _current_preset.source_chat_template.substr(0, 200)
		if _current_preset.source_chat_template.length() > 200:
			preview += "..."
		template_text += "\nTemplate:\n%s" % preview
	_chat_template_preview.text = template_text


## Sets the current preset and populates UI from it
func set_preset(preset: AIPreset) -> void:
	_current_preset = preset
	if preset != null:
		_store_original_values()
		_apply_preset_to_ui(preset)
	_update_preset_ui()
	_update_context_usage()


## Stores the original preset values for reset functionality
func _store_original_values() -> void:
	if _current_preset == null:
		_original_preset_values.clear()
		return

	_original_preset_values = {
		"temperature": _current_preset.temperature,
		"top_p": _current_preset.top_p,
		"top_k": _current_preset.top_k,
		"max_tokens": _current_preset.max_tokens,
		"repeat_penalty": _current_preset.repeat_penalty,
		"min_p": _current_preset.min_p,
		"stop_sequences": _current_preset.stop_sequences.duplicate()
	}


## Applies preset values to the UI sliders/spinboxes
func _apply_preset_to_ui(preset: AIPreset) -> void:
	_temperature_slider.value = preset.temperature
	_top_p_slider.value = preset.top_p
	_top_k_spinbox.value = preset.top_k
	_max_tokens_spinbox.value = preset.max_tokens
	_repeat_penalty_slider.value = preset.repeat_penalty
	_min_p_slider.value = preset.min_p

	# Set stop sequences from preset
	if preset.stop_sequences.is_empty():
		_stop_sequences_input.text = ""
	else:
		_stop_sequences_input.text = "\n".join(preset.stop_sequences)


## Updates the preset from current UI values
func _update_preset_from_ui() -> void:
	if _current_preset == null:
		return

	_current_preset.temperature = _temperature_slider.value
	_current_preset.top_p = _top_p_slider.value
	_current_preset.top_k = int(_top_k_spinbox.value)
	_current_preset.max_tokens = int(_max_tokens_spinbox.value)
	_current_preset.repeat_penalty = _repeat_penalty_slider.value
	_current_preset.min_p = _min_p_slider.value

	# Update stop sequences
	_current_preset.stop_sequences.clear()
	var stop_text = _stop_sequences_input.text.strip_edges()
	if not stop_text.is_empty():
		for seq in stop_text.split("\n", false):
			_current_preset.stop_sequences.append(seq)


func _on_save_preset_pressed() -> void:
	if _current_preset == null or _current_preset.resource_path.is_empty():
		return

	_update_preset_from_ui()
	var err = ResourceSaver.save(_current_preset, _current_preset.resource_path)
	if err == OK:
		_store_original_values()  # Update original values after save


func _on_save_as_preset_pressed() -> void:
	if _current_preset == null:
		return

	# Set default path
	var default_dir = "res://presets"
	if not DirAccess.dir_exists_absolute(default_dir):
		DirAccess.make_dir_absolute(default_dir)
	_save_preset_dialog.current_dir = default_dir
	_save_preset_dialog.current_file = "%s.tres" % _current_preset.preset_name.to_lower().replace(" ", "_")
	_save_preset_dialog.popup_centered()


func _on_save_preset_dialog_file_selected(path: String) -> void:
	if _current_preset == null:
		return

	# Create a duplicate preset with new name
	var new_preset = _current_preset.duplicate() as AIPreset
	new_preset.preset_name = path.get_file().get_basename().replace("_", " ").capitalize()

	# Update with current UI values
	_current_preset = new_preset
	_update_preset_from_ui()

	var err = ResourceSaver.save(new_preset, path)
	if err == OK:
		new_preset.resource_path = path
		_current_preset = new_preset
		_store_original_values()
		_update_preset_ui()

		# Associate with current model config if available
		var current_config = _ai_service.get_current_config() if _ai_service else null
		if current_config != null:
			current_config.ai_preset = new_preset


func _on_reset_preset_pressed() -> void:
	if _original_preset_values.is_empty():
		return

	_temperature_slider.value = _original_preset_values.get("temperature", 0.7)
	_top_p_slider.value = _original_preset_values.get("top_p", 0.9)
	_top_k_spinbox.value = _original_preset_values.get("top_k", 40)
	_max_tokens_spinbox.value = _original_preset_values.get("max_tokens", 256)
	_repeat_penalty_slider.value = _original_preset_values.get("repeat_penalty", 1.1)
	_min_p_slider.value = _original_preset_values.get("min_p", 0.05)

	var stop_seqs: Array = _original_preset_values.get("stop_sequences", [])
	_stop_sequences_input.text = "\n".join(stop_seqs)


func _on_load_preset_pressed() -> void:
	# Set default directory to presets folder
	var default_dir = "res://presets"
	if DirAccess.dir_exists_absolute(default_dir):
		_load_preset_dialog.current_dir = default_dir
	else:
		_load_preset_dialog.current_dir = "res://"
	_load_preset_dialog.popup_centered()


func _on_load_preset_dialog_file_selected(path: String) -> void:
	var loaded_resource = load(path)
	if loaded_resource == null:
		push_error("GenerationTab: Failed to load resource from: %s" % path)
		return

	if not loaded_resource is AIPreset:
		push_error("GenerationTab: Resource is not an AIPreset: %s" % path)
		return

	var preset = loaded_resource as AIPreset
	set_preset(preset)

	# Associate with current model if one is loaded
	var current_config = _ai_service.get_current_config() if _ai_service else null
	if current_config != null:
		current_config.ai_preset = preset


# ==================== Test Context Management ====================


func _on_load_character_pressed() -> void:
	var default_dir = "res://"
	if DirAccess.dir_exists_absolute("res://characters"):
		default_dir = "res://characters"
	_load_character_dialog.current_dir = default_dir
	_load_character_dialog.popup_centered()


func _on_load_character_dialog_file_selected(path: String) -> void:
	var loaded_resource = load(path)
	if loaded_resource == null:
		push_error("GenerationTab: Failed to load resource from: %s" % path)
		return

	if not loaded_resource is CharacterIdentity:
		push_error("GenerationTab: Resource is not a CharacterIdentity: %s" % path)
		return

	_test_character = loaded_resource as CharacterIdentity
	_character_label.text = _test_character.character_name if not _test_character.character_name.is_empty() else path.get_file()
	_character_label.tooltip_text = path
	_update_context_usage()


func _on_clear_character_pressed() -> void:
	_test_character = null
	_character_label.text = "None"
	_character_label.tooltip_text = ""
	_update_context_usage()


func _on_load_world_pressed() -> void:
	var default_dir = "res://"
	if DirAccess.dir_exists_absolute("res://worlds"):
		default_dir = "res://worlds"
	_load_world_dialog.current_dir = default_dir
	_load_world_dialog.popup_centered()


func _on_load_world_dialog_file_selected(path: String) -> void:
	var loaded_resource = load(path)
	if loaded_resource == null:
		push_error("GenerationTab: Failed to load resource from: %s" % path)
		return

	if not loaded_resource is WorldContext:
		push_error("GenerationTab: Resource is not a WorldContext: %s" % path)
		return

	_test_world = loaded_resource as WorldContext
	_world_label.text = _test_world.world_name if not _test_world.world_name.is_empty() else path.get_file()
	_world_label.tooltip_text = path
	_update_context_usage()


func _on_clear_world_pressed() -> void:
	_test_world = null
	_world_label.text = "None"
	_world_label.tooltip_text = ""
	_update_context_usage()


## Returns the test character for use in generation
func get_test_character() -> CharacterIdentity:
	return _test_character if _use_context_check.button_pressed else null


## Returns the test world for use in generation
func get_test_world() -> WorldContext:
	return _test_world if _use_context_check.button_pressed else null


## Check if context should be used in generation
func is_using_context() -> bool:
	return _use_context_check.button_pressed and (_test_character != null or _test_world != null)


# ==================== Context Usage ====================


## Sets up the progress bar StyleBox for dynamic coloring
func _setup_progress_bar_style() -> void:
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.063, 0.725, 0.506)  # Green
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	_context_progress_bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.15, 0.15)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	_context_progress_bar.add_theme_stylebox_override("background", bg_style)


## Estimates token count from text (~4 chars per token)
func _estimate_tokens(text: String) -> int:
	if text.is_empty():
		return 0
	return ceili(text.length() / CHARS_PER_TOKEN)


## Counts tokens using model's tokenizer if loaded, otherwise estimates
## Returns [token_count, is_exact] where is_exact indicates if count is precise
func _count_tokens_smart(text: String) -> Array:
	if text.is_empty():
		return [0, true]

	# Try to use model's tokenizer for exact count
	if _ai_service != null and _ai_service.is_model_loaded():
		var llama = _ai_service.get_llama()
		if llama != null and llama.has_method("count_tokens"):
			var count = llama.count_tokens(text)
			if count >= 0:
				return [count, true]

	# Fallback to estimation
	return [_estimate_tokens(text), false]


## Updates the context usage display with current values
func _update_context_usage() -> void:
	var character_tokens := 0
	var world_tokens := 0
	var prompt_tokens := 0
	var template_tokens := 0
	var response_reserve := int(_max_tokens_spinbox.value)

	# Check if we can use exact tokenization (model must be loaded)
	var has_tokenizer := _ai_service != null and _ai_service.is_model_loaded()
	var is_exact := has_tokenizer  # Start as exact if tokenizer available

	# Calculate character tokens
	if _test_character != null and _use_context_check.button_pressed:
		var char_text := _test_character.to_system_prompt()
		var result := _count_tokens_smart(char_text)
		character_tokens = result[0]
		is_exact = result[1]

	# Calculate world tokens
	if _test_world != null and _use_context_check.button_pressed:
		var world_text := _test_world.to_context_prompt()
		var result := _count_tokens_smart(world_text)
		world_tokens = result[0]
		is_exact = is_exact and result[1]

	# Calculate prompt tokens
	var prompt_result := _count_tokens_smart(_prompt_input.text)
	prompt_tokens = prompt_result[0]
	is_exact = is_exact and prompt_result[1]

	# Calculate template tokens (overhead from chat template)
	template_tokens = _estimate_template_tokens()

	# Get max context from model
	var max_context := 4096  # Default
	var current_config = _ai_service.get_current_config() if _ai_service else null
	if current_config != null:
		max_context = current_config.n_ctx

	# Calculate total
	var total_tokens := character_tokens + world_tokens + prompt_tokens + template_tokens + response_reserve
	var percentage := (float(total_tokens) / float(max_context)) * 100.0

	# Prefix for estimated values
	var prefix := "" if is_exact else "~"

	# Update labels
	_character_tokens_label.text = "%s%d tokens" % [prefix, character_tokens]
	_world_tokens_label.text = "%s%d tokens" % [prefix, world_tokens]
	_prompt_tokens_label.text = "%s%d tokens" % [prefix, prompt_tokens]
	_template_tokens_label.text = "~%d tokens" % template_tokens  # Always estimated
	_reserve_tokens_label.text = "%d tokens" % response_reserve
	_total_tokens_label.text = "%s%d / %d" % [prefix, total_tokens, max_context]

	# Show if using exact or estimated counts
	var mode_text := "exact" if is_exact else "estimated"
	_context_percent_label.text = "%.1f%% of context (%s)" % [percentage, mode_text]

	# Update progress bar
	_context_progress_bar.value = clampf(percentage, 0.0, 100.0)
	_update_progress_bar_color(percentage)


## Estimates template overhead tokens based on preset or default
func _estimate_template_tokens() -> int:
	# If we have a preset with source template, use its length
	if _current_preset != null and not _current_preset.source_chat_template.is_empty():
		# Template has placeholders that get replaced, estimate base overhead
		# Subtract placeholder lengths, add typical content overhead
		var template = _current_preset.source_chat_template
		# Remove Jinja2 placeholders to get base overhead
		var base_template = template
		# Rough estimate: template structure without content
		return _estimate_tokens(base_template) / 3  # Divide by 3 as placeholders inflate size

	# Default estimates by format
	if _current_preset != null:
		match _current_preset.chat_template_format.to_lower():
			"chatml":
				return 25  # <|im_start|>system\n...<|im_end|>\n etc
			"llama", "llama2", "llama3":
				return 30  # [INST] <<SYS>>...<</SYS>>...
			"mistral":
				return 20  # <s>[INST]...
			"vicuna":
				return 15  # USER: ASSISTANT:
			"phi":
				return 20  # <|user|>...<|end|>
			"gemma":
				return 20  # <start_of_turn>...

	# Default fallback (ChatML-like)
	return 25


## Updates the progress bar color based on usage percentage
func _update_progress_bar_color(percentage: float) -> void:
	var fill_style = _context_progress_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill_style == null:
		return

	var color: Color
	if percentage < 50.0:
		# Green
		color = Color(0.063, 0.725, 0.506)
	elif percentage < 80.0:
		# Yellow/Orange - interpolate from green to yellow
		var t := (percentage - 50.0) / 30.0
		color = Color(0.063, 0.725, 0.506).lerp(Color(0.918, 0.675, 0.22), t)
	else:
		# Red - interpolate from yellow to red
		var t := minf((percentage - 80.0) / 20.0, 1.0)
		color = Color(0.918, 0.675, 0.22).lerp(Color(0.937, 0.267, 0.267), t)

	fill_style.bg_color = color


func _on_prompt_text_changed() -> void:
	_update_context_usage()


func _on_use_context_toggled(_pressed: bool) -> void:
	_update_context_usage()


func _on_max_tokens_changed_for_context(_value: float) -> void:
	_update_context_usage()
