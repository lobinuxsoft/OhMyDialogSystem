@tool
extends EditorScript
## Run this script from Editor -> Run to generate the demo dialogue graph.


func _run() -> void:
	var graph := DialogueGraph.new()
	graph.graph_id = "merchant_demo"
	graph.display_name = "Merchant Demo Dialogue"
	graph.description = "A demonstration dialogue with Marcus the Merchant."
	graph.local_variables = {"player_reputation": 60, "talked_to_merchant": false}

	# Nodes
	var start := graph.create_node(DialogueNodeData.NodeType.START, Vector2(50, 200))

	var greeting := graph.create_node(DialogueNodeData.NodeType.STATIC_RESPONSE, Vector2(250, 200))
	greeting.data = {"text": "Welcome, traveler! I am Marcus, purveyor of fine goods. What brings you here?", "speaker": "Marcus"}

	var choice := graph.create_node(DialogueNodeData.NodeType.PLAYER_CHOICE, Vector2(550, 200))
	choice.data = {"choices": [{"text": "I'm looking to buy."}, {"text": "Just browsing."}, {"text": "Special items?"}]}
	choice.output_count = 3

	var buy := graph.create_node(DialogueNodeData.NodeType.STATIC_RESPONSE, Vector2(850, 50))
	buy.data = {"text": "Excellent! I have potions, weapons, and magical trinkets!", "speaker": "Marcus"}

	var browse := graph.create_node(DialogueNodeData.NodeType.STATIC_RESPONSE, Vector2(850, 200))
	browse.data = {"text": "Browse all you like! My prices are irresistible!", "speaker": "Marcus"}

	var check := graph.create_node(DialogueNodeData.NodeType.CONDITION, Vector2(850, 350))
	check.data = {"variable": "player_reputation", "operator": ">=", "value": 50}

	var secret_yes := graph.create_node(DialogueNodeData.NodeType.STATIC_RESPONSE, Vector2(1150, 300))
	secret_yes.data = {"text": "*whispers* Follow me to the back room...", "speaker": "Marcus"}

	var secret_no := graph.create_node(DialogueNodeData.NodeType.STATIC_RESPONSE, Vector2(1150, 450))
	secret_no.data = {"text": "Special items? I'm a legitimate merchant!", "speaker": "Marcus"}

	var event := graph.create_node(DialogueNodeData.NodeType.EVENT, Vector2(1450, 300))
	event.data = {"event_name": "secret_shop_unlocked", "event_data": {"merchant": "Marcus"}}

	var setvar := graph.create_node(DialogueNodeData.NodeType.SET_VARIABLE, Vector2(1150, 50))
	setvar.data = {"variable": "talked_to_merchant", "operation": "set", "value": true}

	var end := graph.create_node(DialogueNodeData.NodeType.END, Vector2(1450, 150))

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
