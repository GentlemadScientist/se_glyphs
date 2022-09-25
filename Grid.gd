extends Spatial

func _ready():
	var unit_nodes = {
		"x": $X,
		"y": $Y,
		"z": $Z
	}
	for unit in unit_nodes:
		unit_nodes[unit].transform.origin = $"/root/Global".scale_multiplier * unit_nodes[unit].transform.origin
		unit_nodes[unit].transform.origin[unit] += unit_nodes[unit].scale[unit]

	var unit_lines = {
		"x": $X_line,
		"y": $Y_line,
		"z": $Z_line
	}
	for unit in unit_lines:
		var to_scale = "y" # The cylinder is initialized around Y axis
		unit_lines[unit].scale[to_scale] = $"/root/Global".scale_multiplier * unit_lines[unit].scale[to_scale]
		unit_lines[unit].transform.origin[unit] = $"/root/Global".scale_multiplier / 2
