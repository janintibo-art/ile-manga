"""Repères du visage sur un corps ajusté (positions MakeHuman complètes, m)."""
import numpy as np


def cube(base, Vfull, name):
    return Vfull[base.group_verts(name)].mean(0)


def landmarks(base, Vfull):
    L = {}
    L['eye_l'] = cube(base, Vfull, 'joint-l-eye')
    L['eye_r'] = cube(base, Vfull, 'joint-r-eye')
    L['mouth'] = cube(base, Vfull, 'joint-mouth')
    L['jaw'] = cube(base, Vfull, 'joint-jaw')
    L['head'] = cube(base, Vfull, 'joint-head')
    L['head2'] = cube(base, Vfull, 'joint-head-2')
    L['neck'] = cube(base, Vfull, 'joint-neck')
    body = base.group_verts('body')
    P = Vfull[body]
    L['top'] = P[np.argmax(P[:, 1])]
    c = (L['eye_l'] + L['eye_r']) / 2
    L['eyes_mid'] = c
    # bout du nez : sommet le plus en avant près de l'axe, sous les yeux
    m = (np.abs(P[:, 0]) < 0.01) & (P[:, 1] < c[1]) & (P[:, 1] > c[1] - 0.08)
    L['nose'] = P[m][np.argmax(P[m][:, 2])]
    # menton : sommet le plus bas de l'axe, devant le cou
    m2 = (np.abs(P[:, 0]) < 0.01) & (P[:, 2] > L['mouth'][2] - 0.02) & (P[:, 1] < L['mouth'][1]) & (P[:, 1] > L['mouth'][1] - 0.09)
    L['chin'] = P[m2][np.argmin(P[m2][:, 1] - P[m2][:, 2] * 0.6)]
    # largeur et profondeur de la tête (au niveau des yeux + 3 cm)
    m3 = (np.abs(P[:, 1] - (c[1] + 0.03)) < 0.01)
    L['half_w'] = np.abs(P[m3][:, 0]).max()
    L['front_z'] = P[m3][:, 2].max()
    L['back_z'] = P[m3][:, 2].min()
    return L
