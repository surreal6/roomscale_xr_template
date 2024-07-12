extends Node3D

const PlayerRoomScale = preload("res://assets/players/player_roomscale.tscn")
const PlayerStanding = preload("res://assets/players/player_standing.tscn")
const PlayerFlat = preload("res://assets/players/player_flat.tscn")
const MenuXR = preload("res://ag_user_settings/menu_xr.tscn") 

var player : Node3D
var menuXR : Node3D
var menuXR_active = false

func _ready():
	$startXr.connect("focus_gained", on_focus_gained)
	$startXr.connect("xr_interface_ready", on_xr_interface_ready)


func on_focus_gained():
	print("FOCUS___________________")


func on_xr_interface_ready():
	match $startXr.game_mode:
		0: 
			player = PlayerRoomScale.instantiate()
			add_child(player)
			$UserSettingsUI.queue_free()
		1:
			player = PlayerStanding.instantiate()
			player.position.y += 2
			add_child(player)
			$UserSettingsUI.queue_free()
		2:
			player = PlayerFlat.instantiate()
			player.position.y += 2
			add_child(player)
			$UserSettingsUI.hide_xr_options()
			player.connect("toggle_menu", on_toggle_flat_menu)

	match $startXr.game_mode:
		0, 1:
			player.connect("toggle_menu", on_toggle_vr_menu)
			DebugKonsole.setup_fixed_konsole(player.get_node("XRCamera3D"))
			if AGUserSettings.system_info["XRRuntimeName"] == "SteamVR/OpenXR":
				DebugKonsole.print(AGUserSettings.system_info["XRRuntimeName"])
			if AGUserSettings.system_info["XRRuntimeName"] == "Oculus":
				DebugKonsole.print(AGUserSettings.system_info["XRRuntimeName"])
				player.setup_for_oculus_controller()


func on_toggle_vr_menu():
	if menuXR_active:
		menuXR_active = false
		menuXR.queue_free()
		player.hide_pointer()
	else:
		var camera = player.get_node("XRCamera3D")
		menuXR_active = true
		menuXR = MenuXR.instantiate()
		menuXR.global_rotation.y = camera.global_rotation.y
		menuXR.xr_camera = camera
		add_child(menuXR)
		player.show_pointer()

func on_toggle_flat_menu():
	$UserSettingsUI.visible = !$UserSettingsUI.visible
