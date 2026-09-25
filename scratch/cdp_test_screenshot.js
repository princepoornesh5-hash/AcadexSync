const fs = require('fs');

async function main() {
  const tabsRes = await fetch('http://localhost:9222/json/list');
  const tabs = await tabsRes.json();
  const pageTab = tabs.find(t => t.type === 'page' && t.url.includes('netlify.app'));
  if (!pageTab) {
    console.error('Page tab not found', tabs);
    return;
  }

  console.log('Connecting to tab:', pageTab.id, pageTab.webSocketDebuggerUrl);
  const ws = new WebSocket(pageTab.webSocketDebuggerUrl);

  let idCounter = 1;
  const pending = new Map();

  function send(method, params = {}) {
    return new Promise((resolve, reject) => {
      const id = idCounter++;
      pending.set(id, { resolve, reject });
      ws.send(JSON.stringify({ id, method, params }));
    });
  }

  ws.onmessage = (event) => {
    const msg = JSON.parse(event.data);
    if (msg.id && pending.has(msg.id)) {
      const { resolve, reject } = pending.get(msg.id);
      pending.delete(msg.id);
      if (msg.error) reject(msg.error);
      else resolve(msg.result);
    }
  };

  await new Promise(r => ws.onopen = r);
  console.log('Connected to CDP!');

  // Wait a moment for Flutter web canvas to render
  await new Promise(r => setTimeout(r, 4000));

  const screenshot = await send('Page.captureScreenshot', { format: 'png' });
  const buffer = Buffer.from(screenshot.data, 'base64');
  const outPath = '/Users/poornesh/.gemini/antigravity-ide/brain/c5ccb28a-9da1-4bf4-8117-85837b1a738c/scratch/deployed_netlify_landing.png';
  fs.writeFileSync(outPath, buffer);
  console.log('Screenshot written to:', outPath);

  // Evaluate DOM/title
  const evalRes = await send('Runtime.evaluate', {
    expression: 'document.title + " | URL: " + window.location.href + " | Body text: " + (document.body ? document.body.innerText.slice(0, 100) : "empty")'
  });
  console.log('DOM Evaluation:', evalRes.result?.value);

  ws.close();
}

main().catch(console.error);
