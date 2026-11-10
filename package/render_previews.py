"""Render the listing / README preview images from out/*.stl (+ loaded capsules from the .scad).
Usage: python render_previews.py <outdir>    (needs openscad on PATH, numpy trimesh pillow)"""
import sys, os, subprocess, trimesh, numpy as np
sys.path.insert(0, os.path.expanduser('~/Projects/coin-vault')); import render
V = os.path.expanduser('~/Projects/coin-vault/'); O = os.path.abspath(sys.argv[1]); os.makedirs(O, exist_ok=True)
TRAY, CAPS, LID = (205, 170, 125), (120, 150, 190), (110, 110, 118)
cache = {}
def caps(c):
    p = f'{O}/_caps_{c}.stl'
    if not os.path.exists(p): subprocess.run(['openscad', '-o', p, '-D', f'capsule="{c}"', '-D', 'part="capsules_full"', V + 'coin_vault.scad'], capture_output=True)
    return trimesh.load(p)
def tray(c):
    t = trimesh.load(V + f'out/coin_vault_tray_{c}.stl'); return t, t.bounds[1][2] - 3.0
def at(m, z): m = m.copy(); m.apply_translation([0, 0, z]); return m
def scene(kinds, lid=False, loaded=True):
    ms, z = [], 0.0
    for c in kinds:
        t, H = tray(c); ms.append((at(t, z), TRAY))
        if loaded: ms.append((at(caps(c), z), CAPS))
        z += H
    if lid: ms.append((at(trimesh.load(V + 'out/coin_vault_lid.stl'), z), LID))
    return ms
JOBS = {'1_stack_with_flat_lid': (['Y63', 'H39', 'HALF'], True, -55, 26), '2_stack_with_slab_tray': (['Y63', 'SLAB', 'H39'], True, -55, 26),
        '3_5oz_Y63_tray': (['Y63'], False, -55, 30), '4_1oz_H39_tray': (['H39'], False, -55, 30), '5_mixed_nickel_half_loaded': (['MIXED'], False, -55, 32),
        '6_rectangular_loaded': (['RECT'], False, -55, 32), '7_slab_tray_loaded': (['SLAB'], False, -55, 28), '8_stack_5oz': (['Y63', 'Y63', 'Y63'], True, -55, 26)}
for name, (kinds, lid, az, el) in JOBS.items():
    render.render(scene(kinds, lid), az=az, el=el, size=1400, out=f'{O}/{name}.png'); print(name, flush=True)
