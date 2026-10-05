#!/usr/bin/env python3
"""ساخت dist/room.html (تک‌فایل). حیوان‌ها از همان PNGهای اپ (flutter_app/assets/avatar/pets) خوانده می‌شوند."""
import json, base64, os, glob
d = os.path.dirname(os.path.abspath(__file__))
av = os.path.join(d, '../legacy-avatar-assets')
data = json.load(open(f'{av}/avatar_data.json'))
b64 = lambda p: 'data:image/png;base64,' + base64.b64encode(open(f'{av}/avatar/{p}', 'rb').read()).decode()
pets = [{'id': i['id'], 'name': i['n'], 'img': b64(i['f']), 'sleep': b64(i['fs']) if i.get('fs') else None} for i in data['items'] if i['k'] == 'pet']
js = '\n'.join(open(f, encoding='utf8').read() for f in sorted(glob.glob(f'{d}/src/[0-9]*.js')))
html = open(f'{d}/src/index.template.html', encoding='utf8').read().replace('/*PETS*/', 'const PETS = ' + json.dumps(pets, ensure_ascii=False) + ';').replace('/*JS*/', js.replace('</script>', '<\\/script>'))
os.makedirs(f'{d}/dist', exist_ok=True)
open(f'{d}/dist/room.html', 'w', encoding='utf8').write(html)
print('built', len(html) // 1024, 'KB,', len(pets), 'pets')
