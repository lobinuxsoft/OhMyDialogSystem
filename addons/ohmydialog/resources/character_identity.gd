@tool
class_name CharacterIdentity
extends Resource
## Defines the identity and personality of an NPC/character.
##
## This resource contains all the information needed to give a character
## a consistent personality when generating dialogue with the LLM.
## The [method to_system_prompt] method converts this data into a system
## prompt that instructs the AI how to roleplay as this character.


## Speech style presets that affect how the character communicates.
enum SpeechStyle {
	CASUAL,      ## Relaxed, informal speech
	FORMAL,      ## Professional, polite speech
	MEDIEVAL,    ## Archaic, fantasy-style speech
	SCIENTIFIC,  ## Technical, precise language
	STREET,      ## Slang, colloquial expressions
	POETIC,      ## Flowery, metaphorical language
	MILITARY,    ## Direct, commanding tone
	CHILDISH,    ## Simple, playful language
	ELDERLY,     ## Wise, slow-paced speech
	ROBOTIC      ## Mechanical, literal speech
}


@export_group("Identity")

## Unique identifier for this character (used for references and saves).
@export var character_id: String = ""

## The character's display name shown in dialogues.
@export var character_name: String = ""

## Optional portrait/avatar texture for UI display.
@export var portrait: Texture2D = null


@export_group("Personality")

## Core personality traits and behavioral tendencies.
## Example: "Cheerful and optimistic, but hides deep insecurities."
@export_multiline var personality: String = ""

## Character's history, origin, and life experiences.
## Example: "A former knight who abandoned their oath after witnessing corruption."
@export_multiline var background: String = ""

## How the character speaks - affects vocabulary and sentence structure.
@export var speech_style: SpeechStyle = SpeechStyle.CASUAL

## Custom speech patterns or verbal tics.
## Example: "Often says 'by the stars' as an exclamation."
@export_multiline var speech_patterns: String = ""


@export_group("Knowledge & Secrets")

## Things this character knows about (topics they can discuss).
## Example: ["blacksmithing", "local politics", "ancient history"]
@export var knowledge: Array[String] = []

## Information the character hides or reveals only under certain conditions.
## Example: ["Is actually the missing prince", "Knows where the treasure is"]
@export var secrets: Array[String] = []


@export_group("Motivation")

## What the character wants to achieve.
## Example: ["Find their missing sister", "Become the best blacksmith"]
@export var goals: Array[String] = []

## What the character fears or avoids.
## Example: ["Being discovered as a fraud", "Deep water"]
@export var fears: Array[String] = []


@export_group("Relationships")

## Dictionary of character_id -> relationship description.
## Example: {"merchant_bob": "Old friend, trusts completely", "guard_captain": "Suspects of corruption"}
@export var relationships: Dictionary = {}


@export_group("Examples")

## Example dialogue lines that demonstrate the character's voice.
## These are included in the prompt to help the AI match the style.
@export var example_dialogues: Array[String] = []


## Generates a system prompt that instructs the LLM to roleplay as this character.
## This is the core method that converts character data into AI instructions.
func to_system_prompt() -> String:
	var prompt_parts: Array[String] = []

	# Character introduction
	prompt_parts.append("You are roleplaying as %s." % character_name if not character_name.is_empty() else "You are roleplaying as an NPC.")

	# Personality
	if not personality.is_empty():
		prompt_parts.append("Personality: %s" % personality)

	# Background
	if not background.is_empty():
		prompt_parts.append("Background: %s" % background)

	# Speech style
	prompt_parts.append("Speech style: %s" % _get_speech_style_description())

	# Speech patterns
	if not speech_patterns.is_empty():
		prompt_parts.append("Speech patterns: %s" % speech_patterns)

	# Knowledge
	if not knowledge.is_empty():
		prompt_parts.append("You have knowledge about: %s." % ", ".join(knowledge))

	# Goals
	if not goals.is_empty():
		prompt_parts.append("Your goals are: %s." % ", ".join(goals))

	# Fears
	if not fears.is_empty():
		prompt_parts.append("You fear: %s." % ", ".join(fears))

	# Relationships (only mention if there are any)
	if not relationships.is_empty():
		var rel_parts: Array[String] = []
		for char_id in relationships:
			rel_parts.append("%s (%s)" % [char_id, relationships[char_id]])
		prompt_parts.append("Key relationships: %s." % ", ".join(rel_parts))

	# Example dialogues
	if not example_dialogues.is_empty():
		prompt_parts.append("\nExample lines that show how you speak:")
		for example in example_dialogues:
			prompt_parts.append('- "%s"' % example)

	# Instructions
	prompt_parts.append("\nStay in character at all times. Respond naturally as this character would.")

	# Secrets reminder (not revealed in prompt, but noted for AI)
	if not secrets.is_empty():
		prompt_parts.append("You have secrets you don't reveal easily. Only hint at them if directly relevant.")

	return "\n".join(prompt_parts)


## Returns a human-readable description of the speech style.
func _get_speech_style_description() -> String:
	match speech_style:
		SpeechStyle.CASUAL:
			return "Casual and relaxed. Use contractions and informal language."
		SpeechStyle.FORMAL:
			return "Formal and polite. Use proper grammar and respectful address."
		SpeechStyle.MEDIEVAL:
			return "Archaic and fantasy-styled. Use 'thee', 'thou', 'hath', etc."
		SpeechStyle.SCIENTIFIC:
			return "Technical and precise. Use accurate terminology and logical structure."
		SpeechStyle.STREET:
			return "Street slang and colloquial. Use informal expressions and attitude."
		SpeechStyle.POETIC:
			return "Flowery and metaphorical. Use imagery and eloquent phrasing."
		SpeechStyle.MILITARY:
			return "Direct and commanding. Use short sentences and military jargon."
		SpeechStyle.CHILDISH:
			return "Simple and playful. Use basic words and enthusiastic tone."
		SpeechStyle.ELDERLY:
			return "Wise and measured. Use proverbs and speak with patience."
		SpeechStyle.ROBOTIC:
			return "Mechanical and literal. Avoid contractions and emotional language."
		_:
			return "Natural conversational tone."


## Serializes the character to a dictionary for JSON/storage.
func to_dict() -> Dictionary:
	return {
		"character_id": character_id,
		"character_name": character_name,
		"personality": personality,
		"background": background,
		"speech_style": speech_style,
		"speech_patterns": speech_patterns,
		"knowledge": knowledge.duplicate(),
		"secrets": secrets.duplicate(),
		"goals": goals.duplicate(),
		"fears": fears.duplicate(),
		"relationships": relationships.duplicate(),
		"example_dialogues": example_dialogues.duplicate()
	}


## Creates a CharacterIdentity from a dictionary.
static func from_dict(dict: Dictionary) -> CharacterIdentity:
	var character := CharacterIdentity.new()
	character.character_id = dict.get("character_id", "")
	character.character_name = dict.get("character_name", "")
	character.personality = dict.get("personality", "")
	character.background = dict.get("background", "")
	character.speech_style = dict.get("speech_style", SpeechStyle.CASUAL)
	character.speech_patterns = dict.get("speech_patterns", "")
	character.knowledge = Array(dict.get("knowledge", []), TYPE_STRING, "", null)
	character.secrets = Array(dict.get("secrets", []), TYPE_STRING, "", null)
	character.goals = Array(dict.get("goals", []), TYPE_STRING, "", null)
	character.fears = Array(dict.get("fears", []), TYPE_STRING, "", null)
	character.relationships = dict.get("relationships", {}).duplicate()
	character.example_dialogues = Array(dict.get("example_dialogues", []), TYPE_STRING, "", null)
	return character


## Returns true if this character has minimum required data.
func is_valid() -> bool:
	return not character_id.is_empty() and not character_name.is_empty()


## Returns a short summary of the character for debugging.
func get_summary() -> String:
	return "%s (%s) - %s" % [
		character_name if not character_name.is_empty() else "Unnamed",
		character_id if not character_id.is_empty() else "no-id",
		SpeechStyle.keys()[speech_style].to_lower()
	]
