@tool
class_name ConversationHistory
extends RefCounted
## Manages conversation history with token-aware truncation.
##
## Stores messages in a structured format compatible with LLM APIs
## and PromptBuilder. Supports automatic truncation to fit context limits.


## Message roles.
enum Role {
	SYSTEM,     ## System instructions
	USER,       ## Player/user messages
	ASSISTANT,  ## NPC/AI responses
	FUNCTION    ## Function call results (future)
}


## A single message in the conversation.
class Message extends RefCounted:
	var role: Role
	var content: String
	var timestamp: float
	var metadata: Dictionary

	func _init(p_role: Role, p_content: String) -> void:
		role = p_role
		content = p_content
		timestamp = Time.get_unix_time_from_system()
		metadata = {}

	## Returns the role as a string.
	func get_role_string() -> String:
		match role:
			Role.SYSTEM:
				return "system"
			Role.USER:
				return "user"
			Role.ASSISTANT:
				return "assistant"
			Role.FUNCTION:
				return "function"
		return "unknown"

	## Converts to dictionary format.
	func to_dict() -> Dictionary:
		return {
			"role": get_role_string(),
			"content": content,
			"timestamp": timestamp,
			"metadata": metadata.duplicate()
		}


## All messages in chronological order.
var messages: Array[Message] = []

## Approximate characters per token for estimation.
const CHARS_PER_TOKEN := 4.0

## Maximum history tokens (0 = unlimited).
var max_tokens: int = 0


## Adds a system message.
func add_system(content: String, meta: Dictionary = {}) -> Message:
	return _add_message(Role.SYSTEM, content, meta)


## Adds a user/player message.
func add_user(content: String, meta: Dictionary = {}) -> Message:
	return _add_message(Role.USER, content, meta)


## Adds an assistant/NPC message.
func add_assistant(content: String, meta: Dictionary = {}) -> Message:
	return _add_message(Role.ASSISTANT, content, meta)


## Adds a message with the specified role.
func _add_message(role: Role, content: String, meta: Dictionary) -> Message:
	var msg := Message.new(role, content)
	msg.metadata = meta.duplicate()
	messages.append(msg)

	# Auto-truncate if limit set
	if max_tokens > 0:
		_truncate_to_tokens(max_tokens)

	return msg


## Returns the full history as an array of dictionaries.
## Format: [{role: String, content: String}, ...]
func get_history() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for msg in messages:
		result.append({
			"role": msg.get_role_string(),
			"content": msg.content
		})
	return result


## Returns history truncated to fit within token limit.
## Preserves the most recent messages.
func get_history_for_context(token_limit: int) -> Array[Dictionary]:
	if token_limit <= 0:
		return get_history()

	var result: Array[Dictionary] = []
	var total_tokens := 0

	# Work backwards from most recent
	for i in range(messages.size() - 1, -1, -1):
		var msg: Message = messages[i]
		var msg_tokens := _estimate_tokens(msg.content)

		if total_tokens + msg_tokens > token_limit:
			break

		result.insert(0, {
			"role": msg.get_role_string(),
			"content": msg.content
		})
		total_tokens += msg_tokens

	return result


## Formats history for prompt building.
## Returns a formatted string suitable for inclusion in prompts.
func to_prompt_format(character_name: String = "Assistant") -> String:
	if messages.is_empty():
		return "(New conversation)"

	var lines: Array[String] = []
	for msg in messages:
		match msg.role:
			Role.USER:
				lines.append("Player: %s" % msg.content)
			Role.ASSISTANT:
				lines.append("%s: %s" % [character_name, msg.content])
			Role.SYSTEM:
				lines.append("[System: %s]" % msg.content)

	return "\n".join(lines)


## Returns the number of messages.
func size() -> int:
	return messages.size()


## Returns true if history is empty.
func is_empty() -> bool:
	return messages.is_empty()


## Clears all messages.
func clear() -> void:
	messages.clear()


## Gets the last N messages.
func get_last(count: int) -> Array[Message]:
	if count <= 0 or messages.is_empty():
		return []

	var start_idx := maxi(0, messages.size() - count)
	var result: Array[Message] = []
	for i in range(start_idx, messages.size()):
		result.append(messages[i])
	return result


## Gets all messages with a specific role.
func get_by_role(role: Role) -> Array[Message]:
	var result: Array[Message] = []
	for msg in messages:
		if msg.role == role:
			result.append(msg)
	return result


## Returns the last message, or null if empty.
func get_last_message() -> Message:
	if messages.is_empty():
		return null
	return messages[messages.size() - 1]


## Estimates total tokens in the history.
func estimate_total_tokens() -> int:
	var total := 0
	for msg in messages:
		total += _estimate_tokens(msg.content)
	return total


## Estimates tokens for a string.
func _estimate_tokens(text: String) -> int:
	if text.is_empty():
		return 0
	return ceili(text.length() / CHARS_PER_TOKEN)


## Truncates history to fit within token limit.
## Removes oldest messages first, keeping the most recent.
func _truncate_to_tokens(limit: int) -> void:
	while estimate_total_tokens() > limit and messages.size() > 1:
		# Remove oldest non-system message
		for i in messages.size():
			if messages[i].role != Role.SYSTEM:
				messages.remove_at(i)
				break


## Sets the maximum token limit for auto-truncation.
func set_max_tokens(limit: int) -> void:
	max_tokens = limit
	if max_tokens > 0:
		_truncate_to_tokens(max_tokens)


## Serializes to dictionary.
func to_dict() -> Dictionary:
	var msgs: Array[Dictionary] = []
	for msg in messages:
		msgs.append(msg.to_dict())

	return {
		"messages": msgs,
		"max_tokens": max_tokens
	}


## Restores from dictionary.
func from_dict(data: Dictionary) -> void:
	messages.clear()
	max_tokens = data.get("max_tokens", 0)

	var msgs: Array = data.get("messages", [])
	for msg_data in msgs:
		var role_str: String = msg_data.get("role", "user")
		var role: Role = Role.USER
		match role_str:
			"system":
				role = Role.SYSTEM
			"user":
				role = Role.USER
			"assistant":
				role = Role.ASSISTANT
			"function":
				role = Role.FUNCTION

		var msg := Message.new(role, msg_data.get("content", ""))
		msg.timestamp = msg_data.get("timestamp", 0.0)
		msg.metadata = msg_data.get("metadata", {}).duplicate()
		messages.append(msg)


## Creates a copy of this history.
func duplicate() -> ConversationHistory:
	var copy := ConversationHistory.new()
	copy.from_dict(to_dict())
	return copy


## Returns a summary string for debugging.
func get_summary() -> String:
	var user_count := get_by_role(Role.USER).size()
	var assistant_count := get_by_role(Role.ASSISTANT).size()
	var tokens := estimate_total_tokens()
	return "%d messages (%d user, %d assistant), ~%d tokens" % [
		messages.size(), user_count, assistant_count, tokens
	]
