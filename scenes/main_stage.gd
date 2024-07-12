extends Node3D

const PlayerRoomScale = preload("res://assets/players/player_roomscale.tscn")
const PlayerStanding = preload("res://assets/players/player_standing.tscn")
const PlayerFlat = preload("res://assets/players/player_flat.tscn")

@onready var menu_pivot = $"menuPivot"

var player : Node3D


func _ready():
	$startXr.connect("focus_gained", on_focus_gained)
	$startXr.connect("xr_interface_ready", on_xr_interface_ready)


#func _process(delta):
	#pass


func on_focus_gained():
	print("FOCUS___________________")


func on_xr_interface_ready():
	match $startXr.game_mode:
		0: 
			player = PlayerRoomScale.instantiate()
			add_child(player)
			menu_pivot.xr_camera = player.get_node("XRCamera3D")
			$UserSettingsUI.queue_free()
		1:
			player = PlayerStanding.instantiate()
			player.position.y += 2
			add_child(player)
			menu_pivot.xr_camera = player.get_node("XRCamera3D")
			$UserSettingsUI.queue_free()
		2:
			player = PlayerFlat.instantiate()
			player.position.y += 2
			add_child(player)
			$menuPivot.queue_free()
			$UserSettingsUI.hide_xr_options()
			player.connect("toggle_menu", on_toggle_flat_menu)

	match $startXr.game_mode:
		0, 1:
			player.connect("toggle_menu", on_toggle_vr_menu)
			DebugKonsole.setup_fixed_konsole(player.get_node("XRCamera3D"))
			if AGUserSettings.system_info["XRRuntimeName"] == "SteamVR/OpenXR":
				DebugKonsole.print(AGUserSettings.system_info["XRRuntimeName"])
			if AGUserSettings.system_info["XRRuntimeName"] == "SteamVR/OpenXR":
				DebugKonsole.print(AGUserSettings.system_info["XRRuntimeName"])

func on_toggle_vr_menu():
	$menuPivot.visible = !$menuPivot.visible

func on_toggle_flat_menu():
	$UserSettingsUI.visible = !$UserSettingsUI.visible
