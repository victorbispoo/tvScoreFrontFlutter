// Serve build/web over HTTP, then run:
// node test/browser/details_routes.cjs http://127.0.0.1:8765
// Set CHROME_EXECUTABLE if Chrome is installed outside its default location.
const assert = require('node:assert/strict');
const { spawn } = require('node:child_process');
const { mkdtemp, readFile } = require('node:fs/promises');
const { tmpdir } = require('node:os');
const { join } = require('node:path');
const { setTimeout: delay } = require('node:timers/promises');

const base = new URL(process.argv[2] ?? 'http://127.0.0.1:8765');
const chrome = process.env.CHROME_EXECUTABLE ??
  (process.platform === 'win32'
    ? 'C:/Program Files/Google/Chrome/Application/chrome.exe'
    : 'google-chrome');
const movie = {
  id: 123, title: 'Filme de teste', release_date: '2024-01-01',
  genre_ids: [18], vote_average: 8, tipoConteudo: 'MOVIE',
};
const series = {
  id: 456, title: 'Série de teste', first_air_date: '2021-01-01',
  genre_ids: [18], vote_average: 8, tipoConteudo: 'TV',
};

async function waitFor(probe, description) {
  const deadline = Date.now() + 25000;
  while (Date.now() < deadline) {
    const result = await probe();
    if (result) return result;
    await delay(200);
  }
  throw new Error(`Timeout: ${description}`);
}

function fixture(path) {
  if (path === '/api/filmes/123') return movie;
  if (path === '/api/series/456') return series;
  if (path === '/api/conteudos/generos') return [{ codigo: 'drama', nome: 'Drama' }];
  if (path.endsWith('/resumo')) return { totalAvaliacoes: 0, media: null };
  if (path.endsWith('/paginadas')) return { content: [], totalPages: 0, totalElements: 0 };
  if (path.endsWith('/episodios/painel')) return { temporadas: [] };
  if (/em-alta|por-nota|por-genero/.test(path)) {
    return { results: [path.startsWith('/api/series') ? series : movie] };
  }
  return [];
}

async function withBrowser(run) {
  const profile = await mkdtemp(join(tmpdir(), 'tvscore-details-'));
  const browser = spawn(chrome, [
    '--headless=new', '--disable-gpu', '--no-first-run', '--remote-debugging-port=0',
    `--user-data-dir=${profile}`, 'about:blank',
  ], { windowsHide: true, stdio: 'ignore' });
  let launchError;
  browser.on('error', (error) => { launchError = error; });
  let socket;
  try {
    const port = await waitFor(async () => {
      if (launchError) throw launchError;
      const file = await readFile(join(profile, 'DevToolsActivePort'), 'utf8')
        .catch(() => '');
      return file.split('\n')[0];
    }, 'Chrome debug port');
    const tabs = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
    socket = new WebSocket(tabs.find((tab) => tab.type === 'page').webSocketDebuggerUrl);
    await new Promise((resolve, reject) => {
      socket.onopen = resolve;
      socket.onerror = reject;
    });

    let id = 0;
    const pending = new Map();
    const requests = [];
    const errors = [];
    const call = (method, params = {}) => new Promise((resolve, reject) => {
      pending.set(++id, (message) => message.error
        ? reject(new Error(message.error.message)) : resolve(message.result));
      socket.send(JSON.stringify({ id, method, params }));
    });
    socket.onmessage = async ({ data }) => {
      const message = JSON.parse(data);
      if (message.id) {
        pending.get(message.id)?.(message);
        pending.delete(message.id);
      } else if (message.method === 'Runtime.exceptionThrown') {
        errors.push(message.params.exceptionDetails.text);
      } else if (message.method === 'Runtime.consoleAPICalled') {
        const output = message.params.args.map((arg) => arg.value).join(' ');
        if (output.includes('Expected DetailsArguments')) errors.push(output);
      } else if (message.method === 'Fetch.requestPaused') {
        const { requestId, request } = message.params;
        const path = new URL(request.url).pathname;
        if (request.method !== 'OPTIONS') requests.push(path);
        try {
          await call('Fetch.fulfillRequest', {
            requestId,
            responseCode: request.method === 'OPTIONS' ? 204 : 200,
            responseHeaders: [
              { name: 'Access-Control-Allow-Origin', value: base.origin },
              { name: 'Access-Control-Allow-Headers', value: '*' },
              { name: 'Access-Control-Allow-Methods', value: 'GET, OPTIONS' },
              { name: 'Content-Type', value: 'application/json' },
            ],
            body: request.method === 'OPTIONS' ? '' :
              Buffer.from(JSON.stringify(fixture(path))).toString('base64'),
          });
        } catch (error) {
          // The browser can cancel an in-flight request while leaving a page.
          if (error.message !== 'Invalid InterceptionId.') errors.push(error.message);
        }
      }
    };
    const evaluate = async (expression) => (await call('Runtime.evaluate', {
      expression, returnByValue: true,
    })).result.value;
    const find = async (label, role) => (await call('Accessibility.getFullAXTree'))
      .nodes.find((node) => label.test(node.name?.value ?? '') &&
        (!role || node.role?.value === role));
    const click = async (node, physical = false) => {
      const { object } = await call('DOM.resolveNode', { backendNodeId: node.backendDOMNodeId });
      const { result } = await call('Runtime.callFunctionOn', {
        objectId: object.objectId,
        functionDeclaration: physical
          ? 'function(){const r=this.getBoundingClientRect();return [r.x+r.width/2,r.y+r.height/2]}'
          : 'function(){this.click()}',
        returnByValue: true,
      });
      if (physical) {
        const [x, y] = result.value;
        for (const type of ['mousePressed', 'mouseReleased']) {
          await call('Input.dispatchMouseEvent', { type, x, y, button: 'left', clickCount: 1 });
        }
      }
    };
    const semantics = async () => {
      const placeholder = await find(/enable accessibility/i, 'button');
      if (placeholder) await click(placeholder);
    };
    const visible = (label, role) => waitFor(async () => {
      await semantics();
      return find(label, role);
    }, `visible ${label}`);
    const open = async (hash) => {
      await call('Page.navigate', { url: new URL(`#${hash}`, base).href });
    };
    const route = (hash) => waitFor(async () => (await evaluate('location.hash')) ===
      `#${hash}`, `route ${hash}`);

    await call('Runtime.enable');
    await call('Page.enable');
    await call('Accessibility.enable');
    await call('Fetch.enable', {
      patterns: [{ urlPattern: 'https://tvscore-backend.onrender.com/api/*' }],
    });
    await call('Emulation.setDeviceMetricsOverride', {
      width: 390, height: 850, deviceScaleFactor: 1, mobile: false,
    });
    await run({ call, evaluate, open, route, visible, click, requests });
    assert.deepEqual(errors, []);
  } finally {
    socket?.close();
    browser.kill();
  }
}

async function run() {
  await withBrowser(async ({ call, evaluate, open, route, visible, click, requests }) => {
    await open('/');
    await click(await visible(/Filme de teste/, 'button'), true);
    await route('/details/movie/123');
    await visible(/Entrar para avaliar/, 'button');
    await evaluate('history.back()');
    await visible(/Filme de teste/, 'button');
    assert.doesNotMatch(await evaluate('location.hash'), /details/);
    console.log('OK: movie URL and browser Back');

    await click(await visible(/Série de teste/, 'button'), true);
    await route('/details/tv/456');
    await visible(/Entrar para avaliar/, 'button');
    await waitFor(() => requests.includes('/api/series/456'), 'catalog enrichment before reload');
    const beforeReload = requests.length;
    await call('Page.reload');
    await waitFor(() => requests.slice(beforeReload).includes('/api/series/456'), 'series request after reload');
    await visible(/Entrar para avaliar/, 'button');
    await visible(/Série de teste/);
    await route('/details/tv/456');
    assert.equal(requests.slice(beforeReload).filter((path) => path === '/api/series/456').length, 1);
    console.log('OK: series URL and F5 with a single title request');
  });

  await withBrowser(async ({ open, route, visible, requests }) => {
    await open('/details/movie/123');
    await route('/details/movie/123');
    await visible(/Entrar para avaliar/, 'button');
    await visible(/Filme de teste/);
    assert.equal(requests.filter((path) => path === '/api/filmes/123').length, 1);
    assert(!requests.includes('/api/favoritos'));
    console.log('OK: direct link in a fresh browser session with guest permissions');
  });

  await withBrowser(async ({ open, visible }) => {
    await open('/details');
    await visible(/Link de detalhes inválido/);
    await visible(/Voltar ao catálogo/, 'button');
    console.log('OK: legacy link shows the safe fallback');
  });
}

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
