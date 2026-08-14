@tool
class_name AIResponseNodeData
extends DialogueNodeData
## Node that generates dynamic responses via LLM.


## Template with {variables} for the prompt.
@export_multiline var prompt_template: String = "":
	set(value):
		prompt_template = value
		emit_changed()

## Suggested emotion for the response (happy, sad, angry, etc.).
@export var emotion_hint: String = "":
	set(value):
		emotion_hint = value
		emit_changed()

## Maximum response length in tokens.
@export_range(1, 4096) var max_tokens: int = 256:
	set(value):
		max_tokens = value
		emit_changed()


## Text sent to the model before it writes a single token.
## Single source of truth so every panel that counts tokens counts the same thing.
func to_prompt_text(graph: DialogueGraph) -> String:
	var parts := PackedStringArray()

	if graph:
		if graph.default_character:
			parts.append(graph.default_character.to_system_prompt())
		if graph.world_context:
			parts.append(graph.world_context.to_context_prompt())

	if not prompt_template.is_empty():
		parts.append(prompt_template)

	return "\n".join(parts)


func _get_node_type() -> DialogueNodeData.NodeType:
	return DialogueNodeData.NodeType.AI_RESPONSE


func _calculate_output_count() -> int:
	return 1


func to_dict() -> Dictionary:
	var dict := super.to_dict()
	dict["prompt_template"] = prompt_template
	dict["emotion_hint"] = emotion_hint
	dict["max_tokens"] = max_tokens
	return dict


func _load_from_dict(dict: Dictionary) -> void:
	prompt_template = dict.get("prompt_template", "")
	emotion_hint = dict.get("emotion_hint", "")
	max_tokens = dict.get("max_tokens", 256)
	super._load_from_dict(dict)


func _migrate_from_data_dict(data: Dictionary) -> void:
	prompt_template = data.get("prompt_template", "")
	emotion_hint = data.get("emotion_hint", "")
	max_tokens = data.get("max_tokens", 256)
