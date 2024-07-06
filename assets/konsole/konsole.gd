extends Node3D
class_name konsole

@export var fixed_labels : Array = []

signal konsole_ready
signal add_klabel

const konsole_label : PackedScene = preload("res://assets/konsole/konsole_label_3d.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	konsole_ready.emit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var fixedLabels = get_tree().get_nodes_in_group("fixed_klabels")
	var floatLabels = get_tree().get_nodes_in_group("float_klabels")

func move_up_all_children(konsole_parent, v_size = 0.1):
	for node in konsole_parent.get_children():
		node.position.y += v_size

func add_label(msg, fixed, delay):
	var kLabel = konsole_label.instantiate()
	kLabel.msg = msg
	kLabel.fixed = fixed
	kLabel.delay = delay
	if fixed :
		move_up_all_children($"../XRCamera3D/look_at")
		kLabel.add_to_group("fixed_klabels")
		$"../XRCamera3D/look_at".add_child(kLabel)
		add_klabel.emit(msg, false, 10)
	else:
		kLabel.add_to_group("float_klabels")
		move_up_all_children($konsole_float)
		$konsole_float.add_child(kLabel)
	kLabel.global_position = $"../XRCamera3D/look_at".global_position
	if !fixed:
		kLabel.global_position.y = 1

	kLabel.connect("autodestroy_label", on_label_autodestroy)

func on_label_autodestroy(kLabel):
	kLabel.disconnect("autodestroy_label", on_label_autodestroy)
	kLabel.queue_free()
	
