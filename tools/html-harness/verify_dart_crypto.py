# -*- coding: utf-8 -*-
"""جهتِ دوم تستِ رمزنگاری: فایل‌هایی که Dart رمز کرده با «خودِ JS برنامه» باز می‌شوند؟
   ابتدا:  cd flutter_app && flutter test test/backup_test.dart   (فایل build/dart_crypto_out.json را می‌سازد)
   سپس:    python3 tools/html-harness/verify_dart_crypto.py
"""
import json, pathlib, subprocess, sys, time
sys.path.insert(0, str(pathlib.Path(__file__).parent))
from playwright.sync_api import sync_playwright
import gen_golden as G

rows = json.load(open(G.ROOT / 'flutter_app' / 'build' / 'dart_crypto_out.json', encoding='utf-8'))
srv = subprocess.Popen([sys.executable, '-m', 'http.server', str(G.PORT), '--bind', '127.0.0.1'], cwd=G.HARNESS, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
time.sleep(1)
try:
    with sync_playwright() as pw:
        P = G.Page(pw)
        outs = P.abatch([('decrypt', [r['env'], r['pass']]) for r in rows])
        wrong = P.abatch([('decrypt', [r['env'], r['pass'] + '!']) for r in rows])
        ok = True
        for i, (r, o, w) in enumerate(zip(rows, outs, wrong)):
            good = o.get('ok') == r['plain'] and w.get('ok') is None
            ok &= good
            print(f"  #{i} JS بازش کرد: {'✓' if o.get('ok') == r['plain'] else '❌'} | رمز غلط رد شد: {'✓' if w.get('ok') is None else '❌'} | {len(r['plain'])} نویسه")
        P.b.close()
finally:
    srv.terminate()
print('نتیجه:', 'Dart→JS سبز ✅' if ok else 'مشکل ❌')
sys.exit(0 if ok else 1)
