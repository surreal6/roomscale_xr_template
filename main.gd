extends Node3D

var xr_interface : XRInterface

var play_area

@onready var environment : Environment = $WorldEnvironment.environment
@onready var konsole : konsole = $XROrigin3D/konsole

func _ready():
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print_to_konsole("OpenXR initialised succesfully")
		#Turn off v-sync!
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		#Change our main viewport to output to the HMD
		get_viewport().use_xr = true
		#set our default value for our AR toggle
		$ARToggle.on = xr_interface.environment_blend_mode != XRInterface.XR_ENV_BLEND_MODE_OPAQUE
		
		print_to_konsole("support STAGE: %s" % xr_interface.supports_play_area_mode(XRInterface.PlayAreaMode.XR_PLAY_AREA_STAGE))
		print_to_konsole("support ROOMSCALE: %s" % xr_interface.supports_play_area_mode(XRInterface.PlayAreaMode.XR_PLAY_AREA_ROOMSCALE))
		
		if xr_interface.supports_play_area_mode(XRInterface.PlayAreaMode.XR_PLAY_AREA_STAGE):
			#xr_interface.set_play_area_mode(XRInterface.PlayAreaMode.XR_PLAY_AREA_STAGE)
			xr_interface.xr_play_area_mode = XRInterface.PlayAreaMode.XR_PLAY_AREA_STAGE
		else:
			#xr_interface.set_play_area_mode(XRInterface.PlayAreaMode.XR_PLAY_AREA_ROOMSCALE)
			xr_interface.xr_play_area_mode = XRInterface.PlayAreaMode.XR_PLAY_AREA_ROOMSCALE
		
		print_to_konsole("play area mode: %s" % xr_interface.xr_play_area_mode)
		
		get_play_area()
		
		
		print_to_konsole("name: %s" % xr_interface.get_name())
		print_to_konsole("system info: %s" % xr_interface.get_system_info())
		print_to_konsole("capabilities: %s" % xr_interface.get_capabilities())
		print_to_konsole("tracking status: %s" % xr_interface.get_tracking_status())	
		print_to_konsole("ar is anchor detection enabled: %s" % xr_interface.ar_is_anchor_detection_enabled)
		
		print_to_konsole("oh, lala", false, 10)

		
		#xr_interface.trigger_haptic_pulse($XROrigin3D/LeftHand,)
		
		# Connect the OpenXR events
		xr_interface.connect("session_begun", _on_openxr_session_begun)
		xr_interface.connect("session_visible", _on_openxr_session_visible)
		xr_interface.connect("session_focussed", _on_openxr_session_focussed)
		xr_interface.connect("session_loss_pending", _on_openxr_session_loss_pending)
		

		# not working
		xr_interface.connect("play_area_changed", _on_play_area_changed)
		
		XRServer.connect("reference_frame_changed", _on_reference_frame_changed)
		
	else:
		print("OpenXR not initialized, please check if your headset is connected")
	
	konsole.connect("konsole_ready", on_konsole_ready)
	konsole.connect("add_klabel", on_add_klabel)

func _on_reference_frame_changed():
	print_to_konsole("XRServer: reference_frame_changed")
	get_play_area()

func _on_openxr_session_begun():
	print_to_konsole("XRInterface: openxr_session_begun")

func _on_openxr_session_visible():
	print_to_konsole("XRInterface: openxr_session_visible")

func _on_openxr_session_focussed():
	print_to_konsole("XRInterface: openxr_session_focussed")
	get_play_area()

func _on_openxr_session_loss_pending():
	print_to_konsole("XRInterface: openxr_session_loss_pending")

func _on_play_area_changed(args):
	print_to_konsole("XRInterface: area changed")
	get_play_area()

func get_play_area():
	await get_tree().create_timer(1).timeout
	play_area = xr_interface.get_play_area()
	build_mesh(play_area)

func on_add_klabel(msg, fixed, delay):
	print_to_konsole(msg, fixed, delay)

func on_konsole_ready(_msg):
	print_to_konsole("konsole_ready", true, 30)

func switch_to_ar() -> bool:
	if xr_interface:
		var modes = xr_interface.get_supported_environment_blend_modes()
		print(modes)
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
		m.add_to_group("play_area_mesh")
		m.mesh = mesh
		self.add_child(m)
		for label in labels:
			m.add_child(label)
		print_to_konsole("build_mesh")

func _on_detector_toggled(is_on):
	print_to_konsole("toggle_passthrough", false, 10)
	if is_on:
		if !switch_to_ar():
			$ARToggle.on = false
	else:
		if !switch_to_vr():
			$ARToggle.on = true

func print_to_konsole(msg, fixed = true, delay = 5):
	print("ptk: " , msg)
	konsole.add_label(msg, fixed, delay)

func print_to_space(position):
	var label = Label3D.new()
	label.text = "%s" % position
	label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	label.no_depth_test = true
	label.font_size = 8
	label.outline_size = 0
	label.position = position
	return label
