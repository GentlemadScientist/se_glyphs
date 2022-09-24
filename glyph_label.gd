extends Label3D

func _process(delta):
	if self.visible:
		var cam_basis = get_viewport().get_camera().get_global_transform().basis
		
		var dir = get_viewport().get_camera().get_global_transform().origin - get_parent().transform.origin
		dir = dir.normalized() * $"/root/Global".scale_multiplier / 4
		
		self.transform.origin = dir
