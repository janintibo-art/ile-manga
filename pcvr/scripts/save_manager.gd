extends RefCounted
## Sauvegardes communes aux deux executables Windows, dans user://.
const SLOT_COUNT: int = 6
const SAVE_DIR: String = "user://saves"

static func path_for(slot: int) -> String:
	return SAVE_DIR + ("/autosave.json" if slot == 0 else "/slot_%d.json" % slot)

## V72 : une lecture gardée en mémoire tant que le fichier n'a pas changé (le chargement d'une
## partie lisait le même fichier 17 fois ; le menu relisait toutes les sauvegardes à chaque fois).
static var _cache: Dictionary = {}

static func _parse(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	if int(value.get("format", 0)) != 1:
		return {}
	return value

static func read_slot(slot: int) -> Dictionary:
	if slot < 0 or slot > SLOT_COUNT:
		return {}
	var path: String = path_for(slot)
	if not FileAccess.file_exists(path) and not FileAccess.file_exists(path + ".bak"):
		return {}
	var stamp: int = FileAccess.get_modified_time(path) if FileAccess.file_exists(path) else -1
	var c: Variant = _cache.get(path, null)
	if c is Array and int(c[0]) == stamp:
		return (c[1] as Dictionary).duplicate(true)
	var data: Dictionary = _parse(path)
	# V72 : un fichier abîmé (coupure pendant l'écriture) : on reprend la copie précédente
	if data.is_empty():
		data = _parse(path + ".bak")
	_cache[path] = [stamp, data]
	return data.duplicate(true)

## extra (V28) : inventaire, vie… ajoutés tels quels au fichier.
## V72 : écriture sûre : un fichier temporaire, vérifié, puis mis à la place de l'ancien (gardé en
## .bak) ; une coupure en pleine écriture ne détruit plus la partie.
static func write_slot(slot: int, position: Vector3, facing: float, seconds: float, extra: Dictionary = {}) -> bool:
	if slot < 0 or slot > SLOT_COUNT:
		return false
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR)) != OK:
		return false
	var data: Dictionary = {
		"format": 1,
		"jeu": "V72",
		"slot": slot,
		"saved_at": Time.get_datetime_string_from_system(),
		"play_seconds": maxf(seconds, 0.0),
		"zone": "Ile Manga",
		"position": [position.x, position.y, position.z],
		"yaw": facing
	}
	for key in extra:
		data[key] = extra[key]
	var path: String = path_for(slot)
	var tmp: String = path + ".tmp"
	var text: String = JSON.stringify(data)
	var handle: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if handle == null:
		return false
	handle.store_string(text)
	handle.flush()
	handle.close()
	# le fichier écrit se relit-il ?
	if typeof(JSON.parse_string(FileAccess.get_file_as_string(tmp))) != TYPE_DICTIONARY:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
		return false
	var g_path: String = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path + ".bak"):
			DirAccess.remove_absolute(g_path + ".bak")
		DirAccess.rename_absolute(g_path, g_path + ".bak")
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), g_path) != OK:
		return false
	_cache.erase(path)
	return true

static func delete_slot(slot: int) -> bool:
	if slot < 1 or slot > SLOT_COUNT:
		return false
	_cache.erase(path_for(slot))
	if FileAccess.file_exists(path_for(slot) + ".bak"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path_for(slot) + ".bak"))
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
