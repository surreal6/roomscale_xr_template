extends Node

enum GameMode {
	ROOMSCALE,
	STANDING,
	FLAT
}

@export var xr_enabled : bool = true
@export var system_info : Dictionary
@export var menu_active = false
@export var passthrough_available : bool = true
@export var game_mode : GameMode = GameMode.ROOMSCALE
@export var first_reference_frame_setup = true

# Vector2(x_axis, z_axis) in meters
@export var play_area_size : Vector2 = Vector2.ZERO
