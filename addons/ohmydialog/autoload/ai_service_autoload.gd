extends Node
## AutoLoad wrapper for AIService.
##
## This script is automatically registered as an AutoLoad by the plugin.
## It ensures AIService is available in both editor and runtime contexts.


var _ai_service: AIService


func _ready() -> void:
	# Check if AIService singleton already exists (editor context)
	var existing := AIService.get_singleton()
	if existing:
		# In editor, the plugin already created AIService
		# Just keep a reference but don't create a duplicate
		_ai_service = existing
		return

	# Runtime context - create AIService
	_ai_service = AIService.new()
	_ai_service.name = "AIService"
	add_child(_ai_service)


func _exit_tree() -> void:
	# Only cleanup if we created the service (runtime context)
	if _ai_service and _ai_service.get_parent() == self:
		_ai_service.queue_free()
		_ai_service = null
