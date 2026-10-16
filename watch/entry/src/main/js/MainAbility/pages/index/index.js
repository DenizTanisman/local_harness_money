import app from '@system.app';
import router from '@system.router';
import { flushQueue } from '../../common/sender.js';

export default {
    data: {
        pending: 0
    },
    onInit() {
        const that = this;
        // Resend anything that could not reach the phone earlier.
        flushQueue(function (remaining) {
            that.pending = remaining;
        });
    },
    openOutcome() {
        router.replace({ uri: 'pages/entry/entry', params: { dir: 'o' } });
    },
    openIncome() {
        router.replace({ uri: 'pages/entry/entry', params: { dir: 'i' } });
    },
    swipe(e) {
        if (e.direction === 'right') {
            app.terminate();
        }
    }
};
