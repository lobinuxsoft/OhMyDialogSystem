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

# Internal state
var _model_manager: ModelManager
var _generation_thread: Thread
var _is_generating: bool = false


func _ready() -> void:
	_unload_btn.pressed.connect(_on_unload_pressed)
	_generate_btn.pressed.connect(_on_generate_pressed)
	_clear_btn.pressed.connect(_on_clear_pressed)

	_temperature_slider.value_changed.connect(_on_temperature_changed)
	_top_p_slider.value_changed.connect(_on_top_p_changed)
	_repeat_penalty_slider.value_changed.connect(_on_repeat_penalty_changed)
	_min_p_slider.value_changed.connect(_on_min_p_changed)

	_setup_sampling_tooltips()
	update_ui_state()


func _exit_tree() -> void:
	if _generation_thread != null and _generation_thread.is_started():
		_generation_thread.wait_to_finish()


## Sets the ModelManager reference for generation
func set_model_manager(manager: ModelManager) -> void:
	_model_manager = manager
	update_ui_state()
	update_loaded_model_info()


## Applies model defaults to sampling parameter UI
func apply_model_defaults(model: ModelConfig) -> void:
	_temperature_slider.value = model.default_temperature
	_top_p_slider.value = model.default_top_p
	_top_k_spinbox.value = model.default_top_k
	_max_tokens_spinbox.value = model.default_max_tokens
	_repeat_penalty_slider.value = model.default_repeat_penalty
	_min_p_slider.value = model.default_min_p


## Updates UI state based on model status
func update_ui_state() -> void:
	if not _model_manager:
		_unload_btn.disabled = true
		_generate_btn.disabled = true
		_status_label.text = "No model loaded"
		_status_label.remove_theme_color_override("font_color")
		return

	var is_loaded = _model_manager.is_model_loaded()

	_unload_btn.disabled = not is_loaded
	_generate_btn.disabled = not is_loaded or _is_generating

	if is_loaded and _model_manager.current_config != null:
		_status_label.text = "Model: %s" % _model_manager.current_config.display_name
		_status_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		_status_label.text = "No model loaded"
		_status_label.remove_theme_color_override("font_color")


## Updates the loaded model info panel
func update_loaded_model_info() -> void:
	if not _model_manager or not _model_manager.is_model_loaded():
		_loaded_model_info.text = "[color=#8b949e]No model loaded.[/color]\n[color=#484f58]Go to Models tab to load one.[/color]"
		return

	var config = _model_manager.current_config
	var info = _model_manager.get_model_info()

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
	var llama = _model_manager.get_llama()
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
	if _is_generating or not _model_manager or not _model_manager.is_model_loaded():
		return

	var prompt = _prompt_input.text.strip_edges()
	if prompt.is_empty():
		_output_display.text = "[Error: Please enter a prompt]"
		return

	_is_generating = true
	_generate_btn.disabled = true
	_generate_btn.text = "Generating..."
	_time_label.text = ""
	_output_display.text = "Generating..."

	_apply_sampling_params()

	_generation_thread = Thread.new()
	_generation_thread.start(_generate_threaded.bind(prompt))


func _generate_threaded(prompt: String) -> void:
	var start_time = Time.get_ticks_msec()
	var llama = _model_manager.get_llama()
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
