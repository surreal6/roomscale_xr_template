extends Node

enum PlayAreaMode {
	ROOMSCALE,
	STANDING,
}

@export_group("Input")

## User setting for snap-turn
@export var snap_turning : bool = true

## User setting for y axis dead zone
@export var y_axis_dead_zone : float = 0.1

## User setting for y axis dead zone
@export var x_axis_dead_zone : float = 0.2

## Used to control rumble like volume
@export_range(0.0, 1.0, 0.05) var haptics_scale := 1.0

@export_group("Player")

## User setting for player height
@export var player_height : float = 1.85: set = set_player_height

@export_group("Options")

@export var play_area_mode : PlayAreaMode = PlayAreaMode.STANDING: set = set_play_area_mode

## Settings file name to persist user settings
var settings_file_name : String = "user://ag_user_settings.json"


# Called when the node enters the scene tree for the first time.
func _ready():
	_load()


## Reset to default values
func reset_to_defaults() -> void:
	# Reset to defaults.
	# Where applicable we obtain our project settings
	snap_turning = XRTools.get_default_snap_turning()
	y_axis_dead_zone = XRTools.get_y_axis_dead_zone()
	x_axis_dead_zone = XRTools.get_x_axis_dead_zone()
	player_height = XRTools.get_player_standard_height()
	haptics_scale = XRToolsRumbleManager.get_default_haptics_scale()
	play_area_mode = PlayAreaMode.STANDING


## Set the player height property
func set_player_height(new_value : float) -> void:
	player_height = clamp(new_value, 1.0, 2.5)


func set_play_area_mode(new_value : PlayAreaMode) -> void:
	print("AG_USER set play area mode to %s" % new_value)
	if new_value != play_area_mode:
		play_area_mode = new_value
		var enum_value = AGUserSettings.PlayAreaMode.find_key(new_value)
		print("play area mode set to %s" % enum_value)


## Save the settings to file
func save() -> void:
	# Convert the settings to a dictionary
	var settings := {
		"input" : {
			"default_snap_turning" : snap_turning,
			"y_axis_dead_zone" : y_axis_dead_zone,
			"x_axis_dead_zone" : x_axis_dead_zone,
			"haptics_scale": haptics_scale
		},
		"player" : {
			"height" : player_height
		},
		"options" : {
			"play_area_mode" : play_area_mode,
		}
	}

	# Convert the settings dictionary to text
	var settings_text := JSON.stringify(settings)

	# Attempt to open the settings file for writing
	var file := FileAccess.open(settings_file_name, FileAccess.WRITE)
	if not file:
		push_warning("Unable to write to %s" % settings_file_name)
		return

	# Write the settings text to the file
	file.store_line(settings_text)
	file.close()


## Load the settings from file
func _load() -> void:
	# First reset our values
	reset_to_defaults()

	# Skip if no settings file found
	if !FileAccess.file_exists(settings_file_name):
		return

	# Attempt to open the settings file for reading
	var file := FileAccess.open(settings_file_name, FileAccess.READ)
	if not file:
		push_warning("Unable to read from %s" % settings_file_name)
		return

	# Read the settings text
	var settings_text := file.get_as_text()
	file.close()

	# Parse the settings text and verify it's a dictionary
	var settings_raw = JSON.parse_string(settings_text)
	if typeof(settings_raw) != TYPE_DICTIONARY:
		push_warning("Settings file %s is corrupt" % settings_file_name)
		return

	# Parse our input settings
	var settings : Dictionary = settings_raw
	if settings.has("input"):
		var input : Dictionary = settings["input"]
		if input.has("default_snap_turning"):
			snap_turning = input["default_snap_turning"]
		if input.has("y_axis_dead_zone"):
			y_axis_dead_zone = input["y_axis_dead_zone"]
		if input.has("x_axis_dead_zone"):
			x_axis_dead_zone = input["x_axis_dead_zone"]
		if input.has("haptics_scale"):
			haptics_scale = input["haptics_scale"]

	# Parse our player settings
	if settings.has("player"):
		var player : Dictionary = settings["player"]
		if player.has("height"):
			player_height = player["height"]

	# Parse our Options settings
	if settings.has("options"):
		var options : Dictionary = settings["options"]
		if options.has("play_area_mode"):
			play_area_mode = options["play_area_mode"]


## Helper function to remap input vector with deadzone values
func get_adjusted_vector2(p_controller, p_input_action):
	var vector = Vector2.ZERO
	var original_vector = p_controller.get_vector2(p_input_action)

	if abs(original_vector.y) > y_axis_dead_zone:
		vector.y = remap(abs(original_vector.y), y_axis_dead_zone, 1, 0, 1)
		if original_vector.y < 0:
			vector.y *= -1

	if abs(original_vector.x) > x_axis_dead_zone:
		vector.x = remap(abs(original_vector.x), x_axis_dead_zone, 1, 0, 1)
		if original_vector.x < 0:
			vector.x *= -1

	return vector
