extends RefCounted
## V184 : le grand contrôle des bugs visuels, les chemins des habitants. Un habitant va de point en point
## du plan de sa ville, en ligne droite ; des bouts de chemin passaient à travers une maison, un mur, un
## arbre, un étal (l'audit des chemins : tests/outils/audit_dehors.py --chemins). La table
## (chemins_table_v184.gd, écrite par l'audit) donne pour chacun un détour : des points où l'on passe en
## plus. On l'applique au plan de la ville (les dictionnaires « points » et « links », partagés par ses
## habitants) quand un habitant s'installe (pnj_v31.setup) : le lien a-b devient a-d1-…-dn-b. Une seconde
## fois ne change rien (le lien a-b n'existe plus).

const Table = preload("res://scripts/pnj/chemins_table_v184.gd")

static var actif: bool = true
static var _liste: Array = []          # [[a, b, [[ax, az, [x, y, z, …]], …]], …] (la table, lue une fois)


static func _lire() -> void:
	if not _liste.is_empty() or Table.TABLE.is_empty():
		return
	for cle in Table.TABLE:
		var ab: PackedStringArray = str(cle).split("|")
		if ab.size() == 2:
			_liste.append([ab[0], ab[1], Table.TABLE[cle]])


## Le nom d'un point de détour (on reconnaît ces points : ils ne sont ni des lieux, ni des portes).
static func nom(a: String, b: String, k: int) -> String:
	return "ch184|%s|%s|%d" % [a, b, k]


static func est_detour(point: String) -> bool:
	return point.begins_with("ch184|")


## Applique la table au plan (points, links) ; le nombre de bouts de chemin changés.
static func appliquer(points: Dictionary, links: Dictionary) -> int:
	if not actif or links.is_empty():
		return 0
	_lire()
	var n: int = 0
	for e in _liste:
		var a: String = e[0]
		var b: String = e[1]
		if not points.has(a) or not points.has(b):
			continue
		var la: Array = links.get(a, [])
		var lb: Array = links.get(b, [])
		var aller: bool = la.has(b)
		var retour: bool = lb.has(a)
		if not aller and not retour:
			continue
		var pa: Vector3 = points[a]
		for v in e[2]:
			if Vector2(pa.x - float(v[0]), pa.z - float(v[1])).length() > 1.0:
				continue
			var c: Array = v[2]
			var noms: Array = []
			for k in range(c.size() / 3):
				var nm: String = nom(a, b, k)
				points[nm] = Vector3(float(c[3 * k]), float(c[3 * k + 1]), float(c[3 * k + 2]))
				links[nm] = []
				noms.append(nm)
			if noms.is_empty():
				break
			var chaine: Array = [a] + noms + [b]
			if aller:
				la[la.find(b)] = noms[0]
				for k2 in range(1, chaine.size() - 1):
					(links[chaine[k2]] as Array).append(chaine[k2 + 1])
			if retour:
				lb[lb.find(a)] = noms[-1]
				for k3 in range(chaine.size() - 2, 0, -1):
					(links[chaine[k3]] as Array).append(chaine[k3 - 1])
			n += 1
			break
	return n
