"""Encodage binaire des Variant de Godot 4 (var_to_bytes / bytes_to_var)."""
import struct, numpy as np, zlib


def _pad(b):
    return b + b'\0' * ((4 - len(b) % 4) % 4)


def enc(v):
    if isinstance(v, bool):
        return struct.pack('<II', 1, 1 if v else 0)
    if isinstance(v, (int, np.integer)):
        v = int(v)
        if -2**31 <= v < 2**31:
            return struct.pack('<Ii', 2, v)
        return struct.pack('<Iq', 2 | (1 << 16), v)
    if isinstance(v, (float, np.floating)):
        return struct.pack('<Id', 3 | (1 << 16), float(v))
    if isinstance(v, str):
        b = v.encode('utf-8')
        return struct.pack('<II', 4, len(b)) + _pad(b)
    if isinstance(v, dict):
        out = struct.pack('<II', 27, len(v))
        for k, x in v.items():
            out += enc(k) + enc(x)
        return out
    if isinstance(v, (list, tuple)):
        out = struct.pack('<II', 28, len(v))
        for x in v:
            out += enc(x)
        return out
    if isinstance(v, (bytes, bytearray)):
        return struct.pack('<II', 29, len(v)) + _pad(bytes(v))
    if isinstance(v, Packed):
        return v.data
    raise TypeError(type(v))


class Packed:
    def __init__(self, data):
        self.data = data


def i32(a):
    a = np.ascontiguousarray(np.asarray(a, dtype='<i4').ravel())
    return Packed(struct.pack('<II', 30, len(a)) + a.tobytes())


def f32(a):
    a = np.ascontiguousarray(np.asarray(a, dtype='<f4').ravel())
    return Packed(struct.pack('<II', 32, len(a)) + a.tobytes())


def v3(a):
    a = np.ascontiguousarray(np.asarray(a, dtype='<f4').reshape(-1, 3))
    return Packed(struct.pack('<II', 36, len(a)) + a.tobytes())


def v2(a):
    a = np.ascontiguousarray(np.asarray(a, dtype='<f4').reshape(-1, 2))
    return Packed(struct.pack('<II', 35, len(a)) + a.tobytes())


def u8(a):
    a = np.ascontiguousarray(np.asarray(a, dtype=np.uint8).ravel())
    return Packed(struct.pack('<II', 29, len(a)) + _pad(a.tobytes()))


def save(path, d):
    raw = enc(d)
    comp = zlib.compress(raw, 9)
    with open(path, 'wb') as f:
        f.write(struct.pack('<4sI', b'IM64', len(raw)) + comp)
    return len(raw), len(comp) + 8


def col4(a):
    a = np.ascontiguousarray(np.asarray(a, dtype='<f4').reshape(-1, 4))
    return Packed(struct.pack('<II', 37, len(a)) + a.tobytes())
