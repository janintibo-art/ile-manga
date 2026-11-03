extends "res://scripts/pnj/pnj_pasta_v98.gd"
## V101 : un habitant du Village des Arbres-Maisons (l'Île Crayonnée). Même vie réglée par l'heure que
## les autres habitants (et toutes les postures des îles d'avant), avec ce qu'il tient en main (fiche
## « crayon ») : le grand pinceau à façade de Basile (Bertrand), l'arrosoir de Rosalie, le panier de
## fleurs de Capucine, la longue-vue de Gaspard. Les vêtements et les chapeaux sont cousus dans le
## corps (V64). Pendant la fête des couleurs, ils lèvent les bras (cheer, comme les adeptes d'Al Dente).


func setup_azur(manager: Node, data: Dictionary) -> void:
	super.setup_azur(manager, data)
	crayon_props(data.get("crayon", {}))


func crayon_props(cr: Dictionary) -> void:
	if skel == null or cr.is_empty() or _hand_prop != null:
		return
	var obj: String = str(cr.get("objet", ""))
	match obj:
		"pinceau_geant":
			_make_big_brush(cr)
		"arrosoir":
			punk_props({"objet": "arrosoir"})
		"panier":
			_mj_object("panier", "")
		"telescope_portable":
			lumen_props({"objet": obj})
		_:
			pass


## Bertrand, le pinceau à façade de Basile : un long manche de bois, une virole de fer, une grosse
## brosse de soies (le bout encore un peu bleu).
func _make_big_brush(cr: Dictionary) -> void:
	_hand_prop = Node3D.new()
	_hand_prop.name = "Pinceau_geant"
	var wood := _m(Color(0.62, 0.44, 0.24), 0.6)
	var iron := _m(Color(0.7, 0.71, 0.73), 0.3, 0.9)
	var soies := _m(Color(0.86, 0.8, 0.66), 0.85)
	var c2: Array = cr.get("c2", [0.2, 0.4, 0.75])
	var bout := _m(Color(float(c2[0]), float(c2[1]), float(c2[2])), 0.5)
	_part(_hand_prop, _cyl(0.016, 0.018, 0.95), wood, Vector3(0, 0.1, 0))
	_part(_hand_prop, _box_mesh_np(Vector3(0.12, 0.07, 0.035)), iron, Vector3(0, -0.4, 0))
	_part(_hand_prop, _box_mesh_np(Vector3(0.13, 0.12, 0.04)), soies, Vector3(0, -0.5, 0))
	_part(_hand_prop, _box_mesh_np(Vector3(0.132, 0.04, 0.042)), bout, Vector3(0, -0.56, 0))
	_attach("RightHand", Vector3(0, -6, 3), _hand_prop, Vector3(180, 0, 0))
