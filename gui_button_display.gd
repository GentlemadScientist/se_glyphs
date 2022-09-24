extends Button

func _ready():
	connect("button_down", get_node("/root/Main/symbol_3d_space"), "_on_display_button_pressed", [self])
	self.text = $"/root/Global".display_button_states[$"/root/Global".display_button_current_state]

func _pressed():
	self.text = $"/root/Global".display_button_states[$"/root/Global".display_button_current_state]
