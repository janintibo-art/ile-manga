"""V95 : la peau des androïdes de Néopolis, et les implants des « modifiés » (espace UV MakeHuman, 2048).

  www/assets/textures/pnj64/peau_synth.png
    R : les joints des plaques d'un androïde (deux anneaux au cou, la ligne du front, celle qui
        descend devant l'oreille jusqu'à la mâchoire, les épaules, les coudes, les poignets, les
        jointures de la main) ;
    G : les circuits lumineux (androïdes : les tempes, les côtés du cou, le dessus des avant-bras ;
        implants : les filets de l'avant-bras gauche et de la tempe gauche) ;
    B : la zone de l'implant (l'avant-bras et la main gauches, une plaque sur la tempe gauche) ;
    A : les joints de l'implant (le bord de la zone, des anneaux, une ligne le long du bras).
La peau elle-même (le teint, le grain) reste celle du corps : le shader peau_v64 lisse et fait briller
la peau des androïdes (polymère), et peint la zone de l'implant en métal (voir corps_v64.gd).
Lancement : python3 -B pcvr/tools/habitants_v64/synth_v95.py
"""
import os
import numpy as np
from PIL import Image

from maps import body_maps, neutral
from skin_tex import Face, smooth
from uvraster import dilate, blur
from chemins import OUTT

SIZE = 2048
W_SEAM = 0.0018          # demi-largeur d'un joint (m)
W_GLOW = 0.0024          # demi-largeur d'un filet lumineux (m)


def line(d, w):
    return np.exp(-(d / w) ** 2)


class Seg:
    """un segment de membre A -> B : t (0 en A, 1 en B), distance à l'axe, angle autour de l'axe
    (0 du côté « dehors » donné par out)."""

    def __init__(self, P, A, B, out):
        a = B - A
        self.L = np.linalg.norm(a)
        a = a / self.L
        u = out - a * np.dot(out, a)
        u /= np.linalg.norm(u)
        v = np.cross(a, u)
        Q = P - A
        self.t = (Q @ a) / self.L
        x = Q @ u
        y = Q @ v
        self.d = np.sqrt(x * x + y * y)
        self.phi = np.arctan2(y, x)

    def ring(self, t0, rmax, w=W_SEAM):
        return line((self.t - t0) * self.L, w) * (self.d < rmax)

    def stripe(self, phi0, t0, t1, rmax, w=W_GLOW):
        dphi = np.angle(np.exp(1j * (self.phi - phi0)))
        on = smooth(t0 - 0.01, t0 + 0.01, self.t) * smooth(t1 + 0.01, t1 - 0.01, self.t) * (self.d < rmax)
        return line(dphi * self.d, w) * on

    def inside(self, t0, t1, rmax, soft=0.01):
        return smooth(t0 - soft, t0 + soft, self.t) * smooth(t1 + soft, t1 - soft, self.t) * (self.d < rmax)


def compose():
    M = body_maps(SIZE)
    F = Face(M)
    base, W, topo, Vw0, HJ, Vf = neutral()
    P = M['P']
    mask = M['mask']
    R = np.zeros(P.shape[:2], np.float32)
    G = np.zeros_like(R)
    B = np.zeros_like(R)
    A = np.zeros_like(R)
    head = F.head.astype(np.float32)
    # ------------------------------------------------------------ la tête (repère : entre les yeux)
    x, y, z, ax, th = F.x, F.y, F.z, F.ax, F.th
    rr = np.sqrt(ax ** 2 + (z - F.zc) ** 2)
    arc = lambda th0: np.radians(np.abs(th - th0)) * rr
    # le joint devant l'oreille, de la tempe à la mâchoire, et la ligne du front (d'une tempe à l'autre)
    R += head * line(arc(73.0), W_SEAM) * smooth(-0.115, -0.1, y) * smooth(0.058, 0.048, y)
    R += head * line(y - 0.052, W_SEAM) * smooth(74.0, 72.0, th) * (F.facing > -0.2)
    # sous le menton : la mâchoire se détache du cou
    R += head * line(y - (F.chin_y + 0.004), W_SEAM) * smooth(0.06, 0.05, ax) * smooth(F.front - 0.07, F.front - 0.05, z) * smooth(0.25, 0.4, -M['N'][..., 1])
    # les circuits des tempes : trois filets et des nœuds, des deux côtés
    temple = head * smooth(80.0, 84.0, th) * smooth(108.0, 104.0, th)
    for y0 in (-0.006, 0.008, 0.022):
        G += temple * line(y - y0, W_GLOW) * smooth(-0.012, -0.008, y) * smooth(0.032, 0.028, y)
    G += head * line(arc(95.0), W_GLOW) * smooth(-0.01, -0.006, y) * smooth(0.026, 0.022, y)
    for th0, y0 in ((86.0, 0.022), (100.0, -0.006), (95.0, 0.008)):
        G += head * line(np.sqrt(arc(th0) ** 2 + (y - y0) ** 2), 0.0028)
    # ------------------------------------------------------------ le cou
    up = HJ['Head'] - HJ['neck']
    neck = Seg(P, HJ['neck'] - up * 1.2, HJ['Head'] + up * 0.2, np.array([1.0, 0.0, 0.0]))
    in_neck = (neck.d < 0.068) & (P[..., 2] < F.L['chin'][2] - 0.05) & (P[..., 1] < F.L['chin'][1])
    for t0 in (0.28, 0.62):
        R += line((neck.t - t0) * neck.L, W_SEAM) * in_neck
    for ph in (0.0, np.pi):
        G += line(np.angle(np.exp(1j * (neck.phi - ph))) * neck.d, W_GLOW) * in_neck * smooth(0.2, 0.3, neck.t) * smooth(0.6, 0.5, neck.t)
    # ------------------------------------------------------------ les bras (à gauche : x > 0)
    for side, s in (('Left', 1.0), ('Right', -1.0)):
        out = np.array([s, 0.0, 0.0])
        sh, el, wr = HJ[side + 'Arm'], HJ[side + 'ForeArm'], HJ[side + 'Hand']
        hand_end = wr + (wr - el) / np.linalg.norm(wr - el) * 0.19
        up_arm = Seg(P, sh, el, np.array([0.0, 1.0, 0.0]))
        fore = Seg(P, el, wr, out)
        hand = Seg(P, wr, hand_end, out)
        side_ok = (P[..., 0] * s) > 0.12
        R += up_arm.ring(0.14, 0.075) * side_ok
        R += fore.ring(0.03, 0.065) * side_ok
        R += fore.ring(1.0, 0.055) * side_ok
        R += hand.ring(0.52, 0.07) * side_ok
        G += fore.stripe(0.0, 0.25, 0.85, 0.06) * side_ok
        G += line(np.sqrt(((fore.t - 0.85) * fore.L) ** 2 + (np.angle(np.exp(1j * fore.phi)) * fore.d) ** 2), 0.0032) * (fore.d < 0.06) * side_ok
        if side == 'Left':
            # l'implant : l'avant-bras (à partir d'un quart) et la main
            zone = np.maximum(fore.inside(0.22, 1.02, 0.07, 0.012), hand.inside(-0.05, 1.2, 0.08, 0.01)) * side_ok
            B = np.maximum(B, zone)
            A += fore.ring(0.22, 0.07, 0.0022) * side_ok
            A += fore.ring(0.5, 0.065) * side_ok + fore.ring(0.76, 0.06) * side_ok + fore.ring(1.0, 0.055) * side_ok
            A += fore.stripe(np.pi * 0.5, 0.22, 1.0, 0.065, W_SEAM) * side_ok
            A += fore.stripe(-np.pi * 0.5, 0.22, 1.0, 0.065, W_SEAM) * side_ok
            A += hand.ring(0.52, 0.07) * side_ok
            G += fore.stripe(np.pi, 0.3, 0.95, 0.065) * side_ok
            for t0 in (0.36, 0.62, 0.88):
                G += line(np.sqrt(((fore.t - t0) * fore.L) ** 2 + (np.angle(np.exp(1j * (fore.phi - np.pi))) * fore.d) ** 2), 0.003) * (fore.d < 0.065) * side_ok
    # ------------------------------------------------------------ la plaque de la tempe gauche (implant)
    left = (x > 0).astype(np.float32)
    e = np.sqrt((arc(93.0) / 0.024) ** 2 + ((y - 0.008) / 0.03) ** 2)
    plate = head * left * smooth(1.0, 0.93, e)
    B = np.maximum(B, plate)
    A += head * left * line((e - 0.965) * 0.027, 0.0022)
    A += head * left * line(y - 0.008, W_SEAM) * smooth(1.0, 0.9, e)
    for y0 in (-0.008, 0.024):
        G += plate * line(y - y0, W_GLOW) * smooth(0.85, 0.7, e)
    G += head * left * line(np.sqrt(arc(93.0) ** 2 + (y - 0.008) ** 2), 0.004)
    # ------------------------------------------------------------ fini
    out = np.stack([np.clip(R, 0, 1), np.clip(G, 0, 1), np.clip(B, 0, 1), np.clip(A, 0, 1)], -1).astype(np.float32)
    out *= mask[..., None]
    out = dilate(out, mask, 24)
    return out


def main():
    img = compose()
    os.makedirs(OUTT, exist_ok=True)
    path = os.path.join(OUTT, 'peau_synth.png')
    Image.fromarray((np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8), 'RGBA').save(path, optimize=True)
    print('V95 :', path, img.shape, [float(img[..., k].max()) for k in range(4)])


if __name__ == '__main__':
    main()
