"""Décisions d'apparence par personnage (forme MakeHuman, teint, coiffure, barbe, tenue).
Déterministe : graine = identifiant du personnage."""
import numpy as np, zlib, json

FEMALE = set('''adele aelwen aicha amelie anouk atlante_0 atlante_2 atlante_4 bricolette brume capucine caramel celeste
clemence colette dagna eclair ecrou electre elfe_1 elfe_3 elfe_5 elfe_7 elfe_8 fanny fatima gisele grelot gwenola halima
heloise hilda hortense ilyria ines khadija lea lila lilas lola lucie lulu lyra mamalou maree margaux margot merelune mochi
morgane myrtille nadine nain_1 nain_3 nain_6 nerea nimiel nina nolwenn odette ondine pauline pivoine plumette pommedepin
prudence rita rosa rosalie rose rosette salome samira selma sofia sylvie sylwen trefle ulfa ursule yasmine yaya zelie
zineb zoe zohra eclair archimage pyra zephyrine sauge berthe mirabelle lin ysolde agathe
anne_rose scarlett coquille mama_grog coralie gwen
neferet merit tiyi nebet ixkanul ixsak ixchab citlali xochitl nenetl
ignatia ferronde sulfura ortie hurla lumina calcine ombreline zebuline vesperine moloka brindille_braise brasille grisette flammeche'''.split())

OLD_EXTRA = {'faelar', 'thorgal', 'nori', 'merelune'}

# modificateurs du visage tirés au hasard (amplitude typique)
FACE_MODS = [
    ('head/head-oval', 0.5), ('head/head-round', 0.4), ('head/head-square', 0.4), ('head/head-triangular', 0.3),
    ('head/head-scale-horiz|decr,incr', 0.25), ('head/head-scale-vert|decr,incr', 0.2), ('head/head-fat|decr,incr', 0.3),
    ('forehead/forehead-scale-vert|decr,incr', 0.25), ('forehead/forehead-trans|backward,forward', 0.3), ('forehead/forehead-temple|decr,incr', 0.3),
    ('eyebrows/eyebrows-trans|down,up', 0.35), ('eyebrows/eyebrows-angle|down,up', 0.35),
    ('nose/nose-trans|down,up', 0.3), ('nose/nose-scale-vert|decr,incr', 0.45), ('nose/nose-scale-horiz|decr,incr', 0.45),
    ('nose/nose-scale-depth|decr,incr', 0.35), ('nose/nose-hump|decr,incr', 0.5), ('nose/nose-point-width|decr,incr', 0.45),
    ('nose/nose-nostrils-width|decr,incr', 0.4), ('nose/nose-curve|concave,convex', 0.4), ('nose/nose-greek|decr,incr', 0.3),
    ('nose/nose-volume|decr,incr', 0.35), ('nose/nose-flaring|decr,incr', 0.3), ('nose/nose-septumangle|decr,incr', 0.3),
    ('mouth/mouth-scale-horiz|decr,incr', 0.35), ('mouth/mouth-scale-vert|decr,incr', 0.3), ('mouth/mouth-lowerlip-volume|decr,incr', 0.4),
    ('mouth/mouth-upperlip-volume|decr,incr', 0.4), ('mouth/mouth-cupidsbow|decr,incr', 0.4), ('mouth/mouth-angles|down,up', 0.3),
    ('mouth/mouth-trans|backward,forward', 0.25), ('mouth/mouth-dimples|in,out', 0.3), ('mouth/mouth-laugh-lines|in,out', 0.3),
    ('chin/chin-prominent|decr,incr', 0.45), ('chin/chin-width|decr,incr', 0.45), ('chin/chin-height|decr,incr', 0.35),
    ('chin/chin-bones|decr,incr', 0.4), ('chin/chin-cleft|decr,incr', 0.35), ('chin/chin-jaw-drop|decr,incr', 0.3),
    ('cheek/l-cheek-bones|decr,incr', 0.4), ('cheek/r-cheek-bones|decr,incr', 0.4), ('cheek/l-cheek-volume|decr,incr', 0.4),
    ('cheek/r-cheek-volume|decr,incr', 0.4), ('cheek/l-cheek-inner|decr,incr', 0.3), ('cheek/r-cheek-inner|decr,incr', 0.3),
    ('ears/l-ear-scale|decr,incr', 0.3), ('ears/r-ear-scale|decr,incr', 0.3), ('ears/l-ear-flap|decr,incr', 0.3), ('ears/r-ear-flap|decr,incr', 0.3),
    ('ears/l-ear-lobe|decr,incr', 0.3), ('ears/r-ear-lobe|decr,incr', 0.3),
    ('eyes/l-eye-scale|decr,incr', 0.25), ('eyes/r-eye-scale|decr,incr', 0.25), ('eyes/l-eye-trans|in,out', 0.25), ('eyes/r-eye-trans|in,out', 0.25),
    ('eyes/l-eye-height2|decr,incr', 0.3), ('eyes/r-eye-height2|decr,incr', 0.3), ('eyes/l-eye-corner1|down,up', 0.3), ('eyes/r-eye-corner1|down,up', 0.3),
    ('eyes/l-eye-bag|decr,incr', 0.3), ('eyes/r-eye-bag|decr,incr', 0.3), ('eyes/l-eye-eyefold|down,up', 0.3), ('eyes/r-eye-eyefold|down,up', 0.3),
    ('neck/neck-scale-horiz|decr,incr', 0.25), ('neck/neck-scale-vert|decr,incr', 0.25),
]
# paires gauche/droite tirées ensemble (visage symétrique, à une légère asymétrie près)
PAIRS = {}
for k, _ in FACE_MODS:
    if '/l-' in k:
        PAIRS[k] = k.replace('/l-', '/r-')


def rng_for(pid, salt=''):
    return np.random.default_rng(zlib.crc32((pid + salt).encode()))


def mix(a, b, t):
    return [a[i] * (1 - t) + b[i] * t for i in range(3)]


def clamp01(x):
    return float(min(1.0, max(0.0, x)))


def lum(c):
    return 0.3 * c[0] + 0.55 * c[1] + 0.15 * c[2]


def decide(pid, p):
    r = rng_for(pid)
    az = p.get('azur', {})
    el = p.get('elfe', {})
    na = p.get('nain', {})
    ke = p.get('kemo', {})
    species = 'humain'
    if 'nain' in p:
        species = 'nain'
    elif 'atlante' in p:
        species = 'atlante'
    elif 'elfe' in p:
        species = 'elfe'
    elif 'kemo' in p:
        species = 'kemo'
    elif 'demon' in p:
        species = 'demon'
    female = pid in FEMALE
    taille = float(az.get('taille', el.get('taille', na.get('taille', 1.0))))
    old = bool(az.get('vieux', False)) or pid in OLD_EXTRA
    child = taille <= 0.82 and species != 'nain'
    carrure = float(az.get('carrure', 1.0))
    teinte = p.get('teinte', [0.95, 0.8, 0.68])
    titre = str(p.get('titre', '')).lower()
    # ------------------------------------------------------------ forme
    m = {}
    m['gender'] = clamp01((0.02 + r.random() * 0.08) if female else (0.92 + r.random() * 0.08))
    if child:
        m['age'] = 0.15 + (taille - 0.64) * 1.05 + r.random() * 0.02
    elif old:
        m['age'] = 0.84 + r.random() * 0.12
    else:
        m['age'] = 0.46 + r.random() * 0.16
        if any(w in titre for w in ('apprenti', 'jeune', 'mousse', 'gamin')):
            m['age'] = 0.38 + r.random() * 0.08
    if species == 'nain':
        m['age'] = 0.62 + r.random() * 0.2 if not old else 0.86 + r.random() * 0.08
        if 'apprenti' in titre:
            m['age'] = 0.5
    m['muscle'] = 0.5 + r.normal(0, 0.1) + (0.06 if not female else 0.0) - (0.1 if old else 0.0)
    m['weight'] = 0.5 + r.normal(0, 0.12)
    if carrure > 1.0:
        m['weight'] += (carrure - 1.0) * 1.3
        m['muscle'] += (carrure - 1.0) * (0.9 if not female else 0.3)
    if child:
        m['weight'] = 0.5 + r.normal(0, 0.06)
        m['muscle'] = 0.5
    if taille != 1.0 and not child and species != 'nain':
        m['height'] = 0.5 + (taille - 1.0) * 5.0
    else:
        m['height'] = 0.5 + r.normal(0, 0.15)
    m['proportions'] = 0.5 + r.normal(0, 0.18)
    L = lum(teinte)
    if L > 0.86:
        rc = [0.04, 0.06, 0.9]
    elif L > 0.74:
        rc = [0.12, 0.08, 0.8]
    elif L > 0.62:
        rc = [0.35, 0.1, 0.55]
    else:
        rc = [0.7, 0.05, 0.25]
    rc = [max(0.0, x + r.normal(0, 0.06)) for x in rc]
    if r.random() < 0.12 and p.get('village') not in ('tazira',):
        rc[1] += 0.4
    # V69 : les peuples des Trois Soleils (Égyptiens ; Mayas et Aztèques, aux traits amérindiens)
    if p.get('village') == 'egypte':
        rc = [0.3 + r.normal(0, 0.05), 0.08, 0.62 + r.normal(0, 0.05)]
    elif p.get('village') in ('maya', 'azteque'):
        rc = [0.12 + r.normal(0, 0.04), 0.58 + r.normal(0, 0.06), 0.3 + r.normal(0, 0.05)]
    # V70 : les démons de Pandémonia (la peau rouge, violette ou cendrée vient de la teinte)
    if species == 'demon':
        rc = [0.25 + r.normal(0, 0.08), 0.1 + r.normal(0, 0.05), 0.65 + r.normal(0, 0.08)]
    rc = [max(0.0, x) for x in rc]
    m['african'], m['asian'], m['caucasian'] = rc
    m['breastsize'] = clamp01(0.4 + r.normal(0, 0.15)) if female else 0.5
    m['breastfirmness'] = 0.3 if old else 0.5 + r.normal(0, 0.1)
    mods = {}
    amp = 1.0 if not child else 0.6
    for k, a in FACE_MODS:
        if '/r-' in k and k.replace('/r-', '/l-') in PAIRS:
            continue
        v = float(np.clip(r.normal(0, a * 0.8), -a * 1.6, a * 1.6)) * amp
        if '|' not in k:
            v = max(0.0, v)          # cibles simples : 0..1 seulement
        mods[k] = v
        if k in PAIRS:
            mods[PAIRS[k]] = v + r.normal(0, 0.04)
    # ------------------------------------------------------------ espèces
    if species in ('elfe', 'atlante'):
        m['height'] = 0.58 + r.random() * 0.17 if not child else m['height']
        m['weight'] = 0.32 + r.random() * 0.12
        m['muscle'] = 0.42 + r.random() * 0.1
        m['proportions'] = 0.95
        for s in ('l', 'r'):
            mods['ears/%s-ear-shape|pointed,triangle' % s] = -1.0
            mods['ears/%s-ear-scale-vert|decr,incr' % s] = 0.7
            mods['ears/%s-ear-trans|down,up' % s] = 0.35
            mods['ears/%s-ear-rot|backward,forward' % s] = -0.4
            mods['ears/%s-ear-wing|decr,incr' % s] = 0.3
            mods['eyes/%s-eye-scale|decr,incr' % s] = 0.25
            mods['eyes/%s-eye-corner1|down,up' % s] = 0.35
            mods['cheek/%s-cheek-bones|decr,incr' % s] = 0.45
        mods['nose/nose-scale-horiz|decr,incr'] = -0.35
        mods['nose/nose-scale-vert|decr,incr'] = mods.get('nose/nose-scale-vert|decr,incr', 0) * 0.5
        mods['chin/chin-width|decr,incr'] = -0.3
        mods['head/head-oval'] = 0.7
        mods['neck/neck-scale-vert|decr,incr'] = 0.3
    if species == 'nain':
        m['height'] = 0.0
        m['muscle'] = 0.75 + r.random() * 0.15
        m['weight'] = 0.7 + r.random() * 0.2
        m['proportions'] = 0.2
        mods['armslegs/lowerlegs-height|decr,incr'] = -1.0
        mods['armslegs/upperlegs-height|decr,incr'] = -1.0
        mods['torso/torso-scale-horiz|decr,incr'] = 0.6
        mods['torso/torso-scale-depth|decr,incr'] = 0.5
        mods['head/head-scale-horiz|decr,incr'] = 0.45
        mods['head/head-scale-vert|decr,incr'] = 0.35
        mods['head/head-scale-depth|decr,incr'] = 0.35
        mods['nose/nose-volume|decr,incr'] = 0.8
        mods['nose/nose-scale-horiz|decr,incr'] = 0.6
        mods['nose/nose-scale-depth|decr,incr'] = 0.4
        mods['nose/nose-point-width|decr,incr'] = 0.7
        mods['neck/neck-scale-vert|decr,incr'] = -0.6
        mods['neck/neck-scale-horiz|decr,incr'] = 0.6
        for s in ('l', 'r'):
            mods['armslegs/%s-hand-scale|decr,incr' % s] = 0.5
            mods['armslegs/%s-foot-scale|decr,incr' % s] = 0.4
            mods['eyebrows/eyebrows-trans|down,up'] = -0.4
    if species == 'kemo':
        for s in ('l', 'r'):
            mods['ears/%s-ear-scale|decr,incr' % s] = -0.8
            mods['ears/%s-ear-flap|decr,incr' % s] = -0.6
        if ke.get('espece') in ('chat', 'renard'):
            mods['nose/nose-scale-horiz|decr,incr'] = -0.3
            mods['nose/nose-point-width|decr,incr'] = -0.3
            mods['chin/chin-width|decr,incr'] = -0.25
        if ke.get('espece') == 'ours':
            m['weight'] = max(m['weight'], 0.75)
            m['muscle'] = max(m['muscle'], 0.7)
    if species == 'demon':
        # des oreilles pointues, des sourcils qui remontent (l'air malicieux), des pommettes hautes
        for sd in ('l', 'r'):
            mods['ears/%s-ear-shape|pointed,triangle' % sd] = -0.9
            mods['ears/%s-ear-scale-vert|decr,incr' % sd] = 0.5
            mods['ears/%s-ear-trans|down,up' % sd] = 0.25
            mods['ears/%s-ear-rot|backward,forward' % sd] = -0.3
            mods['cheek/%s-cheek-bones|decr,incr' % sd] = 0.35
            mods['eyes/%s-eye-corner1|down,up' % sd] = 0.3
        mods['eyebrows/eyebrows-angle|down,up'] = 0.45
    for k in ('muscle', 'weight', 'height', 'proportions'):
        m[k] = clamp01(m[k])
    # ------------------------------------------------------------ teint, visage
    look = {}
    if species == 'atlante':
        skin = [0.74, 0.82, 0.86]
    elif species == 'elfe':
        skin = [min(0.95, teinte[0] * 0.9), min(0.85, teinte[1] * 0.84), min(0.8, teinte[2] * 0.82)]
    elif species == 'demon':
        skin = [teinte[0] * 0.9, teinte[1] * 0.86, teinte[2] * 0.86]
    else:
        skin = [teinte[0] * 0.88, teinte[1] * 0.79, teinte[2] * 0.76]
    skin = [x * (1 + r.normal(0, 0.025)) for x in skin]
    look['peau'] = skin
    hair = az.get('cheveux', el.get('cheveux', na.get('barbe', [0.25, 0.16, 0.1])))
    if pid == 'barnabe':
        hair = [0.92, 0.9, 0.86]
    if pid == 'octave':
        hair = [0.5, 0.46, 0.42]
    look['cheveux'] = hair
    look['poils'] = list(na.get('barbe', hair))
    brow = [c * 0.78 for c in hair] if lum(hair) > 0.25 else hair
    if old and lum(hair) > 0.6:
        brow = [c * 0.88 for c in hair]
    look['sourcils'] = brow
    look['sourcils_epais'] = (0.62 + r.random() * 0.3) if not female else (0.22 + r.random() * 0.25)
    if species == 'nain':
        look['sourcils_epais'] = 1.0
    if child:
        look['sourcils_epais'] = 0.25
    lips = [skin[0] * 0.86, skin[1] * 0.58, skin[2] * 0.6]
    look['levres_force'] = 0.62
    if female and not child:
        look['levres_force'] = 0.8
        if r.random() < 0.45 or p.get('village') == 'teuf':
            lips = [[0.72, 0.16, 0.2], [0.78, 0.36, 0.42], [0.55, 0.18, 0.28], [0.82, 0.42, 0.38]][int(r.integers(4))]
            look['levres_force'] = 0.88
        if r.random() < 0.5 or p.get('village') == 'teuf':
            look['fard_force'] = 0.2 + r.random() * 0.3
            look['fard'] = [[0.45, 0.32, 0.42], [0.35, 0.3, 0.25], [0.32, 0.38, 0.5], [0.5, 0.36, 0.3]][int(r.integers(4))]
    if species == 'demon':
        lips = [skin[0] * 0.62, skin[1] * 0.42, skin[2] * 0.5]
    look['levres'] = lips
    look['rose'] = 0.15 + r.random() * 0.3 + (0.15 if female else 0.0)
    if species == 'demon':
        look['rose'] = 0.05
    eyes = az.get('yeux', el.get('yeux', None))
    if eyes is None:
        eyes = [[0.3, 0.2, 0.1], [0.25, 0.4, 0.55], [0.3, 0.45, 0.3], [0.2, 0.14, 0.08]][int(r.integers(4))]
    look['iris'] = eyes
    age_years = m['age']
    look['age'] = 0.0 if m['age'] < 0.52 else min(1.0, (m['age'] - 0.52) * 2.4)
    if old:
        look['age'] = 0.8 + r.random() * 0.2
    # ------------------------------------------------------------ coiffure et barbe
    style = str(az.get('coiffure', el.get('coiffure', 'court')))
    if species == 'nain':
        coiffe = str(na.get('coiffe', 'casque'))
        style = 'chauve' if coiffe == 'chauve' else ('nain_long' if not female else 'nain_tresses')
    teuf = p.get('teuf', {})
    if 'dreads' in teuf:
        style = 'dreads'
        look['cheveux'] = teuf['dreads']
    beard = str(az.get('barbe', ''))
    if species == 'nain' and not female:
        beard = 'nain_' + str(na.get('style_barbe', 'large'))
    if pid == 'barnabe':
        beard, style = 'longue', 'chauve_couronne'
    if pid == 'octave':
        beard, style = 'moustache', 'court'
    if style == 'chauve' and species != 'nain' and not female and (old or r.random() < 0.5):
        style = 'chauve_couronne'
    look['crane'] = 1.0
    if style == 'chauve':
        look['crane'] = 0.0 if r.random() < 0.5 else 0.25
    if style == 'chauve_couronne':
        look['crane'] = 0.35
    # barbe rasée / ombre
    if female or child:
        look['barbe'] = [0.0, 0.0, 0.0]
    else:
        s = [0.06, 0.25, 0.45, 0.7][int(r.integers(4))]
        if old:
            s *= 0.6
        look['barbe'] = [s, s, s * 0.9]
        if beard in ('moustache',):
            look['barbe'] = [0.9, s, s]
        elif beard in ('courte', 'longue') or beard.startswith('nain'):
            look['barbe'] = [0.9, 0.9, 0.8]
    if species in ('elfe', 'atlante'):
        look['barbe'] = [0.0, 0.0, 0.0]
    look['cils'] = [c * 0.35 for c in brow] if lum(hair) > 0.5 else [0.05, 0.04, 0.035]
    return dict(id=pid, species=species, female=female, child=child, old=old, taille=taille, morph=m, mods=mods,
                look=look, hair=style, beard=beard, carrure=carrure, village=p.get('village'))


# =================================================================== tenues

TROUSERS = {
    'azur': [[0.86, 0.82, 0.72], [0.18, 0.22, 0.35], [0.55, 0.5, 0.4], [0.92, 0.92, 0.9], [0.3, 0.32, 0.36]],
    'carene': [[0.15, 0.18, 0.3], [0.3, 0.28, 0.24], [0.2, 0.2, 0.22], [0.4, 0.36, 0.3]],
    'tazira': [[0.85, 0.8, 0.68], [0.55, 0.45, 0.32], [0.3, 0.3, 0.32], [0.65, 0.55, 0.42], [0.92, 0.9, 0.85]],
    'cliquetis': [[0.22, 0.2, 0.2], [0.35, 0.28, 0.2], [0.18, 0.2, 0.26], [0.42, 0.38, 0.32]],
    'ramure': [[0.4, 0.32, 0.22], [0.32, 0.36, 0.24], [0.5, 0.44, 0.34], [0.28, 0.24, 0.2]],
    'teuf': [[0.22, 0.3, 0.48], [0.15, 0.15, 0.16], [0.75, 0.7, 0.6], [0.3, 0.4, 0.3]],
    'balafre': [[0.2, 0.17, 0.15], [0.38, 0.3, 0.22], [0.15, 0.16, 0.22], [0.55, 0.48, 0.38], [0.3, 0.12, 0.1]],
    'egypte': [[0.95, 0.93, 0.86], [0.92, 0.9, 0.82]],
    'maya': [[0.92, 0.9, 0.84], [0.7, 0.2, 0.15], [0.2, 0.3, 0.6]],
    'azteque': [[0.94, 0.92, 0.86], [0.85, 0.75, 0.4], [0.25, 0.5, 0.55]],
    'pandemonia': [[0.12, 0.1, 0.1], [0.25, 0.08, 0.08], [0.18, 0.14, 0.2], [0.3, 0.24, 0.2]],
}
SHOES = [[0.32, 0.2, 0.12], [0.12, 0.1, 0.09], [0.45, 0.32, 0.2], [0.55, 0.42, 0.3]]


def col(c):
    return [float(x) for x in c]


def darker(c, k=0.6):
    return [x * k for x in c]


def outfit(D, p):
    r = rng_for(D['id'], 'tenue')
    az = p.get('azur', {})
    el = p.get('elfe', {})
    na = p.get('nain', {})
    tz = p.get('tz', {})
    cq = p.get('cq', {})
    vil = D['village'] or 'azur'
    titre = str(p.get('titre', '')).lower()
    female, child, old = D['female'], D['child'], D['old']
    haut = col(az.get('haut', [0.8, 0.78, 0.72]))
    pal = TROUSERS.get(vil, TROUSERS['azur'])
    trous = col(pal[int(r.integers(len(pal)))])
    shoe = col(SHOES[int(r.integers(len(SHOES)))])
    T = []

    def add(v, c, tissu='coton', **kw):
        g = {'v': v, 'c': col(c), 'tissu': tissu}
        g.update(kw)
        T.append(g)
    pid = D['id']
    # --------------------------------------------------------- cas particuliers
    if pid == 'barnabe':
        add('chemise_courte', [0.86, 0.8, 0.66], 'lin', boutons=1.0)
        add('pantacourt', [0.62, 0.55, 0.42], 'toile')
        return T
    if pid == 'octave':
        add('chemise_longue', [0.62, 0.6, 0.56], 'lin', boutons=1.0)
        add('pantalon', [0.3, 0.24, 0.18], 'toile', poches=1.0)
        add('bottes', [0.2, 0.14, 0.1], 'cuir')
        add('tablier', [0.36, 0.22, 0.12], 'cuir')
        add('bavette', [0.36, 0.22, 0.12], 'cuir')
        return T
    if D['species'] in ('elfe', 'atlante') or pid == 'lyra':
        robe = col(el.get('robe', [0.16, 0.42, 0.32]))
        cape = el.get('cape')
        bijou = col(el.get('bijou', [0.85, 0.85, 0.8]))
        soft = 'soie' if D['species'] == 'atlante' else 'lin'
        if str(el.get('silhouette', 'robe')) == 'tunique':
            add('tunique_haut', robe, soft)
            add('tunique_bas', robe, soft)
            add('collant', darker(robe, 0.45), 'coton')
            add('bottes_hautes', [0.36, 0.26, 0.17], 'cuir')
        else:
            add('corsage_long', robe, soft)
            add('jupe_longue', robe, soft)
            add('chaussures', [0.42, 0.32, 0.22], 'cuir')
        add('ceinture_ample', bijou, 'cuir')
        if cape and D['species'] != 'atlante' and not child:
            add('cape', cape, 'laine' if D['species'] == 'elfe' else soft)
        return T
    if D['species'] == 'nain':
        tun = col(na.get('tunique', [0.4, 0.2, 0.12]))
        add('tunique_haut', tun, 'laine')
        add('tunique_bas', tun, 'laine')
        add('pantalon', [0.32, 0.26, 0.2], 'toile')
        add('bottes', [0.25, 0.17, 0.11], 'cuir')
        add('ceinture_ample', [0.3, 0.19, 0.1], 'cuir')
        if na.get('tablier'):
            add('tablier', [0.32, 0.2, 0.11], 'cuir')
        if na.get('cape'):
            add('cape', na['cape'], 'laine')
        return T
    # --------------------------------------------------------- Arcanelle : robes de sorciers
    arc = p.get('arc')
    if vil == 'arcanelle' and arc:
        robe = col(arc.get('robe', haut))
        tissu = 'laine' if old else 'lin'
        if female:
            add('corsage_long', robe, tissu)
            add('jupe_longue', robe, tissu)
            add('ceinture_ample', [0.78, 0.62, 0.3] if arc.get('etoiles') else darker(robe, 0.5), 'cuir')
        elif az.get('tablier') or child:
            add('tunique_haut', robe, tissu)
            add('tunique_bas', robe, tissu)
            add('pantalon', darker(robe, 0.45), 'toile')
            add('ceinture_ample', [0.3, 0.2, 0.12], 'cuir')
        else:
            add('djellaba_haut', robe, tissu)
            add('djellaba_bas', robe, tissu)
            add('pantalon', darker(robe, 0.45), 'toile')
        add('chaussures' if child else 'bottes', [0.24, 0.16, 0.1], 'cuir')
        if az.get('tablier'):
            add('tablier', az['tablier'], 'coton')
        if az.get('foulard'):
            add('col', az['foulard'], 'soie')
        if arc.get('cape') and not child:
            add('cape', arc['cape'], 'laine')
        return T
    # --------------------------------------------------------- V70 : les démons de Pandémonia
    dem = p.get('demon')
    if vil == 'pandemonia' and isinstance(dem, dict):
        tenue = str(dem.get('tenue', 'artisan'))
        noir = [0.1, 0.08, 0.09]
        bordeaux = [0.35, 0.06, 0.08]
        bottes = [0.12, 0.08, 0.07]
        if child:
            add('tshirt' if not female else 'corsage', haut, 'coton')
            add('short' if not female else 'jupe', darker(haut, 0.5), 'coton')
            add('chaussures', [0.25, 0.12, 0.08], 'cuir')
            return T
        if tenue == 'noble':
            if female:
                add('corsage_long', haut, 'soie')
                add('jupe_longue', darker(haut, 0.7), 'soie')
                add('ceinture_ample', [0.85, 0.62, 0.25], 'soie')
            else:
                add('chemise_longue', [0.9, 0.86, 0.8], 'soie', boutons=1.0)
                add('veste', haut, 'laine')
                add('pantalon', noir, 'laine')
            add('bottes', bottes, 'cuir')
            if not dem.get('ailes'):
                add('cape', bordeaux if lum(haut) > 0.2 else [0.45, 0.08, 0.1], 'laine')
        elif tenue in ('savant', 'pretre'):
            add('djellaba_haut', haut, 'laine')
            add('djellaba_bas', haut, 'laine')
            add('pantalon', noir, 'toile')
            add('chaussures', bottes, 'cuir')
            if tenue == 'pretre':
                add('ceinture_ample', [0.85, 0.55, 0.15], 'laine')
            elif not dem.get('ailes'):
                add('cape', darker(haut, 0.6), 'laine')
        elif tenue == 'garde':
            add('tunique_haut', haut, 'laine')
            add('tunique_bas', haut, 'laine')
            add('collant', noir, 'coton')
            add('bottes_hautes', bottes, 'cuir')
            add('ceinture_ample', [0.25, 0.15, 0.08], 'cuir')
            add('cape', bordeaux, 'laine')
        elif tenue == 'gladiateur':
            if female:
                add('corsage', haut, 'coton')
                add('pantalon', [0.3, 0.2, 0.12], 'toile')
            else:
                add('tunique_haut', haut, 'cuir')
                add('tunique_bas', [0.3, 0.2, 0.12], 'cuir')
                add('pantalon', [0.18, 0.12, 0.1], 'toile')
            add('bottes_hautes', bottes, 'cuir')
            add('ceinture_ample', [0.6, 0.45, 0.2], 'cuir')
        elif tenue == 'marin':
            add('chemise_longue' if not female else 'corsage_long', haut, 'lin', boutons=1.0)
            add('gilet', [0.15, 0.12, 0.1], 'cuir')
            add('pantalon', trous, 'toile', poches=1.0)
            add('bottes', bottes, 'cuir')
            add('ceinture_ample', [0.55, 0.1, 0.08], 'laine')
        elif tenue == 'cuisinier':
            add('chemise_courte', haut, 'coton', boutons=1.0)
            add('pantalon', [0.2, 0.18, 0.18], 'toile', poches=1.0)
            add('chaussures', bottes, 'cuir')
            add('tablier', [0.95, 0.94, 0.9] if lum(haut) < 0.8 else [0.6, 0.15, 0.1], 'coton')
        elif tenue == 'marchand':
            if female:
                add('corsage_long', haut, 'coton')
                add('jupe_longue', darker(haut, 0.55), 'coton')
            else:
                add('chemise_longue', haut, 'coton', boutons=1.0)
                add('gilet', darker(haut, 0.5), 'laine')
                add('pantalon', trous, 'toile', poches=1.0)
            add('chaussures', bottes, 'cuir')
        else:  # artisan
            if female:
                add('corsage', haut, 'coton')
                add('pantalon', trous, 'toile', poches=1.0)
            else:
                add('chemise_courte', haut, 'coton', boutons=1.0)
                add('pantalon', trous, 'toile', poches=1.0)
            add('bottes', bottes, 'cuir')
            add('tablier', [0.3, 0.18, 0.1], 'cuir')
        if az.get('foulard'):
            add('col', az['foulard'], 'soie')
        return T
    # --------------------------------------------------------- V69 : les Trois Soleils (Égyptiens, Mayas, Aztèques)
    sol = p.get('sol')
    if vil in ('egypte', 'maya', 'azteque') and isinstance(sol, dict):
        tenue = str(sol.get('tenue', 'peuple'))
        lin = [0.95, 0.93, 0.86]
        sandales = [0.62, 0.48, 0.3]
        if vil == 'egypte':
            if female or (child and female):
                add('corsage_long', lin, 'lin')
                add('jupe_longue', lin, 'lin')
                if tenue == 'pretre':
                    add('cape', [0.97, 0.95, 0.9], 'lin')
                    add('ceinture_ample', [0.85, 0.65, 0.2], 'soie')
                else:
                    add('ceinture_ample', [0.75, 0.3, 0.22] if r.random() < 0.5 else [0.25, 0.45, 0.6], 'lin')
            else:
                if tenue in ('scribe', 'pretre'):
                    add('tunique_haut', lin, 'lin')
                    add('jupe_longue' if tenue == 'pretre' else 'jupe', lin, 'lin')
                else:
                    add('debardeur', lin, 'lin')
                    add('jupe', [0.92, 0.9, 0.82], 'lin')
                add('ceinture_ample', [0.9, 0.88, 0.8] if tenue != 'scribe' else [0.25, 0.4, 0.62], 'lin')
            add('chaussures', sandales, 'cuir')
            return T
        haut = col(az.get('haut', lin))
        if vil == 'maya':
            if female:
                add('tunique_haut', haut, 'coton', motif=5, c2=[0.75, 0.15, 0.12], echelle=0.045)
                add('jupe_longue', [0.2, 0.28, 0.55] if r.random() < 0.6 else [0.55, 0.15, 0.12], 'coton')
            else:
                if tenue in ('pretre', 'joueur', 'chasseur'):
                    add('debardeur', haut, 'coton')
                else:
                    add('tunique_haut', haut, 'coton', motif=5, c2=[0.2, 0.3, 0.6], echelle=0.05)
                add('jupe', [0.9, 0.88, 0.8] if tenue != 'chasseur' else [0.45, 0.32, 0.2], 'coton')
                add('ceinture_ample', [0.75, 0.15, 0.1] if tenue != 'joueur' else [0.45, 0.3, 0.2], 'cuir' if tenue == 'joueur' else 'coton')
                if tenue == 'pretre':
                    add('cape', [0.12, 0.45, 0.32], 'coton')
                elif tenue == 'chasseur':
                    add('cape', [0.5, 0.36, 0.2], 'cuir')
            add('chaussures', sandales, 'cuir')
            return T
        # les Aztèques
        if female:
            add('tunique_haut', haut, 'coton', motif=5, c2=[0.25, 0.5, 0.55], echelle=0.05)
            add('jupe_longue', [0.94, 0.92, 0.86], 'coton')
        elif tenue == 'guerrier':
            add('collant', [0.85, 0.65, 0.2], 'coton', motif=4, c2=[0.15, 0.1, 0.06], echelle=0.05)
            add('debardeur', [0.85, 0.65, 0.2], 'coton', motif=4, c2=[0.15, 0.1, 0.06], echelle=0.05)
            add('ceinture_ample', [0.75, 0.12, 0.1], 'cuir')
        else:
            add('tunique_haut' if tenue != 'pretre' else 'debardeur', [0.94, 0.92, 0.86] if tenue != 'pretre' else [0.1, 0.1, 0.12], 'coton')
            add('jupe', [0.9, 0.88, 0.82], 'coton')
            add('ceinture_ample', [0.75, 0.15, 0.1], 'coton')
            add('cape', haut if tenue != 'pretre' else [0.1, 0.1, 0.12], 'coton')
        add('chaussures', sandales, 'cuir')
        return T
    # --------------------------------------------------------- V68 : la Balafre : les pirates et les gens du port
    pir = p.get('pirate')
    if vil == 'balafre' and isinstance(pir, dict):
        role = str(pir.get('role', ''))
        shirt = [0.9, 0.86, 0.76] if r.random() < 0.55 else col(haut)
        sash = [[0.62, 0.1, 0.08], [0.12, 0.1, 0.1], [0.75, 0.55, 0.15], [0.15, 0.3, 0.5]][int(r.integers(4))]
        boots = [0.16, 0.11, 0.08]
        if role in ('capitaine', 'gouverneur', 'cartographe', 'conteur', 'receleur', 'croupier'):
            if female:
                add('corsage_long', [0.92, 0.88, 0.8], 'lin', boutons=1.0)
                add('veste', haut, 'laine')
                add('pantalon', trous, 'toile')
            else:
                add('chemise_longue', [0.92, 0.9, 0.84] if role != 'conteur' else [0.7, 0.66, 0.58], 'lin', boutons=1.0)
                add('veste', haut, 'laine')
                add('pantalon', trous, 'toile', poches=1.0)
            if role in ('capitaine', 'conteur'):
                add('ceinture_ample', sash, 'laine')
            add('bottes', boots, 'cuir')
        elif role in ('tavernière', 'tatoueuse') or (female and role in ('charpentière',)):
            add('corsage_long', col(haut), 'coton')
            if role == 'tavernière':
                add('jupe_longue', [0.3, 0.16, 0.12], 'laine')
            else:
                add('pantalon', trous, 'toile', poches=1.0)
            add('ceinture_ample', sash, 'cuir')
            add('bottes', boots, 'cuir')
        elif female:
            add('corsage_long', shirt, 'lin', boutons=1.0)
            add('gilet', [0.22, 0.14, 0.1] if r.random() < 0.6 else darker(col(haut), 0.6), 'cuir')
            add('pantalon', trous, 'toile', poches=1.0)
            add('ceinture_ample', sash, 'laine')
            add('bottes', boots, 'cuir')
        else:
            if role in ('forgeron',):
                add('debardeur', [0.42, 0.36, 0.3], 'coton')
            elif r.random() < 0.3 and role in ('matelot', 'gabier', 'vigie', 'mousse', 'canonnier', 'timonier'):
                add('tshirt', [0.92, 0.9, 0.86], 'coton', motif=1, c2=[0.15, 0.2, 0.38], echelle=0.035)
            else:
                add('chemise_longue' if r.random() < 0.6 else 'chemise_courte', shirt, 'lin', boutons=1.0)
            if role not in ('forgeron', 'chirurgien', 'mousse', 'musicien') and r.random() < 0.7:
                add('gilet', [0.24, 0.15, 0.1] if r.random() < 0.6 else darker(col(haut), 0.55), 'cuir')
            elif role == 'musicien':
                add('gilet', [0.45, 0.12, 0.1], 'laine')
            add('pantacourt' if role in ('mousse', 'matelot', 'gabier') and r.random() < 0.6 else 'pantalon', trous, 'toile', poches=1.0)
            if role not in ('chirurgien', 'forgeron'):
                add('ceinture_ample', sash, 'laine')
            add('bottes', boots, 'cuir')
        if az.get('tablier'):
            add('tablier', az['tablier'], 'cuir' if role in ('forgeron', 'chirurgien') else 'coton')
        if az.get('foulard'):
            add('col', az['foulard'], 'soie')
        return T
    # --------------------------------------------------------- enfants
    if child:
        if female and az.get('robe'):
            add('corsage', haut, 'coton')
            add('jupe', az['robe'], 'coton')
        else:
            add('tshirt', haut, 'coton')
            add('short' if not female else ('jupe' if r.random() < 0.5 else 'short'), trous if not female else darker(haut, 0.7), 'coton')
        add('chaussures', [0.9, 0.9, 0.88] if r.random() < 0.4 else shoe, 'cuir')
        return T
    # --------------------------------------------------------- adultes
    motif = {}
    if vil == 'carene' and any(w in titre for w in ('mousse', 'pêcheur', 'calfat', 'guetteur', 'capitaine', 'marin')):
        motif = {'motif': 1, 'c2': [0.95, 0.95, 0.93], 'echelle': 0.035}
    elif r.random() < 0.18 and vil in ('azur', 'teuf', 'ramure', 'carene'):
        motif = {'motif': int(r.choice([2, 3, 4])), 'c2': [min(1, x * 1.35 + 0.15) for x in haut], 'echelle': 0.03 + 0.03 * r.random()}
    robe = az.get('robe')
    is_djellaba = (vil == 'tazira' and robe is not None and not female)
    if is_djellaba:
        add('djellaba_haut', robe, 'laine' if old else 'lin')
        add('djellaba_bas', robe, 'laine' if old else 'lin')
        add('pantalon', trous, 'lin')
        add('chaussures', [0.85, 0.65, 0.25] if r.random() < 0.5 else [0.6, 0.15, 0.1], 'cuir')
    elif female and robe is not None:
        long_dress = bool(az.get('robe_longue', False)) or vil == 'tazira'
        top = 'corsage_long' if (long_dress or old or vil in ('carene', 'cliquetis')) else ('corsage' if (r.random() < 0.65 or 'capitaine' in titre) else 'corsage_nu')
        if vil == 'teuf':
            top = 'debardeur'
        add(top, haut, 'coton', **motif)
        add('jupe_longue' if long_dress else 'jupe', robe, 'coton' if not long_dress else 'lin')
        add('chaussures', shoe, 'cuir')
    else:
        # haut
        if vil == 'teuf' or any(w in titre for w in ('maître-nageur', 'docker')):
            add('debardeur' if r.random() < 0.5 else 'tshirt', haut, 'coton')
        elif any(w in titre for w in ('joggeur', 'coureu', 'gamin')):
            add('tshirt', haut, 'coton')
        elif any(w in titre for w in ('capitaine', 'maire', 'réceptionniste', 'commandante', 'amirale', 'brigadier', 'garde', 'caïd', 'lord', 'professeur')):
            add('chemise_longue', [0.94, 0.94, 0.92] if 'brigadier' not in titre else [0.7, 0.75, 0.85], 'coton', boutons=1.0)
            if not p.get('pirate'):
                add('veste', haut, 'laine')
        elif vil in ('carene', 'cliquetis', 'ramure') and r.random() < 0.45:
            add('pull' if vil == 'carene' else 'chemise_longue', haut, 'laine' if vil == 'carene' else 'coton', boutons=0.0 if vil == 'carene' else 1.0, **motif)
            if vil == 'cliquetis' and r.random() < 0.6:
                add('gilet', darker(haut, 0.55) if lum(haut) > 0.5 else [0.45, 0.35, 0.22], 'laine', motif=2 if r.random() < 0.4 else 0, c2=darker(haut, 0.8))
        elif female:
            add('corsage_long' if (old or r.random() < 0.4) else 'corsage', haut, 'coton', **motif)
        else:
            add('chemise_courte' if vil in ('azur', 'tazira', 'teuf') or r.random() < 0.4 else 'chemise_longue', haut, 'lin' if vil in ('azur', 'tazira') else 'coton', boutons=1.0, **motif)
        if p.get('pirate'):
            add('gilet', [0.25, 0.16, 0.1], 'cuir')
            add('ceinture_ample', [0.6, 0.12, 0.1], 'laine')
        # bas
        if female and not (vil in ('teuf',) and r.random() < 0.5):
            if r.random() < 0.55 and vil not in ('cliquetis',):
                add('jupe' if r.random() < 0.6 else 'jupe_longue', darker(haut, 0.6) if r.random() < 0.5 else trous, 'coton')
            else:
                add('pantalon', trous, 'jean' if vil == 'teuf' else 'toile', poches=1.0)
        elif any(w in titre for w in ('maître-nageur', 'joggeur')):
            add('short', [0.15, 0.25, 0.55] if 'nageur' in titre else trous, 'coton')
        elif vil == 'teuf':
            add('bermuda' if r.random() < 0.5 else 'pantalon', trous, 'jean', poches=1.0)
        elif 'pêcheur' in titre or 'mousse' in titre:
            add('pantacourt', trous, 'toile', poches=1.0)
        else:
            add('pantalon', trous, 'lin' if vil in ('azur', 'tazira') else 'toile', poches=1.0)
        # chaussures
        if 'nageur' in titre:
            pass
        elif any(w in titre for w in ('pêcheur', 'docker', 'garde', 'grutier', 'calfat', 'forgeron', 'mousse', 'pisteu')) or p.get('pirate') or vil == 'carene':
            add('bottes', [0.18, 0.13, 0.1], 'cuir')
        else:
            add('chaussures', [0.92, 0.92, 0.9] if vil == 'teuf' else shoe, 'cuir')
    # accessoires textiles de la fiche
    if az.get('tablier'):
        bib = any(w in titre for w in ('chef', 'cuisin', 'boulang', 'forger', 'glacier', 'armurier', 'poissonn', 'boucher'))
        add('tablier' if not ('serveu' in titre or 'barman' in titre) else 'tablier_court', az['tablier'], 'cuir' if 'forger' in titre or 'armurier' in titre else 'coton')
        if bib:
            add('bavette', az['tablier'], 'cuir' if 'forger' in titre or 'armurier' in titre else 'coton')
    if az.get('foulard'):
        # foulard noué autour du cou : une bande ajustée au cou (pas un anneau posé sur les épaules)
        add('col', az['foulard'], 'soie')
    if cq.get('blouse'):
        add('chemise_longue', [0.92, 0.92, 0.9], 'coton', boutons=1.0)
        add('blouse_bas', cq['blouse'], 'coton')
    if not any(g['v'] in ('ceinture_ample',) for g in T) and any(g['v'] == 'pantalon' for g in T) and not female and r.random() < 0.5 \
            and not any(g['v'] in ('chemise_courte', 'chemise_longue', 'pull', 'veste', 'tshirt', 'debardeur') for g in T[:1]):
        add('ceinture_ample', [0.25, 0.16, 0.1], 'cuir')
    return T


SLOTS = [
    ('haut', ('chemise_courte', 'chemise_longue', 'chemise_rentree', 'tshirt', 'debardeur', 'pull', 'corsage', 'corsage_long', 'corsage_nu', 'tunique_haut', 'djellaba_haut')),
    ('dessus', ('veste', 'gilet')),
    ('bas', ('pantalon', 'pantacourt', 'bermuda', 'short', 'collant')),
    ('jupe', ('jupe', 'jupe_longue', 'tunique_bas', 'djellaba_bas', 'blouse_bas')),
    ('pieds', ('chaussures', 'bottes', 'bottes_hautes')),
    ('tablier', ('tablier', 'tablier_court')),
]


def clean_outfit(T, p):
    cq = p.get('cq', {})
    if cq.get('blouse'):
        # blouse de laboratoire : le haut prend la couleur de la blouse
        for g in T:
            if g['v'] in SLOTS[0][1]:
                g.update({'v': 'chemise_longue', 'c': col(cq['blouse']), 'tissu': 'coton', 'boutons': 1.0})
                break
    seen = set()
    out = []
    for g in T:
        slot = next((s for s, names in SLOTS if g['v'] in names), g['v'])
        if slot in seen:
            continue
        seen.add(slot)
        out.append(g)
    # un tablier sur une jupe : la variante qui passe au-dessus d'elle
    sur = {'jupe': 'jupe', 'jupe_longue': 'longue', 'tunique_bas': 'tunique'}
    jupe = next((sur[g['v']] for g in out if g['v'] in sur), None)
    if jupe is not None:
        for g in out:
            if g['v'] in ('tablier', 'tablier_court'):
                g['v'] = g['v'] + '_sur_' + jupe
    return out


def assets(D):
    r = rng_for(D['id'], 'coiffure')
    h = D['hair']
    hair = {'court': 'court_f' if D['female'] else 'court', 'long': 'long' if r.random() < 0.5 else 'long_b', 'carre': 'carre',
            'chignon': 'chignon', 'queue': 'queue', 'boucles': 'boucles', 'tresse': 'tresse', 'chauve': '',
            'chauve_couronne': 'chauve_couronne', 'dreads': 'dreads', 'nain_long': 'nain_long', 'nain_tresses': 'nain_tresses'}.get(h, 'court')
    beard = {'moustache': 'barbe_moustache', 'courte': 'barbe_courte', 'longue': 'barbe_longue',
             'nain_large': 'barbe_nain_large', 'nain_tresse': 'barbe_nain_tresse', 'nain_fourche': 'barbe_nain_fourche'}.get(D['beard'], '')
    return hair, beard


# =================================================================== chapeaux et coiffes (proxies)

HAT_CUT = {'ch_paille': 0.035, 'ch_capeline': 0.035, 'ch_casquette': 0.045, 'ch_kepi': 0.05, 'ch_marin': 0.05, 'ch_beret': 0.03,
           'ch_cuisinier': 0.05, 'ch_tricorne': 0.045, 'ch_haut_de_forme': 0.05, 'ch_fez': 0.02, 'ch_bonnet': 0.065,
           'ch_bandana': 0.045, 'ch_foulard_tete': 0.3, 'ch_capuche': 0.3, 'ch_casque': 0.075, 'ch_turban': 0.07, 'ch_casque_aviateur': 0.3,
           'ch_sorcier': 0.045}


def hats_for(D, p):
    az = p.get('azur', {})
    tz = p.get('tz', {})
    cq = p.get('cq', {})
    te = p.get('teuf', {})
    na = p.get('nain', {})
    out = []
    hc = az.get('chapeau_c')
    k = str(az.get('chapeau', ''))
    defaults = {'paille': [0.86, 0.72, 0.42], 'capeline': [0.92, 0.86, 0.7], 'casquette': [0.15, 0.2, 0.4], 'kepi': [0.12, 0.15, 0.3],
                'marin': [0.1, 0.13, 0.28], 'beret': [0.1, 0.1, 0.12], 'cuisinier': [0.97, 0.97, 0.96]}
    if k in defaults:
        out.append({'v': 'ch_' + k, 'c': col(hc if hc is not None else defaults[k]), 'tissu': 'paille' if k in ('paille', 'capeline') else ('laine' if k in ('beret', 'marin', 'kepi') else 'coton')})
    if D['id'] == 'barnabe':
        out.append({'v': 'ch_paille', 'c': [0.9, 0.72, 0.4], 'tissu': 'paille'})
    for key, v, tissu, dflt in (('turban', 'ch_turban', 'lin', [0.9, 0.88, 0.8]), ('fez', 'ch_fez', 'laine', [0.62, 0.08, 0.1]),
                                ('foulard_tete', 'ch_foulard_tete', 'soie', [0.6, 0.3, 0.3]), ('tricorne', 'ch_tricorne', 'laine', [0.08, 0.07, 0.07]),
                                ('bandana', 'ch_bandana', 'coton', [0.7, 0.1, 0.1])):
        if key in tz:
            c = tz[key] if isinstance(tz[key], list) else dflt
            out.append({'v': v, 'c': col(c), 'tissu': tissu})
    if 'haut_de_forme' in cq:
        out.append({'v': 'ch_haut_de_forme', 'c': col(cq['haut_de_forme']), 'tissu': 'laine'})
    if 'casque_aviateur' in cq:
        out.append({'v': 'ch_casque_aviateur', 'c': col(cq['casque_aviateur']), 'tissu': 'cuir'})
    if 'bonnet' in te:
        out.append({'v': 'ch_bonnet', 'c': col(te['bonnet']), 'tissu': 'laine'})
    if 'bandana' in te:
        out.append({'v': 'ch_bandana', 'c': col(te['bandana']), 'tissu': 'coton'})
    arc = p.get('arc', {})
    if 'chapeau' in arc:
        out.append({'v': 'ch_sorcier', 'c': col(arc['chapeau']), 'tissu': 'laine'})
    coiffe = str(na.get('coiffe', ''))
    if coiffe == 'casque':
        out.append({'v': 'ch_casque', 'c': col(na.get('metal', [0.6, 0.6, 0.64])), 'tissu': 'metal'})
    elif coiffe == 'capuche':
        out.append({'v': 'ch_capuche', 'c': col(na.get('tunique', [0.4, 0.2, 0.12])), 'tissu': 'laine'})
    elif coiffe == 'bonnet':
        out.append({'v': 'ch_bonnet', 'c': [0.75, 0.2, 0.15], 'tissu': 'laine'})
    out = out[:1]
    cut = HAT_CUT.get(out[0]['v'], 99.0) if out else 99.0
    return out, cut


def adult_height(D, hgt):
    """taille finale d'un adulte (m) : la forme MakeHuman garde ses proportions, mais la taille
    reste humaine (les très grands et les très petits sont ramenés en douceur vers la moyenne).
    Une taille donnée par la fiche (1,1 : un costaud) part de la moyenne de son sexe."""
    female = D['female']
    c, s = (1.63, 0.14) if female else (1.75, 0.16)
    if D['species'] == 'elfe':
        c += 0.06
    t = float(D.get('taille', 1.0))
    if abs(t - 1.0) > 0.01:
        return t * c
    return c + s * float(np.tanh((hgt - c) / s))
