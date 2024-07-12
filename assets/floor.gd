extends StaticBody3D

@export var show_floor : bool = true: set = set_show_floor

func set_show_floor(new_value):
	show_floor = new_value
	if show_floor:
		$floorInterior.show()
	else:
		$floorInterior.hide()
