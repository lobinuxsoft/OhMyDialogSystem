@tool
class_name VariableProvider
extends RefCounted
## Provides list of available variables for dropdowns in the editor.
##
## Collects variables from multiple sources:
## - Local: Variables defined in the current DialogueGraph
## - Global: Variables defined in plugin configuration
## - AutoLoads: Properties from project autoloads


## Category names for UI display.
const CATEGORY_LOCAL := "Local"
const CATEGORY_GLOBAL := "Global"
const CATEGORY_AUTOLOADS := "AutoLoads"


## Returns all available variables organized by source.
## Result format: { "Local": [...], "Global": [...], "AutoLoads": { "SingletonName": [...], ... } }
static func get_all_variables(graph: DialogueGraph = null) -> Dictionary:
	var result := {
		CATEGORY_LOCAL: [] as Array[String],
		CATEGORY_GLOBAL: [] as Array[String],
		CATEGORY_AUTOLOADS: {}
	}

	# Local variables from the current graph
	if graph and not graph.local_variables.is_empty():
		for var_name in graph.local_variables.keys():
			result[CATEGORY_LOCAL].append(str(var_name))

	# Global variables from plugin configuration
	result[CATEGORY_GLOBAL] = _get_global_variables()

	# Variables from AutoLoads
	result[CATEGORY_AUTOLOADS] = _get_autoload_variables()

	return result


## Returns list of category names that have variables.
static func get_available_categories(graph: DialogueGraph = null) -> Array[String]:
	var categories: Array[String] = []
	var all_vars := get_all_variables(graph)

	if not all_vars[CATEGORY_LOCAL].is_empty():
		categories.append(CATEGORY_LOCAL)
	if not all_vars[CATEGORY_GLOBAL].is_empty():
		categories.append(CATEGORY_GLOBAL)
	if not all_vars[CATEGORY_AUTOLOADS].is_empty():
		categories.append(CATEGORY_AUTOLOADS)

	return categories


## Returns a flat list of all variables with prefixes.
## Format: "var_name" for local/global, "AutoloadName.property" for autoloads.
static func get_flat_variable_list(graph: DialogueGraph = null, category: String = "") -> Array[String]:
	var result: Array[String] = []
	var all_vars := get_all_variables(graph)

	if category.is_empty() or category == CATEGORY_LOCAL:
		for var_name in all_vars[CATEGORY_LOCAL]:
			result.append(var_name)

	if category.is_empty() or category == CATEGORY_GLOBAL:
		for var_name in all_vars[CATEGORY_GLOBAL]:
			result.append(var_name)

	if category.is_empty() or category == CATEGORY_AUTOLOADS:
		for autoload_name in all_vars[CATEGORY_AUTOLOADS]:
			for prop_name in all_vars[CATEGORY_AUTOLOADS][autoload_name]:
				result.append("%s.%s" % [autoload_name, prop_name])

	return result


## Reads autoload variables from project.godot.
static func _get_autoload_variables() -> Dictionary:
	var autoloads := {}

	var config := ConfigFile.new()
	var err := config.load("res://project.godot")
	if err != OK:
		return autoloads

	if not config.has_section("autoload"):
		return autoloads

	for key in config.get_section_keys("autoload"):
		var path: String = config.get_value("autoload", key, "")
		if path.is_empty():
			continue

		# Remove leading * (indicates enabled autoload)
		path = path.trim_prefix("*")

		# Get exported properties from the script
		var exports := _get_exported_properties(path)
		if not exports.is_empty():
			autoloads[key] = exports

	return autoloads


## Extracts @export properties from a script.
static func _get_exported_properties(script_path: String) -> Array[String]:
	var exports: Array[String] = []

	if not ResourceLoader.exists(script_path):
		return exports

	var script = load(script_path)
	if not script:
		return exports

	# Get property list from the script
	var properties: Array[Dictionary] = script.get_script_property_list()
	for prop: Dictionary in properties:
		# Check if property is exported (has PROPERTY_USAGE_STORAGE flag from @export)
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and prop.usage & PROPERTY_USAGE_STORAGE:
			# Skip internal properties
			if not prop.name.begins_with("_"):
				exports.append(prop.name)

	return exports


## Reads global variables from plugin configuration file.
static func _get_global_variables() -> Array[String]:
	var globals: Array[String] = []

	var config_path := "res://addons/ohmydialog/config/global_variables.cfg"
	if not FileAccess.file_exists(config_path):
		return globals

	var config := ConfigFile.new()
	if config.load(config_path) != OK:
		return globals

	if config.has_section("variables"):
		for key in config.get_section_keys("variables"):
			globals.append(key)

	return globals


## Saves a global variable to the configuration file.
static func add_global_variable(var_name: String, default_value: Variant = null) -> void:
	var config_path := "res://addons/ohmydialog/config/global_variables.cfg"

	# Ensure directory exists
	var dir := DirAccess.open("res://addons/ohmydialog")
	if dir and not dir.dir_exists("config"):
		dir.make_dir("config")

	var config := ConfigFile.new()
	config.load(config_path)  # Ignore error if file doesn't exist

	config.set_value("variables", var_name, default_value)
	config.save(config_path)


## Removes a global variable from the configuration file.
static func remove_global_variable(var_name: String) -> void:
	var config_path := "res://addons/ohmydialog/config/global_variables.cfg"

	if not FileAccess.file_exists(config_path):
		return

	var config := ConfigFile.new()
	if config.load(config_path) != OK:
		return

	if config.has_section_key("variables", var_name):
		# ConfigFile doesn't have erase, so we rebuild without the key
		var new_config := ConfigFile.new()
		for key in config.get_section_keys("variables"):
			if key != var_name:
				new_config.set_value("variables", key, config.get_value("variables", key))
		new_config.save(config_path)
