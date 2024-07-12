extends Node3D

var offset = false

@export var xr_camera : XRCamera3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if xr_camera:
		global_position = xr_camera.global_position
		if abs(global_rotation.y - xr_camera.global_rotation.y) > 0.1:
			offset = true
	
	if offset == true:		
		global_rotation.y = lerp_angle(global_rotation.y, xr_camera.global_rotation.y, delta)
		if abs(global_rotation.y - xr_camera.global_rotation.y) < 0.05:
			offset = false
