extends TabContainer

signal player_height_changed(new_height)
signal change_play_area_mode

@onready var snap_turning_button = $Input/InputVBox/SnapTurning/SnapTurningCB
@onready var haptics_scale_slider = $Input/InputVBox/HapticsScale/HapticsScaleSlider
@onready var y_deadzone_slider = $Input/InputVBox/yAxisDeadZone/yAxisDeadZoneSlider
@onready var x_deadzone_slider = $Input/InputVBox/xAxisDeadZone/xAxisDeadZoneSlider
@onready var player_height_slider = $Player/PlayerVBox/PlayerHeight/PlayerHeightSlider
@onready var play_area_mode_button = $Options/OptionsVBox/PlayAreaMode/PlayAreaModeSelector
@onready var passthrough_button = $Options/OptionsVBox/Passthrough/PassthroughCB

func _update():
	# Input
	snap_turning_button.button_pressed = XRToolsUserSettings.snap_turning
	y_deadzone_slider.value = XRToolsUserSettings.y_axis_dead_zone
	x_deadzone_slider.value = XRToolsUserSettings.x_axis_dead_zone
	haptics_scale_slider.value = XRToolsUserSettings.haptics_scale

	# Player
	player_height_slider.value = XRToolsUserSettings.player_height

	#Options
	play_area_mode_button.selected = TemplateUserSettings.play_area_mode
	passthrough_button.button_pressed = TemplateUserSettings.passthrough
	if !TemplateUserSettings.passthrough_available:
		$Options/OptionsVBox/Passthrough.hide()


# Called when the node enters the scene tree for the first time.
func _ready():
	var webxr_interface = XRServer.find_interface("WebXR")
	set_tab_hidden(2, webxr_interface == null)
	set_tab_hidden(0, !TemplateUserSettings.game_mode == 1)
	set_tab_hidden(1, !TemplateUserSettings.game_mode == 1)
	
	if !TemplateUserSettings.xr_enabled:
		$Options/OptionsVBox/PlayAreaMode.hide()
		$Options/OptionsVBox/Passthrough.hide()

	if TemplateUserSettings and XRToolsUserSettings:
		_update()
	else:
		$Save/Button.disabled = true


func _on_Save_pressed():
	if TemplateUserSettings:
		# Save
		TemplateUserSettings.save()

	if XRToolsUserSettings:
		# Save
		XRToolsUserSettings.save()


func _on_Reset_pressed():
	if TemplateUserSettings:
		TemplateUserSettings.reset_to_defaults()
		_update()
	
	if XRToolsUserSettings:
		XRToolsUserSettings.reset_to_defaults()
		_update()
		player_height_changed.emit(XRToolsUserSettings.player_height)


# Input settings changed
func _on_SnapTurningCB_pressed():
	XRToolsUserSettings.snap_turning = snap_turning_button.button_pressed


# Player settings changed
func _on_PlayerHeightSlider_drag_ended(_value_changed):
	XRToolsUserSettings.player_height = player_height_slider.value
	player_height_changed.emit(XRToolsUserSettings.player_height)


func _on_web_xr_primary_item_selected(index: int) -> void:
	XRToolsUserSettings.webxr_primary = index


func _on_y_axis_dead_zone_slider_value_changed(value):
	XRToolsUserSettings.y_axis_dead_zone = y_deadzone_slider.value


func _on_x_axis_dead_zone_slider_value_changed(value):
	XRToolsUserSettings.x_axis_dead_zone = x_deadzone_slider.value


func _on_haptics_scale_slider_value_changed(value):
	XRToolsUserSettings.haptics_scale = value


func _on_play_area_mode_item_selected(index: int) -> void:
	var enum_value = TemplateUserSettings.PlayAreaMode.find_key(index)
	TemplateUserSettings.play_area_mode = TemplateUserSettings.PlayAreaMode[enum_value]
	get_tree().reload_current_scene()

func _on_passthrough_cb_pressed(value):
	TemplateUserSettings.passthrough = value
