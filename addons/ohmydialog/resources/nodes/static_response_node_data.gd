@tool
class_name StaticResponseNodeData
extends DialogueNodeData
## Node that displays pre-written dialogue text.


## Character name to display as speaker.
@export var speaker: String = "":
	set(value):
		speaker = value
		emit_changed()

## The dialogue text to display.
@export_multiline var text: String = "":
	set(value):
		text = value
		emit_changed()

## Emotion tag for animations/portraits.
@export var emotion: String = "":
	set(value):
		emotion = value
		emit_changed()


func _get_node_type() -> DialogueNodeData.NodeType:
	return DialogueNodeData.NodeType.STATIC_RESPONSE


func _calculate_output_count() -> int:
	return 1


func validate() -> Array[String]:
	var errors := super.validate()
	if text.is_empty():
		errors.append("STATIC_RESPONSE requires text content")
	return errors


func to_dict() -> Dictionary:
	var dict := super.to_dict()
	dict["speaker"] = speaker
	dict["text"] = text
	dict["emotion"] = emotion
	return dict


func _load_from_dict(dict: Dictionary) -> void:
	speaker = dict.get("speaker", "")
	text = dict.get("text", "")
	emotion = dict.get("emotion", "")
	super._load_from_dict(dict)


func _migrate_from_data_dict(data: Dictionary) -> void:
	speaker = data.get("speaker", "")
	text = data.get("text", "")
	emotion = data.get("emotion", "")
