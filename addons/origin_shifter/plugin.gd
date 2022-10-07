tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("OriginShifter", "Node", load("res://addons/origin_shifter/origin_shifter.gd"), load("res://addons/origin_shifter/origin_shifter_icon.svg"))

func _exit_tree():
	remove_custom_type("OriginShifter")
