extends Node

var glyphs = {}
var used_coord_map = {} # A map of references of coords to symbols, for easy access to a symbol at a given coord

var glyph_script = preload("res://glyph_image.gd")
var glyph_area_script = preload("res://glyph_area.gd")
var collision_shape_script = preload("res://collision_shape.gd")
var label_script = preload("res://glyph_label.gd")

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
		
		if $"/root/Global".display_button_current_state == 1 && "cartouche" in data: # Name
			glyph_label.text = data.cartouche
		elif $"/root/Global".display_button_current_state == 2 && "coord" in data: # Coord
			glyph_label.text = str(data.coord.x,"\n",data.coord.y,"\n",data.coord.z) # Set dynamically
		elif $"/root/Global".display_button_current_state == 3 && "codename" in data: # Codename
			glyph_label.text = data.codename
		glyph_label.billboard = SpatialMaterial.BILLBOARD_ENABLED
		glyph_label.modulate = Color(0, 0, 0, 1)
		glyph_label.set_script(label_script)
		symbol.add_child(glyph_label)
		
		var area = Area.new()
		nodes.area = area
		area.set_script(glyph_area_script)
		
		var sphere = MeshInstance.new()
		nodes.sphere = sphere
		sphere.mesh = load('res://assets/sphere_mesh.tres')
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
		
		if "codename" in data && data.codename != "center":
			# Register as used only real nodes : no center, no custom ones
			var used_x = stepify(data.coord.x, 0.000001)
			var used_y = stepify(data.coord.y, 0.000001)
			var used_z = stepify(data.coord.z, 0.000001)
			if !used_x in used_coord_map:
				used_coord_map[used_x] = {}
			if !used_y in used_coord_map[used_x]:
				used_coord_map[used_x][used_y] = {}

			used_coord_map[used_x][used_y][used_z] = {
				"key": key,
				"nodes": nodes
			}
		
		data.nodes = nodes
		glyphs[key] = data
	fill_empty_coords()

func fill_empty_coords():
	var vec_scale = $"/root/Global".scale_multiplier / 3 * Vector3(1,1,1)
	var fill_count = 0
	for coord in all_ti_coordinate_list():
		var used_x = stepify(coord.x, 0.000001)
		var used_y = stepify(coord.y, 0.000001)
		var used_z = stepify(coord.z, 0.000001)
		if (!used_x in used_coord_map
			|| !used_y in used_coord_map[used_x]
			|| !used_z in used_coord_map[used_x][used_y]
		):
			fill_count += 1
			# Unused coord space : create empty sphere
			var sphere = MeshInstance.new()
			sphere.mesh = load('res://assets/sphere_mesh.tres')
			sphere.material_override = load('res://assets/sphere_material_empty.tres')
			sphere.transform.origin = coord * $"/root/Global".scale_multiplier
			sphere.scale = vec_scale / 2
			
			var glyph_label = Label3D.new()
			glyph_label.font = $"/root/Global".font
			glyph_label.font.size = 3 * $"/root/Global".scale_multiplier
			if $"/root/Global".display_button_current_state == 2: # Coord
				glyph_label.text = str(coord.x,"\n",coord.y,"\n",coord.z) # Set dynamically
			glyph_label.billboard = SpatialMaterial.BILLBOARD_ENABLED
			glyph_label.modulate = Color(0.8, 0.8, 0.8, 1)
			glyph_label.set_script(label_script)
			sphere.add_child(glyph_label)
			
			if !coord.x in used_coord_map:
				used_coord_map[coord.x] = {}
			if !coord.y in used_coord_map[coord.x]:
				used_coord_map[coord.x][coord.y] = {}
			used_coord_map[coord.x][coord.y][coord.z] = {
				"nodes": {
					"sphere": sphere,
					"glyph_label": glyph_label
				}
			}
		
			add_child(sphere)
	print("fill: ",fill_count)
	connect_siblings()
	draw_wireframe()

func unload_data():
	# Delete all instances
	for key in glyphs:
		if "nodes" in glyphs[key]:
			glyphs[key].nodes.symbol.queue_free()
	glyphs = {}
	used_coord_map = {}

# A function returning all possible coordinates of the truncated icosahedron we are dealing with
func all_ti_coordinate_list():
	# We need all even permutations (basically 3 shifts with triplets) for all combinations of positive/negative terms of 3 sets below
	var t1 = [0, 0.18983879552606, 0.9818152737217]
	var t2 = [0.20847820715387, 0.73564182776852, 0.6444904486331]
	var t3 = [0.3373248250886, 0.39831700267993, 0.85296865578697]
	
	var result = []
	for t in [t1, t2, t3]:
		for n3 in [t[2], -t[2]]:
			for n2 in [t[1], -t[1]]:
				var n1_group = [t[0]]
				if t[0] != 0:
					n1_group.append(-t[0])
				for n1 in n1_group:
					result.append(Vector3(n1,n2,n3))
					result.append(Vector3(n3,n1,n2))
					result.append(Vector3(n2,n3,n1))
	return result

# Adds information about 3 nearest siblings to the data def
func connect_siblings():
	for x in used_coord_map:
		for y in used_coord_map[x]:
			for z in used_coord_map[x][y]:
				var def = used_coord_map[x][y][z]
				var min_angle = 180 # To be reduced
				var candidates = []
				if !"siblings" in def:
					def.siblings = {}
				# naive crawl looking for siblings
				for x1 in used_coord_map:
					for y1 in used_coord_map[x1]:
						for z1 in used_coord_map[x1][y1]:
							if (!(x == x1 && y == y1 && z == z1)):
								var tmp_min = Vector3(x1,y1,z1).distance_squared_to (Vector3(x,y,z))
								if tmp_min < min_angle:
									min_angle = tmp_min
								if tmp_min <= 0.2:
									candidates.append(Vector3(x1,y1,z1))
				used_coord_map[x][y][z]["siblings"] = candidates
	pass

func draw_wireframe():
	var connections = {}
	var draw = $draw
	for x in used_coord_map:
		for y in used_coord_map[x]:
			for z in used_coord_map[x][y]:
				var def = used_coord_map[x][y][z]
				var key1 = str(x,y,z)
				for sibling in def.siblings:
					var key2 = str(sibling.x, sibling.y, sibling.z)
					if key2 in connections && connections[key2] == key1:
						# A shape has been drawn from sibling to current one already
						continue
					if !key1 in connections:
						connections[key1] = key2
					draw.begin(Mesh.PRIMITIVE_LINE_STRIP)
					draw.add_vertex(Vector3(x,y,z) * $"/root/Global".scale_multiplier)
					draw.add_vertex(Vector3(sibling.x,sibling.y,sibling.z) * $"/root/Global".scale_multiplier)
					draw.end()


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
		sphere.material_override = load("res://assets/sphere_material_main.tres")
		# Color the linked ones
		if "links" in glyphs[glyph_key] && glyphs[glyph_key].links.length() > 0:
			for link_key in glyphs[glyph_key].links.split(","):
				if link_key.length() > 0 && link_key != "?":
					if "nodes" in glyphs[link_key] && "sphere" in glyphs[link_key].nodes:
						glyphs[link_key].nodes.sphere.material_override = load("res://assets/sphere_material_secondary.tres")
		
	pass # Replace with function body.


func _on_glyphs_button_pressed(button_pressed):
	for key in glyphs:
		if "glyph_image" in glyphs[key].nodes:
			glyphs[key].nodes.glyph_image.visible = button_pressed;
	pass # Replace with function body.

func _on_display_button_pressed(button: Button):
	$"/root/Global".display_button_current_state = $"/root/Global".get_next_state($"/root/Global".display_button_current_state, $"/root/Global".display_button_states)
	var next_state = $"/root/Global".get_next_state($"/root/Global".display_button_current_state, $"/root/Global".display_button_states)
	
	for x in used_coord_map:
		for y in used_coord_map[x]:
			for z in used_coord_map[x][y]:
				var def = used_coord_map[x][y][z]
				if "glyph_label" in def.nodes:
					if $"/root/Global".display_button_current_state == 0: # None
						if "key" in def:
							glyphs[def["key"]].nodes.glyph_label.text = ""
					elif $"/root/Global".display_button_current_state == 1: # Name
						if "key" in def && "cartouche" in glyphs[def["key"]]:
							def.nodes.glyph_label.text = glyphs[def["key"]].cartouche
						else:
							def.nodes.glyph_label.text = ""
					elif $"/root/Global".display_button_current_state == 2: # Coords
						def.nodes.glyph_label.text = str(x, "\n", y, "\n", z)
					elif $"/root/Global".display_button_current_state == 3: # Codename
						if "key" in def && "codename" in glyphs[def["key"]]:
							def.nodes.glyph_label.text = glyphs[def["key"]].codename
						else:
							def.nodes.glyph_label.text = ""
	
func _on_scale_changed(value, slider: HSlider):
	var default_scale = $"/root/Global".scale_multiplier * Vector3(1,1,1) / 6
	for x in used_coord_map:
		for y in used_coord_map[x]:
			for z in used_coord_map[x][y]:
				var def = used_coord_map[x][y][z]
				if "sphere" in def.nodes:
					var sphere_node: MeshInstance = def.nodes.sphere
					sphere_node.scale = default_scale * value
					if "key" in def:
						# Original data
						def.nodes.glyph_label.font.size = 3 * $"/root/Global".scale_multiplier * value

func _on_wireframe_button_pressed(button_pressed):
	$draw.visible = button_pressed
	pass

func _on_fov_changed(value, slider: HSlider):
	$Camera.fov = value
	print("NEW VALUE", value)
