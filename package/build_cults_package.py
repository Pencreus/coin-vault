"""Rebuild the Cults3D / download package (STL + plain 3MF per part, one zip per tray) from out/*.stl.
Usage: python build_cults_package.py <dest>      (dest = .../Copper_Capsule_Trays; STL/ 3MF/ Zips_per_tray/ and ../Copper_Capsule_Trays.zip are rewritten; Images/ + LISTING_TEXT.md are left alone)
Needs: trimesh numpy"""
import sys, os, shutil, zipfile, trimesh
V = os.path.expanduser('~/Projects/coin-vault/out/'); D = os.path.abspath(sys.argv[1])
TR = [('1_5oz_Y63_48_capsules', 'Y63', ['5oz_Y63']), ('2_1oz_H39_117_capsules', 'H39', ['1oz_H39']),
      ('3_Buffalo_Nickel_175_capsules', 'NICKEL', ['Buffalo_Nickel']), ('4_Half_Dollar_105_capsules', 'HALF', ['Half_Dollar']),
      ('5_Mixed_35_nickel_105_half', 'MIXED', ['Buffalo_Nickel', 'Half_Dollar']), ('6_Rectangular_35.7x57.5_90_capsules', 'RECT', ['Rectangular']),
      ('7_Slab_52_or_84_capsules', 'SLAB', ['Slab'])]
BK = {'5oz_Y63': 'Y63', '1oz_H39': 'H39', 'Buffalo_Nickel': 'NICKEL', 'Half_Dollar': 'HALF', 'Rectangular': 'RECT', 'Slab': 'SLAB'}
for d in ('STL', '3MF', 'Zips_per_tray'): shutil.rmtree(f'{D}/{d}', ignore_errors=True)
for fmt in ('STL', '3MF'):
    for sub in ('1_Trays', '2_Lid', '3_Bookends'): os.makedirs(f'{D}/{fmt}/{sub}')
def emit(src, sub, name):
    for fmt in ('STL', '3MF'):
        p = f'{D}/{fmt}/{sub}/{name}.{fmt.lower()}'
        if fmt == 'STL': shutil.copy(V + src, p)
        else: trimesh.load(V + src).export(p)
for name, key, _ in TR: emit(f'coin_vault_tray_{key}.stl', '1_Trays', name)
emit('coin_vault_lid.stl', '2_Lid', 'Flat_Lid')
for name, key in BK.items(): emit(f'coin_vault_bookend_{key}.stl', '3_Bookends', f'Bookend_{name}')
os.makedirs(f'{D}/Zips_per_tray')
for name, key, bks in TR:
    with zipfile.ZipFile(f'{D}/Zips_per_tray/{name[2:]}.zip', 'w', zipfile.ZIP_DEFLATED) as z:
        for fmt in ('3MF', 'STL'):
            ext = fmt.lower(); z.write(f'{D}/{fmt}/1_Trays/{name}.{ext}', f'{fmt}/{name[2:]}.{ext}' if fmt == 'STL' else f'{name[2:]}.{ext}')
            for b in bks: z.write(f'{D}/{fmt}/3_Bookends/Bookend_{b}.{ext}', f'Bookends/{"STL/" if fmt == "STL" else ""}Bookend_{b}.{ext}')
            z.write(f'{D}/{fmt}/2_Lid/Flat_Lid.{ext}', f'Lid/{"STL/" if fmt == "STL" else ""}Flat_Lid.{ext}')
top = os.path.join(os.path.dirname(D), os.path.basename(D) + '.zip')
with zipfile.ZipFile(top, 'w', zipfile.ZIP_DEFLATED) as z:
    for fmt in ('3MF', 'STL'):
        for root, _, fs in os.walk(f'{D}/{fmt}'):
            for f in fs:
                if not f.startswith('.'): p = os.path.join(root, f); z.write(p, os.path.relpath(p, D))
print('ok', top)
