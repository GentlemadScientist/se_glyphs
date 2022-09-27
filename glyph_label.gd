extends Label3D

func _process(delta):
	if self.visible:
		var cam_basis = get_viewport().get_camera().get_global_transform().basis
		
		var sphere: MeshInstance = get_parent()
		var mesh: SphereMesh = sphere.mesh
		
		var dir = get_viewport().get_camera().get_global_transform().origin - sphere.get_parent().transform.origin
		dir = dir.normalized() * (mesh.radius + $"/root/Global".scale_multiplier / 22)
		
		self.transform.origin = dir
