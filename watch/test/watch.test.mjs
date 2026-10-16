// Logic tests for the watch app, run on a computer:
//   node --import ./watch/test/register.mjs --test watch/test/watch.test.mjs
import './mocks.mjs'; // fakes for @system.* (same instance the pages get)
import { test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const root = new URL('../entry/src/main/js/MainAbility/', import.meta.url);
const w = () => globalThis.__watch;

/** Builds a page instance like the framework does: data fields + methods. */
async function page(path, params = {}) {
    const def = (await import(new URL(path, root).href)).default;
    const vm = { ...JSON.parse(JSON.stringify(def.data)), ...params };
    for (const [k, v] of Object.entries(def)) if (typeof v === 'function') vm[k] = v;
    if (vm.onInit) vm.onInit();
    return vm;
}

beforeEach(() => {
    Object.assign(w(), { storage: {}, sent: [], sendOk: true, routes: [], terminated: false });
    globalThis.setTimeout = (fn) => fn(); // run the "back to main" timer at once
});

test('main screen opens the entry page with the right direction', async () => {
    const vm = await page('pages/index/index.js');
    vm.openOutcome();
    vm.openIncome();
    assert.deepEqual(w().routes.map((r) => r.params.dir), ['o', 'i']);
    vm.swipe({ direction: 'right' });
    assert.equal(w().terminated, true);
});

test('keypad: digits, no leading zero, delete, max length', async () => {
    const vm = await page('pages/entry/entry.js', { dir: 'o' });
    vm.k0(); vm.k1(); vm.k2(); vm.k0();
    assert.equal(vm.digits, '120');
    assert.equal(vm.amountText, '120 ₺');
    vm.kDel();
    assert.equal(vm.digits, '12');
    for (let i = 0; i < 10; i++) vm.k9();
    assert.equal(vm.digits.length, 7);
    vm.kDel(); vm.kDel(); vm.kDel(); vm.kDel(); vm.kDel(); vm.kDel(); vm.kDel();
    vm.kOk();
    assert.equal(vm.step, 'amount', 'OK needs an amount');
});

test('full outcome flow sends the expected message and returns to main', async () => {
    const vm = await page('pages/entry/entry.js', { dir: 'o' });
    vm.k4(); vm.k5(); vm.kOk();
    assert.equal(vm.step, 'category');
    assert.equal(vm.categoryLabels[0], 'Yeme-İçme');
    vm.categoryChanged({ newSelected: 1, newValue: 'Market' });
    vm.categoryDone();
    assert.equal(vm.step, 'note');
    vm.noteChanged({ newSelected: 1, newValue: 'Kahve' });
    vm.send();
    const msg = JSON.parse(w().sent.at(-1));
    assert.equal(msg.d, 'o');
    assert.equal(msg.a, 45);
    assert.equal(msg.c, 'market');
    assert.equal(msg.n, 'Kahve');
    assert.match(msg.id, /^\d{13}$/);
    assert.match(vm.resultText, /45 ₺ kaydedildi/);
    assert.equal(w().routes.at(-1).uri, 'pages/index/index');
});

test('income with "Not yok" sends no note', async () => {
    const vm = await page('pages/entry/entry.js', { dir: 'i' });
    vm.k1(); vm.k0(); vm.k0(); vm.kOk(); vm.categoryDone(); vm.send();
    const msg = JSON.parse(w().sent.at(-1));
    assert.deepEqual([msg.d, msg.a, msg.c, msg.n], ['i', 100, 'harclik', undefined]);
});

test('swipe right steps back', async () => {
    const vm = await page('pages/entry/entry.js', { dir: 'o' });
    vm.k5(); vm.kOk(); vm.categoryDone();
    vm.swipe({ direction: 'right' });
    assert.equal(vm.step, 'category');
    vm.swipe({ direction: 'right' });
    assert.equal(vm.step, 'amount');
    vm.swipe({ direction: 'right' });
    assert.equal(w().routes.at(-1).uri, 'pages/index/index');
});

test('offline: entry is queued, shown as pending, and resent later', async () => {
    w().sendOk = false;
    const vm = await page('pages/entry/entry.js', { dir: 'o' });
    vm.k7(); vm.kOk(); vm.categoryDone(); vm.send();
    assert.match(vm.resultText, /ulaşılamadı/);
    assert.equal(JSON.parse(w().storage.queue).length, 1);

    const main = await page('pages/index/index.js'); // still offline
    assert.equal(main.pending, 1);

    w().sendOk = true;
    const again = await page('pages/index/index.js');
    assert.equal(again.pending, 0);
    assert.equal(JSON.parse(w().storage.queue).length, 0);
    assert.equal(JSON.parse(w().sent.at(-1)).a, 7);
});

test('every watch category id exists in Para (lib/core/watch_bridge.dart)', async () => {
    const { CATEGORIES } = await import(new URL('common/config.js', root).href);
    const dart = readFileSync(new URL('../../lib/core/watch_bridge.dart', import.meta.url), 'utf8');
    const block = (dir) => dart.split(`'${dir}': {`)[1].split('}')[0];
    for (const [id] of CATEGORIES.o) assert.ok(block('outcome').includes(`'${id}':`), `outcome ${id}`);
    for (const [id] of CATEGORIES.i) assert.ok(block('income').includes(`'${id}':`), `income ${id}`);
});

test('pages: every handler and class used in .hml exists', async () => {
    for (const name of ['index', 'entry']) {
        const dir = new URL(`pages/${name}/`, root);
        const hml = readFileSync(new URL(`${name}.hml`, dir), 'utf8');
        const css = readFileSync(new URL(`${name}.css`, dir), 'utf8');
        const def = (await import(new URL(`${name}.js`, dir).href)).default;
        for (const [, fn] of hml.matchAll(/on(?:click|swipe|change)="(\w+)"/g)) {
            assert.equal(typeof def[fn], 'function', `${name}: handler ${fn}`);
        }
        for (const [, list] of hml.matchAll(/class="([^"{]+)"/g)) {
            for (const cls of list.trim().split(/\s+/)) {
                assert.ok(css.includes(`.${cls} {`) || css.includes(`.${cls}{`), `${name}: class .${cls}`);
            }
        }
        for (const [, field] of hml.matchAll(/\{\{\s*(\w+)/g)) {
            assert.ok(field in def.data, `${name}: data field ${field}`);
        }
    }
});
