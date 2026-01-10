@tool
@icon("res://addons/ohmydialog/icons/world_context.svg")
class_name WorldContext
extends Resource
## Defines the world/scenario context for dialogue generation.
##
## This resource contains information about the game world that helps
## the LLM generate contextually appropriate responses. It includes
## setting details, lore, current events, and dynamic state tracking.


## Time period presets that affect the world's technological and cultural level.
enum TimePeriod {
	PREHISTORIC,   ## Before recorded history
	ANCIENT,       ## Ancient civilizations (Egypt, Rome, etc.)
	MEDIEVAL,      ## Middle ages, castles, knights
	RENAISSANCE,   ## Early modern period, art and science
	INDUSTRIAL,    ## Steam age, factories
	MODERN,        ## Contemporary real world
	NEAR_FUTURE,   ## Close future, emerging tech
	FAR_FUTURE,    ## Distant future, space travel
	POST_APOCALYPTIC, ## After civilization collapse
	FANTASY,       ## Magic-based, no specific era
	STEAMPUNK,     ## Victorian + steam technology
	CYBERPUNK      ## High tech, low life
}


@export_group("Identity")

## Unique identifier for this world context.
@export var world_id: String = ""

## Display name of the world/setting.
@export var world_name: String = ""


@export_group("Setting")

## Brief description of the setting.
@export_multiline var setting: String = ""

## The technological and cultural era of this world.
@export var time_period: TimePeriod = TimePeriod.FANTASY

## The overall tone of the world.
@export var tone: String = ""

## Deep background lore and history of the world.
@export_multiline var lore: String = ""


@export_group("World Data")

## Major factions, nations, or groups in the world.
@export var factions: Dictionary = {}

## Known locations in the world.
@export var locations: Dictionary = {}

## Important NPCs the player might hear about.
@export var important_npcs: Dictionary = {}


@export_group("Dynamic State")

## The current location context (can be updated dynamically).
@export var current_location: String = ""

## Current events happening in the world (can be updated dynamically).
@export var current_events: Array[String] = []

## Dynamic state variables that can change during gameplay.
@export var dynamic_state: Dictionary = {}


@export_group("Rules")

## World rules and constraints for the AI.
@export var rules: Array[String] = []

## Topics or themes to avoid in this world.
@export var forbidden_topics: Array[String] = []


## Generates a context prompt that describes the world for the LLM.
## This is injected into prompts to give the AI world awareness.
func to_context_prompt() -> String:
	var prompt_parts: Array[String] = []

	# World introduction
	if not world_name.is_empty():
		prompt_parts.append("The story takes place in %s." % world_name)

	# Setting
	if not setting.is_empty():
		prompt_parts.append("Setting: %s" % setting)

	# Time period
	prompt_parts.append("Era: %s" % _get_time_period_description())

	# Current location
	if not current_location.is_empty():
		var loc_desc: String = locations.get(current_location, current_location)
		prompt_parts.append("Current location: %s" % loc_desc)

	# Lore (condensed)
	if not lore.is_empty():
		prompt_parts.append("World lore: %s" % lore)

	# Active factions
	if not factions.is_empty():
		var faction_list: Array[String] = []
		for faction_id in factions:
			faction_list.append("%s: %s" % [faction_id, factions[faction_id]])
		prompt_parts.append("Major factions: %s" % "; ".join(faction_list))

	# Current events
	if not current_events.is_empty():
		prompt_parts.append("Current events: %s" % ", ".join(current_events))

	# Dynamic state
	if not dynamic_state.is_empty():
		var state_parts: Array[String] = []
		for key in dynamic_state:
			state_parts.append("%s: %s" % [key, str(dynamic_state[key])])
		prompt_parts.append("World state: %s" % ", ".join(state_parts))

	# Tone
	if not tone.is_empty():
		prompt_parts.append("Tone: %s" % tone)

	# Rules
	if not rules.is_empty():
		prompt_parts.append("World rules to follow: %s" % ", ".join(rules))

	# Forbidden topics
	if not forbidden_topics.is_empty():
		prompt_parts.append("Never mention or reference: %s" % ", ".join(forbidden_topics))

	return "\n".join(prompt_parts)


## Returns a description of the time period for prompts.
func _get_time_period_description() -> String:
	match time_period:
		TimePeriod.PREHISTORIC:
			return "Prehistoric - before civilization, primitive tools and survival"
		TimePeriod.ANCIENT:
			return "Ancient - great empires, mythology, bronze and iron age"
		TimePeriod.MEDIEVAL:
			return "Medieval - feudal kingdoms, castles, knights and peasants"
		TimePeriod.RENAISSANCE:
			return "Renaissance - art, science, early firearms, exploration"
		TimePeriod.INDUSTRIAL:
			return "Industrial - steam power, factories, urbanization"
		TimePeriod.MODERN:
			return "Modern - contemporary technology and society"
		TimePeriod.NEAR_FUTURE:
			return "Near future - advanced technology, AI, space exploration beginning"
		TimePeriod.FAR_FUTURE:
			return "Far future - interstellar travel, advanced civilizations"
		TimePeriod.POST_APOCALYPTIC:
			return "Post-apocalyptic - civilization has fallen, survival in ruins"
		TimePeriod.FANTASY:
			return "Fantasy - magic exists, medieval-like but with supernatural elements"
		TimePeriod.STEAMPUNK:
			return "Steampunk - Victorian aesthetics with steam-powered technology"
		TimePeriod.CYBERPUNK:
			return "Cyberpunk - high technology, mega-corporations, urban dystopia"
		_:
			return "Unspecified era"


## Updates a dynamic state variable.
func set_state(key: String, value: Variant) -> void:
	dynamic_state[key] = value


## Gets a dynamic state variable, with optional default.
func get_state(key: String, default: Variant = null) -> Variant:
	return dynamic_state.get(key, default)


## Adds a current event to the world.
func add_event(event: String) -> void:
	if not current_events.has(event):
		current_events.append(event)


## Removes a current event from the world.
func remove_event(event: String) -> void:
	current_events.erase(event)


## Clears all current events.
func clear_events() -> void:
	current_events.clear()


## Sets the current location by ID.
func set_location(location_id: String) -> void:
	current_location = location_id


## Serializes the world context to a dictionary.
func to_dict() -> Dictionary:
	return {
		"world_id": world_id,
		"world_name": world_name,
		"setting": setting,
		"time_period": time_period,
		"lore": lore,
		"factions": factions.duplicate(),
		"locations": locations.duplicate(),
		"current_location": current_location,
		"important_npcs": important_npcs.duplicate(),
		"current_events": current_events.duplicate(),
		"rules": rules.duplicate(),
		"dynamic_state": dynamic_state.duplicate(),
		"tone": tone,
		"forbidden_topics": forbidden_topics.duplicate()
	}


## Creates a WorldContext from a dictionary.
static func from_dict(dict: Dictionary) -> WorldContext:
	var world := WorldContext.new()
	world.world_id = dict.get("world_id", "")
	world.world_name = dict.get("world_name", "")
	world.setting = dict.get("setting", "")
	world.time_period = dict.get("time_period", TimePeriod.FANTASY)
	world.lore = dict.get("lore", "")
	world.factions = dict.get("factions", {}).duplicate()
	world.locations = dict.get("locations", {}).duplicate()
	world.current_location = dict.get("current_location", "")
	world.important_npcs = dict.get("important_npcs", {}).duplicate()
	world.current_events = Array(dict.get("current_events", []), TYPE_STRING, "", null)
	world.rules = Array(dict.get("rules", []), TYPE_STRING, "", null)
	world.dynamic_state = dict.get("dynamic_state", {}).duplicate()
	world.tone = dict.get("tone", "")
	world.forbidden_topics = Array(dict.get("forbidden_topics", []), TYPE_STRING, "", null)
	return world


## Returns true if this world has minimum required data.
func is_valid() -> bool:
	return not world_id.is_empty() and not world_name.is_empty()


## Returns a short summary of the world for debugging.
func get_summary() -> String:
	return "%s (%s) - %s" % [
		world_name if not world_name.is_empty() else "Unnamed World",
		world_id if not world_id.is_empty() else "no-id",
		TimePeriod.keys()[time_period].to_lower().replace("_", " ")
	]


## Estimates the number of tokens this world context will use.
## Uses ~4 characters per token as approximation.
func estimate_tokens() -> int:
	return ceili(to_context_prompt().length() / 4.0)
