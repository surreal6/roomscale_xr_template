extends XROrigin3D

var tween : Tween
var active_hand : XRController3D

@export var menu : Node3D

@onready var left_hand = $LeftHand
@onready var right_hand = $RightHand
@onready var left_hand_pointer = $LeftHand/Pointer
@onready var right_hand_pointer = $RightHand/Pointer

func _ready():
	left_hand_pointer.visible = false
	right_hand_pointer.visible = true
	active_hand = right_hand

###
## HANDS ENERGY POINTER
###

# Callback for our tween to set the energy level on our active pointer.
func _update_energy(new_value : float):
	var pointer = active_hand.get_node("Pointer")
	var material : ShaderMaterial = pointer.material_override
	if material:
		material.set_shader_parameter("energy", new_value)


# Start our tween to show a pulse on our click.
func _do_tween_energy():
	if tween:
		tween.kill()

	tween = create_tween()
	tween.tween_method(_update_energy, 5.0, 1.0, 0.5)

func _on_left_hand_button_pressed(action_name):
	if action_name == "trigger_click":
		# Make the left hand the active pointer.
		left_hand_pointer.visible = true
		right_hand_pointer.visible = false

		active_hand = left_hand
		#menu.controller = active_hand

		# Make a visual pulse.
		_do_tween_energy()

		# And make us feel it.
		# Note: frequence == 0.0 => XR runtime chooses optimal frequency for a given controller.
		active_hand.trigger_haptic_pulse("haptic", 0.0, 1.0, 0.5, 0.0)
	if action_name == "ax_button":
		menu.visible = !menu.visible

func _on_right_hand_button_pressed(action_name):
	if action_name == "trigger_click":
		# Make the right hand the active pointer.
		left_hand_pointer.visible = false
		right_hand_pointer.visible = true

		active_hand = right_hand
		#menu.controller = active_hand

		# Make a visual pulse.
		_do_tween_energy()

		# And make us feel it.
		# Note: frequence == 0.0 => XR runtime chooses optimal frequency for a given controller.
		active_hand.trigger_haptic_pulse("haptic", 0.0, 1.0, 0.5, 0.0)
	if action_name == "ax_button":
		menu.visible = !menu.visible
