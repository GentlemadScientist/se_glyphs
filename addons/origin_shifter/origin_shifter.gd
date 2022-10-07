extends Node

export var world_node : NodePath = "../../"
export var max_distance_from_origin : float = 10000
export var enable_logging : bool = false

onready var node_to_keep_centered : Spatial = get_parent()

func update():
	if node_to_keep_centered.translation.length() > max_distance_from_origin:
		var translated_nodes : PoolStringArray = []
		for child in get_node(world_node).get_children():
			if child is Spatial:
				child.global_translate(-node_to_keep_centered.global_transform.origin)
				translated_nodes.append(child.name)
		if enable_logging:
			print("Shifted all children of '%s' (%s) so '%s' is at the origin." % [get_node(world_node).name, translated_nodes.join(", "), node_to_keep_centered.name])
