extends Node3D

signal player_height_changed

var offset = false

@export var xr_camera : XRCamera3D

func _ready():
	$menuViewport2Din3D.connect_scene_signal("player_height_changed", on_player_height_changed)

func on_player_height_changed(new_height):
	player_height_changed.emit(new_height)

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
