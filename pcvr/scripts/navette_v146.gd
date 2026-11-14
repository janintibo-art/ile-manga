extends "res://scripts/dirigeable_v61.gd"
## V146 : la Navette des Nuées, le dirigeable qui fait la navette entre le Mât des Nuées de Hautefond (sur
## la falaise du sud, au bout de son ponton suspendu au-dessus de la mer) et le Quai des Nuées de l'Île
## Perchée (à 270 m au-dessus de la mer). Le même dirigeable que le Zéphyr (V61), en plus festif : une
## enveloppe à rayures rouges et crème, comme un chapiteau de foire, et des empennages vert sapin.

const ESCALES := [["hautefond_mat", "Mât des Nuées (Hautefond)"], ["perchee_quai", "Quai des Nuées (Pile-ou-Face)"]]


func _init() -> void:
	cruise_y = 300.0
	attente = 32.0
	escales = ESCALES
	msg_largue = "La Navette des Nuées largue les amarres : prochaine escale, %s."
	msg_bord = "À bord de la Navette des Nuées ! Prochaine escale : %s (le dirigeable part dans %d s)."


func _mat(key: String) -> Material:
	if _mats.has(key):
		return _mats[key]
	match key:
		"toile":
			var img := Image.create(64, 8, true, Image.FORMAT_RGB8)
			for x in range(64):
				var c: Color = Color(0.72, 0.14, 0.12) if (x / 8) % 2 == 0 else Color(0.93, 0.87, 0.74)
				for y in range(8):
					img.set_pixel(x, y, c)
			img.generate_mipmaps()
			var m := StandardMaterial3D.new()
			m.albedo_texture = ImageTexture.create_from_image(img)
			m.roughness = 0.82
			m.uv1_scale = Vector3(1.0, 6.0, 1.0)
			_mats[key] = m
			return m
		"rouge":
			var r := StandardMaterial3D.new()
			r.albedo_color = Color(0.12, 0.3, 0.2)
			r.roughness = 0.7
			_mats[key] = r
			return r
	return super._mat(key)


func leave() -> void:
	if not riding:
		return
	riding = false
	var spot: Vector3 = door_pos() + (rig.global_transform.basis * Vector3(0, 0, 1.6))
	spot.y = (pads[stop_i] as Vector3).y + 0.3
	main.place_player_v35(spot, rig.global_transform.basis * Vector3(0, 0, 1))
	if main.get("hero_v28") != null and main.hero_v28 != null and not main.xr_active:
		main.hero_v28.leave_ride()
		main.hero_v28.cam_distance = 1.0
	main.last_ok_v29.clear()
	main._show_message_v28("Terminus : %s." % stop_name(stop_i))
