@tool
extends EditorScript
## Run this script from Editor -> Run to generate the demo dialogue graph.


func _run() -> void:
	var graph := DialogueGraph.new()
	graph.graph_id = "merchant_demo"
	graph.display_name = "Merchant Demo Dialogue"
	graph.description = "A demonstration dialogue with Marcus the Merchant."
	graph.local_variables = {"player_reputation": 60, "talked_to_merchant": false}

	# Nodes - using typed subclasses
	var start: StartNodeData = graph.create_node(DialogueNodeData.NodeType.START, Vector2(50, 200))

	var greeting: StaticResponseNodeData = graph.create_node(DialogueNodeData.NodeType.STATIC_RESPONSE, Vector2(250, 200))
	greeting.speaker = "Marcus"
	greeting.text = "Welcome, traveler! I am Marcus, purveyor of fine goods. What brings you here?"

	var choice: PlayerChoiceNodeData = graph.create_node(DialogueNodeData.NodeType.PLAYER_CHOICE, Vector2(550, 200))
	choice.add_choice("I'm looking to buy.")
	choice.add_choice("Just browsing.")
	choice.add_choice("Special items?")

	var buy: StaticResponseNodeData = graph.create_node(DialogueNodeData.NodeType.STATIC_RESPONSE, Vector2(850, 50))
	buy.speaker = "Marcus"
	buy.text = "Excellent! I have potions, weapons, and magical trinkets!"

	var browse: StaticResponseNodeData = graph.create_node(DialogueNodeData.NodeType.STATIC_RESPONSE, Vector2(850, 200))
	browse.speaker = "Marcus"
	browse.text = "Browse all you like! My prices are irresistible!"

	var check: ConditionNodeData = graph.create_node(DialogueNodeData.NodeType.CONDITION, Vector2(850, 350))
	check.variable = "player_reputation"
	check.operator = DialogueNodeData.ComparisonOperator.GREATER_EQUAL
	check.value = 50

	var secret_yes: StaticResponseNodeData = graph.create_node(DialogueNodeData.NodeType.STATIC_RESPONSE, Vector2(1150, 300))
	secret_yes.speaker = "Marcus"
	secret_yes.text = "*whispers* Follow me to the back room..."

	var secret_no: StaticResponseNodeData = graph.create_node(DialogueNodeData.NodeType.STATIC_RESPONSE, Vector2(1150, 450))
	secret_no.speaker = "Marcus"
	secret_no.text = "Special items? I'm a legitimate merchant!"

	var event: EventNodeData = graph.create_node(DialogueNodeData.NodeType.EVENT, Vector2(1450, 300))
	event.event_name = "secret_shop_unlocked"
	event.event_data = {"merchant": "Marcus"}

	var setvar: SetVariableNodeData = graph.create_node(DialogueNodeData.NodeType.SET_VARIABLE, Vector2(1150, 50))
	setvar.variable = "talked_to_merchant"
	setvar.operation = DialogueNodeData.VariableOperation.SET
	setvar.value = true

	var end: EndNodeData = graph.create_node(DialogueNodeData.NodeType.END, Vector2(1450, 150))

	# Connections
	graph.connect_nodes(start.node_id, 0, greeting.node_id)
	graph.connect_nodes(greeting.node_id, 0, choice.node_id)
	graph.connect_nodes(choice.node_id, 0, buy.node_id)
	graph.connect_nodes(choice.node_id, 1, browse.node_id)
	graph.connect_nodes(choice.node_id, 2, check.node_id)
	graph.connect_nodes(buy.node_id, 0, setvar.node_id)
	graph.connect_nodes(browse.node_id, 0, end.node_id)
	graph.connect_nodes(check.node_id, 0, secret_yes.node_id)
	graph.connect_nodes(check.node_id, 1, secret_no.node_id)
	graph.connect_nodes(secret_yes.node_id, 0, event.node_id)
	graph.connect_nodes(secret_no.node_id, 0, end.node_id)
	graph.connect_nodes(event.node_id, 0, end.node_id)
	graph.connect_nodes(setvar.node_id, 0, end.node_id)

	# Save
	var err := ResourceSaver.save(graph, "res://examples/resources/merchant_dialogue.tres")
	print("Demo graph saved!" if err == OK else "Error: %s" % error_string(err))
