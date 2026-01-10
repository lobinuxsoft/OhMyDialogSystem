@tool
@icon("res://addons/ohmydialog/icons/character_identity.svg")
class_name CharacterIdentity
extends Resource
## Defines the identity and personality of an NPC/character.
##
## This resource contains all the information needed to give a character
## a consistent personality when generating dialogue with the LLM.
## The [method to_system_prompt] method converts this data into a system
## prompt that instructs the AI how to roleplay as this character.
##
## Properties are hidden from Godot's native inspector and displayed
## via a custom inspector plugin instead.


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


# === PROPERTY STORAGE (no @export - hidden from native inspector) ===

## Unique identifier for this character (used for references and saves).
var character_id: String = ""

## The character's display name shown in dialogues.
var character_name: String = ""

## Optional portrait/avatar texture for UI display.
var portrait: Texture2D = null

## Core personality traits and behavioral tendencies.
var personality: String = ""

## Character's history, origin, and life experiences.
var background: String = ""

## How the character speaks - affects vocabulary and sentence structure.
var speech_style: SpeechStyle = SpeechStyle.CASUAL

## Custom speech patterns or verbal tics.
var speech_patterns: String = ""

## Things this character knows about (topics they can discuss).
var knowledge: Array[String] = []

## Information the character hides or reveals only under certain conditions.
var secrets: Array[String] = []

## What the character wants to achieve.
var goals: Array[String] = []

## What the character fears or avoids.
var fears: Array[String] = []

## Dictionary of character_id -> relationship description.
var relationships: Dictionary = {}

## Example dialogue lines that demonstrate the character's voice.
var example_dialogues: Array[String] = []


# === PROPERTY SYSTEM (for saving/loading without showing in native inspector) ===

func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []

	# All properties use STORAGE only - they save/load but don't show in native inspector
	# Our custom EditorInspectorPlugin handles the UI

	properties.append({
		"name": "character_id",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "character_name",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "portrait",
		"type": TYPE_OBJECT,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "Texture2D",
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "personality",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "background",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "speech_style",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ",".join(SpeechStyle.keys()),
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "speech_patterns",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "knowledge",
		"type": TYPE_ARRAY,
		"hint": PROPERTY_HINT_TYPE_STRING,
		"hint_string": "%d:" % TYPE_STRING,
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "secrets",
		"type": TYPE_ARRAY,
		"hint": PROPERTY_HINT_TYPE_STRING,
		"hint_string": "%d:" % TYPE_STRING,
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "goals",
		"type": TYPE_ARRAY,
		"hint": PROPERTY_HINT_TYPE_STRING,
		"hint_string": "%d:" % TYPE_STRING,
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "fears",
		"type": TYPE_ARRAY,
		"hint": PROPERTY_HINT_TYPE_STRING,
		"hint_string": "%d:" % TYPE_STRING,
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "relationships",
		"type": TYPE_DICTIONARY,
		"usage": PROPERTY_USAGE_STORAGE
	})
	properties.append({
		"name": "example_dialogues",
		"type": TYPE_ARRAY,
		"hint": PROPERTY_HINT_TYPE_STRING,
		"hint_string": "%d:" % TYPE_STRING,
		"usage": PROPERTY_USAGE_STORAGE
	})

	return properties


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


## Estimates the number of tokens this character's prompt will use.
## Uses ~4 characters per token as approximation.
func estimate_tokens() -> int:
	return ceili(to_system_prompt().length() / 4.0)
