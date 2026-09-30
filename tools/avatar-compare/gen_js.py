"""خروجیِ واقعیِ avCompose نسخه‌ی HTML را برای چند پیکربندی به PNG می‌نویسد (مرجعِ مقایسه‌ی پیکسلی).
خروجی: flutter_app/test/golden/avatar/<n>.png و cases.json"""
import base64, json, os, random, sys
from playwright.sync_api import sync_playwright

root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
src = open(os.path.join(root, 'www/index.html'), encoding='utf-8').read()
marker = 'function avPaint(canvas, comp, crop) {'
assert marker in src
src = src.replace(marker, 'window.__avc = { compose: avCompose, items: AV_ITEM_MAP, all: AV_ITEMS };\n            ' + marker, 1)
tmp = os.path.join(root, 'www', '_avtest.html')
open(tmp, 'w', encoding='utf-8').write(src)
out = os.path.join(root, 'flutter_app/test/golden/avatar'); os.makedirs(out, exist_ok=True)
rnd = random.Random(7)
try:
    with sync_playwright() as p:
        b = p.chromium.launch(executable_path=os.environ.get('RP_CHROMIUM') or None); pg = b.new_page(); pg.goto('file://' + tmp); pg.wait_for_function('window.__avc')
        items = pg.evaluate('window.__avc.all.map(i=>({id:i.id,kind:i.kind,slot:i.slot,gender:i.gender,hasFit:!!i.fits,fits:i.fits?Object.keys(i.fits):[]}))')
        bases = [i for i in items if i['kind'] == 'base']
        cases = []
        for n in range(40):
            g = rnd.choice(['male', 'female'])
            eq = {}
            base = [x for x in bases if x['gender'] == g]; eq['base'] = rnd.choice(base)['id']
            pool = [x for x in items if x['kind'] != 'base' and x['gender'] in (g, 'both') and (x['kind'] in ('pet', 'petgear') or g in x['fits'])]
            for slot in rnd.sample(sorted({x['slot'] for x in pool}), k=rnd.randint(0, 6)):
                eq[slot] = rnd.choice([x for x in pool if x['slot'] == slot])['id']
            cases.append({'gender': g, 'equipped': eq, 'cond': rnd.choice(['ok', 'tired', 'hurt', 'sick', 'asleep']), 'mode': rnd.choice([None, None, 'noPet', 'petOnly'])})
        for n, c in enumerate(cases):
            d = pg.evaluate('''async c => { const cv = await window.__avc.compose(c.gender, c.equipped, c.cond, c.mode || undefined); return cv.toDataURL('image/png'); }''', c)
            open(f'{out}/{n}.png', 'wb').write(base64.b64decode(d.split(',')[1]))
        json.dump(cases, open(f'{out}/cases.json', 'w'))
        print(len(cases), 'cases')
finally:
    os.remove(tmp)
