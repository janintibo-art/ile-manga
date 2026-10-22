"""Atlas des mèches : 8 colonnes (lisse dense, lisse, lisse clairsemé, ondulé, ondulé clairsemé,
bouclé, épais (barbe, dreads), court duveteux). v = 0 à la racine (haut), 1 à la pointe (bas)."""
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

KINDS = [  # (nombre de brins, amplitude d'ondulation (fraction de colonne), fréquence, épaisseur, fin aléatoire)
    (150, 0.03, 3.0, 2.6, 0.9),
    (110, 0.05, 2.5, 2.2, 0.75),
    (60, 0.08, 2.0, 1.8, 0.55),
    (110, 0.12, 4.0, 2.2, 0.8),
    (60, 0.14, 3.5, 1.8, 0.6),
    (90, 0.2, 10.0, 2.4, 0.8),
    (45, 0.08, 3.0, 4.5, 0.85),
    (160, 0.08, 2.0, 1.6, 0.35),
]


def atlas(size=1024, seed=21):
    rng = np.random.default_rng(seed)
    S = 2
    W = H = size * S
    colw = W // 8
    alpha = Image.new('L', (W, H), 0)
    lumi = Image.new('L', (W, H), 0)
    da = ImageDraw.Draw(alpha)
    dl = ImageDraw.Draw(lumi)
    for c, (n, amp, freq, th, endmin) in enumerate(KINDS):
        x0c = c * colw
        for k in range(n):
            m = 0.08 + amp
            x = x0c + colw * (m + (1 - 2 * m) * rng.random())
            start = rng.random() * (0.08 if c != 7 else 0.6)
            end = endmin + (1 - endmin) * rng.random()
            if c == 7:
                end = min(1.0, start + 0.25 + rng.random() * 0.25)
            ph = rng.random() * 6.28
            fr = freq * (0.8 + 0.4 * rng.random())
            lum = 150 + int(rng.random() * 105)
            pts = []
            steps = 60
            for s in range(steps + 1):
                t = start + (end - start) * s / steps
                xx = x + np.sin(ph + t * fr * 6.28) * amp * colw
                pts.append((xx, t * H))
            for s in range(steps):
                t = s / steps
                w = max(1, int(round(th * S * (1 - 0.7 * t))))
                a = int(255 * (1 - 0.15 * t))
                da.line([pts[s], pts[s + 1]], fill=a, width=w)
                dl.line([pts[s], pts[s + 1]], fill=int(lum * (0.75 + 0.25 * min(1, t * 4))), width=w)
    a = np.asarray(alpha.resize((size, size), Image.LANCZOS)).astype(np.float32) / 255
    l = np.asarray(lumi.resize((size, size), Image.LANCZOS)).astype(np.float32) / 255
    l = np.where(a > 0.01, l / np.maximum(a, 0.01), 0.0)
    # étendre la couleur sous l'alpha nul (évite les franges sombres au mipmapping)
    m = a > 0.05
    idx = ndimage.distance_transform_edt(~m, return_distances=False, return_indices=True)
    l = l[tuple(idx)]
    rgb = np.stack([l, l, l], -1)
    return np.concatenate([np.clip(rgb, 0, 1), np.clip(a, 0, 1)[..., None]], -1)
