extends Control
## Test scene for the OhMyDialog system.
##
## Demonstrates DialogueManager with AIService integration.
## Requires a model to be loaded via Model Manager before AI responses work.


@onready var dialogue_panel: PanelContainer = %DialoguePanel
@onready var speaker_label: Label = %SpeakerLabel
@onready var dialogue_text: RichTextLabel = %DialogueText
@onready var choices_container: VBoxContainer = %ChoicesContainer
@onready var continue_button: Button = %ContinueButton
@onready var input_field: LineEdit = %InputField
@onready var send_button: Button = %SendButton
@onready var status_label: Label = %StatusLabel
@onready var start_button: Button = %StartButton
@onready var debug_label: Label = %DebugLabel

var dialogue_manager: DialogueManager

# Debug tracking
var last_player_input: String = ""
var pending_choices: Array[Dictionary] = []

# Resources
var merchant_character: CharacterIdentity
var fantasy_world: WorldContext
var merchant_dialogue: DialogueGraph


func _ready() -> void:
	_setup_dialogue_system()
	_connect_signals()
	_load_resources()
	_update_ui_state()
	_check_ai_service()


func _setup_dialogue_system() -> void:
	# Create DialogueManager - it will use AIService automatically
	dialogue_manager = DialogueManager.new()
	add_child(dialogue_manager)


func _check_ai_service() -> void:
	var ai_service := AIService.get_singleton()
	if not ai_service:
		status_label.text = "AIService not available"
		return

	if ai_service.is_model_loaded():
		status_label.text = "Model loaded - Ready to start"
	else:
		status_label.text = "No model loaded - Load one via Model Manager for AI responses"


func _load_resources() -> void:
	merchant_character = load("res://examples/resources/merchant_character.tres")
	fantasy_world = load("res://examples/resources/fantasy_world.tres")
	merchant_dialogue = load("res://examples/resources/merchant_dialogue.tres")

	if merchant_character:
		dialogue_manager.default_character = merchant_character
	if fantasy_world:
		dialogue_manager.world_context = fantasy_world
	# Note: ai_preset is now set on DialogueGraph, not DialogueManager


func _connect_signals() -> void:
	# UI signals
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	send_button.pressed.connect(_on_send_pressed)
	input_field.text_submitted.connect(_on_input_submitted)

	# DialogueManager signals
	dialogue_manager.dialogue_started.connect(_on_dialogue_started)
	dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)
	dialogue_manager.npc_speaking.connect(_on_npc_speaking)
	dialogue_manager.npc_response_completed.connect(_on_npc_response_completed)
	dialogue_manager.player_choices_available.connect(_on_choices_available)
	dialogue_manager.waiting_for_player_input.connect(_on_waiting_for_input)
	dialogue_manager.event_triggered.connect(_on_event_triggered)
	dialogue_manager.variable_changed.connect(_on_variable_changed)
	dialogue_manager.error_occurred.connect(_on_error)


func _update_ui_state() -> void:
	var is_active := dialogue_manager.is_active() if dialogue_manager else false

	dialogue_panel.visible = is_active
	start_button.visible = not is_active
	status_label.text = "Dialogue active" if is_active else "Press Start to begin"


func _clear_choices() -> void:
	for child in choices_container.get_children():
		child.queue_free()


func _show_continue() -> void:
	continue_button.visible = true
	choices_container.visible = false
	input_field.visible = false
	send_button.visible = false


func _show_choices(choices: Array[Dictionary]) -> void:
	_clear_choices()
	continue_button.visible = false
	choices_container.visible = true
	input_field.visible = false
	send_button.visible = false

	# Store choices for debug tracking
	pending_choices = choices

	for i in choices.size():
		var choice: Dictionary = choices[i]
		var button := Button.new()
		button.text = "%d. %s" % [i + 1, choice.get("text", "Choice")]
		# Use the original index from the choice data, not the filtered list index
		var original_index: int = choice.get("index", i)
		button.pressed.connect(_on_choice_selected.bind(original_index))
		choices_container.add_child(button)


func _show_input() -> void:
	continue_button.visible = false
	choices_container.visible = false
	input_field.visible = true
	send_button.visible = true
	input_field.grab_focus()


func _update_debug() -> void:
	if dialogue_manager:
		var info := dialogue_manager.get_debug_info()
		var lines: Array[String] = []

		lines.append("Mode: %s" % info.get("mode", "?"))
		lines.append("Model: %s" % info.get("model", "none"))
		lines.append("")
		lines.append("Character: %s" % info.get("character", "none"))
		if not info.get("character_personality", "").is_empty():
			lines.append("  %s" % info.get("character_personality", "").substr(0, 40))
		lines.append("")
		lines.append("World: %s" % info.get("world", "none"))
		if not info.get("world_location", "").is_empty():
			lines.append("  @ %s" % info.get("world_location", ""))
		lines.append("")
		lines.append("Last Input: %s" % (last_player_input if not last_player_input.is_empty() else "(none)"))
		lines.append("")
		lines.append("History: %s" % info.get("history", "?"))

		debug_label.text = "\n".join(lines)


# ==================== UI Signal Handlers ====================


func _on_start_pressed() -> void:
	if merchant_dialogue:
		dialogue_manager.start_dialogue(merchant_dialogue, DialogueManager.DialogueMode.SCRIPTED)
	else:
		push_error("No dialogue graph loaded!")


func _on_continue_pressed() -> void:
	# For static responses, just continue
	dialogue_manager.select_choice(0)


func _on_send_pressed() -> void:
	var text := input_field.text.strip_edges()
	if not text.is_empty():
		last_player_input = text  # Track for debug
		dialogue_manager.send_player_message(text)
		input_field.text = ""
		_update_debug()


func _on_input_submitted(text: String) -> void:
	_on_send_pressed()


func _on_choice_selected(index: int) -> void:
	# Store selected choice text for debug display
	for choice in pending_choices:
		if choice.get("index", -1) == index:
			last_player_input = choice.get("text", "")
			break
	pending_choices.clear()

	dialogue_manager.select_choice(index)
	_clear_choices()
	_update_debug()


# ==================== DialogueManager Signal Handlers ====================


func _on_dialogue_started(_graph: DialogueGraph) -> void:
	print("[DialogueTest] Dialogue started!")
	last_player_input = ""
	pending_choices.clear()
	_update_ui_state()
	_update_debug()


func _on_dialogue_ended(reason: String) -> void:
	print("[DialogueTest] Dialogue ended: %s" % reason)
	speaker_label.text = ""
	dialogue_text.text = "[i]Dialogue ended.[/i]"
	_show_continue()
	continue_button.visible = false
	await get_tree().create_timer(2.0).timeout
	_update_ui_state()


func _on_npc_speaking(speaker: String, text: String, is_streaming: bool) -> void:
	speaker_label.text = speaker
	if not is_streaming:
		dialogue_text.text = text
		_show_continue()  # Static response - show continue button
	else:
		dialogue_text.text = "[i]Generating response...[/i]"
		# For AI streaming, continue button will show after response completes
		continue_button.visible = false
	_update_debug()


func _on_npc_response_completed(full_text: String) -> void:
	dialogue_text.text = full_text
	# Show continue button after AI response completes
	_show_continue()
	_update_debug()


func _on_choices_available(choices: Array[Dictionary]) -> void:
	_show_choices(choices)
	_update_debug()


func _on_waiting_for_input() -> void:
	_show_input()
	_update_debug()


func _on_event_triggered(event_name: String, data: Dictionary) -> void:
	print("[DialogueTest] Event: %s - %s" % [event_name, data])
	status_label.text = "Event: %s" % event_name


func _on_variable_changed(var_name: String, old_value: Variant, new_value: Variant) -> void:
	print("[DialogueTest] Variable changed: %s = %s (was %s)" % [var_name, new_value, old_value])


func _on_error(message: String) -> void:
	push_error("[DialogueTest] Error: %s" % message)
	status_label.text = "ERROR: %s" % message
