extends Node

var scale_multiplier : float = 20
var font = init_default_dynamic_font()

var display_button_states = ["None", "Name", "Coords", "Codename"]
var display_button_current_state = 1

var opaque_mode = false
var grid_siblings_mode = false
var center_hidden = false
var camera_hide_radius_squared = 0
var subsphere_node = "H"
var subsphere_rotated = 0
var is_3d = true

func get_next_state(el, array: Array):
	if el >= array.size() - 1:
		return 0
	else:
		return el + 1

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
