# رندرِ ۴۸ نشان به PNG شفاف برای اپ (assets/badges/badge_01..48.png)
import os, sys
from playwright.sync_api import sync_playwright
here = os.path.dirname(os.path.abspath(__file__))
dest = os.path.abspath(os.path.join(here, '../../flutter_app/assets/badges'))
os.makedirs(dest, exist_ok=True)
with sync_playwright() as pw:
    b = pw.chromium.launch(executable_path='/opt/pw-browsers/chromium-1194/chrome-linux/chrome')
    pg = b.new_page(viewport={'width': 400, 'height': 400}, device_scale_factor=1)
    for i in range(1, 49):
        svg = open(f'{here}/out/badge_{i:02d}.svg').read()
        pg.set_content(f'<html><body style="margin:0;background:transparent">{svg}</body></html>')
        pg.locator('svg').screenshot(path=f'{dest}/badge_{i:02d}.png', omit_background=True)
    b.close()
print('ok', len(os.listdir(dest)))
