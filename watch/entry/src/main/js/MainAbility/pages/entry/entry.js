import router from '@system.router';
import { CATEGORIES, NOTES } from '../../common/config.js';
import { sendEntry } from '../../common/sender.js';

const MAX_DIGITS = 7;

export default {
    data: {
        dir: 'o', // 'o' outcome | 'i' income — set by router params
        step: 'amount',
        digits: '',
        amountText: '0 ₺',
        categoryLabels: [],
        notes: [],
        categoryIndex: 0,
        noteIndex: 0,
        resultText: ''
    },
    onInit() {
        const list = CATEGORIES[this.dir] || CATEGORIES.o;
        const labels = [];
        for (let i = 0; i < list.length; i++) {
            labels.push(list[i][1]);
        }
        this.categoryLabels = labels;
        this.notes = NOTES[this.dir] || NOTES.o;
    },

    // Keypad (one handler per key: no event parameters needed).
    k0() { this.digit('0'); },
    k1() { this.digit('1'); },
    k2() { this.digit('2'); },
    k3() { this.digit('3'); },
    k4() { this.digit('4'); },
    k5() { this.digit('5'); },
    k6() { this.digit('6'); },
    k7() { this.digit('7'); },
    k8() { this.digit('8'); },
    k9() { this.digit('9'); },
    kDel() {
        this.digits = this.digits.substring(0, this.digits.length - 1);
        this.showAmount();
    },
    kOk() {
        if (this.digits.length > 0) {
            this.step = 'category';
        }
    },
    digit(d) {
        if (this.digits.length >= MAX_DIGITS || (this.digits === '' && d === '0')) {
            return;
        }
        this.digits = this.digits + d;
        this.showAmount();
    },
    showAmount() {
        this.amountText = (this.digits === '' ? '0' : this.digits) + ' ₺';
    },

    categoryChanged(e) {
        this.categoryIndex = e.newSelected;
    },
    categoryDone() {
        this.step = 'note';
    },
    noteChanged(e) {
        this.noteIndex = e.newSelected;
    },
    send() {
        const list = CATEGORIES[this.dir] || CATEGORIES.o;
        const entry = {
            id: '' + new Date().getTime(),
            d: this.dir,
            a: parseInt(this.digits, 10),
            c: list[this.categoryIndex][0]
        };
        if (this.noteIndex > 0) {
            entry.n = this.notes[this.noteIndex];
        }
        this.step = 'done';
        this.resultText = 'Gönderiliyor...';
        const that = this;
        sendEntry(entry, function (sent) {
            that.resultText = sent
                ? (that.dir === 'i' ? '+' : '−') + that.digits + ' ₺ kaydedildi'
                : 'Telefona ulaşılamadı, sonra gönderilecek';
            setTimeout(function () {
                router.replace({ uri: 'pages/index/index' });
            }, 1500);
        });
    },

    swipe(e) {
        if (e.direction !== 'right') {
            return;
        }
        // Swipe right = one step back.
        if (this.step === 'note') {
            this.step = 'category';
        } else if (this.step === 'category') {
            this.step = 'amount';
        } else if (this.step === 'amount') {
            router.replace({ uri: 'pages/index/index' });
        }
    }
};
