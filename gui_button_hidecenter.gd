extends CheckButton

func _ready():
	connect("toggled", get_node("/root/Main/symbol_3d_space"), "_on_disable_center_pressed")
