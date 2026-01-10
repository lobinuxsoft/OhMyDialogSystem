@tool
class_name PlayerChoiceNodeData
extends DialogueNodeData
## Node that presents choices to the player.


## Array of choice texts. Each choice creates one output port.
@export var choices: PackedStringArray = []:
	set(value):
		choices = value
		emit_changed()


func _get_node_type() -> DialogueNodeData.NodeType:
	return DialogueNodeData.NodeType.PLAYER_CHOICE


func _calculate_output_count() -> int:
	return maxi(1, choices.size())


func validate() -> Array[String]:
	var errors := super.validate()
	if choices.is_empty():
		errors.append("PLAYER_CHOICE requires at least one choice")
	for i in choices.size():
		if choices[i].is_empty():
			errors.append("Choice %d has empty text" % (i + 1))
	return errors


func to_dict() -> Dictionary:
	var dict := super.to_dict()
	dict["choices"] = Array(choices)
	return dict


func _load_from_dict(dict: Dictionary) -> void:
	var raw_choices: Array = dict.get("choices", [])
	choices = PackedStringArray()
	for c in raw_choices:
		if c is String:
			choices.append(c)
		elif c is Dictionary:
			# Legacy format migration
			choices.append(c.get("text", ""))
	super._load_from_dict(dict)


func _migrate_from_data_dict(data: Dictionary) -> void:
	var raw_choices: Array = data.get("choices", [])
	choices = PackedStringArray()
	for c in raw_choices:
		if c is String:
			choices.append(c)
		elif c is Dictionary:
			choices.append(c.get("text", ""))


## Adds a new choice.
func add_choice(text: String) -> void:
	choices.append(text)
	refresh_output_count()
	emit_changed()


## Removes a choice at the given index.
func remove_choice(index: int) -> void:
	if index >= 0 and index < choices.size():
		choices.remove_at(index)
		refresh_output_count()
		emit_changed()


## Updates choice text at the given index.
func set_choice_text(index: int, text: String) -> void:
	if index >= 0 and index < choices.size():
		choices[index] = text
		emit_changed()
