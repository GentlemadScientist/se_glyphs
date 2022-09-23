extends Node

var scale_multiplier = 0.3
var selected_material = init_selected_material()
var selected_material_link = init_selected_material_link()

func init_selected_material():
	var mat = SpatialMaterial.new()
	mat.albedo_color = Color(1, 0.2, 0.2, 1.0)
	return mat
	
func init_selected_material_link():
	var mat = SpatialMaterial.new()
	mat.albedo_color = Color(0.4, 0.6, 1, 1.0)
	return mat

func settings():
	return {
		"selected_color": "a"
	};
