const fs = require('fs');

async function main() {
  const tabsRes = await fetch('http://localhost:9222/json/list');
  const tabs = await tabsRes.json();
  const pageTab = tabs.find(t => t.type === 'page' && t.url.includes('netlify.app'));
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
  ws.onmessage = (e) => {
    const msg = JSON.parse(e.data);
    if (msg.id && pending.has(msg.id)) {
      const { resolve, reject } = pending.get(msg.id);
      pending.delete(msg.id);
      if (msg.error) reject(msg.error);
      else resolve(msg.result);
    }
  };
  await new Promise(r => ws.onopen = r);
  await send('Page.bringToFront');
  await send('Emulation.setFocusEmulationEnabled', { enabled: true });
  await new Promise(r => setTimeout(r, 500));

  console.log('Sending mouse move and click to email field at (380, 225)...');
  await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 380, y: 225 });
  await new Promise(r => setTimeout(r, 100));
  await send('Input.dispatchMouseEvent', { type: 'mousePressed', x: 380, y: 225, button: 'left', clickCount: 1 });
  await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x: 380, y: 225, button: 'left', clickCount: 1 });
  await new Promise(r => setTimeout(r, 500));

  // Type characters
  const email = 'prabhakar@gmail.com';
  for (const ch of email) {
    await send('Input.dispatchKeyEvent', {
      type: 'keyDown',
      text: ch,
      unmodifiedText: ch,
      key: ch,
    });
    await send('Input.dispatchKeyEvent', {
      type: 'keyUp',
      key: ch,
    });
    await new Promise(r => setTimeout(r, 30));
  }

  await new Promise(r => setTimeout(r, 1000));

  const ss = await send('Page.captureScreenshot', { format: 'png' });
  fs.writeFileSync('/Users/poornesh/.gemini/antigravity-ide/brain/c5ccb28a-9da1-4bf4-8117-85837b1a738c/scratch/typed_email.png', Buffer.from(ss.data, 'base64'));
  console.log('Screenshot saved to typed_email.png');

  ws.close();
}

main().catch(console.error);
