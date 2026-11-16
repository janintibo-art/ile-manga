## La beauté du monde (V158) : les textures du monde importées avec leurs mipmaps (et compressées),
## sauf les images de l'interface, le pixel art et les découpes fines ; les sols partagés en haute
## définition (2048) ; les maisons qu'on visite : leurs murs ont leur relief, le bois des meubles,
## les tissus, le cuir, la sonde de reflets de la pièce ; les planchers des maisons du village ;
## les plants de tomates de l'Île des Géants n'ont plus de partie vide.
const NOM := "beaute"


func _import(p: String) -> String:
	var f := FileAccess.open(p + ".import", FileAccess.READ)
	return f.get_as_text() if f != null else ""


func _serie() -> void:
	# --- les réglages d'import (le fichier .import à côté de chaque texture)
	var avec: Array = ["terrain/grass.jpg", "terrain/sand_n.png", "terrain/rock.jpg", "maisons/chaux_ocre.png", "maisons/chaux_ocre_n.png",
		"azur/calcaire.png", "coeur/pierre.png", "moai/pierre_moai_n.png", "interior/floor.png", "neo/ecrans_larges.png", "ciel/nuage.png"]
	var mal: Array = []
	for r in avec:
		var t: String = _import("res://assets/textures/" + r)
		if not (t.contains("mipmaps/generate=true") and t.contains("compress/mode=2")):
			mal.append(r)
	_ok(mal.is_empty(), "les textures du monde : compressées, avec leurs mipmaps (%d vues ; sans : %s)" % [avec.size(), str(mal)])
	var sans: Array = ["flora/leaves.png", "jungle/palm_frond.png", "pixel90/" + _premier("res://assets/textures/pixel90/")]
	var mal2: Array = []
	for r2 in sans:
		if _import("res://assets/textures/" + r2).contains("mipmaps/generate=true"):
			mal2.append(r2)
	_ok(mal2.is_empty(), "les découpes fines et le pixel art restent comme avant (%s)" % str(mal2))
	_ok(_import("res://assets/textures/terrain/grass_n.png").contains("compress/high_quality=true"), "les cartes de relief en haute qualité")
	# --- les sols partagés en haute définition
	var tailles: Array = []
	for s in ["grass.jpg", "sand.jpg", "stone.jpg", "rock.jpg", "grass_n.png", "sand_n.png", "stone_n.png"]:
		var tx: Texture2D = load("res://assets/textures/terrain/" + s)
		tailles.append(tx.get_width() if tx != null else 0)
	_ok(int(tailles[0]) == 2048 and int(tailles[1]) == 2048 and int(tailles[2]) == 2048 and int(tailles[3]) == 2048 and int(tailles[4]) >= 1024 and int(tailles[6]) >= 1024,
		"les sols de l'île : %s px" % str(tailles))
	# --- les planchers des maisons du village (V27) et du château
	var fm: StandardMaterial3D = houses_v27.get("_floor") if houses_v27 != null else null
	_ok(fm != null and fm.normal_texture != null and fm.albedo_texture != null and fm.albedo_texture.get_width() >= 1024, "le plancher des maisons du village : ses lames, son relief")
	# --- une maison qu'on visite
	_ranger()
	await _images(2)
	testeur_v78._visit("famille")
	await _att(0.3)
	for k in range(40):
		if not maisons_v81.busy:
			break
		await _att(0.1)
	_ok(maisons_v81.inside and maisons_v81.R != null, "on entre dans une maison (%s)" % str(maisons_v81.ctx.get("style", "")))
	if maisons_v81.inside and maisons_v81.R != null:
		var R = maisons_v81.R
		var bois: StandardMaterial3D = R.mat("bois")
		var tissu: StandardMaterial3D = R.mat("tissu_rouge")
		var cuir: StandardMaterial3D = R.mat("cuir")
		var mur: StandardMaterial3D = R.mat("mur")
		_ok(bois != null and bois.normal_texture != null and bois.albedo_texture.resource_path.ends_with("bois_meuble.png"), "le bois des meubles : son fil, son relief")
		_ok(tissu != null and tissu.albedo_texture != null and tissu.normal_texture != null, "les tissus : un tissage, teint")
		_ok(cuir != null and cuir.albedo_texture != null, "le cuir grainé")
		var pm: String = str((R.pal["mur"] as Array)[0])
		var a_relief: bool = ResourceLoader.exists("res://assets/textures/" + pm.get_basename() + "_n.png")
		_ok(mur != null and (mur.normal_texture != null or not a_relief), "les murs ont leur relief (%s)" % pm)
		var sonde: Node = maisons_v81.room.get_node_or_null("Sonde_v158")
		_ok(sonde is ReflectionProbe and (sonde as ReflectionProbe).interior, "la sonde de reflets de la pièce")
		_ok(await _debout("dans la maison", 0.6), "on tient debout dans la maison")
		# les papiers peints, chaux, parquets et carrelages des maisons ont tous leur relief
		var manque: Array = []
		for st in R.STYLES:
			for k2 in ["sol", "mur", "bas", "plafond"]:
				var p: String = str((R.STYLES[st][k2] as Array)[0])
				if p.begins_with("maisons/") and not ResourceLoader.exists("res://assets/textures/" + p.get_basename() + "_n.png"):
					manque.append(p)
		for st2 in R.VARIANTES:
			for v in R.VARIANTES[st2]:
				for k3 in ["sol", "mur", "bas", "plafond"]:
					if (v as Dictionary).has(k3):
						var p2: String = str((v[k3] as Array)[0])
						if p2.begins_with("maisons/") and not ResourceLoader.exists("res://assets/textures/" + p2.get_basename() + "_n.png"):
							manque.append(p2)
		_ok(manque.is_empty(), "les textures des maisons ont toutes leur relief (%s)" % str(manque))
	maisons_v81._teardown()
	await _att(0.2)
	# --- l'Île des Géants : les plants de tomates (une partie vide n'est plus ajoutée au maillage)
	var GF = load("res://scripts/geants_flore_v142.gd").new()
	var vides: int = 0
	var surf: int = 0
	for v2 in range(6):
		var m: ArrayMesh = GF._m_tomate(v2)
		for s2 in range(m.get_surface_count()):
			surf += 1
			if m.surface_get_array_len(s2) == 0:
				vides += 1
	GF.free()
	_ok(vides == 0 and surf >= 24, "les plants de tomates : %d parties, aucune vide" % surf)


func _premier(dossier: String) -> String:
	var d := DirAccess.open(dossier)
	if d == null:
		return ""
	for f in d.get_files():
		if f.ends_with(".png"):
			return f
	return ""
