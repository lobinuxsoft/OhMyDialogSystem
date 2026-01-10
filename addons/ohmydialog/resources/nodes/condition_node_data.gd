@tool
class_name ConditionNodeData
extends DialogueNodeData
## Node that branches based on condition evaluation.


## Variable name to check.
@export var variable: String = "":
	set(v):
		variable = v
		emit_changed()

## Comparison operator to use.
@export var operator: DialogueNodeData.ComparisonOperator = DialogueNodeData.ComparisonOperator.EQUAL:
	set(v):
		operator = v
		emit_changed()

## Value to compare against.
@export var value: Variant:
	set(v):
		value = v
		emit_changed()


func _get_node_type() -> DialogueNodeData.NodeType:
	return DialogueNodeData.NodeType.CONDITION


func _calculate_output_count() -> int:
	return 2  # TRUE and FALSE branches


func validate() -> Array[String]:
	var errors := super.validate()
	if variable.is_empty():
		errors.append("CONDITION requires a variable name")
	return errors


func to_dict() -> Dictionary:
	var dict := super.to_dict()
	dict["variable"] = variable
	dict["operator"] = operator
	dict["value"] = value
	return dict


func _load_from_dict(dict: Dictionary) -> void:
	variable = dict.get("variable", "")
	operator = dict.get("operator", DialogueNodeData.ComparisonOperator.EQUAL)
	value = dict.get("value", null)
	super._load_from_dict(dict)


func _migrate_from_data_dict(data: Dictionary) -> void:
	variable = data.get("variable", "")
	operator = data.get("operator", DialogueNodeData.ComparisonOperator.EQUAL)
	value = data.get("value", null)
