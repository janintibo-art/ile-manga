extends Node3D
## V199 : les mains en VR (à la place des deux boîtes de couleur) : la paume, cinq doigts de trois
## phalanges, le pouce, le poignet et le bas de la manche. Les doigts suivent la manette : la
## gâchette ferme l'index, la poignée ferme le majeur, l'annulaire et l'auriculaire ; le pouce se pose
## quand on touche un bouton ou le joystick.
##
## Repère : la pose « grip » d'OpenXR. -Z va dans le tunnel du poing fermé (le manche de la manette),
## la paume regarde vers -X pour la main droite et vers +X pour la main gauche. La main est construite
## pour la droite, puis renversée en X pour la gauche.

const PEAU := Color(0.87, 0.67, 0.55)
const MANCHE := Color(0.2, 0.27, 0.36)
const ONGLE := Color(0.93, 0.78, 0.72)

# [z de la base du doigt, longueurs des trois phalanges, rayon, écart (degrés, vers l'arrière)]
const DOIGTS := {
	"index": [-0.030, [0.044, 0.026, 0.021], 0.0095, -6.0],
	"majeur": [-0.010, [0.048, 0.029, 0.022], 0.0098, -1.0],
	"annulaire": [0.010, [0.044, 0.027, 0.021], 0.0093, 4.0],
	"auriculaire": [0.028, [0.035, 0.021, 0.018], 0.0083, 9.0],
}
# combien chaque articulation se plie quand le doigt est fermé (degrés)
const PLI := [62.0, 88.0, 64.0]
const PLI_OUVERT := [24.0, 30.0, 18.0]

var controleur: XRController3D
var cote: float = 1.0                       # 1 : main droite ; -1 : main gauche
var _doigts: Dictionary = {}                # nom -> [Node3D articulation 0, 1, 2]
var _pouce: Array = []
var _ferme: Dictionary = {"index": 0.0, "majeur": 0.0, "annulaire": 0.0, "auriculaire": 0.0, "pouce": 0.0}
var _mat_peau: StandardMaterial3D
var _mat_manche: StandardMaterial3D
var _mat_ongle: StandardMaterial3D
var essai_ferme: float = -1.0              # (pour les tests : force la fermeture des doigts)
var tient: bool = false                    # une arme en main : le poing reste fermé dessus


func setup(ctrl: XRController3D, gauche: bool) -> void:
	controleur = ctrl
	cote = -1.0 if gauche else 1.0
	name = "Main_v199_" + ("gauche" if gauche else "droite")
	_mat_peau = StandardMaterial3D.new()
	_mat_peau.albedo_color = PEAU
	_mat_peau.roughness = 0.58
	_mat_peau.subsurf_scatter_enabled = true
	_mat_peau.subsurf_scatter_strength = 0.35
	_mat_peau.rim_enabled = true
	_mat_peau.rim = 0.25
	_mat_peau.rim_tint = 0.6
	_mat_manche = StandardMaterial3D.new()
	_mat_manche.albedo_color = MANCHE
	_mat_manche.roughness = 0.9
	_mat_ongle = StandardMaterial3D.new()
	_mat_ongle.albedo_color = ONGLE
	_mat_ongle.roughness = 0.3
	_construire()
	ctrl.add_child(self)


func _p(v: Vector3) -> Vector3:
	return Vector3(v.x * cote, v.y, v.z)


func _capsule(parent: Node3D, from_local: Vector3, longueur: float, rayon: float, mat: Material, dir: Vector3 = Vector3.DOWN) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var c := CapsuleMesh.new()
	c.radius = rayon
	c.height = maxf(longueur + rayon * 2.0, rayon * 2.0 + 0.001)
	c.radial_segments = 12
	c.rings = 4
	m.mesh = c
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# la capsule de Godot est le long de Y ; on la couche dans la direction voulue
	var b := Basis()
	if dir.normalized().abs() != Vector3.UP:
		b = Basis(Quaternion(Vector3.UP, dir.normalized()))
	elif dir.y > 0.0:
		b = Basis()
	m.transform = Transform3D(b, from_local + dir.normalized() * longueur * 0.5)
	parent.add_child(m)
	return m


func _construire() -> void:
	# la paume : un ovoïde aplati, posé contre le manche (le dos de la main vers +X pour la droite)
	var paume := MeshInstance3D.new()
	var pm := SphereMesh.new()
	pm.radius = 0.5
	pm.height = 1.0
	pm.radial_segments = 20
	pm.rings = 10
	paume.mesh = pm
	paume.material_override = _mat_peau
	paume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	paume.transform = Transform3D(Basis.from_scale(Vector3(0.03, 0.09, 0.086)), _p(Vector3(0.032, -0.002, 0.0)))
	add_child(paume)
	# les jointures : une rangée de petites bosses au bas de la paume, d'où partent les doigts
	for nom0 in DOIGTS:
		var bosse := MeshInstance3D.new()
		var bs := SphereMesh.new()
		bs.radius = float(DOIGTS[nom0][2]) * 1.25
		bs.height = bs.radius * 2.0
		bs.radial_segments = 12
		bs.rings = 6
		bosse.mesh = bs
		bosse.material_override = _mat_peau
		bosse.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bosse.position = _p(Vector3(0.03, -0.042, float(DOIGTS[nom0][0])))
		add_child(bosse)
	# le poignet et le bas de la manche (court : on voit surtout la main)
	# (le poignet est au bord de la paume opposé aux jointures, vers +Y : l'avant-bras part de là)
	_capsule(self, _p(Vector3(0.03, 0.036, 0.006)), 0.035, 0.023, _mat_peau, Vector3(0.15, 1, 0.25))
	_capsule(self, _p(Vector3(0.033, 0.07, 0.015)), 0.05, 0.026, _mat_manche, Vector3(0.15, 1, 0.25))
	# les quatre doigts : ils partent du bas de la paume et s'enroulent sous le manche (autour de Z)
	for nom in DOIGTS:
		var d: Array = DOIGTS[nom]
		var z0: float = float(d[0])
		var lg: Array = d[1]
		var r: float = float(d[2])
		var art: Array = []
		var parent: Node3D = self
		var at: Vector3 = _p(Vector3(0.03, -0.043, z0))
		for k in range(3):
			var j := Node3D.new()
			j.position = at
			if k == 0:
				j.rotation_degrees = Vector3(-float(d[3]), 0, 0)
			parent.add_child(j)
			var lk: float = float(lg[k])
			_capsule(j, Vector3.ZERO, lk, r * (1.0 - 0.1 * k), _mat_peau, Vector3.DOWN)
			if k == 2:
				# l'ongle, sur le dos du bout du doigt
				var o := MeshInstance3D.new()
				var ob := BoxMesh.new()
				ob.size = Vector3(0.003, lk * 0.55, r * 1.3)
				o.mesh = ob
				o.material_override = _mat_ongle
				o.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				o.position = _p(Vector3(r * 0.85, -lk * 0.62, 0))
				j.add_child(o)
			art.append(j)
			parent = j
			at = Vector3(0, -lk, 0)
		_doigts[nom] = art
	# le pouce : sur le dessus du manche, il part vers l'avant
	var parent_p: Node3D = self
	var at_p: Vector3 = _p(Vector3(0.016, 0.03, -0.03))
	var lgp := [0.034, 0.026, 0.022]
	for k2 in range(3):
		var jp := Node3D.new()
		jp.position = at_p
		if k2 == 0:
			jp.rotation_degrees = Vector3(70.0, 0.0, -25.0 * cote)
		parent_p.add_child(jp)
		_capsule(jp, Vector3.ZERO, float(lgp[k2]), 0.0115 * (1.0 - 0.08 * k2), _mat_peau, Vector3.DOWN)
		_pouce.append(jp)
		parent_p = jp
		at_p = Vector3(0, -float(lgp[k2]), 0)


func _process(delta: float) -> void:
	if controleur == null or not is_instance_valid(controleur):
		return
	var trig: float = controleur.get_float("trigger")
	var grip: float = controleur.get_float("grip")
	var pouce_pose: bool = controleur.is_button_pressed("primary_touch") or controleur.is_button_pressed("ax_touch") or controleur.is_button_pressed("by_touch") or controleur.is_button_pressed("ax_button") or controleur.is_button_pressed("by_button")
	if tient:
		trig = 1.0
		grip = 1.0
	if essai_ferme >= 0.0:
		trig = essai_ferme
		grip = essai_ferme
	var cible := {"index": trig, "majeur": grip, "annulaire": grip, "auriculaire": grip, "pouce": 1.0 if pouce_pose else maxf(grip * 0.5, trig * 0.3)}
	var k_suivi: float = clampf(delta * 18.0, 0.0, 1.0)
	for nom in cible:
		_ferme[nom] = lerpf(float(_ferme[nom]), float(cible[nom]), k_suivi)
	for nom in _doigts:
		var f: float = float(_ferme[nom])
		var art: Array = _doigts[nom]
		for k in range(3):
			var a: float = lerpf(PLI_OUVERT[k], PLI[k], f)
			# le doigt s'enroule autour du manche (axe Z) : vers -X (la paume) pour la droite
			var j: Node3D = art[k]
			var rz: float = -a * cote
			if k == 0:
				var d: Array = DOIGTS[nom]
				j.rotation_degrees = Vector3(-float(d[3]), 0, rz)
			else:
				j.rotation_degrees = Vector3(0, 0, rz)
	var fp: float = float(_ferme["pouce"])
	if _pouce.size() == 3:
		(_pouce[1] as Node3D).rotation_degrees = Vector3(0, 0, lerpf(-8.0, -32.0, fp) * cote)
		(_pouce[2] as Node3D).rotation_degrees = Vector3(0, 0, lerpf(-6.0, -40.0, fp) * cote)
