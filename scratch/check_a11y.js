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

  const res = await send('Runtime.evaluate', {
    expression: `(() => {
      const pane = document.querySelector("flt-glass-pane");
      const sr = pane ? pane.shadowRoot : null;
      const elements = sr ? Array.from(sr.querySelectorAll("[role], [aria-label], button, input, canvas")) : [];
      return { count: elements.length, items: elements.map(e => ({ tag: e.tagName, role: e.getAttribute("role"), aria: e.getAttribute("aria-label") })) };
    })()`,
    returnByValue: true
  });
  console.log('A11y elements:', JSON.stringify(res.result?.value, null, 2));

  ws.close();
}

main().catch(console.error);
