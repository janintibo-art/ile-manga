extends RefCounted
## Sauvegardes communes aux deux executables Windows, dans user://.
const SLOT_COUNT: int = 6
const SAVE_DIR: String = "user://saves"

static func path_for(slot: int) -> String:
	return SAVE_DIR + ("/autosave.json" if slot == 0 else "/slot_%d.json" % slot)

static func read_slot(slot: int) -> Dictionary:
	if slot < 0 or slot > SLOT_COUNT:
		return {}
	var path: String = path_for(slot)
	if not FileAccess.file_exists(path):
		return {}
	var raw: String = FileAccess.get_file_as_string(path)
	var value: Variant = JSON.parse_string(raw)
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	if int(value.get("format", 0)) != 1:
		return {}
	return value

static func write_slot(slot: int, position: Vector3, facing: float, seconds: float) -> bool:
	if slot < 0 or slot > SLOT_COUNT:
		return false
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR)) != OK:
		return false
	var data: Dictionary = {
		"format": 1,
		"slot": slot,
		"saved_at": Time.get_datetime_string_from_system(),
		"play_seconds": maxf(seconds, 0.0),
		"zone": "Ile Manga",
		"position": [position.x, position.y, position.z],
		"yaw": facing
	}
	var handle: FileAccess = FileAccess.open(path_for(slot), FileAccess.WRITE)
	if handle == null:
		return false
	handle.store_string(JSON.stringify(data, "  "))
	handle.flush()
	handle.close()
	return true

static func delete_slot(slot: int) -> bool:
	if slot < 1 or slot > SLOT_COUNT:
		return false
	if not FileAccess.file_exists(path_for(slot)):
		return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path_for(slot))) == OK

static func latest_slot() -> int:
	var chosen: int = -1
	var stamp: String = ""
	for slot in range(0, SLOT_COUNT + 1):
		var data: Dictionary = read_slot(slot)
		var date: String = str(data.get("saved_at", ""))
		if date > stamp:
			stamp = date
			chosen = slot
	return chosen
