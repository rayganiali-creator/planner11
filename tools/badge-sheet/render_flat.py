# رندر نشان‌های flat → PNG شفاف 320×320 در flutter_app/assets/badges
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import flat48
from playwright.sync_api import sync_playwright
dst = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'flutter_app', 'assets', 'badges')
with sync_playwright() as pw:
    b = pw.chromium.launch(executable_path='/opt/pw-browsers/chromium-1194/chrome-linux/chrome'); pg = b.new_page(viewport={'width': 320, 'height': 320}, device_scale_factor=1)
    for i in range(1, 49):
        svg = flat48.single(i).replace('width="400" height="400"', 'width="320" height="320"')
        pg.set_content(f'<html><body style="margin:0;background:transparent">{svg}</body></html>')
        pg.screenshot(path=os.path.join(dst, f'badge_{i:02d}.png'), omit_background=True)
    b.close()
print('done')
