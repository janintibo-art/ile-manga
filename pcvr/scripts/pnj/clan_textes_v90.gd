extends RefCounted
## V90 : ce que disent les gens du Clan (l'Île Pixelithique). Ils parlent à leur façon : des phrases
## courtes, le prénom à la place de « je », et beaucoup d'étonnement devant le héros… qui n'a pas un
## seul pixel. Pour eux, il vient « du pays des Lisses », au-delà de la grande eau.

const NOMS := {"ougha": "Ougha", "ocre": "Ocre", "mamie_silex": "Mamie Silex", "grok": "Grok", "ploc": "Ploc", "pika": "Pika",
	"vieux_flint": "Vieux Flint", "boum": "Boum"}

## Ce qu'ils disent tout seuls (bulles)
const BULLES := {
	"ougha": ["Ougha chef. Ougha surveille.", "Hmm. Toi toujours lisse.", "Grosse-Dent… grrr.", "Feu bon. Feu chaud. Ougha aime feu."],
	"ocre": ["Ocre cherche rouge plus rouge.", "Mur vide. Mur triste.", "Toi bouge pas ! Ocre regarde toi.", "Comment peindre rond ? Hmm…"],
	"mamie_silex": ["Qui a faim ? Tout le monde a faim !", "Fougère grillée, miam.", "Toi trop maigre. Pas assez de carrés.", "Ploc ! Pika ! Pas toucher braises !"],
	"grok": ["Grok chasse. Grok rate. Grok chasse encore.", "Raptor rapide. Grok plus rapide. Presque.", "Chut. Grok écoute la jungle.", "Corne-Sur-Nez pas content aujourd'hui."],
	"ploc": ["Pique ! Pique !", "Toi lisse ! Hi hi !", "Ploc plus grand que Pika !", "Ploc veut voir Grosse-Dent ! … Non. Ploc veut pas."],
	"pika": ["Pika plus grande que Ploc !", "Toi lisse comme galet mouillé !", "Hi hi ! Toi pas carré !", "Pika a trouvé un œuf ! … C'était un caillou."],
	"vieux_flint": ["Vieux Flint se souvient…", "Avant, volcan dormait. Maintenant, volcan ronfle.", "Zzz… hein ? Vieux Flint pas dormir.", "Les Lisses… la légende dit vrai."],
	"boum": ["Boum ! Boum-boum !", "Tambour parle. Tambour dit : danse !", "Boum aime boum.", "Boum-ba-boum !"],
}

## La première rencontre (Ougha, et tout le Clan derrière lui)
const RENCONTRE := "STOP ! Toi… toi quoi ? Toi pas carré. Toi tout LISSE ! Pas un seul pixel ! Ougha jamais vu chose comme toi. Toi venir d'où ? Du ciel ? De la grande eau ? Du ventre du volcan ?"
const RENCONTRE_CHOIX := [
	{"id": "monde", "label": "Je viens d'un autre monde, au-delà de la mer."},
	{"id": "ami", "label": "Je suis un voyageur. Un ami !"},
	{"id": "bouh", "label": "Bouh !"},
]
const RENCONTRE_REP := {
	"monde": "AUTRE MONDE ! (Tout le Clan fait « Ooooh ».) Vieux Flint avait raison : le pays des Lisses, au-delà de la grande eau ! Là-bas, tout rond ? Tout doux ? Même les cailloux ? Incroyable.",
	"ami": "Ami ? … Ougha réfléchit. (Ougha réfléchit très fort, ça fait du bruit.) D'accord. Toi ami. Ami lisse. Premier ami lisse du Clan !",
	"bouh": "AAAH ! (Ougha saute derrière le totem. Le Clan aussi. Puis tout le monde éclate de rire.) Ha ! Ha ! Ha ! Toi drôle, chose lisse ! Toi rester !",
}
const QUETE := "Écoute, chose lisse. Au nord, dans le Cirque des Os, vit Grosse-Dent. Grand lézard. Grandes dents. Très grand cri. La nuit, Grosse-Dent vient, Grosse-Dent casse les séchoirs, Grosse-Dent mange toute la viande du Clan. Clan a peur. Toi… toi pas pareil. Toi peut-être chasser Grosse-Dent ?"
const QUETE_CHOIX := [{"id": "oui", "label": "Je vais m'en occuper !"}, {"id": "non", "label": "Laisse-moi d'abord visiter l'île."}]
const QUETE_OUI := "OUGHA ! (Ça veut dire « super ».) Grok dit : Grosse-Dent crie avant de mordre. Et quand Grosse-Dent fonce et cogne la roche, Grosse-Dent voit des étoiles. Taper à ce moment-là !"
const QUETE_NON := "D'accord. Île grande. Mais pas trop attendre : Grosse-Dent a très faim."
const OUGHA_ENCOURS := ["Grosse-Dent toujours là. Ougha entend son cri la nuit.", "Cirque des Os, au nord. Suivre le chemin des pierres.", "Quand Grosse-Dent cogne la roche : taper, taper, taper !"]
const OUGHA_VICTOIRE := "TOI AS CHASSÉ GROSSE-DENT ! (Ougha lève les bras. Tout le Clan crie.) Ce soir, grande fête ! Ocre va peindre ça sur le mur. Toi… toi maintenant du Clan. Clan des Carrés… et un Lisse !"
const OUGHA_APRES := ["Grosse-Dent dort maintenant. Grosse-Dent ronfle. Grosse-Dent gentil quand il dort.", "Toi du Clan. Toi toujours bienvenu au feu.", "Ougha fier. Ougha content. Ougha a faim. Mamie !"]

const OCRE := "Ocre peint. Ocre peint tout : Corne-Sur-Nez, Long-Cou, le soleil, Grosse-Dent… Mais toi… Ocre sait pas peindre toi. Toi trop rond ! Toi trop lisse ! Ocre a seulement des carrés !"
const OCRE_CHOIX := [{"id": "essaie", "label": "Essaie quand même !"}, {"id": "fermer", "label": "Je repasserai."}]
const OCRE_PORTRAIT := "Bouge pas… bouge PAS… (Ocre tire la langue. Ocre gratte, tamponne, souffle de l'ocre rouge sur une pierre plate.) Voilà ! C'est toi ! … Enfin. C'est toi en carré. Ocre a fait de son mieux. Prends. Ocre en peint un autre sur le mur de la grotte."
const OCRE_APRES := ["Ton portrait est sur le mur, dans la Grotte aux Peintures. Tout le Clan vient le voir. Ils rient. Mais gentiment.", "Ocre a besoin d'un rouge plus rouge. Peut-être dans le volcan ? … Non. Trop chaud.", "Peindre Grosse-Dent, facile. Peindre toi, très dur."]

const MAMIE := "Toi ! Toi trop maigre ! Pas assez de carrés ! Mange, mange. Galette de fougère, recette de Mamie Silex. Bien croustillante."
const MAMIE_ENCORE := ["Encore faim ? Mamie a encore une galette.", "Mange doucement. Galette chaude.", "Toi grandir. Toi devenir carré comme nous !"]
const MAMIE_PLUS := ["Plus de galette pour l'instant ! Revenir plus tard, ventre vide.", "Mamie fait cuire. Revenir tout à l'heure !"]

const GROK := "Grok chasseur. Grok connaît toutes les bêtes de l'île. Toi veux savoir ?"
const GROK_CHOIX := [{"id": "raptor", "label": "Les raptors ?"}, {"id": "trice", "label": "Le tricératops ?"}, {"id": "anky", "label": "L'ankylosaure ?"},
	{"id": "ptero", "label": "Les ptéranodons ?"}, {"id": "longcou", "label": "Les grands, au lac ?"}, {"id": "fermer", "label": "Merci, Grok !"}]
const GROK_REP := {
	"raptor": "Raptor : petit, rapide, toujours en bande. Raptor tourne autour, puis saute. Quand raptor se baisse et siffle : toi bouge ! Après le saut, raptor tout étourdi : taper !",
	"trice": "Corne-Sur-Nez : gros, grincheux. Il gratte la terre avec le pied, puis il FONCE. Toi pas rester devant ! S'il fonce dans un rocher : bong ! Il voit des étoiles. Taper !",
	"anky": "Queue-Massue : dos tout dur, comme pierre. Taper sur le dos, ça sert à rien. Sa queue tourne, tourne… et BAM. Taper sur la tête, ou quand il est fatigué.",
	"ptero": "Grand-Bec : il vole. Il tourne, il tourne, puis il pique sur toi. Toi te baisser… non, toi rouler ! Quand il remonte, il est lent : taper !",
	"longcou": "Long-Cou ? Long-Cou gentil ! Long-Cou mange les arbres. Long-Cou jamais méchant. Mais attention à ses pieds : très grands pieds.",
}
const PLOC := "Ploc ! Moi Ploc ! (Il te pique avec un bâton.) Pique ! … Toi pas dire « aïe » ? Toi même pas faire de pixels quand on pique ? Toi trop fort !"
const PIKA := "Moi Pika ! Toi viens d'où ? Pays des Lisses ? Là-bas, les enfants aussi sont lisses ? Ils roulent pour aller plus vite ? Hi hi hi !"
const ENFANTS_CHOIX := [{"id": "jouer", "label": "On joue ?"}, {"id": "fermer", "label": "Salut les petits !"}]
const ENFANTS_JEU := ["Jeu du Grosse-Dent ! Toi être Grosse-Dent ! Toi crier ! … (Ils s'enfuient en hurlant de rire.)", "Cache-cache ! Toi compter jusqu'à… euh… beaucoup !", "Jeu du caillou ! Qui lance le plus loin ? … Ploc a lancé sur Pika. Pika pas contente."]

const FLINT := "Vieux Flint se souvient… Quand Vieux Flint était petit carré, le grand-père de Vieux Flint racontait : un jour viendra une chose LISSE, de l'autre côté de la grande eau. Elle chassera le grand cri du nord. Et le Clan dansera. Hmm. Vieux Flint croit que c'est toi."
const FLINT_CHOIX := [{"id": "volcan", "label": "Et le volcan ?"}, {"id": "lac", "label": "Et le lac ?"}, {"id": "lisses", "label": "Les Lisses, c'est qui ?"}, {"id": "fermer", "label": "Merci, Vieux Flint."}]
const FLINT_REP := {
	"volcan": "Mont Fumant. Il ronfle, il fume, il crache du rouge. Ne jamais marcher sur le rouge : rouge mange les pieds. Les Grand-Bec aiment voler au-dessus : air chaud, ils planent.",
	"lac": "Lac des Long-Cous. Eau calme, Long-Cou boit, Long-Cou mange les grands arbres. Avant, Vieux Flint nageait là. Avant d'être vieux. Il y a très longtemps. Hier, peut-être.",
	"lisses": "Les Lisses… gens d'un autre monde. Tout rond, tout doux, pas un seul carré. On dit qu'ils voient les choses… comment dire… en très, très petits pixels. Si petits qu'on les voit plus. Bizarre, non ?",
}
const BOUM := "Boum ! Boum-boum ! Boum fait parler tambour. Tambour dit : tout le monde danse ! Toi danser aussi ?"
const BOUM_CHOIX := [{"id": "danse", "label": "Allez, on danse !"}, {"id": "fermer", "label": "Peut-être plus tard."}]
const BOUM_DANSE := "BOUM-BA-BOUM ! (Tout le Clan se met à danser autour du feu. Même Ougha. Surtout Ougha.)"
