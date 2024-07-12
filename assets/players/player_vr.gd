extends XROrigin3D

signal toggle_menu

@export var menu : Node3D

@onready var left_hand = $LeftHand
@onready var right_hand = $RightHand
@onready var left_hand_pointer = $LeftHand/FunctionPointer
@onready var right_hand_pointer = $RightHand/FunctionPointer

var active_hand : XRController3D
var oculus = false
var active_pointer = false

func _ready():
	left_hand_pointer.enabled = false
	left_hand_pointer.visible = false
	right_hand_pointer.visible = true
	right_hand_pointer.enabled = true
	
	active_hand = right_hand


func setup_for_oculus_controller():
	left_hand.pose = "grip"
	left_hand_pointer.rotation_degrees.x = -50
	left_hand_pointer.y_offset = 0.02
	right_hand.pose = "grip"
	right_hand_pointer.rotation_degrees.x = -50
	right_hand_pointer.y_offset = 0.02


func _on_left_hand_button_pressed(action_name):
	if action_name == "trigger_click" and active_pointer:
		# Make the left hand the active pointer.
		left_hand_pointer.enabled = true
		left_hand_pointer.visible = true
		right_hand_pointer.visible = false
		right_hand_pointer.enabled = false

		active_hand = left_hand

		# And make us feel it.
		# Note: frequence == 0.0 => XR runtime chooses optimal frequency for a given controller.
		active_hand.trigger_haptic_pulse("haptic", 0.0, 1.0, 0.5, 0.0)

	if action_name == "ax_button":
		toggle_menu.emit()

func _on_right_hand_button_pressed(action_name):
	if action_name == "trigger_click" and active_pointer:
		# Make the right hand the active pointer.
		left_hand_pointer.enabled = false
		left_hand_pointer.visible = false
		right_hand_pointer.visible = true
		right_hand_pointer.enabled = true

		active_hand = right_hand

		# And make us feel it.
		# Note: frequence == 0.0 => XR runtime chooses optimal frequency for a given controller.
		active_hand.trigger_haptic_pulse("haptic", 0.0, 1.0, 0.5, 0.0)

	if action_name == "ax_button":
		toggle_menu.emit()

func hide_pointer():
	left_hand_pointer.enabled = false
	left_hand_pointer.visible = false
	right_hand_pointer.visible = false
	right_hand_pointer.enabled = false
	
	active_pointer = false

func show_pointer():
	if active_hand == right_hand:
		left_hand_pointer.enabled = false
		left_hand_pointer.visible = false
		right_hand_pointer.visible = true
		right_hand_pointer.enabled = true
	else:
		left_hand_pointer.enabled = true
		left_hand_pointer.visible = true
		right_hand_pointer.visible = false
		right_hand_pointer.enabled = false
	
	active_pointer = true
