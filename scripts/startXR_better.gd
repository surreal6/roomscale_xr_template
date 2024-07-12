extends Node3D

signal focus_lost
signal focus_gained
signal pose_recentered
signal xr_interface_ready

enum GameMode {
	ROOMSCALE,
	STANDING,
	FLAT
}

@export var maximum_refresh_rate : int = 90
@export var game_mode : GameMode = GameMode.ROOMSCALE

var xr_interface : OpenXRInterface
var xr_is_focussed = false

# Called when the node enters the scene tree for the first time.
func _ready():
	# waiting for xr_interface to finish auto initialization
	# also allow mainStage to connect to ready signal
	await get_tree().create_timer(0.1).timeout

	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR instantiated successfully.")
		var vp : Viewport = get_viewport()

		# Enable XR on our viewport
		vp.use_xr = true

		# Make sure v-sync is off, v-sync is handled by OpenXR
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

		# Enable VRS if we're using the mobile or forward+ renderer
		if RenderingServer.get_rendering_device():
			vp.vrs_mode = Viewport.VRS_XR
		elif int(ProjectSettings.get_setting("xr/openxr/foveation_level")) == 0:
			push_warning("OpenXR: Recommend setting Foveation level to High in Project Settings")

		# Connect the OpenXR events
		xr_interface.session_begun.connect(_on_openxr_session_begun)
		xr_interface.session_visible.connect(_on_openxr_visible_state)
		xr_interface.session_focussed.connect(_on_openxr_focused_state)
		xr_interface.session_stopping.connect(_on_openxr_stopping)
		xr_interface.pose_recentered.connect(_on_openxr_pose_recentered)
		
		if AGUserSettings.play_area_mode == AGUserSettings.PlayAreaMode.ROOMSCALE:
			if xr_interface.supports_play_area_mode(XRInterface.PlayAreaMode.XR_PLAY_AREA_STAGE):
				if xr_interface.xr_play_area_mode != XRInterface.PlayAreaMode.XR_PLAY_AREA_STAGE:
					xr_interface.set_play_area_mode(XRInterface.PlayAreaMode.XR_PLAY_AREA_STAGE)
				game_mode = GameMode.ROOMSCALE
			else:
				print("STAGE play area mode not supported")
				# TODO
				## change play area preferences and reload
				get_tree().quit()
		
		if AGUserSettings.play_area_mode == AGUserSettings.PlayAreaMode.STANDING:
			if xr_interface.supports_play_area_mode(XRInterface.PlayAreaMode.XR_PLAY_AREA_SITTING):
				if xr_interface.xr_play_area_mode != XRInterface.PlayAreaMode.XR_PLAY_AREA_SITTING:
					xr_interface.set_play_area_mode(XRInterface.PlayAreaMode.XR_PLAY_AREA_SITTING)
				game_mode = GameMode.STANDING
			else:
				print("SITTING play area mode not supported")
				# TODO
				## change play area preferences and reload
				get_tree().quit()
		
		# check which play area mode is setup
		print("XR_Interface play area mode: %s" % xr_interface.xr_play_area_mode)
		var enum_value = AGUserSettings.PlayAreaMode.find_key(AGUserSettings.play_area_mode)
		print("AGUserSettings: play area mode set to %s" % enum_value)
		
		AGUserSettings.xr_enabled = true
		AGUserSettings.system_info = xr_interface.get_system_info()
		print("AGUserSettings: system info: \n%s" % AGUserSettings.system_info)
		
	else:
		# We couldn't start OpenXR.
		print("OpenXR not instantiated!")
		game_mode = GameMode.FLAT
		AGUserSettings.xr_enabled = false
	
	xr_interface_ready.emit()

# Handle OpenXR session ready
func _on_openxr_session_begun() -> void:
	# Get the reported refresh rate
	var current_refresh_rate = xr_interface.get_display_refresh_rate()
	if current_refresh_rate > 0:
		print("OpenXR: Refresh rate reported as ", str(current_refresh_rate))
	else:
		print("OpenXR: No refresh rate given by XR runtime")

	# See if we have a better refresh rate available
	var new_rate = current_refresh_rate
	var available_rates : Array = xr_interface.get_available_display_refresh_rates()
	if available_rates.size() == 0:
		print("OpenXR: Target does not support refresh rate extension")
	elif available_rates.size() == 1:
		# Only one available, so use it
		new_rate = available_rates[0]
	else:
		for rate in available_rates:
			if rate > new_rate and rate <= maximum_refresh_rate:
				new_rate = rate

	# Did we find a better rate?
	if current_refresh_rate != new_rate:
		print("OpenXR: Setting refresh rate to ", str(new_rate))
		xr_interface.set_display_refresh_rate(new_rate)
		current_refresh_rate = new_rate

	# Now match our physics rate
	Engine.physics_ticks_per_second = current_refresh_rate

# Handle OpenXR visible state
func _on_openxr_visible_state() -> void:
	# We always pass this state at startup,
	# but the second time we get this it means our player took off their headset
	if xr_is_focussed:
		print("OpenXR lost focus")

		xr_is_focussed = false

		# pause our game
		process_mode = Node.PROCESS_MODE_DISABLED

		emit_signal("focus_lost")

# Handle OpenXR focused state
func _on_openxr_focused_state() -> void:
	print("OpenXR gained focus")
	xr_is_focussed = true

	# unpause our game
	process_mode = Node.PROCESS_MODE_INHERIT

	emit_signal("focus_gained")

# Handle OpenXR stopping state
func _on_openxr_stopping() -> void:
	# Our session is being stopped.
	print("OpenXR is stopping")

# Handle OpenXR pose recentered signal
func _on_openxr_pose_recentered() -> void:
	# User recentered view, we have to react to this by recentering the view.
	# This is game implementation dependent.
	print("OpenXR is recentering")
	emit_signal("pose_recentered")
