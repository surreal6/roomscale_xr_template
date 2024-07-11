extends TabContainer

signal player_height_changed(new_height)

@onready var snap_turning_button = $Input/InputVBox/SnapTurning/SnapTurningCB
@onready var haptics_scale_slider = $Input/InputVBox/HapticsScale/HapticsScaleSlider
@onready var y_deadzone_slider = $Input/InputVBox/yAxisDeadZone/yAxisDeadZoneSlider
@onready var x_deadzone_slider = $Input/InputVBox/xAxisDeadZone/xAxisDeadZoneSlider
@onready var player_height_slider = $Player/PlayerVBox/PlayerHeight/PlayerHeightSlider
@onready var play_area_mode_button = $Options/OptionsVBox/Options/PlayAreaMode

func _update():
	# Input
	snap_turning_button.button_pressed = AGUserSettings.snap_turning
	y_deadzone_slider.value = AGUserSettings.y_axis_dead_zone
	x_deadzone_slider.value = AGUserSettings.x_axis_dead_zone
	haptics_scale_slider.value = AGUserSettings.haptics_scale

	# Player
	player_height_slider.value = AGUserSettings.player_height

	#Options
	play_area_mode_button.selected = AGUserSettings.play_area_mode


# Called when the node enters the scene tree for the first time.
func _ready():
	if AGUserSettings:
		_update()
	else:
		$Save/Button.disabled = true


func _on_Save_pressed():
	if AGUserSettings:
		# Save
		AGUserSettings.save()


func _on_Reset_pressed():
	if AGUserSettings:
		AGUserSettings.reset_to_defaults()
		_update()
		emit_signal("player_height_changed", AGUserSettings.player_height)


# Input settings changed
func _on_SnapTurningCB_pressed():
	AGUserSettings.snap_turning = snap_turning_button.button_pressed


# Player settings changed
func _on_PlayerHeightSlider_drag_ended(_value_changed):
	AGUserSettings.player_height = player_height_slider.value
	emit_signal("player_height_changed", AGUserSettings.player_height)


func _on_y_axis_dead_zone_slider_value_changed(value):
	AGUserSettings.y_axis_dead_zone = y_deadzone_slider.value


func _on_x_axis_dead_zone_slider_value_changed(value):
	AGUserSettings.x_axis_dead_zone = x_deadzone_slider.value


func _on_haptics_scale_slider_value_changed(value):
	AGUserSettings.haptics_scale = value


func _on_play_area_mode_item_selected(index: int) -> void:
	var enum_value = AGUserSettings.PlayAreaMode.find_key(index)
	AGUserSettings.play_area_mode = AGUserSettings.PlayAreaMode[enum_value]
