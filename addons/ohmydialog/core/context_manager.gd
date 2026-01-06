@tool
class_name ContextManager
extends RefCounted
## Manages dynamic context for dialogue execution.
##
## Handles variables, condition evaluation, and event triggering.
## Provides a unified interface for accessing game state from dialogues.


## Emitted when a variable changes.
signal variable_changed(name: String, old_value: Variant, new_value: Variant)

## Emitted when an event is triggered.
signal event_triggered(event_name: String, data: Dictionary)


## Global variables (persist across dialogues and sessions).
var global_variables: Dictionary = {}

## Session variables (persist during game session, reset on restart).
var session_variables: Dictionary = {}

## Local variables (scoped to current dialogue).
var local_variables: Dictionary = {}

## External variable providers (for game integration).
var _external_providers: Array[Callable] = []

## Expression parser cache.
var _expression_cache: Dictionary = {}


## Sets a variable in the specified scope.
func set_variable(name: String, value: Variant, scope: String = "local") -> void:
	var old_value: Variant = get_variable(name)

	match scope:
		"global":
			global_variables[name] = value
		"session":
			session_variables[name] = value
		_:
			local_variables[name] = value

	if old_value != value:
		variable_changed.emit(name, old_value, value)


## Sets a local variable (shorthand).
func set_var(name: String, value: Variant) -> void:
	set_variable(name, value, "local")


## Gets a variable, checking all scopes (local -> session -> global -> external).
func get_variable(name: String, default: Variant = null) -> Variant:
	# Check local first
	if local_variables.has(name):
		return local_variables[name]

	# Then session
	if session_variables.has(name):
		return session_variables[name]

	# Then global
	if global_variables.has(name):
		return global_variables[name]

	# Finally check external providers
	for provider in _external_providers:
		var result: Variant = provider.call(name)
		if result != null:
			return result

	return default


## Gets a variable (shorthand).
func get_var(name: String, default: Variant = null) -> Variant:
	return get_variable(name, default)


## Checks if a variable exists in any scope.
func has_variable(name: String) -> bool:
	return local_variables.has(name) or \
		   session_variables.has(name) or \
		   global_variables.has(name)


## Removes a variable from the specified scope.
func remove_variable(name: String, scope: String = "local") -> void:
	match scope:
		"global":
			global_variables.erase(name)
		"session":
			session_variables.erase(name)
		_:
			local_variables.erase(name)


## Clears all local variables (called when dialogue ends).
func clear_local() -> void:
	local_variables.clear()


## Clears session variables (called on game restart).
func clear_session() -> void:
	session_variables.clear()


## Registers an external variable provider.
## The callable should take (name: String) and return Variant or null.
func register_provider(provider: Callable) -> void:
	if provider not in _external_providers:
		_external_providers.append(provider)


## Unregisters an external variable provider.
func unregister_provider(provider: Callable) -> void:
	_external_providers.erase(provider)


# ==================== Condition Evaluation ====================


## Evaluates a condition expression and returns the result.
## Supports: comparisons (==, !=, <, >, <=, >=), boolean operators (and, or, not)
func evaluate_condition(expression: String) -> bool:
	expression = expression.strip_edges()

	if expression.is_empty():
		return true

	# Check cache first
	# Note: Cache is cleared when variables change for affected expressions
	# For simplicity, we evaluate each time (cache could be added later)

	# Handle boolean operators
	if " and " in expression.to_lower():
		var parts := expression.split(" and ", false, 1)
		return evaluate_condition(parts[0]) and evaluate_condition(parts[1])

	if " or " in expression.to_lower():
		var parts := expression.split(" or ", false, 1)
		return evaluate_condition(parts[0]) or evaluate_condition(parts[1])

	if expression.to_lower().begins_with("not "):
		return not evaluate_condition(expression.substr(4))

	# Handle parentheses (simple case)
	if expression.begins_with("(") and expression.ends_with(")"):
		return evaluate_condition(expression.substr(1, expression.length() - 2))

	# Parse comparison expression
	return _evaluate_comparison(expression)


## Evaluates a simple comparison expression.
func _evaluate_comparison(expression: String) -> bool:
	# Try each operator
	for op in [">=", "<=", "!=", "==", ">", "<", " is ", " not "]:
		var idx := expression.find(op)
		if idx > 0:
			var left := expression.substr(0, idx).strip_edges()
			var right := expression.substr(idx + op.length()).strip_edges()
			var op_clean := op.strip_edges()

			var left_val := _resolve_value(left)
			var right_val := _resolve_value(right)

			match op_clean:
				"==", "is":
					return left_val == right_val
				"!=", "not":
					return left_val != right_val
				">":
					return left_val > right_val
				"<":
					return left_val < right_val
				">=":
					return left_val >= right_val
				"<=":
					return left_val <= right_val

	# No operator found - treat as boolean variable check
	var value := _resolve_value(expression)
	return bool(value)


## Resolves a value (variable name or literal).
func _resolve_value(value_str: String) -> Variant:
	value_str = value_str.strip_edges()

	# Boolean literals
	if value_str == "true":
		return true
	if value_str == "false":
		return false
	if value_str == "null":
		return null

	# Numeric literals
	if value_str.is_valid_int():
		return value_str.to_int()
	if value_str.is_valid_float():
		return value_str.to_float()

	# String literals (quoted)
	if (value_str.begins_with("\"") and value_str.ends_with("\"")) or \
	   (value_str.begins_with("'") and value_str.ends_with("'")):
		return value_str.substr(1, value_str.length() - 2)

	# Variable reference
	return get_variable(value_str)


# ==================== Events ====================


## Triggers a named event with optional data.
func trigger_event(event_name: String, data: Dictionary = {}) -> void:
	event_triggered.emit(event_name, data)


## Triggers an event and waits for handlers (async-friendly).
func trigger_event_async(event_name: String, data: Dictionary = {}) -> void:
	# For now, just trigger - async handling can be added later
	trigger_event(event_name, data)


# ==================== Serialization ====================


## Serializes persistent data (global and session variables).
func to_dict() -> Dictionary:
	return {
		"global_variables": global_variables.duplicate(true),
		"session_variables": session_variables.duplicate(true)
	}


## Restores persistent data.
func from_dict(data: Dictionary) -> void:
	global_variables = data.get("global_variables", {}).duplicate(true)
	session_variables = data.get("session_variables", {}).duplicate(true)


## Returns all variables merged (for debugging).
func get_all_variables() -> Dictionary:
	var result := global_variables.duplicate()
	result.merge(session_variables)
	result.merge(local_variables)
	return result


## Returns a summary for debugging.
func get_summary() -> String:
	return "Global: %d, Session: %d, Local: %d vars" % [
		global_variables.size(),
		session_variables.size(),
		local_variables.size()
	]


# ==================== Utility ====================


## Increments a numeric variable.
func increment(name: String, amount: int = 1) -> void:
	var current := get_variable(name, 0)
	if current is int or current is float:
		set_var(name, current + amount)


## Decrements a numeric variable.
func decrement(name: String, amount: int = 1) -> void:
	increment(name, -amount)


## Toggles a boolean variable.
func toggle(name: String) -> void:
	var current := get_variable(name, false)
	set_var(name, not bool(current))


## Appends to an array variable.
func append_to(name: String, value: Variant) -> void:
	var current := get_variable(name, [])
	if current is Array:
		var arr: Array = current.duplicate()
		arr.append(value)
		set_var(name, arr)


## Removes from an array variable.
func remove_from(name: String, value: Variant) -> void:
	var current := get_variable(name, [])
	if current is Array:
		var arr: Array = current.duplicate()
		arr.erase(value)
		set_var(name, arr)
