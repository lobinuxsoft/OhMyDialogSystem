class_name MockLlamaInterface
extends RefCounted
## Mock LlamaInterface for testing the dialogue system without actual LLM.
##
## Generates predefined or random responses based on context.


signal token_generated(token: String)
signal generation_completed(full_text: String)


## Predefined responses by character name.
var character_responses: Dictionary = {
	"Merchant": [
		"Ah, a customer! Take a look at my wares.",
		"These prices are the best you'll find in town!",
		"I have rare items from distant lands.",
		"Interested in a trade perhaps?",
	],
	"Guard": [
		"Move along, citizen.",
		"The city is safe under our watch.",
		"Have you seen anything suspicious?",
		"No trouble here, I hope.",
	],
	"Innkeeper": [
		"Welcome to my humble inn!",
		"A room for the night? Or perhaps some ale?",
		"You look like you've traveled far.",
		"Rest well, traveler.",
	],
}

## Default responses when character not found.
var default_responses: Array[String] = [
	"Interesting... tell me more.",
	"I see what you mean.",
	"That's quite a thought.",
	"Hmm, let me think about that.",
	"Indeed, you make a good point.",
]

## Simulated delay range in seconds.
var min_delay: float = 0.3
var max_delay: float = 1.0

## Whether to simulate streaming.
var simulate_streaming: bool = true

## Internal state.
var _current_character: String = ""


## Sets temperature (ignored in mock, just for API compatibility).
func set_temperature(_value: float) -> void:
	pass

func set_top_p(_value: float) -> void:
	pass

func set_top_k(_value: int) -> void:
	pass

func set_max_tokens(_value: int) -> void:
	pass

func set_repeat_penalty(_value: float) -> void:
	pass


## Generates a response (blocking).
func generate(prompt: String) -> String:
	_extract_character_from_prompt(prompt)
	return _get_response()


## Generates a response with streaming simulation.
func generate_stream(prompt: String) -> void:
	_extract_character_from_prompt(prompt)
	var response := _get_response()

	if simulate_streaming:
		# Simulate token-by-token generation
		_stream_response(response)
	else:
		generation_completed.emit(response)


## Extracts character name from prompt for context-aware responses.
func _extract_character_from_prompt(prompt: String) -> void:
	# Look for "You are roleplaying as X" pattern
	var regex := RegEx.new()
	regex.compile("roleplaying as (\\w+)")
	var result := regex.search(prompt)
	if result:
		_current_character = result.get_string(1)
	else:
		_current_character = ""


## Gets a response based on current character.
func _get_response() -> String:
	var responses: Array
	if character_responses.has(_current_character):
		responses = character_responses[_current_character]
	else:
		responses = default_responses

	return responses[randi() % responses.size()]


## Simulates streaming by emitting tokens.
func _stream_response(response: String) -> void:
	# Split into words for more natural streaming
	var words := response.split(" ")

	for i in words.size():
		var word := words[i]
		if i < words.size() - 1:
			word += " "

		# Random delay between tokens
		await Engine.get_main_loop().create_timer(randf_range(0.02, 0.08)).timeout
		token_generated.emit(word)

	generation_completed.emit(response)


## Adds custom responses for a character.
func add_character_responses(character_name: String, responses: Array[String]) -> void:
	character_responses[character_name] = responses
