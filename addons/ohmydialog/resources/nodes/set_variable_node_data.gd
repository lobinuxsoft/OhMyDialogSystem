@tool
class_name SetVariableNodeData
extends DialogueNodeData
## Node that modifies a dialogue variable.


## Scope determines variable persistence level.
enum VariableScope {
	LOCAL,    ## Only during this graph execution
	SESSION,  ## Persists during the game session
	GLOBAL    ## Persists between sessions (saved)
}


## Name of the variable to modify.
@export var variable: String = "":
	set(v):
		variable = v
		emit_changed()

## Operation to perform on the variable.
@export var operation: DialogueNodeData.VariableOperation = DialogueNodeData.VariableOperation.SET:
	set(v):
		operation = v
		emit_changed()

## Value to use in the operation.
@export var value: Variant:
	set(v):
		value = v
		emit_changed()

## Scope determines how long the variable persists.
@export var scope: VariableScope = VariableScope.LOCAL:
	set(v):
		scope = v
		emit_changed()


func _get_node_type() -> DialogueNodeData.NodeType:
	return DialogueNodeData.NodeType.SET_VARIABLE


func _calculate_output_count() -> int:
	return 1


func validate() -> Array[String]:
	var errors := super.validate()
	if variable.is_empty():
		errors.append("SET_VARIABLE requires a variable name")
	return errors


func to_dict() -> Dictionary:
	var dict := super.to_dict()
	dict["variable"] = variable
	dict["operation"] = operation
	dict["value"] = value
	dict["scope"] = scope
	return dict


func _load_from_dict(dict: Dictionary) -> void:
	variable = dict.get("variable", "")
	operation = dict.get("operation", DialogueNodeData.VariableOperation.SET)
	value = dict.get("value", null)
	scope = dict.get("scope", VariableScope.LOCAL)
	super._load_from_dict(dict)


func _migrate_from_data_dict(data: Dictionary) -> void:
	variable = data.get("variable", "")
	operation = data.get("operation", DialogueNodeData.VariableOperation.SET)
	value = data.get("value", null)
