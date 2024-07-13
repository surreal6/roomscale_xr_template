extends Node

signal switch_to_ar
signal switch_to_vr

enum PlayAreaMode {
	ROOMSCALE,
	STANDING,
}

enum GameMode {
	ROOMSCALE,
	STANDING,
	FLAT
}

@export var game_mode : GameMode = GameMode.ROOMSCALE

@export_group("Options")

@export var xr_enabled : bool = true
@export var system_info : Dictionary

@export var play_area_mode : PlayAreaMode = PlayAreaMode.ROOMSCALE: set = set_play_area_mode
@export var passthrough : bool = false: set = set_passthrough

@export var passthrough_available : bool = true

## Settings file name to persist user settings
var settings_file_name : String = "user://ag_user_settings.json"


# Called when the node enters the scene tree for the first time.
func _ready():
	_load()


## Reset to default values
func reset_to_defaults() -> void:
	# Reset to defaults.
	play_area_mode = PlayAreaMode.ROOMSCALE
	passthrough = false
	passthrough_available = true


func set_play_area_mode(new_value : PlayAreaMode) -> void:
	if new_value != play_area_mode:
		play_area_mode = new_value
		var enum_value = AGUserSettings.PlayAreaMode.find_key(new_value)
		print("play area mode set to %s" % enum_value)


func set_passthrough(new_value : bool) -> void:
	if passthrough != new_value:
		passthrough = new_value
		if new_value:
			switch_to_ar.emit()
		else:
			switch_to_vr.emit()


## Save the settings to file
func save() -> void:
	# Convert the settings to a dictionary
	var settings := {
		"options" : {
			"xr_enabled" : xr_enabled,
			"play_area_mode" : play_area_mode,
			"passthrough" : passthrough,
			"passthrough_available" : passthrough_available,
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

	# Parse our Options settings
	if settings.has("options"):
		var options : Dictionary = settings["options"]
		# ignore xr_enabled when loading
		#if options.has("xr_enabled"):
			#xr_enabled = options["xr_enabled"]
		#if options.has("system_info"):
			#system_info = options["system_info"]
		if options.has("play_area_mode"):
			play_area_mode = options["play_area_mode"]
		if options.has("passthrough"):
			passthrough = options["passthrough"]
		#if options.has("passthrough_available"):
			#passthrough_available = options["passthrough_available"]
