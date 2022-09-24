extends Sprite3D

func _process(delta):
	if self.visible:
		var dir = Vector3() # Relative position of the sprite related to the sphere
		var cam_basis = get_viewport().get_camera().get_global_transform().basis
		
		dir += cam_basis[0] # One to the right
		dir += cam_basis[1] # One to the top
		dir += cam_basis[2] # One towards the camera
		dir = dir.normalized() * $"/root/Global".scale_multiplier / 4
		self.transform.origin = dir
