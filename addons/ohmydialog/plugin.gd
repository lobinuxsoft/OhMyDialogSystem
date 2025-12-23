@tool
extends EditorPlugin
## OhMyDialogSystem - AI-powered dialogue system for Godot
##
## Main plugin entry point. Handles initialization and cleanup of
## editor components, custom types, and dock panels.


func _enter_tree() -> void:
	# Plugin initialization
	print("OhMyDialogSystem: Plugin loaded")


func _exit_tree() -> void:
	# Plugin cleanup
	print("OhMyDialogSystem: Plugin unloaded")
