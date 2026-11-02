extends RefCounted
## V99 : les matériaux « coloriage » de l'Île Crayonnée.
## Tout ce qui est posé sur l'île (le sol a son propre shader) passe par convert_tree() : chaque
## matériau est remplacé par une copie qui ajoute, à la fin de son fragment(), le rendu coloriage
## de crayon_v99.gdshaderinc (le papier, l'encre, et la carte des couleurs qui rend la vraie
## matière là où l'île a retrouvé ses couleurs) :
##  - un ShaderMaterial : son code est recopié, l'include et quelques lignes y sont ajoutés (un
##    shader par code d'origine et par genre, mis en cache) ; ses paramètres sont recopiés ;
##  - un StandardMaterial3D : un shader équivalent est écrit (couleur, texture, couleur des sommets,
##    relief, rugosité, métal, émission, transparence, découpe, triplanaire) ;
## et, pour les objets pleins (pas l'eau, pas les feuillages découpés), une passe de contour
## (crayon_contour_v99) dessine leur silhouette à l'encre.
## Le genre d'un matériau (voir crayon_encre) : 0 objet, 1 eau, 2 feuillage, 3 écorce, 4 pierre,
## 5 planches, 6 herbe et fleurs, 7 chute d'eau ; il est deviné (le shader d'origine, sa texture), ou donné par
## set_meta("crayon", genre) sur le matériau ou sur le nœud.

const INC := "res://shaders/crayon_v99.gdshaderinc"
const CONTOUR := "res://shaders/crayon_contour_v99.gdshader"

static var _shaders: Dictionary = {}        # clé (code, genre) -> Shader
static var _done: Dictionary = {}           # id du matériau d'origine + genre -> matériau converti
static var _meshes: Dictionary = {}         # id du maillage d'origine -> copie convertie
static var _contour: ShaderMaterial
static var converted: int = 0
static var failed: Array = []


static func contour_material() -> ShaderMaterial:
	if _contour == null:
		_contour = ShaderMaterial.new()
		_contour.shader = load(CONTOUR)
	return _contour


## Convertit tout ce qui est sous root (MeshInstance3D, MultiMeshInstance3D, CSG exclus).
static func convert_tree(root: Node) -> void:
	for n in root.find_children("*", "GeometryInstance3D", true, false):
		if n.has_meta("crayon_non"):
			continue
		if n is MeshInstance3D:
			convert_mesh_instance(n)
		elif n is MultiMeshInstance3D:
			convert_multimesh(n)
	if root is MeshInstance3D:
		convert_mesh_instance(root)
	elif root is MultiMeshInstance3D:
		convert_multimesh(root)


static func _node_kind(n: Node) -> int:
	return int(n.get_meta("crayon")) if n.has_meta("crayon") else -1


static func convert_mesh_instance(mi: MeshInstance3D) -> void:
	if mi.has_meta("crayon_fait") or mi.mesh == null:
		return
	mi.set_meta("crayon_fait", true)
	var nk: int = _node_kind(mi)
	if mi.material_override != null:
		mi.material_override = convert_mat(mi.material_override, nk)
		return
	for i in range(mi.mesh.get_surface_count()):
		var m: Material = mi.get_surface_override_material(i)
		if m == null:
			m = mi.mesh.surface_get_material(i)
		if m != null:
			mi.set_surface_override_material(i, convert_mat(m, nk))


static func convert_multimesh(mmi: MultiMeshInstance3D) -> void:
	if mmi.has_meta("crayon_fait") or mmi.multimesh == null or mmi.multimesh.mesh == null:
		return
	mmi.set_meta("crayon_fait", true)
	var nk: int = _node_kind(mmi)
	if mmi.material_override != null:
		mmi.material_override = convert_mat(mmi.material_override, nk)
		return
	var src: Mesh = mmi.multimesh.mesh
	var key: String = "%d_%d" % [src.get_instance_id(), nk]
	if not _meshes.has(key):
		var cp: Mesh = src.duplicate()
		for i in range(cp.get_surface_count()):
			var m: Material = src.surface_get_material(i)
			if m != null:
				cp.surface_set_material(i, convert_mat(m, nk))
		_meshes[key] = cp
	mmi.multimesh.mesh = _meshes[key]


## Le matériau « coloriage » qui remplace m (le même pour le même m).
static func convert_mat(m: Material, kind: int = -1) -> Material:
	if m == null:
		return null
	if m.has_meta("crayon_converti"):
		return m
	if kind < 0 and m.has_meta("crayon"):
		kind = int(m.get_meta("crayon"))
	var key: String = "%d_%d" % [m.get_instance_id(), kind]
	if _done.has(key):
		return _done[key]
	var out: Material = m
	if m is ShaderMaterial:
		out = _convert_shader_material(m, kind)
	elif m is BaseMaterial3D:
		out = _convert_standard(m, kind)
	if out != m:
		out.set_meta("crayon_converti", true)
		converted += 1
	_done[key] = out
	return out


# ------------------------------------------------------------------- ShaderMaterial

static func _guess_kind(sm: ShaderMaterial) -> int:
	var path: String = sm.shader.resource_path if sm.shader != null else ""
	if path.contains("eau") or path.contains("water") or path.contains("waterfall"):
		return 1
	if path.contains("rock") or path.contains("roche") or path.contains("pierre"):
		return 4
	if path.contains("foliage") or path.contains("feuillage"):
		var tex: Variant = sm.get_shader_parameter("albedo_tex")
		var tp: String = (tex as Texture2D).resource_path if tex is Texture2D else ""
		if tp.contains("bark") or tp.contains("ecorce"):
			return 3
		if tex is Texture2D and sm.get_shader_parameter("use_texture") != false:
			return 2
		return 6
	return 0


static func _convert_shader_material(sm: ShaderMaterial, kind: int) -> Material:
	if sm.shader == null:
		return sm
	if kind < 0:
		kind = _guess_kind(sm)
	var code: String = sm.shader.code
	var ck: String = "%d|%s" % [kind, code]
	var sh: Shader = _shaders.get(ck, null)
	if sh == null:
		var nc: String = inject(code, kind)
		if nc == "":
			failed.append(sm.shader.resource_path)
			return sm
		sh = Shader.new()
		sh.code = nc
		_shaders[ck] = sh
	var out := ShaderMaterial.new()
	out.shader = sh
	for u in sm.shader.get_shader_uniform_list():
		var nm: String = str(u["name"])
		var v: Variant = sm.get_shader_parameter(nm)
		if v != null:
			out.set_shader_parameter(nm, v)
	out.render_priority = sm.render_priority
	if _wants_contour(code, kind):
		out.next_pass = contour_material()
	return out


static func _wants_contour(code: String, kind: int) -> bool:
	if kind in [1, 2, 6, 7]:
		return false
	var rm: String = ""
	for line in code.split("\n"):
		if line.strip_edges().begins_with("render_mode"):
			rm = line
	if rm.contains("cull_disabled") or rm.contains("cull_front") or rm.contains("blend_") or rm.contains("unshaded"):
		return false
	if code.contains("wind") or code.contains("TIME"):
		return false
	return true


## Le code d'un shader « spatial », avec le rendu coloriage ajouté à la fin de son fragment() ;
## "" s'il n'est pas convertible.
static func inject(code: String, kind: int) -> String:
	if not code.contains("shader_type spatial"):
		return ""
	var rx := RegEx.new()
	rx.compile("void\\s+fragment\\s*\\(\\s*\\)\\s*\\{")
	var mt: RegExMatch = rx.search(code)
	if mt == null:
		return ""
	# la fin du fragment() : l'accolade qui ferme la sienne
	var depth: int = 0
	var end: int = -1
	var i: int = mt.get_end() - 1
	while i < code.length():
		var ch: String = code[i]
		if ch == "{":
			depth += 1
		elif ch == "}":
			depth -= 1
			if depth == 0:
				end = i
				break
		i += 1
	if end < 0:
		return ""
	var body: String = code.substr(mt.get_end(), end - mt.get_end())
	if body.contains("return;"):
		return ""
	var ra := RegEx.new()
	ra.compile("\\bALPHA\\s*=")
	var alpha: String = "ALPHA" if ra.search(body) != null else "1.0"
	# le papier est mat : pas de reflet du ciel, pas de lumière qui traverse les feuilles
	var extra: String = ""
	var rx2 := RegEx.new()
	for bi in ["BACKLIGHT", "SPECULAR", "ROUGHNESS", "METALLIC", "CLEARCOAT", "RIM"]:
		rx2.compile("\\b%s\\s*[*+-]?=" % bi)
		var written: bool = rx2.search(body) != null
		match bi:
			"BACKLIGHT", "METALLIC", "CLEARCOAT", "RIM":
				if written:
					extra += "\t\t%s *= cr_c;\n" % bi
			"SPECULAR":
				extra += ("\t\tSPECULAR *= cr_c;\n" if written else "\t\tSPECULAR = 0.5 * cr_c;\n")
			"ROUGHNESS":
				if written:
					extra += "\t\tROUGHNESS = mix(1.0, ROUGHNESS, cr_c);\n"
	var snippet: String = "\n\t// --- V99 : le coloriage de l'Île Crayonnée\n\t{\n" \
		+ "\t\tvec3 cr_wp = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;\n" \
		+ "\t\tvec3 cr_nw = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);\n" \
		+ "\t\tvec3 cr_vw = normalize(CAMERA_POSITION_WORLD - cr_wp);\n" \
		+ "\t\tfloat cr_ink = crayon_encre(cr_wp, cr_nw, cr_vw, UV, %s, TIME);\n" % alpha \
		+ "\t\tfloat cr_c;\n" \
		+ "\t\tALBEDO = crayon_melange(ALBEDO, cr_wp, cr_ink, cr_c);\n" \
		+ "\t\tEMISSION += cr_papier(cr_wp) * (1.0 - cr_c) * 0.2 * crayon_jour * (1.0 - cr_ink);\n" \
		+ extra \
		+ "\t}\n"
	var out: String = code.substr(0, end) + snippet + code.substr(end)
	# l'include, juste après les lignes shader_type / render_mode
	var lines: PackedStringArray = out.split("\n")
	var at: int = 0
	for k in range(lines.size()):
		var s: String = lines[k].strip_edges()
		if s.begins_with("shader_type") or s.begins_with("render_mode"):
			at = k + 1
			# un render_mode sur plusieurs lignes
			var k2: int = k
			while not lines[k2].contains(";") and k2 < lines.size() - 1:
				k2 += 1
				at = k2 + 1
	var head: String = "#define CR_KIND %d\n#include \"%s\"" % [kind, INC]
	lines.insert(at, head)
	out = "\n".join(lines)
	# les include relatifs deviennent absolus (le nouveau shader n'a pas de dossier)
	out = out.replace("#include \"res://", "#include \"@@RES@@").replace("#include \"", "#include \"res://shaders/").replace("#include \"res://shaders/@@RES@@", "#include \"res://")
	return out


# ------------------------------------------------------------------- StandardMaterial3D

static func _convert_standard(m: BaseMaterial3D, kind: int) -> Material:
	if m.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED:
		return m
	if kind < 0:
		kind = 0
	var cull: String = "cull_back"
	if m.cull_mode == BaseMaterial3D.CULL_DISABLED:
		cull = "cull_disabled"
	elif m.cull_mode == BaseMaterial3D.CULL_FRONT:
		cull = "cull_front"
	var tr: int = m.transparency
	var rm: Array = [cull, "diffuse_burley", "specular_schlick_ggx"]
	if tr == BaseMaterial3D.TRANSPARENCY_ALPHA:
		rm.append("blend_mix")
		rm.append("depth_draw_opaque")
	elif tr == BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS:
		rm.append("depth_prepass_alpha")
	if m.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
		rm.append("unshaded")
	if m.blend_mode == BaseMaterial3D.BLEND_MODE_ADD:
		rm.append("blend_add")
	var ck: String = "std|%d|%s|%d" % [kind, ",".join(rm), tr]
	var sh: Shader = _shaders.get(ck, null)
	if sh == null:
		var alpha_lines: String = ""
		match tr:
			BaseMaterial3D.TRANSPARENCY_ALPHA, BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS:
				alpha_lines = "\tALPHA = a.a;\n"
			BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
				alpha_lines = "\tALPHA = a.a;\n\tALPHA_SCISSOR_THRESHOLD = alpha_scissor;\n"
			BaseMaterial3D.TRANSPARENCY_ALPHA_HASH:
				alpha_lines = "\tALPHA = a.a;\n\tALPHA_HASH_SCALE = 1.0;\n"
		var code: String = "shader_type spatial;\nrender_mode %s;\n" % ", ".join(rm) \
			+ "uniform vec4 albedo : source_color = vec4(1.0);\n" \
			+ "uniform sampler2D texture_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;\n" \
			+ "uniform bool use_albedo_tex = false;\n" \
			+ "uniform bool use_vcol = false;\n" \
			+ "uniform sampler2D texture_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;\n" \
			+ "uniform bool use_normal = false;\n" \
			+ "uniform float normal_scale = 1.0;\n" \
			+ "uniform float roughness = 1.0;\n" \
			+ "uniform float metallic = 0.0;\n" \
			+ "uniform float specular = 0.5;\n" \
			+ "uniform vec3 emission : source_color = vec3(0.0);\n" \
			+ "uniform float emission_energy = 0.0;\n" \
			+ "uniform sampler2D texture_emission : source_color, hint_default_black, filter_linear_mipmap, repeat_enable;\n" \
			+ "uniform bool use_emission_tex = false;\n" \
			+ "uniform vec3 uv1_scale = vec3(1.0);\n" \
			+ "uniform vec3 uv1_offset = vec3(0.0);\n" \
			+ "uniform bool triplanar = false;\n" \
			+ "uniform float triplanar_sharp = 1.0;\n" \
			+ "uniform float alpha_scissor = 0.5;\n" \
			+ "varying vec3 tp_pos;\nvarying vec3 tp_w;\n" \
			+ "void vertex() {\n\tif (triplanar) {\n\t\ttp_w = pow(abs(NORMAL), vec3(triplanar_sharp));\n\t\ttp_w /= max(dot(tp_w, vec3(1.0)), 1e-4);\n\t\ttp_pos = VERTEX * uv1_scale + uv1_offset;\n\t\ttp_pos *= vec3(1.0, -1.0, 1.0);\n\t} else {\n\t\tUV = UV * uv1_scale.xy + uv1_offset.xy;\n\t}\n}\n" \
			+ "vec4 tri_tex(sampler2D t, vec3 p, vec3 w) {\n\treturn texture(t, p.zy) * w.x + texture(t, p.xz) * w.y + texture(t, p.xy * vec2(-1.0, 1.0)) * w.z;\n}\n" \
			+ "void fragment() {\n\tvec4 a = albedo;\n\tif (use_albedo_tex) {\n\t\ta *= triplanar ? tri_tex(texture_albedo, tp_pos, tp_w) : texture(texture_albedo, UV);\n\t}\n\tif (use_vcol) {\n\t\ta *= COLOR;\n\t}\n" \
			+ "\tALBEDO = a.rgb;\n\tROUGHNESS = roughness;\n\tMETALLIC = metallic;\n\tSPECULAR = specular;\n" \
			+ "\tif (use_normal) {\n\t\tNORMAL_MAP = triplanar ? tri_tex(texture_normal, tp_pos, tp_w).rgb : texture(texture_normal, UV).rgb;\n\t\tNORMAL_MAP_DEPTH = normal_scale;\n\t}\n" \
			+ "\tEMISSION = emission * emission_energy;\n\tif (use_emission_tex) {\n\t\tEMISSION *= texture(texture_emission, UV).rgb;\n\t}\n" \
			+ alpha_lines + "}\n"
		var nc: String = inject(code, kind)
		sh = Shader.new()
		sh.code = nc
		_shaders[ck] = sh
	var out := ShaderMaterial.new()
	out.shader = sh
	out.set_shader_parameter("albedo", m.albedo_color)
	if m.albedo_texture != null:
		out.set_shader_parameter("texture_albedo", m.albedo_texture)
		out.set_shader_parameter("use_albedo_tex", true)
	out.set_shader_parameter("use_vcol", m.vertex_color_use_as_albedo)
	if m.normal_enabled and m.normal_texture != null:
		out.set_shader_parameter("texture_normal", m.normal_texture)
		out.set_shader_parameter("use_normal", true)
		out.set_shader_parameter("normal_scale", m.normal_scale)
	out.set_shader_parameter("roughness", m.roughness)
	out.set_shader_parameter("metallic", m.metallic)
	out.set_shader_parameter("specular", m.metallic_specular)
	if m.emission_enabled:
		out.set_shader_parameter("emission", Color(m.emission.r, m.emission.g, m.emission.b))
		out.set_shader_parameter("emission_energy", m.emission_energy_multiplier)
		if m.emission_texture != null:
			out.set_shader_parameter("texture_emission", m.emission_texture)
			out.set_shader_parameter("use_emission_tex", true)
	out.set_shader_parameter("uv1_scale", m.uv1_scale)
	out.set_shader_parameter("uv1_offset", m.uv1_offset)
	out.set_shader_parameter("triplanar", m.uv1_triplanar)
	out.set_shader_parameter("triplanar_sharp", m.uv1_triplanar_sharpness)
	out.set_shader_parameter("alpha_scissor", m.alpha_scissor_threshold)
	out.render_priority = m.render_priority
	if tr == BaseMaterial3D.TRANSPARENCY_DISABLED and cull == "cull_back" and kind in [0, 3, 4, 5] and m.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED:
		out.next_pass = contour_material()
	return out
