extends SceneTree
## Mesure le tracé du grand huit (sans lancer le jeu) : longueur, durée, vitesses, forces, croisements.
##     godot --headless --path pcvr --script res://grand_huit_mesure.gd


func _init() -> void:
	var T = load("res://scripts/grand_huit_trace_v209.gd")
	var d: Dictionary = T.tracer()
	var n: int = int(d["n"])
	var pts: PackedVector3Array = d["pts"]
	var v: PackedFloat32Array = d["v"]
	var haut: PackedVector3Array = d["haut"]
	var tan: PackedVector3Array = d["tan"]
	var duree: float = 0.0
	var vmax: float = 0.0
	var gmax: float = -9.0
	var gmin: float = 9.0
	var cmax: float = 0.0
	var pente: float = 0.0
	var roulis: float = 0.0
	var pneus: int = 0
	for i in range(n):
		duree += float(d["pas"]) / maxf(v[i], 0.5)
		vmax = maxf(vmax, v[i])
		var f: Vector2 = T.forces(d, i)
		if T.zone(d, i) == "libre":
			if f.x > gmax:
				gmax = f.x
			if f.x < gmin:
				gmin = f.x
			cmax = maxf(cmax, absf(f.y))
			if v[i] <= T.V_MINI + 0.01:
				pneus += 1
		pente = maxf(pente, absf(rad_to_deg(asin(tan[i].y))))
		roulis = maxf(roulis, rad_to_deg(haut[i].angle_to(haut[(i + 1) % n])) * v[i])
	print("MESURE longueur %.0f m, durée %.0f s, vitesse max %.1f m/s (%.0f km/h)" % [float(d["longueur"]), duree, vmax, vmax * 3.6])
	print("MESURE g vertical de %.2f à %.2f, g de côté max %.2f, pente max %.0f°, roulis max %.0f °/s, mètres aux pneus %d" % [gmin, gmax, cmax, pente, roulis, pneus])
	print("MESURE repères arret %d chaine %d-%d sommet %d (%.1f m) freins %d" % [int(d["arret"]), int(d["chaine0"]), int(d["chaine1"]), int(d["sommet"]), pts[int(d["sommet"])].y, int(d["freins"])])
	# les croisements : deux bouts de voie trop près l'un de l'autre
	var pire: float = 99.0
	var ou: String = ""
	for i in range(0, n, 2):
		for j in range(i + 40, n, 2):
			if n - j + i < 40:
				continue
			var dd: float = pts[i].distance_to(pts[j])
			if dd < pire:
				pire = dd
				ou = "%d %s / %d %s" % [i, str(pts[i].snapped(Vector3.ONE * 0.1)), j, str(pts[j].snapped(Vector3.ONE * 0.1))]
	print("MESURE croisement le plus serré %.1f m : %s" % [pire, ou])
	for i in range(0, n, 5):
		var f2: Vector2 = T.forces(d, i)
		if T.zone(d, i) != "libre" or (f2.x < 3.6 and f2.x > -0.35 and absf(f2.y) < 0.6 and i % 100 != 0):
			continue
		print("  %4d %-7s %s v %.1f g %.2f / %.2f haut.y %.2f" % [i, T.zone(d, i), str(pts[i].snapped(Vector3.ONE * 0.1)), v[i], f2.x, f2.y, haut[i].y])
	quit()
