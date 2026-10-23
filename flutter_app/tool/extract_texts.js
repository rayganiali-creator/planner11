// متن‌های آموزش اولیه، قوانین و راهنماها را عیناً از www/index.html بیرون می‌کشد → assets/texts.json
const fs = require('fs');
const h = fs.readFileSync(__dirname + '/../../www/index.html', 'utf8');
function grab(name, open, close) {
  const i = h.indexOf('const ' + name + ' =');
  if (i < 0) throw new Error('missing ' + name);
  let j = h.indexOf(open, i), depth = 0, k = j, inStr = null, esc = false;
  for (; k < h.length; k++) {
    const c = h[k];
    if (inStr) { if (esc) esc = false; else if (c === '\\') esc = true; else if (c === inStr) inStr = null; continue; }
    if (c === "'" || c === '"' || c === '`') { inStr = c; continue; }
    if (c === open) depth++; else if (c === close) { depth--; if (depth === 0) break; }
  }
  return new Function('return ' + h.slice(j, k + 1))();
}
const out = {
  onboarding: grab('ONBOARDING_SLIDES', '[', ']'),
  terms: grab('TERMS_SECTIONS', '[', ']'),
  help: grab('HELP_CONTENT', '{', '}'),
};
const tv = h.match(/const TERMS_VERSION\s*=\s*([^;]+);/)[1].trim();
const ov = h.match(/const ONBOARDING_VERSION\s*=\s*(\d+)/)[1];
out.termsVersion = new Function('return ' + tv)();
out.onboardingVersion = +ov;
fs.writeFileSync(__dirname + '/../assets/texts.json', JSON.stringify(out));
console.log(out.onboarding.length, 'slides', out.terms.length, 'terms', Object.keys(out.help).length, 'help', out.termsVersion, out.onboardingVersion);
