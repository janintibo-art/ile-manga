extends Translation
## V104 : le choix de la langue (français, anglais, espagnol).
## Le jeu est écrit en français ; pour l'anglais et l'espagnol, cette « traduction » est branchée
## sur le TranslationServer de Godot : chaque texte affiché par un Label, un Button, un
## RichTextLabel ou un Label3D lui est soumis, et elle répond avec la table de la langue
## (res://data/langues/en.json, es.json) :
##  - « textes » : phrase française exacte -> traduction ;
##  - « motifs » : phrases avec des trous, {} (n'importe quel texte) et {n} (un nombre) ; les trous
##    sont recopiés dans la traduction (dans l'ordre, ou {1}, {2}… pour les remettre ailleurs), et le
##    texte d'un trou est lui-même traduit s'il est connu ;
##  - sinon, le texte est découpé (lignes, balises BBCode, séparateurs « • », « · », « — », « | »)
##    et chaque morceau est traduit à part ; les décorations (✦, ▸, parenthèses…) sont gardées, et
##    une phrase en MAJUSCULES est traduite comme sa version normale, puis remise en majuscules.
## Ce qui n'est pas dans la table reste en français (les tables grandissent version après version).
##
## API (statique) : Langue.charger() au démarrage ; Langue.choisir("en") ; Langue.code ;
##   Langue.t("texte") pour traduire à la main (texte composé dans le code, panneau VR) ;
##   Langue.nom("es") -> "Español" ; Langue.suivante() -> le code suivant (fr -> en -> es -> fr).

const CODES := ["fr", "en", "es"]
const NOMS := {"fr": "Français", "en": "English", "es": "Español"}
const FICHIER := "user://langue_v104.cfg"
const DECOR_DEBUT := " \u00a0\u202f\t([«\"'✦✧▸➤◉★●⚔•✓▶○◆◇✹⚑☀☠⌖🎒📜🗺👥⭐♥♡▲⚓➶◔-–:"
const DECOR_FIN := " \u00a0\u202f\t)]»\"'.!?…✦✧◆:,;"

static var code: String = "fr"
static var _textes: Dictionary = {}
static var _bas: Dictionary = {}          # minuscules -> traduction (pour les MAJUSCULES)
static var _motifs: Array = []            # [RegEx, modèle, nb de trous, début fixe, longueur]
static var _par_lettre: Dictionary = {}   # V106 : première lettre du début fixe -> motifs (les plus longs d'abord)
static var _sans_debut: Array = []        # V106 : les motifs qui commencent par un trou
static var _cache: Dictionary = {}
static var _inst: Translation = null
static var _sep: RegEx = null
## V107 : les textes déjà traduits (sorties du traducteur, répliques composées par les habitants) :
## on ne les retraduit pas quand une étiquette les affiche.
static var _sorties: Dictionary = {}


static func nom(c: String) -> String:
	return str(NOMS.get(c, c))


static func suivante() -> String:
	var i: int = CODES.find(code)
	return str(CODES[(i + 1) % CODES.size()])


## Au démarrage : la langue choisie la dernière fois.
static func charger() -> void:
	var cf := ConfigFile.new()
	var c: String = "fr"
	if cf.load(FICHIER) == OK:
		c = str(cf.get_value("langue", "code", "fr"))
	choisir(c, false)


static func choisir(c: String, garder: bool = true) -> void:
	if not CODES.has(c):
		c = "fr"
	code = c
	_cache.clear()
	_textes.clear()
	_bas.clear()
	_motifs.clear()
	_par_lettre.clear()
	_sans_debut.clear()
	_sorties.clear()
	if _inst != null:
		TranslationServer.remove_translation(_inst)
	if c != "fr":
		_lire_table(c)
		if _inst == null:
			_inst = (load("res://scripts/langue_v104.gd") as GDScript).new()
		_inst.locale = c
		TranslationServer.add_translation(_inst)
	TranslationServer.set_locale(c)
	if garder:
		var cf := ConfigFile.new()
		cf.set_value("langue", "code", c)
		cf.save(FICHIER)


static func _lire_table(c: String) -> void:
	var path: String = "res://data/langues/%s.json" % c
	if not FileAccess.file_exists(path):
		push_warning("V104 : table de langue absente " + path)
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("V104 : table de langue illisible " + path)
		return
	var tx: Dictionary = data.get("textes", {})
	for k in tx:
		_textes[str(k)] = str(tx[k])
		# V107 : les minuscules ne servent qu'aux noms et aux courtes étiquettes (pas aux dialogues)
		if str(k).length() <= 80:
			_bas[str(k).to_lower()] = str(tx[k])
	var mo: Dictionary = data.get("motifs", {})
	var keys: Array = mo.keys()
	# les motifs les plus longs d'abord (les plus précis)
	keys.sort_custom(func(a, b): return str(a).length() > str(b).length())
	for k2 in keys:
		var src: String = str(k2)
		var rx_s: String = "^"
		var holes: int = 0
		var i: int = 0
		while i < src.length():
			if src.substr(i, 3) == "{n}":
				rx_s += "(-?\\d+(?:[.,]\\d+)?)"
				holes += 1
				i += 3
			elif src.substr(i, 2) == "{}":
				rx_s += "([^•·|\\n]+?)"
				holes += 1
				i += 2
			else:
				var ch: String = src[i]
				rx_s += ("\\" + ch) if "\\^$.|?*+()[]{}/".contains(ch) else ch
				i += 1
		rx_s += "$"
		var rx := RegEx.new()
		if rx.compile(rx_s) == OK:
			var deb: String = src
			var cut: int = deb.find("{")
			if cut >= 0:
				deb = deb.substr(0, cut)
			var e: Array = [rx, str(mo[k2]), holes, deb, src.length()]
			_motifs.append(e)
			if deb == "":
				_sans_debut.append(e)
			else:
				if not _par_lettre.has(deb[0]):
					_par_lettre[deb[0]] = []
				_par_lettre[deb[0]].append(e)


## La traduction d'un texte (dans la langue choisie).
static func t(s: String) -> String:
	if code == "fr" or s == "":
		return s
	if _cache.has(s):
		return _cache[s]
	if _sorties.has(s):
		return s
	var r: String = _decoupe(s, 0)
	if _cache.size() > 6000:
		_cache.clear()
	_cache[s] = r
	marque(r)
	return r


## V107 : la traduction exacte d'un texte de la table (sans motif), "" s'il n'y en a pas.
static func exact(s: String) -> String:
	if code == "fr":
		return s
	return str(_textes.get(s, ""))


## V107 : ce texte est déjà dans la langue du joueur (une réplique composée morceau par morceau).
static func marque(s: String) -> String:
	if code != "fr" and s != "":
		if _sorties.size() > 6000:
			_sorties.clear()
		_sorties[s] = true
	return s


func _get_message(src_message: StringName, _context: StringName) -> StringName:
	return StringName(t(String(src_message)))


## Une phrase entière : la table, puis les motifs, puis sans les décorations.
static func _phrase(s: String, depth: int) -> String:
	if _textes.has(s):
		return _textes[s]
	if s == "":
		return ""
	if _sorties.has(s):
		return s
	# V106 : seuls les motifs qui commencent comme le texte (ou par un trou) sont essayés, toujours
	# les plus longs d'abord
	var a: Array = _par_lettre.get(s[0], [])
	var b: Array = _sans_debut
	var ia: int = 0
	var ib: int = 0
	while ia < a.size() or ib < b.size():
		var m: Array
		if ib >= b.size() or (ia < a.size() and int(a[ia][4]) >= int(b[ib][4])):
			m = a[ia]
			ia += 1
			if not s.begins_with(str(m[3])):
				continue
		else:
			m = b[ib]
			ib += 1
		var rm: RegExMatch = (m[0] as RegEx).search(s)
		if rm == null:
			continue
		var out: String = str(m[1])
		var vals: Array = []
		for g in range(1, int(m[2]) + 1):
			var v: String = rm.get_string(g)
			vals.append(_decoupe(v, depth + 1) if depth < 3 else v)   # V105 : le trou est découpé lui aussi
		for g2 in range(vals.size()):
			out = out.replace("{%d}" % (g2 + 1), vals[g2])
		# les trous dans l'ordre, {} ou {n}, le premier rencontré d'abord
		for v2 in vals:
			var a1: int = out.find("{}")
			var a2: int = out.find("{n}")
			if a1 < 0 and a2 < 0:
				break
			if a2 >= 0 and (a1 < 0 or a2 < a1):
				out = out.substr(0, a2) + str(v2) + out.substr(a2 + 3)
			else:
				out = out.substr(0, a1) + str(v2) + out.substr(a1 + 2)
		return out
	return ""


## Un morceau : tel quel, sinon sans ses décorations (d'abord les symboles, puis aussi la
## ponctuation), sinon en minuscules (pour les MAJUSCULES).
const PONCT := ".!?…:,;"


static func _coeur(s: String, depth: int) -> String:
	var r: String = _phrase(s, depth)
	if r != "":
		return r
	# V105 : un nom mis en minuscules au milieu d'une phrase (« 2 × pomme ») : la table, sans la
	# majuscule du début
	if s == s.to_lower() and _bas.has(s):
		var rb: String = str(_bas[s])
		return rb.substr(0, 1).to_lower() + rb.substr(1)
	var a: int = 0
	while a < s.length() and DECOR_DEBUT.contains(s[a]):
		a += 1
	for with_punct in [false, true]:
		var b: int = s.length()
		while b > a and DECOR_FIN.contains(s[b - 1]) and (with_punct or not PONCT.contains(s[b - 1])):
			b -= 1
		if b <= a:
			continue
		var core: String = s.substr(a, b - a).strip_edges()
		if core == s:
			continue
		var r2: String = _phrase(core, depth)
		if r2 == "" and core == core.to_upper() and core != core.to_lower() and _bas.has(core.to_lower()):
			r2 = str(_bas[core.to_lower()]).to_upper()
		if r2 != "":
			return s.substr(0, a) + r2 + _fin(s.substr(b))
	var core2: String = s.strip_edges()
	if core2 == core2.to_upper() and core2 != core2.to_lower() and _bas.has(core2.to_lower()):
		return str(_bas[core2.to_lower()]).to_upper()
	# V105 : une liste « a, b, c » (récompenses, objets à apporter) : élément par élément
	if depth < 3 and s.contains(", "):
		var outp: PackedStringArray = []
		var moved: bool = false
		for p in s.split(", "):
			var tp: String = _coeur(p, depth + 1)
			moved = moved or tp != p
			outp.append(tp)
		if moved:
			return ", ".join(outp)
	return s


## La ponctuation : « mot : » en français, « word: » en anglais et en espagnol.
static func _fin(suf: String) -> String:
	var st: String = suf.strip_edges()
	if st != "" and st in [":", "!", "?", ";", " :", "…"] or (st.length() <= 3 and st.begins_with(":")):
		return suf.lstrip(" \u00a0\u202f")
	return suf


## Un texte entier : on essaie d'abord tel quel, puis morceau par morceau.
static func _decoupe(s: String, depth: int) -> String:
	var whole: String = _phrase(s, depth)
	if whole != "":
		return whole
	if _sep == null:
		_sep = RegEx.new()
		_sep.compile("(\\[[^\\]\\n]*\\]|\\n|\\s+[•·—|]\\s+|\\s{2,}|\\t)")
	var out: String = ""
	var pos: int = 0
	var any_sep: bool = false
	for m in _sep.search_all(s):
		any_sep = true
		out += _morceau(s.substr(pos, m.get_start() - pos), depth)
		out += m.get_string()
		pos = m.get_end()
	if not any_sep:
		return _coeur(s, depth)
	out += _morceau(s.substr(pos), depth)
	return out


static func _morceau(p: String, depth: int) -> String:
	if p.strip_edges() == "":
		return p
	var lead: int = p.length() - p.lstrip(" ").length()
	var trail: int = p.length() - p.rstrip(" ").length()
	var core: String = p.strip_edges()
	return p.substr(0, lead) + _coeur(core, depth) + p.substr(p.length() - trail)
