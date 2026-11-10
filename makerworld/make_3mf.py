"""Bambu Studio (A1, 0.4 mm) project files for MakerWorld: one plate per part. Reuses the 3MF writer from ~/Projects/coin-trays.
Usage: python make_3mf.py <dest-dir>   (needs numpy, trimesh, manifold3d, shapely, scipy)"""
import sys, os, json, zipfile, shutil
DEST=os.path.abspath(sys.argv[1]); os.makedirs(DEST,exist_ok=True)
sys.argv=['x','/nonexistent','/tmp/_unused_3mf']; sys.path.insert(0,os.path.expanduser('~/Projects/coin-trays/tools'))
import numpy as np, trimesh
import make_color_3mf as m
V=os.path.expanduser('~/Projects/coin-vault/out/'); PITCH=307.2; NPLATES=int(os.environ.get('NPLATES','9'))
def cols(n): v=n**0.5; r=round(v); return r+1 if v>r else r      # Bambu Studio's plate grid: cols = round(sqrt(n)), rounded up on a tie-ish
COLS=cols(NPLATES)
def obj(name,stl,plate,xy):
    t=trimesh.load(V+stl); c=(t.bounds[0]+t.bounds[1])/2; h=t.bounds[1][2]-t.bounds[0][2]
    t=t.copy(); t.vertices=t.vertices-c
    i=plate-1; x=(i%COLS)*PITCH+xy[0]; y=-(i//COLS)*PITCH+xy[1]
    return dict(name=name,item=f'1 0 0 0 1 0 0 0 1 {x:.6f} {y:.6f} {h/2:.6f}',plate=plate,parts=[dict(name=name,mesh=t,extruder=1)])
PLATE_NAMES={1:'Y63 5oz tray (48)',2:'H39 1oz tray (117)',3:'Nickel tray (175)',4:'Half dollar tray (105)',5:'Mixed nickel + half tray (140)',
    6:'Rectangular capsule tray (90)',7:'Slab tray (52 or 84)',8:'Lid (one per stack)',9:'Bookends x6 (all sizes)'}   # keep <= ~30 chars, no colon (Bambu Studio blanks long names)
def name_plates(ms):
    import re
    return re.sub(r'(<metadata key="plater_id" value="(\d+)"/>\s*<metadata key="plater_name" value=")"',lambda g:g.group(1)+PLATE_NAMES.get(int(g.group(2)),'')+'"',ms)
def project(path,title,objs):
    m.write_project(path,title,objs,None)
    s=json.load(open(f'{m.AS}/bambu_template/project_settings.config'))
    s.update({'layer_height':'0.2','print_settings_id':'0.20mm Standard @BBL A1','sparse_infill_density':'15%','wall_loops':'3',
              'filament_settings_id':['Bambu PLA Basic @BBL A1','Bambu PLA Basic @BBL A1'],'filament_colour':['#3A3A3C','#000000'],'enable_support':'0'})
    tmp=path+'.tmp'
    with zipfile.ZipFile(path) as zi, zipfile.ZipFile(tmp,'w',zipfile.ZIP_DEFLATED) as zo:
        for it in zi.infolist(): zo.writestr(it.filename, json.dumps(s,indent=4) if it.filename=='Metadata/project_settings.config' else name_plates(zi.read(it.filename).decode()) if it.filename=='Metadata/model_settings.config' else zi.read(it.filename))
    os.replace(tmp,path)
C=(128,128)
fam=[obj('5 oz Y63 tray (48)','coin_vault_tray_Y63.stl',1,C),obj('1 oz H39 tray (117)','coin_vault_tray_H39.stl',2,C),
     obj('Nickel tray (175)','coin_vault_tray_NICKEL.stl',3,C),obj('Half dollar tray (105)','coin_vault_tray_HALF.stl',4,C),
     obj('Mixed nickel + half tray (140)','coin_vault_tray_MIXED.stl',5,C),obj('Rectangular capsule tray (90)','coin_vault_tray_RECT.stl',6,C),
     obj('Slab tray (52 or 84)','coin_vault_tray_SLAB.stl',7,C),obj('Lid','coin_vault_lid.stl',8,C)]
bk=[('Y63','coin_vault_bookend_Y63.stl',(50,50)),('H39','coin_vault_bookend_H39.stl',(130,50)),('RECT','coin_vault_bookend_RECT.stl',(195,50)),
    ('SLAB','coin_vault_bookend_SLAB.stl',(70,125)),('HALF','coin_vault_bookend_HALF.stl',(150,125)),('NICKEL','coin_vault_bookend_NICKEL.stl',(200,125))]
fam+= [obj(f'Bookend {n}',f,9,xy) for n,f,xy in bk]
project(f'{DEST}/coin_vault_all_trays.3mf','Coin Vault - all trays',fam)
