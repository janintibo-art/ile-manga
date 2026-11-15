## Le sac qui grandit (V151) : 32 cases au niveau 1, deux de plus à chaque niveau (90 au niveau 30) ;
## les cases fermées ne reçoivent rien ; un niveau gagné ouvre des cases (et le dit) ; la grille du carnet
## se resserre pour tout montrer ; un cadeau refusé faute de place (Faelar et sa lanterne de fée), puis
## accepté quand le sac a grandi ; la sauvegarde garde tout.
const NOM := "sac"


func _serie() -> void:
	var inv: Node = inventory_v28
	var pr: Node = progression_v63
	pr.level = 1
	_ok(inv.capacite() == 32, "niveau 1 : 32 cases (%d)" % inv.capacite())
	pr.level = 30
	_ok(inv.capacite() == 90, "niveau 30 : 90 cases (%d)" % inv.capacite())
	pr.level = 1
	# on remplit les 32 cases d'objets différents
	inv._clear_slots()
	var n: int = 0
	for id in inv.ITEMS.keys():
		if n >= 32:
			break
		if str(inv.ITEMS[id]["kind"]) in ["materiau", "nourriture", "tresor"] and int(inv.ITEMS[id]["max"]) > 1:
			if inv.add(str(id), 1) == 1:
				n += 1
	_ok(n == 32 and inv.cases_libres() == 0, "le sac est plein : 32 objets différents")
	_ok(inv.add("lanterne_fee", 1) == 0 and not inv.can_accept([["lanterne_fee", 1]]), "plus de place : rien n'entre (les cases fermées restent fermées)")
	# Faelar donne sa lanterne : refusée, sac plein
	var fa: Node3D = null
	for npc in npcs_v31:
		if is_instance_valid(npc) and npc.get("brain") != null and str(npc.brain.data.get("id", "")) == "faelar":
			fa = npc
	if fa != null:
		place_player_v35(fa.global_position + Vector3(0, 0.3, 2.0), Vector3(0, 0, -1))
		await _att(1.0)
		_talk_v31(fa)
		await _att(0.5)
		_on_dialogue_choice_v31("porte")
		await _att(0.5)
		_ok(dialogue_v31.opened and str(dialogue_v31._text.text).contains("sac est plein") and inv.count("lanterne_fee") == 0, "Faelar : « ton sac est plein »")
		dialogue_v31._pick(0)
		await _att(0.3)
		_ok(dialogue_v31.choices.size() >= 2 and not dialogue_v31._gate, "« Continuer » : les réponses reviennent")
	# un niveau de plus : deux cases s'ouvrent
	pr.gain(pr.need(1) + 1, "quetes")
	await _att(0.3)
	_ok(pr.level >= 2 and inv.capacite() == 32 + 2 * (pr.level - 1) and inv.cases_libres() >= 2, "un niveau gagné : le sac s'agrandit (%d cases)" % inv.capacite())
	if fa != null:
		_on_dialogue_choice_v31("porte")
		await _att(0.5)
		_ok(inv.count("lanterne_fee") == 1, "avec la place, Faelar donne sa lanterne de fée")
		_close_dialogue_v31()
	# la grille du carnet
	inv.open(0)
	await _att(0.3)
	var visibles: int = 0
	for b in inv._buttons:
		if (b as Button).visible:
			visibles += 1
	_ok(visibles == inv.capacite() and inv._grille.columns == 8, "la grille montre les %d cases (sur %d colonnes)" % [visibles, inv._grille.columns])
	pr.level = 30
	inv._refresh()
	await _att(0.2)
	var vis30: int = 0
	for b2 in inv._buttons:
		if (b2 as Button).visible:
			vis30 += 1
	_ok(vis30 == 90 and inv._grille.columns == 10, "niveau 30 : 90 cases, dix colonnes")
	inv.close()
	# la sauvegarde
	inv.add("pepite_or", 1)
	var d: Dictionary = inv.serialize()
	inv.load_data(d)
	_ok(inv.count("pepite_or") >= 1 and inv.count("lanterne_fee") == (1 if fa != null else 0), "la sauvegarde garde le sac")
	pr.level = 1
	inv._clear_slots()
