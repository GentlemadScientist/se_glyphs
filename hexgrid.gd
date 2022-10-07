extends Node2D

var grid_data = {}
var all_glyphs = null
var center_pos = Vector2(1000,650)
var edge_length = 90

var target_coord = {}
var key1 = ""
var key2 = ""
var coord1 = {}
var coord2 = {}

func _ready():
	pass

func on_glyphs_loaded(glyphs):
	var vector_a = Vector2.LEFT.rotated(30*PI/180).normalized() * edge_length  # Top right to bottom left
	var vector_b = Vector2.RIGHT.rotated(-30*PI/180).normalized() * edge_length  # Top left to bottom right
	var vector_c = Vector2.UP * edge_length  # Bottom to top
	for glyph_key in glyphs:
		var glyph = glyphs[glyph_key]
		if "a" in glyph:
			# Hex positions
			var pos_vector = (
				+ (glyph["a"] - 3) * vector_a
				+ (glyph["b"] - 3) * vector_b
				- (glyph["c"] - 3 ) * vector_c
			)
			glyph["2d_coord"] = Vector2(center_pos.x + pos_vector.x, center_pos.y - pos_vector.y) # Cause the grid Y is from top to bottom which sucks
			
			var area = Area2D.new()
			area.transform.origin = glyph["2d_coord"]
			var sprite = Sprite.new()
			sprite.texture = load(str("res://assets/glyph-a-",glyph["se_code"],".png"))
			area.add_child(sprite)
			
			var coll_shape = CollisionShape2D.new()
			coll_shape.shape = RectangleShape2D.new()
			coll_shape.scale = Vector2.ONE * 2.5
			area.add_child(coll_shape)
			
			var label = Label.new()
			label.text = glyph_key
			label.rect_position.x = -3 * glyph_key.length()
			label.rect_position.y = 26
			area.add_child(label)
			
			add_child(area)
			var _err = area.connect("input_event", self, "_on_glyph_input_event", [glyph])
			if _err:
				print(_err)
			
			if not glyph["a"] in grid_data:
				grid_data[glyph["a"]] = {}
			if not glyph["b"] in grid_data[glyph["a"]]:
				grid_data[glyph["a"]][glyph["b"]] = {}
			grid_data[glyph["a"]][glyph["b"]][glyph["c"]] = glyph
	
	all_glyphs = glyphs

func _on_glyph_input_event(viewport, event, shape_idx, glyph):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		pass
		#alert("Hello", "message")

func alert(text: String, title: String='Message') -> void:
	var dialog = AcceptDialog.new()
	dialog.dialog_text = text
	dialog.window_title = title
	dialog.connect('modal_closed', dialog, 'queue_free')
	add_child(dialog)
	dialog.popup_centered()

func get_gui_grid_node():
	var node = get_node("/root/Main/GUI/HBoxContainer/VBoxContainer/GridContainer")
	return node

func process_input(text: String, type, node: LineEdit):
	if type == "target" || type == "key1" || type == "key2":
		var found = false
		for glyph in all_glyphs:
			if text == glyph:
				if type == "target":
					target_coord = all_glyphs[glyph].coord
				if type == "key1":
					key1 = text
				if type == "key2":
					key2 = text
				found = true
		if !found:
			if type == "target":
				target_coord = null
			node.text = ""
	if type == "coord1" || type == "coord2":
		var coords = text.split(",", false)
		if coords.size() == 3:
			var coord = {
				"x": float(coords[0].strip_edges()),
				"y": float(coords[1].strip_edges()),
				"z": float(coords[2].strip_edges())
			}
			if type == "coord1":
				coord1 = coord
			elif type == "coord2":
				coord2 = coord
		else:
			node.text = ""
	
	var pos_adjust = Vector2.ZERO #Vector2(0,-35)
	
	if key1:
		$c1.show()
		$c1.transform.origin = all_glyphs[key1]["2d_coord"] + pos_adjust
	else:
		$c1.hide()
		
	if key2:
		$c2.show()
		$c2.transform.origin = all_glyphs[key2]["2d_coord"] + pos_adjust
	else:
		$c2.hide()
	
	
	if "x" in coord1 && "x" in coord2 && target_coord != null && "x" in target_coord && key1 && key2:
		var rel_target = Vector2(
			all_glyphs[key1]["2d_coord"].x * coord1.z * target_coord.x / (coord1.x * target_coord.z),
			all_glyphs[key1]["2d_coord"].y * coord1.z * target_coord.y / (coord1.y * target_coord.z)
		)
		
		var rel_c2 = Vector2(
			all_glyphs[key1]["2d_coord"].x * coord1.z * coord2.x / (coord1.x * coord2.z),
			all_glyphs[key1]["2d_coord"].y * coord1.z * coord2.y / (coord1.y * coord2.z)
		)
		
		var current_c2_vec: Vector2 = Vector2(rel_c2.x - all_glyphs[key1]["2d_coord"].x, rel_c2.y - all_glyphs[key1]["2d_coord"].y)
		var target_c2_vec: Vector2 = all_glyphs[key2]["2d_coord"] - all_glyphs[key1]["2d_coord"]
		
		$c2.transform.origin = rel_c2
		$c_target.transform.origin = rel_target
		
		var needed_rotation = current_c2_vec.angle_to(target_c2_vec)
		var needed_scale = target_c2_vec.length() / current_c2_vec.length()
		
		#$c2.transform.origin = (rel_c2 - $c1.transform.origin).rotated(needed_rotation) * needed_scale + $c1.transform.origin
		
		#$c_target.transform.origin = (rel_target - $c1.transform.origin).rotated(needed_rotation) * needed_scale + $c1.transform.origin
		$c_target.show()
	else:
		$c_target.hide()
			
	node.release_focus()

func _on_target_text_entered(new_text):
	var node = get_gui_grid_node().get_node("target")
	process_input(new_text, "target", node)

func _on_key1_text_entered(new_text):
	var node = get_gui_grid_node().get_node("key1")
	process_input(new_text, "key1", node)

func _on_coord1_text_entered(new_text):
	var node = get_gui_grid_node().get_node("coord1")
	process_input(new_text, "coord1", node)

func _on_key2_text_entered(new_text):
	var node = get_gui_grid_node().get_node("key2")
	process_input(new_text, "key2", node)

func _on_coord2_text_entered(new_text):
	var node = get_gui_grid_node().get_node("coord2")
	process_input(new_text, "coord2", node)
