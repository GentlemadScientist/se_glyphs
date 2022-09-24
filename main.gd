extends Node

var glyphs = {}

func load_data_file(path):
	$HTTPRequest.request(path)
	pass
	
func _on_request_completed(result, response_code, headers, body):
	if response_code >= 200 && response_code < 400:
		load_data(body.get_string_from_utf8())
	
func load_data(content):
	unload_data()
	if content.length() == 0:
		return
	var json = JSON.parse(content)
	if json.error != OK:
		print("Unable to parse data json")
	var glyph_script = preload("res://glyph_image.gd")
	var glyph_area_script = preload("res://glyph_area.gd")
	var collision_shape_script = preload("res://collision_shape.gd")
	var label_script = preload("res://glyph_label.gd")
	
	var vec_scale = $"/root/Global".scale_multiplier / 3 * Vector3(1,1,1)
	
	for key in json.result:
		var data = json.result[key]
		var nodes = {}; # A reference to all new nodes, to be able to delete them
		
		if data.coord.x == 0 && data.coord.y == 0 && data.coord.z == 0 && data.se_code != 64:
			data.nodes = {}
			glyphs[key] = data
			continue # Undefined coords, still add to the db but do not display
		
		# Generate an instance of symbol with all data
		var symbol = Position3D.new()
		nodes.symbol = symbol
		symbol.transform.origin = $"/root/Global".scale_multiplier * Vector3(data.coord.x, data.coord.y, data.coord.z)
		
		var glyph_image = Sprite3D.new()
		nodes.glyph_image = glyph_image
		var texture = load(str("res://assets/glyph-a-",data.se_code,".png"))
		glyph_image.texture = texture
		glyph_image.billboard = SpatialMaterial.BILLBOARD_ENABLED
		glyph_image.set_script(glyph_script)
		glyph_image.scale = vec_scale
		symbol.add_child(glyph_image)
		
		var glyph_label = Label3D.new()
		nodes.glyph_label = glyph_label
		glyph_label.font = $"/root/Global".font
		glyph_label.font.size = 3 * $"/root/Global".scale_multiplier
		
		#glyph_label.text = str(data.coord.x,"\n",data.coord.y,"\n",data.coord.z) # Set dynamically
		glyph_label.billboard = SpatialMaterial.BILLBOARD_ENABLED
		glyph_label.modulate = Color(0, 0, 0, 1)
		glyph_label.set_script(label_script)
		symbol.add_child(glyph_label)
		
		var area = Area.new()
		nodes.area = area
		area.set_script(glyph_area_script)
		
		var sphere = MeshInstance.new()
		nodes.sphere = sphere
		sphere.mesh = SphereMesh.new()
		nodes.sphere_mesh = sphere.mesh
		sphere.scale = vec_scale / 2
		area.add_child(sphere)
		
		area.connect("input_event", self, "_on_glyph_area_input_event", [key, sphere])
		
		var collision = CollisionShape.new()
		nodes.collision = collision
		var sphereShape = SphereShape.new()
		nodes.collision_sphereShape = sphereShape
		collision.shape = sphereShape
		collision.scale = vec_scale / 2
		collision.set_script(collision_shape_script)
		area.add_child(collision)
		symbol.add_child(area)
		add_child(symbol)
		data.nodes = nodes
		glyphs[key] = data

func unload_data():
	# Delete all instances
	for key in glyphs:
		if "nodes" in glyphs[key]:
			glyphs[key].nodes.symbol.queue_free()
	glyphs = {}

func draw_grid():
	pass

func init_handlers():
	pass

func _ready():
	$HTTPRequest.connect("request_completed", self, "_on_request_completed")
	if OS.is_debug_build():
		# Read local user file
		var data_file = File.new()
		data_file.open("user://data.json", File.READ)
		var content = data_file.get_as_text()
		load_data(content)
		data_file.close()
	else:
		# HTML release : load data.json through http. I could not find a way to export the json file
		load_data_file("https://gentlemadscientist.github.io/se_glyphs/output/data.json")
		
		pass
	draw_grid()
	init_handlers()

func _unhandled_input(event):
	# This is (for some reason) called before children's input_event. So we want to reset the state here, and handle special case inside input_event
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		for key in glyphs:
			if "nodes" in glyphs[key] && "sphere" in glyphs[key].nodes:
				glyphs[key].nodes.sphere.material_override = null

func _on_glyph_area_input_event(camera, event, position, normal, shape_idx, glyph_key:String, sphere: MeshInstance):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		# Color the selected one
		sphere.material_override = $"/root/Global".selected_material
		# Color the linked ones
		if glyphs[glyph_key].links.length() > 0:
			for link_key in glyphs[glyph_key].links.split(","):
				if link_key.length() > 0 && link_key != "?":
					if "nodes" in glyphs[link_key] && "sphere" in glyphs[link_key].nodes:
						glyphs[link_key].nodes.sphere.material_override = $"/root/Global".selected_material_link
		
	pass # Replace with function body.


func _on_glyphs_button_pressed(button_pressed):
	for key in glyphs:
		if "glyph_image" in glyphs[key].nodes:
			glyphs[key].nodes.glyph_image.visible = button_pressed;
	pass # Replace with function body.

func _on_display_button_pressed(button: Button):
	$"/root/Global".display_button_current_state = $"/root/Global".get_next_state($"/root/Global".display_button_current_state, $"/root/Global".display_button_states)
	var next_state = $"/root/Global".get_next_state($"/root/Global".display_button_current_state, $"/root/Global".display_button_states)
	for key in glyphs:
		if "glyph_label" in glyphs[key].nodes:
			if $"/root/Global".display_button_current_state == 0: # None
				glyphs[key].nodes.glyph_label.text = ""
			elif $"/root/Global".display_button_current_state == 1: # Name
				glyphs[key].nodes.glyph_label.text = glyphs[key].cartouche
			elif $"/root/Global".display_button_current_state == 2: # Coords
				glyphs[key].nodes.glyph_label.text = str(glyphs[key].coord.x, "\n", glyphs[key].coord.y, "\n", glyphs[key].coord.z)
			elif $"/root/Global".display_button_current_state == 3: # Codename
				glyphs[key].nodes.glyph_label.text = glyphs[key].codename
	
