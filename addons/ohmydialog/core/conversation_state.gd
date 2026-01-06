@tool
class_name ConversationState
extends RefCounted
## Manages the state of free-form AI conversations.
##
## Tracks conversation history, return conditions, and limits for
## hybrid graph/free dialogue systems.


## Emitted when a return condition is met.
signal return_condition_met(condition_name: String)

## Emitted when max exchanges reached.
signal max_exchanges_reached

## Emitted when timeout occurs.
signal timeout_reached


## Conversation history as array of {role: String, content: String}.
var messages: Array[Dictionary] = []

## Conditions that trigger return to graph execution.
## Each condition is {name: String, type: String, value: Variant}
## Types: "keyword", "sentiment", "turn_count", "custom"
var return_conditions: Array[Dictionary] = []

## Maximum number of exchanges before forcing return (0 = unlimited).
var max_exchanges: int = 0

## Timeout in seconds before forcing return (0.0 = no timeout).
var timeout_seconds: float = 0.0

## Node ID to return to when exiting free mode.
var on_return_node_id: String = ""

## Timestamp when conversation started (for timeout calculation).
var _start_time: float = 0.0

## Whether the conversation is currently active.
var _is_active: bool = false


## Starts a new free conversation session.
func start_conversation(return_node_id: String = "") -> void:
	messages.clear()
	on_return_node_id = return_node_id
	_start_time = Time.get_unix_time_from_system()
	_is_active = true


## Ends the current conversation session.
func end_conversation() -> void:
	_is_active = false


## Returns whether the conversation is currently active.
func is_active() -> bool:
	return _is_active


## Adds a player message to the history.
func add_player_message(content: String) -> void:
	messages.append({
		"role": "player",
		"content": content
	})


## Adds an NPC/AI message to the history.
func add_npc_message(content: String) -> void:
	messages.append({
		"role": "assistant",
		"content": content
	})


## Adds a system message to the history.
func add_system_message(content: String) -> void:
	messages.append({
		"role": "system",
		"content": content
	})


## Gets the number of exchanges (player-npc pairs).
func get_exchange_count() -> int:
	var player_count := 0
	for msg in messages:
		if msg.role == "player":
			player_count += 1
	return player_count


## Gets elapsed time since conversation started.
func get_elapsed_time() -> float:
	if not _is_active:
		return 0.0
	return Time.get_unix_time_from_system() - _start_time


## Checks if conversation should return to graph execution.
## Returns the condition name if met, empty string otherwise.
func should_return_to_graph(latest_message: String = "") -> String:
	if not _is_active:
		return ""

	# Check max exchanges
	if max_exchanges > 0 and get_exchange_count() >= max_exchanges:
		max_exchanges_reached.emit()
		return "max_exchanges"

	# Check timeout
	if timeout_seconds > 0.0 and get_elapsed_time() >= timeout_seconds:
		timeout_reached.emit()
		return "timeout"

	# Check custom conditions
	for condition in return_conditions:
		if _evaluate_condition(condition, latest_message):
			return_condition_met.emit(condition.get("name", "unnamed"))
			return condition.get("name", "condition_met")

	return ""


## Evaluates a single return condition.
func _evaluate_condition(condition: Dictionary, latest_message: String) -> bool:
	var condition_type: String = condition.get("type", "")
	var value: Variant = condition.get("value", null)

	match condition_type:
		"keyword":
			# Check if keyword appears in latest message
			if value is String:
				return latest_message.to_lower().contains(value.to_lower())
			elif value is Array:
				for keyword in value:
					if latest_message.to_lower().contains(keyword.to_lower()):
						return true

		"turn_count":
			# Check if turn count threshold reached
			if value is int:
				return get_exchange_count() >= value

		"exact_phrase":
			# Check for exact phrase match (case insensitive)
			if value is String:
				return latest_message.to_lower() == value.to_lower()

		"custom":
			# Custom conditions should be handled externally
			# This allows game-specific logic
			pass

	return false


## Adds a keyword-based return condition.
func add_keyword_condition(name: String, keywords: Variant) -> void:
	return_conditions.append({
		"name": name,
		"type": "keyword",
		"value": keywords
	})


## Adds a turn count return condition.
func add_turn_count_condition(name: String, turns: int) -> void:
	return_conditions.append({
		"name": name,
		"type": "turn_count",
		"value": turns
	})


## Adds an exact phrase return condition.
func add_exact_phrase_condition(name: String, phrase: String) -> void:
	return_conditions.append({
		"name": name,
		"type": "exact_phrase",
		"value": phrase
	})


## Clears all return conditions.
func clear_conditions() -> void:
	return_conditions.clear()


## Sets the maximum exchanges limit.
func set_max_exchanges(limit: int) -> void:
	max_exchanges = limit


## Sets the timeout in seconds.
func set_timeout(seconds: float) -> void:
	timeout_seconds = seconds


## Gets the last N messages from history.
func get_recent_messages(count: int) -> Array[Dictionary]:
	if count <= 0 or messages.is_empty():
		return []

	var start_idx := maxi(0, messages.size() - count)
	var result: Array[Dictionary] = []
	for i in range(start_idx, messages.size()):
		result.append(messages[i])
	return result


## Gets all messages for a specific role.
func get_messages_by_role(role: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for msg in messages:
		if msg.role == role:
			result.append(msg)
	return result


## Clears conversation history but keeps settings.
func clear_messages() -> void:
	messages.clear()


## Returns full state as dictionary (for serialization).
func to_dict() -> Dictionary:
	return {
		"messages": messages.duplicate(true),
		"return_conditions": return_conditions.duplicate(true),
		"max_exchanges": max_exchanges,
		"timeout_seconds": timeout_seconds,
		"on_return_node_id": on_return_node_id,
		"is_active": _is_active,
		"start_time": _start_time
	}


## Restores state from dictionary.
func from_dict(data: Dictionary) -> void:
	messages.clear()
	for msg in data.get("messages", []):
		messages.append(msg)

	return_conditions.clear()
	for cond in data.get("return_conditions", []):
		return_conditions.append(cond)

	max_exchanges = data.get("max_exchanges", 0)
	timeout_seconds = data.get("timeout_seconds", 0.0)
	on_return_node_id = data.get("on_return_node_id", "")
	_is_active = data.get("is_active", false)
	_start_time = data.get("start_time", 0.0)
