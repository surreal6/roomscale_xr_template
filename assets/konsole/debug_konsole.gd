extends Node

signal add_klabel

const konsole_label : PackedScene = preload("res://assets/konsole/konsole_label_3d.tscn")

@export var fixed_konsole : Node3D
@export var float_konsole : Node3D

func setup_fixed_konsole(camera_node):
	var look_at_node = Node3D.new()
	var float_node = Node3D.new()
	camera_node.add_child(look_at_node)
	camera_node.add_child(float_node)
	look_at_node.position.z = -2
	float_node.position.z = -1.5
	fixed_konsole = look_at_node
	float_konsole = float_node
	DebugKonsole.print("fixed_konsole y: %s" % fixed_konsole.global_position.y)
	DebugKonsole.print("float_konsole y: %s" % float_konsole.global_position.y)

func print(msg, fixed = true, delay = 5):
	print("k$: " , msg)
	if AGUserSettings.xr_enabled:
		add_label(msg, fixed, delay)

func move_up_all_children(konsole_parent, v_size = 0.05):
	for node in konsole_parent.get_children():
		node.position.y += v_size

func add_label(msg, fixed, delay):
	var kLabel = konsole_label.instantiate()
	kLabel.msg = msg
	kLabel.fixed = fixed
	kLabel.delay = delay
	if fixed :
		move_up_all_children(fixed_konsole)
		kLabel.add_to_group("fixed_klabels")
		fixed_konsole.add_child(kLabel)
		add_klabel.emit(msg, false, 10)
	else:
		kLabel.add_to_group("float_klabels")
		move_up_all_children(float_konsole)
		float_konsole.add_child(kLabel)
	kLabel.global_position = fixed_konsole.global_position
	if !fixed:
		kLabel.global_position.y = 1

	kLabel.connect("autodestroy_label", on_label_autodestroy)

func on_label_autodestroy(kLabel):
	kLabel.disconnect("autodestroy_label", on_label_autodestroy)
	kLabel.queue_free()
