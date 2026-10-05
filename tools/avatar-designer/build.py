#!/usr/bin/env python3
"""ساخت dist/avatar-designer.html (تک‌فایلِ مستقل، بدون وابستگیِ بیرونی)"""
import glob, os
d = os.path.dirname(os.path.abspath(__file__))
css = open(f'{d}/src/style.css', encoding='utf8').read()
js = '\n'.join(open(f, encoding='utf8').read() for f in sorted(glob.glob(f'{d}/src/[0-9]*.js')))
html = open(f'{d}/src/index.template.html', encoding='utf8').read().replace('/*CSS*/', css).replace('/*JS*/', js.replace('</script>', '<\\/script>'))
os.makedirs(f'{d}/dist', exist_ok=True)
open(f'{d}/dist/avatar-designer.html', 'w', encoding='utf8').write(html)
print('built', len(html) // 1024, 'KB')
