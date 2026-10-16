// Node ESM hooks: map @system.* to the fakes and load the watch sources
// (plain .js without a package.json) as ES modules.
const mocks = new URL('./mocks.mjs', import.meta.url).href;
const names = { '@system.storage': 'storage', '@system.router': 'router', '@system.app': 'app', '@system.wearengine': 'wearengine' };

export async function resolve(specifier, context, next) {
    if (specifier in names) {
        return { url: `${mocks}?m=${names[specifier]}`, shortCircuit: true };
    }
    return next(specifier, context);
}

export async function load(url, context, next) {
    if (url.startsWith(mocks + '?m=')) {
        const name = new URL(url).searchParams.get('m');
        return {
            format: 'module',
            source: `import * as m from '${mocks}'; export default m.${name};`,
            shortCircuit: true
        };
    }
    if (url.includes('/watch/entry/') && url.endsWith('.js')) {
        const result = await next(url, { ...context, format: 'module' });
        return { ...result, format: 'module' };
    }
    return next(url, context);
}
