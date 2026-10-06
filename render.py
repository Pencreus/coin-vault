"""Tiny numpy z-buffer renderer (flat shaded, orthographic) for STL previews."""
import sys
import numpy as np
import trimesh
from PIL import Image


def look(az, el):
    az, el = np.radians(az), np.radians(el)
    d = np.array([np.cos(el) * np.cos(az), np.cos(el) * np.sin(az), np.sin(el)])  # toward camera
    right = np.cross([0, 0, 1], d); right /= np.linalg.norm(right)
    up = np.cross(d, right)
    return d, right, up


def render(meshes, az=-55, el=28, size=1400, out="out.png"):
    d, right, up = look(az, el)
    light = np.array([0.4, -0.6, 0.8]); light /= np.linalg.norm(light)
    allv = np.vstack([m.vertices for m, _ in meshes])
    P = np.stack([allv @ right, allv @ up], 1)
    lo, hi = P.min(0), P.max(0)
    scale = (size * 0.9) / (hi - lo).max()
    off = (size - (hi - lo) * scale) / 2
    img = np.full((size, size, 3), 245, np.float32)
    zb = np.full((size, size), -np.inf, np.float32)
    for m, col in meshes:
        v = m.vertices
        sx = (v @ right - lo[0]) * scale + off[0]
        sy = size - ((v @ up - lo[1]) * scale + off[1])
        sz = v @ d
        n = m.face_normals
        shade = 0.35 + 0.65 * np.clip(n @ light, 0, 1) * 0.8 + 0.2 * np.clip(n @ d, 0, 1)
        f = m.faces
        for t in range(len(f)):
            if n[t] @ d <= 0:
                continue
            i0, i1, i2 = f[t]
            x = np.array([sx[i0], sx[i1], sx[i2]]); y = np.array([sy[i0], sy[i1], sy[i2]]); z = np.array([sz[i0], sz[i1], sz[i2]])
            xmin, xmax = int(max(x.min(), 0)), int(min(x.max() + 1, size))
            ymin, ymax = int(max(y.min(), 0)), int(min(y.max() + 1, size))
            if xmin >= xmax or ymin >= ymax:
                continue
            gx, gy = np.meshgrid(np.arange(xmin, xmax) + 0.5, np.arange(ymin, ymax) + 0.5)
            den = (y[1] - y[2]) * (x[0] - x[2]) + (x[2] - x[1]) * (y[0] - y[2])
            if abs(den) < 1e-9:
                continue
            a = ((y[1] - y[2]) * (gx - x[2]) + (x[2] - x[1]) * (gy - y[2])) / den
            b = ((y[2] - y[0]) * (gx - x[2]) + (x[0] - x[2]) * (gy - y[2])) / den
            c = 1 - a - b
            inside = (a >= -1e-6) & (b >= -1e-6) & (c >= -1e-6)
            zz = a * z[0] + b * z[1] + c * z[2]
            sub = zb[ymin:ymax, xmin:xmax]
            win = inside & (zz > sub)
            sub[win] = zz[win]
            img[ymin:ymax, xmin:xmax][win] = np.array(col) * shade[t]
    Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).save(out)


if __name__ == "__main__":
    # usage: render.py out.png az el file.stl:r,g,b[:dx,dy,dz] ...
    out, az, el = sys.argv[1], float(sys.argv[2]), float(sys.argv[3])
    ms = []
    for spec in sys.argv[4:]:
        parts = spec.split(":")
        m = trimesh.load(parts[0])
        col = [float(c) for c in parts[1].split(",")]
        if len(parts) > 2:
            m.apply_translation([float(c) for c in parts[2].split(",")])
        ms.append((m, col))
    render(ms, az, el, out=out)
