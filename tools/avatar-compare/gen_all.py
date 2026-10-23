"""هر آیتمِ آواتار × هر جنسیتِ سازگار (۲۵۷ حالت) را با avCompose واقعیِ HTML می‌سازد؛ مرجعِ test/avatar_all_test.dart."""
import base64, json, os, sys
from playwright.sync_api import sync_playwright
root='/home/user/planner11'
src=open(root+'/www/index.html',encoding='utf-8').read()
marker='function avPaint(canvas, comp, crop) {'
src=src.replace(marker,'window.__avc = { compose: avCompose, items: AV_ITEM_MAP, all: AV_ITEMS };\n            '+marker,1)
tmp=root+'/www/_avtest.html'; open(tmp,'w',encoding='utf-8').write(src)
out=root+'/flutter_app/test/golden/avatar_all'; os.makedirs(out,exist_ok=True)
try:
  with sync_playwright() as p:
    b=p.chromium.launch(executable_path=os.environ.get('RP_CHROMIUM') or None); pg=b.new_page(); pg.goto('file://'+tmp); pg.wait_for_function('window.__avc')
    items=pg.evaluate('window.__avc.all.map(i=>({id:i.id,kind:i.kind,slot:i.slot,gender:i.gender,fits:i.fits?Object.keys(i.fits):[], on:i.on||null}))')
    bases=[i for i in items if i['kind']=='base']
    cases=[]
    for g in ['male','female']:
      base=[x for x in bases if x['gender']==g][0]['id']
      for it in items:
        if it['kind']=='base' or it['gender'] not in (g,'both'): continue
        eq={'base':base}
        if it['kind']=='petgear':
          eq['pet']=[x for x in items if x['kind']=='pet'][0]['id']
        eq[it['slot']]=it['id']
        cases.append({'gender':g,'equipped':eq,'cond':'ok','mode':None,'id':it['id'],'slot':it['slot']})
    for n,c in enumerate(cases):
      d=pg.evaluate('''async c => { const cv = await window.__avc.compose(c.gender, c.equipped, c.cond, undefined); return cv ? cv.toDataURL('image/png') : null; }''',c)
      c['hasjs']=bool(d)
      if d: open(f'{out}/{n}.png','wb').write(base64.b64decode(d.split(',')[1]))
    json.dump(cases,open(out+'/cases.json','w')); json.dump(items,open(out+'/items.json','w'))
    print(len(cases), sum(1 for c in cases if not c['hasjs']))
finally: os.remove(tmp)
