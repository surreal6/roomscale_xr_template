extends Node3D

signal focus_lost
signal focus_gained
signal pose_recentered
signal xr_interface_ready

@export var maximum_refresh_rate : int = 90

@onready var main_stage = $".."
@onready var environment : Environment = $"../WorldEnvironment".environment

var xr_interface : OpenXRInterface
var xr_is_focussed = false

var play_area


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
		
		xr_interface.play_area_changed.connect(_on_play_area_changed)
		
		XRServer.reference_frame_changed.connect(_on_reference_frame_changed)
		
		if TemplateUserSettings.play_area_mode == TemplateUserSettings.PlayAreaMode.ROOMSCALE:
			if xr_interface.supports_play_area_mode(XRInterface.PlayAreaMode.XR_PLAY_AREA_STAGE):
				if xr_interface.xr_play_area_mode != XRInterface.PlayAreaMode.XR_PLAY_AREA_STAGE:
					xr_interface.set_play_area_mode(XRInterface.PlayAreaMode.XR_PLAY_AREA_STAGE)
				TemplateGlobals.game_mode = TemplateGlobals.GameMode.ROOMSCALE
			else:
				print("STAGE play area mode not supported")
				# TODO
				## change play area preferences and reload
				get_tree().quit()
		
		if TemplateUserSettings.play_area_mode == TemplateUserSettings.PlayAreaMode.STANDING:
			if xr_interface.supports_play_area_mode(XRInterface.PlayAreaMode.XR_PLAY_AREA_SITTING):
				if xr_interface.xr_play_area_mode != XRInterface.PlayAreaMode.XR_PLAY_AREA_SITTING:
					xr_interface.set_play_area_mode(XRInterface.PlayAreaMode.XR_PLAY_AREA_SITTING)
				TemplateGlobals.game_mode = TemplateGlobals.GameMode.STANDING
			else:
				print("SITTING play area mode not supported")
				# TODO
				## change play area preferences and reload
				get_tree().quit()
		
		# check which play area mode is setup
		print("XR_Interface play area mode: %s" % xr_interface.xr_play_area_mode)
		var enum_value = TemplateUserSettings.PlayAreaMode.find_key(TemplateUserSettings.play_area_mode)
		print("TemplateUserSettings: play area mode set to %s" % enum_value)
		
		TemplateGlobals.xr_enabled = true
		TemplateGlobals.system_info = xr_interface.get_system_info()
		TemplateGlobals.passthrough_available = is_ar_available()
	else:
		# We couldn't start OpenXR.
		print("OpenXR not instantiated!")
		TemplateGlobals.game_mode = TemplateGlobals.GameMode.FLAT
		TemplateGlobals.xr_enabled = false
	
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


func _on_play_area_changed() -> void:
	DebugKonsole.print("XRInterface: area changed", false)
	get_play_area()


func _on_reference_frame_changed() -> void:
	#DebugKonsole.print("XRServer: reference_frame_changed", false)
	print("XRServer: reference_frame_changed")
	get_play_area()
	
	
func is_ar_available() -> bool:
	if xr_interface:
		var modes = xr_interface.get_supported_environment_blend_modes()
		if XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND in modes:
			return true
		elif XRInterface.XR_ENV_BLEND_MODE_ADDITIVE in modes:
			return true
		else:
			return false
	else:
		return false

func switch_to_ar() -> bool:
	if xr_interface:
		var modes = xr_interface.get_supported_environment_blend_modes()
		if XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND in modes:
			xr_interface.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND
		elif XRInterface.XR_ENV_BLEND_MODE_ADDITIVE in modes:
			xr_interface.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_ADDITIVE
		else:
			return false
	else:
		return false

	get_viewport().transparent_bg = true
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	return true

func switch_to_vr() -> bool:
	if xr_interface:
		var modes = xr_interface.get_supported_environment_blend_modes()
		if XRInterface.XR_ENV_BLEND_MODE_OPAQUE in modes:
			xr_interface.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_OPAQUE
		else:
			return false
	else:
		return false
	
	get_viewport().transparent_bg = false
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_BG
	return true

## DRAW PLAY AREA

func get_play_area():
	await get_tree().create_timer(1).timeout
	play_area = xr_interface.get_play_area()
	build_mesh(play_area)

func build_mesh(points):
	if points.size() > 0:
		for node in get_tree().get_nodes_in_group("play_area_mesh"):
			node.queue_free()
		var st = SurfaceTool.new()
		var labels = []
		st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
		for point in points:
			st.add_vertex(point)
			labels.append(print_to_space(point))
		st.add_vertex(points[0])
		var mesh = st.commit()
		var m = MeshInstance3D.new()
		m.name = "play_area_mesh"
		m.add_to_group("play_area_mesh")
		m.mesh = mesh
		m.position.y += 0.001
		main_stage.add_child(m)
		for label in labels:
			m.add_child(label)
		calculate_boundary_dimensions(points)
	else:
		DebugKonsole.print("no points in play area", false)


func calculate_boundary_dimensions(points):
	var minX : float = 0.0
	var minZ : float = 0.0
	var maxX : float = 0.0
	var maxZ : float = 0.0
	if points.size() == 4:
		for point in points:
			print("----", point)
			print(minX, " ", maxX, " ", minZ, " ", maxZ)
			if point.x > maxX : maxX = point.x
			if point.x < minX : minX = point.x
			if point.z > maxZ : maxZ = point.z
			if point.z < minZ : minZ = point.z
	var sizeX = abs(minX) + maxX
	var sizeZ = abs(minZ) + maxZ
	DebugKonsole.print("Play area is %s x %s meters" % [snapped(sizeX, 0.01), snapped(sizeZ, 0.01)], false)
				

func print_to_space(position):
	var label = Label3D.new()
	label.text = "%s" % position
	label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	label.no_depth_test = true
	label.font_size = 8
	label.outline_size = 0
	label.position = position
	label.modulate = Color("#000")
	return label
