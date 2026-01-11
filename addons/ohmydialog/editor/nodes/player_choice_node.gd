@tool
class_name PlayerChoiceNode
extends BaseDialogueNode
## Visual node for presenting choices to the player.
##
## Has one input and multiple outputs - one per choice option.
## Each output connects to the next node for that choice.


func _configure_slots() -> void:
	# Will be configured in _create_content_ui after children are added
	pass


func _create_content_ui() -> void:
	var choice_node := node_data as PlayerChoiceNodeData
	var choices: PackedStringArray = choice_node.choices if choice_node else PackedStringArray()

	if choices.is_empty() and choice_node:
		choice_node.add_choice("Choice 1")
		choices = choice_node.choices

	# First choice goes in _content_container (slot 0 has input)
	var first_text: String = choices[0] if not choices.is_empty() else "Choice 1"
	_add_label("1. " + first_text)

	# Remaining choices as direct children (slots 1, 2, 3...)
	for i in range(1, choices.size()):
		var text: String = choices[i]

		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(180, 20)

		var label := Label.new()
		label.text = "%d. %s" % [i + 1, text]
		label.clip_text = true
		label.custom_minimum_size.x = 180
		row.add_child(label)

		add_child(row)

	# Configure slots - one output per choice
	for i in range(choices.size()):
		if i == 0:
			# Slot 0: input left, output right
			set_slot(i, true, 0, Color.WHITE, true, 0, Color.WHITE)
		else:
			# Other slots: no input, output right
			set_slot(i, false, 0, Color.WHITE, true, 0, Color.WHITE)
