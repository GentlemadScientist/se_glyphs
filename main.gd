extends Node

var glyphs = {}
		
func load_data(content):
	if content.length() == 0:
		return
	var json = JSON.parse(content)
	var glyph_script = preload("res://glyph_image.gd")
	var glyph_area_script = preload("res://glyph_area.gd")
	var collision_shape_script = preload("res://collision_shape.gd")
	
	var vec_scale = Vector3($"/root/Global".scale_multiplier, $"/root/Global".scale_multiplier, $"/root/Global".scale_multiplier)
	
	for key in json.result:
		var data = json.result[key]
		
		if data.coord.x == 0 && data.coord.y == 0 && data.coord.z == 0 && data.se_code != 64:
			glyphs[key] = data
			continue # Undefined coords, still add to the db but do not display
		
		# Generate an instance of symbol with all data
		var symbol = Position3D.new()
		symbol.transform.origin = Vector3(data.coord.x, data.coord.y, data.coord.z)
		
		var glyph_image = Sprite3D.new()
		var texture = load(str("res://assets/glyph-a-",data.se_code,".png"))
		glyph_image.texture = texture
		glyph_image.billboard = SpatialMaterial.BILLBOARD_ENABLED
		glyph_image.set_script(glyph_script)
		glyph_image.scale = vec_scale
		
		symbol.add_child(glyph_image)
		
		var area = Area.new()
		area.set_script(glyph_area_script)
		
		var sphere = MeshInstance.new()
		sphere.mesh = SphereMesh.new()
		sphere.scale = vec_scale / 2
		area.add_child(sphere)
		data.sphere = sphere
		
		area.connect("input_event", self, "_on_glyph_area_input_event", [key, sphere])
		
		var collision = CollisionShape.new()
		var sphereShape = SphereShape.new()
		collision.shape = sphereShape
		collision.scale = vec_scale / 2
		collision.set_script(collision_shape_script)
		area.add_child(collision)
		symbol.add_child(area)
		add_child(symbol)
		glyphs[key] = data

func draw_grid():
	pass

func init_handlers():
	pass

func _ready():
	if OS.is_debug_build():
		# Read local user file
		var data_file = File.new()
		data_file.open("res://data.json", File.READ)
		var content = data_file.get_as_text()
		load_data(content)
		data_file.close()
	else:
		# HTML release : load data.json through http. I could not find a way to export user file
		
		pass
	draw_grid()
	init_handlers()

func _unhandled_input(event):
	# This is (for some reason) called before children's input_event. So we want to reset the state here, and handle special case inside input_event
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		for key in glyphs:
			if "sphere" in glyphs[key]:
				glyphs[key].sphere.material_override = null

func _on_glyph_area_input_event(camera, event, position, normal, shape_idx, glyph_key:String, sphere: MeshInstance):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		# Color the selected one
		sphere.material_override = $"/root/Global".selected_material
		# Color the linked ones
		if glyphs[glyph_key].links.length() > 0:
			for link_key in glyphs[glyph_key].links.split(","):
				if link_key.length() > 0 && link_key != "?":
					if "sphere" in glyphs[link_key]:
						glyphs[link_key].sphere.material_override = $"/root/Global".selected_material_link
		
	pass # Replace with function body.
