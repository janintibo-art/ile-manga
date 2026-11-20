"""Compare deux corps d'habitant (fichiers IM64 du générateur V64, pnj64/*.bin) : mêmes clés, mêmes entiers,
flottants proches (V183 : les témoins refaits sur le PC de l'auteur, comparés à ceux du jeu).

    python3 tests/outils/comparer_corps.py A.bin B.bin
"""
import struct, sys, zlib
import numpy as np


def lire(path):
    raw = open(path, 'rb').read()
    tag, n = struct.unpack('<4sI', raw[:8])
    assert tag == b'IM64', path
    data = zlib.decompress(raw[8:])
    assert len(data) == n, (len(data), n)
    v, pos = _dec(data, 0)
    assert pos == len(data), (pos, len(data))
    return v


def _dec(b, i):
    h, = struct.unpack_from('<I', b, i)
    t, flag = h & 0xFFFF, h >> 16
    i += 4
    if t == 0:
        return None, i
    if t == 1:
        return struct.unpack_from('<I', b, i)[0] != 0, i + 4
    if t == 2:
        if flag & 1:
            return struct.unpack_from('<q', b, i)[0], i + 8
        return struct.unpack_from('<i', b, i)[0], i + 4
    if t == 3:
        if flag & 1:
            return struct.unpack_from('<d', b, i)[0], i + 8
        return struct.unpack_from('<f', b, i)[0], i + 4
    n, = struct.unpack_from('<I', b, i)
    i += 4
    if t == 4:
        s = b[i:i + n].decode('utf-8')
        return s, i + n + (-n % 4)
    if t == 27:
        d = {}
        for _ in range(n & 0x7FFFFFFF):
            k, i = _dec(b, i)
            v, i = _dec(b, i)
            d[k] = v
        return d, i
    if t == 28:
        out = []
        for _ in range(n & 0x7FFFFFFF):
            v, i = _dec(b, i)
            out.append(v)
        return out, i
    if t == 29:
        return np.frombuffer(b, np.uint8, n, i).copy(), i + n + (-n % 4)
    if t == 30:
        return np.frombuffer(b, '<i4', n, i).copy(), i + 4 * n
    if t == 32:
        return np.frombuffer(b, '<f4', n, i).copy(), i + 4 * n
    if t == 35:
        return np.frombuffer(b, '<f4', 2 * n, i).reshape(-1, 2).copy(), i + 8 * n
    if t == 36:
        return np.frombuffer(b, '<f4', 3 * n, i).reshape(-1, 3).copy(), i + 12 * n
    if t == 37:
        return np.frombuffer(b, '<f4', 4 * n, i).reshape(-1, 4).copy(), i + 16 * n
    raise ValueError('type %d à %d' % (t, i))


def comparer(a, b, chemin='', out=None):
    """Renvoie une liste (chemin, quoi, écart) : ce qui diffère."""
    out = [] if out is None else out
    if isinstance(a, dict) and isinstance(b, dict):
        for k in sorted(set(a) | set(b), key=str):
            if k not in a or k not in b:
                out.append((chemin + '/' + str(k), 'absent ' + ('A' if k not in a else 'B'), None))
            else:
                comparer(a[k], b[k], chemin + '/' + str(k), out)
    elif isinstance(a, list) and isinstance(b, list):
        if len(a) != len(b):
            out.append((chemin, 'longueur %d / %d' % (len(a), len(b)), None))
        for k, (x, y) in enumerate(zip(a, b)):
            comparer(x, y, '%s[%d]' % (chemin, k), out)
    elif isinstance(a, np.ndarray) and isinstance(b, np.ndarray):
        if a.shape != b.shape:
            out.append((chemin, 'forme %s / %s' % (a.shape, b.shape), None))
        elif a.dtype.kind == 'f':
            d = float(np.abs(a - b).max()) if a.size else 0.0
            if d > 0:
                out.append((chemin, 'flottants', d))
        elif not np.array_equal(a, b):
            e = np.abs(a.astype(np.int64) - b.astype(np.int64))
            out.append((chemin, 'entiers : %d différents sur %d (écart max %d, médian des différents %d)'
                        % (int((e > 0).sum()), e.size, int(e.max()), int(np.median(e[e > 0]))), None))
    elif isinstance(a, float) or isinstance(b, float):
        if abs(float(a) - float(b)) > 0:
            out.append((chemin, 'flottant %r / %r' % (a, b), abs(float(a) - float(b))))
    elif a != b:
        out.append((chemin, '%r / %r' % (a, b), None))
    return out


def dq_mm(d):
    """'dq' (écarts au corps neutre, 0,1 mm, octets faibles puis forts) -> (n, 3) en mm."""
    if isinstance(d, dict) and isinstance(d.get('dq'), np.ndarray):
        b = d['dq']
        n = b.size // 6
        lo, hi = b[:3 * n].reshape(3, n), b[3 * n:].reshape(3, n)
        q = (lo.astype(np.uint16) | (hi.astype(np.uint16) << 8)).view(np.int16)
        d = dict(d)
        d['dq'] = (q.T.astype(np.float64) / 10.0)
    return d


if __name__ == '__main__':
    A, B = dq_mm(lire(sys.argv[1])), dq_mm(lire(sys.argv[2]))
    diff = comparer(A, B)
    pire = max([d for _, _, d in diff if d is not None] or [0.0])
    autres = [x for x in diff if x[2] is None]
    for c, q, d in sorted(diff, key=lambda x: -(x[2] or 1e9))[:25]:
        print('  %-50s %s%s' % (c, q, '' if d is None else ' %.2e' % d))
    print('ECART_MAX %.3e ; DIFFERENCES_NON_FLOTTANTES %d' % (pire, len(autres)))
