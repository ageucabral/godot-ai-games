// Abre o jogo exportado (build/web) num navegador Chromium sem tela,
// confere se o Godot iniciou sem erros e salva uma captura em build/web_screenshot.png
// (janela em pé, do tamanho de um celular).
// Uso: tools/web_smoke_test.sh
const { chromium } = require('playwright');
const url = process.argv[2] || 'http://localhost:8060/index.html';
const shot = process.argv[3] || 'build/web_screenshot.png';
(async () => {
  const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const page = await browser.newPage({ viewport: { width: 432, height: 768 } });
  const logs = [];
  const errors = [];
  page.on('console', (m) => { logs.push(m.text()); if (m.type() === 'error') errors.push(m.text()); });
  page.on('pageerror', (e) => errors.push(e.message));
  await page.goto(url);
  const deadline = Date.now() + 30000;
  while (Date.now() < deadline && !logs.some((l) => l.startsWith('Godot Engine'))) {
    await page.waitForTimeout(500);
  }
  await page.waitForTimeout(3000);
  await page.screenshot({ path: shot });
  await browser.close();
  console.log(logs.join('\n'));
  if (!logs.some((l) => l.startsWith('Godot Engine'))) { console.error('FALHOU: o Godot não iniciou no navegador.'); process.exit(1); }
  if (errors.length) { console.error('FALHOU: erros no navegador:\n' + errors.join('\n')); process.exit(1); }
  console.log('OK: o jogo abriu no navegador. Captura: ' + shot);
})();
