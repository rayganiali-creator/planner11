#!/usr/bin/env python3
"""SVG → PNG با Chromium (Playwright)."""
import os, sys
from playwright.sync_api import sync_playwright
d = os.path.dirname(os.path.abspath(__file__)); out = os.path.join(d, 'out')
with sync_playwright() as p:
    b = p.chromium.launch(executable_path=os.environ.get('CHROME', '/opt/pw-browsers/chromium-1194/chrome-linux/chrome'))
    pg = b.new_page(viewport={'width': 2140, 'height': 1640}, device_scale_factor=1.5)
    pg.goto('file://' + os.path.join(out, 'badge-sheet.svg')); pg.wait_for_timeout(500)
    pg.screenshot(path=os.path.join(out, 'badge-sheet.png'))
    b.close()
print('rendered')
