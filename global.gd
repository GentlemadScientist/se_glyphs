extends Node

var scale_multiplier = 10
var selected_material = init_selected_material()
var selected_material_link = init_selected_material_link()
var font = init_default_dynamic_font()

var display_button_states = ["None", "Name", "Coords", "Codename"]
var display_button_current_state = 0

func get_next_state(el, array: Array):
	if el >= array.size() - 1:
		return 0
	else:
		return el + 1

func init_selected_material():
	var mat = SpatialMaterial.new()
	mat.albedo_color = Color(1, 0.2, 0.2, 1.0)
	return mat
	
func init_selected_material_link():
	var mat = SpatialMaterial.new()
	mat.albedo_color = Color(0.4, 0.6, 1, 1.0)
	return mat

func init_default_dynamic_font():
	var _font = DynamicFont.new()
	var font_data = DynamicFontData.new()
	font_data.font_path = "res://assets/fonts/Montserrat-Regular.ttf"
	font_data.antialiased = true
	_font.font_data = font_data;
	
	_font.use_filter = true
	return _font

func settings():
	return {
		"selected_color": "a"
	};
