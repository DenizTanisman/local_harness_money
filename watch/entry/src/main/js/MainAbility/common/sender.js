import storage from '@system.storage';
import { Builder, Message, P2pClient } from '../wearengine/wearengine.js';
import { PHONE_PKG, PHONE_FINGERPRINT } from './config.js';

// Entries that could not reach the phone wait here (JSON strings) and are
// resent the next time the app opens or an entry is sent.
const QUEUE_KEY = 'queue';
let client = null;

function p2p() {
    if (!client) {
        client = new P2pClient();
        client.setPeerPkgName(PHONE_PKG);
        client.setPeerFingerPrint(PHONE_FINGERPRINT);
    }
    return client;
}

function sendOne(json, done) {
    let finished = false;
    const finish = function (ok) {
        if (!finished) {
            finished = true;
            done(ok);
        }
    };
    const builder = new Builder();
    builder.setDescription(json);
    const message = new Message();
    message.builder = builder;
    p2p().send(message, {
        onSuccess: function () { finish(true); },
        onFailure: function () { finish(false); },
        onSendResult: function () {},
        onSendProgress: function () {}
    });
}

function readQueue(done) {
    storage.get({
        key: QUEUE_KEY,
        default: '[]',
        success: function (value) {
            try {
                done(JSON.parse(value || '[]'));
            } catch (e) {
                done([]);
            }
        },
        fail: function () { done([]); }
    });
}

function writeQueue(list, done) {
    storage.set({
        key: QUEUE_KEY,
        value: JSON.stringify(list),
        complete: function () { done(); }
    });
}

/** Sends one entry; on failure it is queued. done(sent: boolean). */
export function sendEntry(entry, done) {
    const json = JSON.stringify(entry);
    sendOne(json, function (ok) {
        if (ok) {
            flushQueue(function () { done(true); });
            return;
        }
        readQueue(function (list) {
            list.push(json);
            writeQueue(list, function () { done(false); });
        });
    });
}

/** Resends queued entries in order; done(remaining: number). */
export function flushQueue(done) {
    readQueue(function (list) {
        if (list.length === 0) {
            done(0);
            return;
        }
        sendOne(list[0], function (ok) {
            if (!ok) {
                done(list.length);
                return;
            }
            list.shift();
            writeQueue(list, function () { flushQueue(done); });
        });
    });
}
