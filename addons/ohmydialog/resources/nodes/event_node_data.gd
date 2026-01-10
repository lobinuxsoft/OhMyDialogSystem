@tool
class_name EventNodeData
extends DialogueNodeData
## Node that emits a signal/event to the game.


## Name of the event to emit.
@export var event_name: String = "":
	set(value):
		event_name = value
		emit_changed()

## Optional data to pass with the event.
@export var event_data: Dictionary = {}:
	set(value):
		event_data = value
		emit_changed()


func _get_node_type() -> DialogueNodeData.NodeType:
	return DialogueNodeData.NodeType.EVENT


func _calculate_output_count() -> int:
	return 1


func validate() -> Array[String]:
	var errors := super.validate()
	if event_name.is_empty():
		errors.append("EVENT requires an event_name")
	return errors


func to_dict() -> Dictionary:
	var dict := super.to_dict()
	dict["event_name"] = event_name
	dict["event_data"] = event_data.duplicate(true)
	return dict


func _load_from_dict(dict: Dictionary) -> void:
	event_name = dict.get("event_name", "")
	event_data = dict.get("event_data", {})
	if event_data is Dictionary:
		event_data = event_data.duplicate(true)
	else:
		event_data = {}
	super._load_from_dict(dict)


func _migrate_from_data_dict(data: Dictionary) -> void:
	event_name = data.get("event_name", "")
	event_data = data.get("event_data", {})
	if event_data is Dictionary:
		event_data = event_data.duplicate(true)
	else:
		event_data = {}
