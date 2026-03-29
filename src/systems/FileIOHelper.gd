class_name FileIOHelper
extends RefCounted

## Static helpers for JSON file persistence.
## Consolidates the repeated FileAccess + JSON.parse pattern used by
## SaveManager, SettingsManager, and GameManager.


## Load and parse a JSON file. Returns the parsed Variant (Dictionary, Array, etc.)
## or null if the file does not exist or parsing fails.
static func load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return null
	var json_string := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(json_string) != OK:
		return null
	return json.data


## Save a Variant as JSON to the given path. Returns OK on success.
static func save_json(path: String, data: Variant) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return ERR_FILE_CANT_WRITE
	file.store_string(JSON.stringify(data))
	file.close()
	return OK
