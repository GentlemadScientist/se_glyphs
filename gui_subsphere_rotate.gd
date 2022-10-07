extends HSlider

func _ready():
	var _err = connect("value_changed", get_node("/root/Main/symbol_3d_space"), "_on_subsphere_rotate_changed", [self])
