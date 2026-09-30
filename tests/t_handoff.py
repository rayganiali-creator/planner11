"""پلِ انتقال: در «برنامه‌ی بومیِ» شبیه‌سازی‌شده، فایل rp_handoff.json (قالب پشتیبان) نوشته می‌شود."""
import json, os, sys
from playwright.sync_api import sync_playwright
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
exe = os.environ.get('CHROMIUM_PATH') or '/opt/pw-browsers/chromium-1194/chrome-linux/chrome'
INIT = """
window.__fsw = [];
window.Capacitor = { isNativePlatform: () => true, Plugins: { Filesystem: {
  writeFile: async o => { window.__fsw.push(['write', o.path, o.directory, o.encoding, o.data]); return {uri:'x'}; },
  rename: async o => { window.__fsw.push(['rename', o.from, o.to, o.directory, o.toDirectory]); return {}; } } } };
localStorage.setItem('rp_test_seed','1');
"""
with sync_playwright() as p:
    b = p.chromium.launch(executable_path=exe); pg = b.new_page()
    pg.add_init_script(INIT)
    errs = []; pg.on('pageerror', lambda e: errs.append(str(e)))
    pg.goto('file://' + os.path.join(root, 'www/index.html'))
    pg.wait_for_timeout(6500)
    w = pg.evaluate('window.__fsw')
    kinds = [(x[0], x[1]) for x in w]
    assert ('write', 'rp_handoff.tmp') in kinds, kinds
    assert ('rename', 'rp_handoff.tmp') in kinds, kinds
    assert ('write', 'rp_handoff.meta.json') in kinds, kinds
    tmp = [x for x in w if x[1] == 'rp_handoff.tmp'][0]
    assert tmp[2] == 'DATA' and tmp[3] == 'utf8'
    data = json.loads(tmp[4])
    assert data.get('version') and 'data' in data and 'habits' in data['data'], list(data)[:8]
    ren = [x for x in w if x[0] == 'rename'][0]
    assert ren[2] == 'rp_handoff.json' and ren[3] == 'DATA' and ren[4] == 'DATA'
    def writes(): return len([x for x in pg.evaluate('window.__fsw') if x[0] == 'write' and x[1] == 'rp_handoff.tmp'])
    def hide():
        pg.evaluate("Object.defineProperty(document,'hidden',{configurable:true,get:()=>true}); document.dispatchEvent(new Event('visibilitychange'))")
        pg.wait_for_timeout(800)
    n0 = writes()
    hide()                      # داده عوض نشده ← نوشتنِ اضافی نه
    assert writes() == n0, (writes(), n0)
    pg.evaluate("document.getElementById('themeToggle').click()")   # تغییرِ واقعیِ داده (saveState)
    pg.wait_for_timeout(300)
    hide()
    assert writes() == n0 + 1, (writes(), n0)
    last = [x for x in pg.evaluate('window.__fsw') if x[0] == 'write' and x[1] == 'rp_handoff.tmp'][-1]
    assert json.loads(last[4])['data']['theme'] == 'dark'       # آخرین وضعیت نوشته شد
    assert not errs, errs
    print('OK handoff', data['version'], len(tmp[4]), 'bytes')
