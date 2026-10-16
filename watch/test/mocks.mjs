// Fakes for the watch's @system modules, shared through globalThis so tests
// can inspect and steer them.
const state = (globalThis.__watch = globalThis.__watch || {
    storage: {},
    sent: [],
    sendOk: true,
    routes: [],
    terminated: false
});

export const storage = {
    get({ key, default: def, success }) {
        success(key in state.storage ? state.storage[key] : def);
    },
    set({ key, value, success, complete }) {
        state.storage[key] = value;
        if (success) success();
        if (complete) complete();
    }
};

export const router = {
    replace(options) { state.routes.push(options); }
};

export const app = {
    terminate() { state.terminated = true; }
};

export const wearengine = {
    getWearEngineVersion({ complete }) { complete('1.0.401'); },
    setPackageName({ complete }) { if (complete) complete(); },
    setFingerprint({ complete }) { if (complete) complete(); },
    sendMsg({ message, success, fail }) {
        if (state.sendOk) {
            state.sent.push(message);
            success();
        } else {
            fail('unreachable', 206);
        }
    }
};
