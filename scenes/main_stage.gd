extends Node3D

const PlayerRoomScale = preload("res://assets/players/player_roomscale.tscn")
const PlayerStanding = preload("res://assets/players/player_standing.tscn")
const PlayerFlat = preload("res://assets/players/player_flat.tscn")
const MenuXR = preload("res://ag_user_settings/menu_xr.tscn")
const MenuFlat = preload("res://ag_user_settings/ag_user_settings_ui.tscn")

var player : Node3D
var menu_instance : Node
var menu_active = false

#var counter = 0

func _ready():
	$startXr.connect("focus_gained", on_focus_gained)
	$startXr.connect("xr_interface_ready", on_xr_interface_ready)
	AGUserSettings.connect("switch_to_ar", on_switch_to_ar)
	AGUserSettings.connect("switch_to_vr", on_switch_to_vr)

#
#func _process(delta):
	#counter += delta
	#if counter > 5:
		#var cam_height = str(player.get_node("XRCamera3D").global_position.y)
		#DebugKonsole.print(cam_height, false)
		#counter = 0


func on_focus_gained():
	print("FOCUS___________________")


func on_switch_to_ar():
	$startXr.switch_to_ar()
	$floor.show_floor = false


func on_switch_to_vr():
	$startXr.switch_to_vr()
	$floor.show_floor = true


func on_xr_interface_ready():
	match AGUserSettings.game_mode:
		0: 
			player = PlayerRoomScale.instantiate()
			add_child(player)
			$startXr.get_play_area()
		1:
			player = PlayerStanding.instantiate()
			player.position.y += 2
			add_child(player)
			# wait for player to touch floor
			await get_tree().create_timer(2).timeout
		2:
			player = PlayerFlat.instantiate()
			player.position.y += 2
			add_child(player)
			player.connect("toggle_menu", on_toggle_flat_menu)

	match AGUserSettings.game_mode:
		0, 1:
			player.connect("toggle_menu", on_toggle_vr_menu)
			DebugKonsole.setup_fixed_konsole(player.get_node("XRCamera3D"))
			if AGUserSettings.system_info["XRRuntimeName"] == "SteamVR/OpenXR":
				DebugKonsole.print(AGUserSettings.system_info["XRRuntimeName"], false)
			if AGUserSettings.system_info["XRRuntimeName"] == "Oculus":
				DebugKonsole.print(AGUserSettings.system_info["XRRuntimeName"], false)
				player.setup_for_oculus_controller()


func on_toggle_vr_menu():
	if menu_active:
		menu_active = false
		menu_instance.queue_free()
		player.hide_pointer()
	else:
		var camera = player.get_node("XRCamera3D")
		menu_active = true
		menu_instance = MenuXR.instantiate()
		menu_instance.global_rotation.y = camera.global_rotation.y
		menu_instance.xr_camera = camera
		menu_instance.connect("player_height_changed", _on_settings_ui_player_height_changed)
		add_child(menu_instance)
		player.show_pointer()


func on_toggle_flat_menu():
	if menu_active:
		menu_active = false
		menu_instance.queue_free()
	else:
		menu_active = true
		menu_instance = MenuFlat.instantiate()
		add_child(menu_instance)	


func _on_settings_ui_player_height_changed(new_height):
	DebugKonsole.print("player height changed %s" % new_height, false)
	match AGUserSettings.game_mode:
		1:
			player.get_node("PlayerBody").calibrate_player_height()
