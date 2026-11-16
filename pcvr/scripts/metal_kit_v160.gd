extends RefCounted
## V160 : le kit des métaux, pour toutes les villes (Hautefond, la Cité des Nuées, les Strates, le Dôme
## d'Azur, l'Île Perchée). Les métaux y étaient des aplats de couleur (en VR : du plastique) ; ils ont
## maintenant leur grain (le brossage de l'acier, la patine du laiton, le vert-de-gris), leur relief et
## leur rugosité (le reflet n'est pas le même partout). La texture est neutre : la couleur du métal
## reste celle que chaque ville lui donne. Posée en triplanaire (les pièces sont des formes simples).

const T := "res://assets/textures/beau160/"

## Les genres : brosse (acier, aluminium, titane), patine (laiton, bronze, or, cuivre), verdigris,
## fer (fer forgé noir).
const GENRES := {"brosse": ["metal_brosse", 2.0, 0.45], "patine": ["metal_patine", 1.6, 0.7], "verdigris": ["verdigris", 1.0, 0.8], "fer": ["fer_noir", 1.6, 0.8]}


## Habille un métal (StandardMaterial3D) : sa texture, son relief, sa rugosité. echelle : combien de
## fois la texture par mètre (0 : celle du genre). Sans les textures (un vieil export), rien ne change.
static func habille(m: StandardMaterial3D, genre: String, echelle: float = 0.0) -> StandardMaterial3D:
	if m == null or not GENRES.has(genre):
		return m
	var g: Array = GENRES[genre]
	var nom: String = str(g[0])
	if not ResourceLoader.exists(T + nom + ".png"):
		return m
	m.albedo_texture = load(T + nom + ".png")
	if genre == "verdigris":
		m.albedo_color = Color(1, 1, 1)
	if ResourceLoader.exists(T + nom + "_n.png"):
		m.normal_enabled = true
		m.normal_texture = load(T + nom + "_n.png")
		m.normal_scale = float(g[2])
	if ResourceLoader.exists(T + nom + "_r.png"):
		m.roughness_texture = load(T + nom + "_r.png")
		m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
		# la texture module la rugosité : un peu plus haut pour garder le reflet moyen
		m.roughness = clampf(m.roughness * 1.18, 0.05, 1.0)
	m.uv1_triplanar = true
	var e: float = echelle if echelle > 0.0 else float(g[1])
	m.uv1_scale = Vector3(e, e, e)
	return m


## Le genre d'un métal d'après sa couleur (pour les villes qui n'ont qu'une fonction « métal ») :
## les jaunes et les rouges sont patinés, les gris brossés, les très sombres en fer forgé.
static func genre_de(c: Color) -> String:
	var l: float = c.r * 0.3 + c.g * 0.59 + c.b * 0.11
	if c.g > c.r * 1.05 and c.g > c.b:
		return "verdigris"
	if c.r > c.b * 1.35:
		return "patine"
	if l < 0.26:
		return "fer"
	return "brosse"
