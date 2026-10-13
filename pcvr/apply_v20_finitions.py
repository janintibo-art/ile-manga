#!/usr/bin/env python3
"""Ile Manga V20 part 2, safe idempotent visual-only patch."""
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
MARK = 'ILE_MANGA_V20_FINITION_2'
patches = {
 'pcvr/shaders/terrain.gdshader': [
  ('ground *= mix(0.91, 1.08, broad);', 'ground *= mix(0.935, 1.065, broad);'),
  ('ROUGHNESS = mix(0.98, 0.84, rock_weight);', 'ROUGHNESS = mix(0.97, 0.88, rock_weight);'),
  ('SPECULAR = 0.17 + 0.08 * beach_weight;', 'SPECULAR = 0.16 + 0.08 * beach_weight;'),
 ],
 'pcvr/shaders/water.gdshader': [
  ('vec3(0.81, 0.95, 0.98)', 'vec3(0.86, 0.96, 0.99)'),
  ('ROUGHNESS = 0.25 + ripple.x * 0.04;', 'ROUGHNESS = 0.28 + ripple.x * 0.035;'),
 ],
 'pcvr/scripts/village_v19.gd': [
  ('roof.roughness = 0.94', 'roof.roughness = 0.89'),
  ('timber.roughness = 0.96', 'timber.roughness = 0.91'),
  ('window_mat.roughness = 0.20', 'window_mat.roughness = 0.16'),
 ],
 'pcvr/scripts/main.gd': [
  ('env.glow_intensity = 0.35', 'env.glow_intensity = 0.29'),
  ('env.fog_density = 0.0015', 'env.fog_density = 0.00135'),
 ]
}
new_contents = {}
for rel, pairs in patches.items():
 p=ROOT/rel
 original=p.read_text(encoding='utf-8')
 txt=original
 for before,after in pairs:
  if txt.count(before)==1:
   txt=txt.replace(before,after)
  elif txt.count(after)==1:
   pass
  else:
   raise SystemExit(f'ARRET de securite : {rel} : motif attendu introuvable / duplique : {before}')
 if MARK not in txt:
  txt += f'\n# {MARK}\n' if rel.endswith('.gd') else f'\n// {MARK}\n'
 new_contents[p]=txt
for p,txt in new_contents.items():
 p.write_text(txt,encoding='utf-8')
 print('OK', p.relative_to(ROOT))
print('V20 partie 2 : fichiers graphiques mis a jour; physique inchangee.')
