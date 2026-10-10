# apply_sonora_sso.py
"""Apply the reviewed Harmonix browser-return change to the user's Sonora checkout."""
from pathlib import Path

root = Path(r'D:/DEV/NODEJS/sonora')
client = root / 'core/kyrosClient.js'
adapter = root / 'routes/harmonix.js'
auth = root / 'routes/auth.js'

def replace_once(text, old, new):
    if text.count(old) != 1:
        raise RuntimeError(f'Expected exactly one match: {old[:70]}')
    return text.replace(old, new, 1)

client_text = client.read_text(encoding='utf-8')
client_text = replace_once(client_text, 'export function registerAppSso(state) {', 'export function registerAppSso(state, { platform = null } = {}) {')
client_text = replace_once(client_text, 'appSso.set(String(state), { tokens: null, createdAt: Date.now() });',
    'appSso.set(String(state), { tokens: null, platform, createdAt: Date.now() });')
client_text = replace_once(client_text, 'export function isAppSsoPending(state) {',
    'export function getAppSsoPlatform(state) {\n  return appSso.get(String(state))?.platform ?? null;\n}\n\nexport function isAppSsoPending(state) {')
adapter_text = replace_once(adapter.read_text(encoding='utf-8'), 'registerAppSso(state);',
    'registerAppSso(state, { platform: String(req.query.platform || "") });')
auth_text = replace_once(auth.read_text(encoding='utf-8'), '  isAppSsoPending,', '  isAppSsoPending,\n  getAppSsoPlatform,')
auth_text = replace_once(auth_text, 'const router = express.Router();',
    'import { appSsoCompletionPage } from "../core/appSsoCompletion.js";\n\nconst router = express.Router();')
start = auth_text.index('    return res\n      .set("Content-Type", "text/html; charset=utf-8")')
end = auth_text.index('\n  }', start)
auth_text = auth_text[:start] + '''    const completion = appSsoCompletionPage(getAppSsoPlatform(state));
    return res.set({
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "no-store",
      "Referrer-Policy": "no-referrer",
      "Content-Security-Policy": completion.csp,
    }).send(completion.html);''' + auth_text[end:]
completion = '''// appSsoCompletion.js
import { randomBytes } from "node:crypto";

export function appSsoCompletionPage(platform) {
  const nonce = randomBytes(18).toString("base64");
  // Fixed allowlist, never reflect an arbitrary return URL or OAuth tokens.
  const mobile = platform === "android" || platform === "ios";
  const returnUrl = mobile ? "harmonix://auth/sso-complete" : null;
  const html = `<!doctype html><html lang="fr"><head><meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1"><title>Harmonix — connexion réussie</title>
    <style nonce="${nonce}">body{font:17px system-ui;background:#0A0F2B;color:#F2F1FA;margin:0;min-height:100vh;display:grid;place-items:center}main{max-width:30rem;padding:2rem;text-align:center}a,button{display:inline-block;background:#7B5CFF;color:#000;border:0;border-radius:12px;padding:14px 20px;text-decoration:none;font:inherit;margin:12px}p{line-height:1.6}</style></head>
    <body><main><h1>Connexion réussie</h1><p>Harmonix récupère ta session. Tu peux reprendre ton écoute.</p>
    ${returnUrl ? `<a href="${returnUrl}">Revenir dans Harmonix</a>` : ""}
    <button id="close">Fermer cet onglet</button><p>Si ton navigateur garde cet onglet ouvert, reviens dans Harmonix : la connexion continue automatiquement.</p>
    </main><script nonce="${nonce}">
      history.replaceState(null, '', location.pathname);
      document.getElementById('close').onclick = () => window.close();
      ${returnUrl ? `setTimeout(() => { location.href = ${JSON.stringify(returnUrl)}; }, 250);` : ""}
      if (window.opener) setTimeout(() => window.close(), 1000);
    </script></body></html>`;
  return { html, csp: `default-src 'none'; style-src 'nonce-${nonce}'; script-src 'nonce-${nonce}'; base-uri 'none'; frame-ancestors 'none'` };
}
'''
test = '''// app-sso-completion.test.js
import test from "node:test";
import assert from "node:assert/strict";
import { appSsoCompletionPage } from "../core/appSsoCompletion.js";
import { registerAppSso, getAppSsoPlatform, setAppSsoToken, consumeAppSsoToken } from "../core/kyrosClient.js";

test("mobile SSO returns to the fixed Harmonix scheme without exposing tokens", () => {
  for (const platform of ["android", "ios"]) {
    const page = appSsoCompletionPage(platform);
    assert.match(page.html, /harmonix:\\/\\/auth\\/sso-complete/);
    assert.match(page.csp, /frame-ancestors 'none'/);
    assert.doesNotMatch(page.html, /access_token|refresh_token/);
  }
});
test("untrusted platforms cannot inject a redirect or executable HTML", () => {
  const page = appSsoCompletionPage('<script>alert(1)</script>');
  assert.doesNotMatch(page.html, /harmonix:\\/\\/|alert\\(1\\)/);
  assert.match(page.html, /window.close/);
});
test("the relay remembers the platform and still delivers the token exactly once", () => {
  registerAppSso('completion-platform-test', { platform: 'android' });
  assert.equal(getAppSsoPlatform('completion-platform-test'), 'android');
  setAppSsoToken('completion-platform-test', { access_token: 'test-token' });
  assert.deepEqual(consumeAppSsoToken('completion-platform-test'), { access_token: 'test-token' });
  assert.equal(getAppSsoPlatform('completion-platform-test'), null);
});
'''
# Validate every replacement before writing any external file.
for target, content in [(client, client_text), (adapter, adapter_text), (auth, auth_text),
    (root / 'core/appSsoCompletion.js', completion), (root / 'test/app-sso-completion.test.js', test)]:
    target.write_text(content, encoding='utf-8', newline='\n')
print('Applied Sonora SSO browser return and regression tests.')
