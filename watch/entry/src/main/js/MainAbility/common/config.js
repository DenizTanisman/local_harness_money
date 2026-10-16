// Phone app this watch app talks to (Para) and its signing-certificate
// SHA-256 fingerprint without colons — must match supportLists in config.json.
export const PHONE_PKG = 'dev.deniz.local_harness_para';
export const PHONE_FINGERPRINT = 'CA13E808DEF8DA9E9451E8D65B6EAEC2DEFD71F0C8424F885981FE55F929CB10';

// Categories: [id sent to the phone, label]. Ids map to Para categories in
// lib/core/watch_bridge.dart (watchCategories).
export const CATEGORIES = {
    o: [
        ['yeme', 'Yeme-İçme'],
        ['market', 'Market'],
        ['ulasim', 'Ulaşım'],
        ['alisveris', 'Alışveriş'],
        ['eglence', 'Eğlence'],
        ['saglik', 'Sağlık'],
        ['diger', 'Diğer']
    ],
    i: [
        ['harclik', 'Harçlık'],
        ['burs', 'Burs'],
        ['iade', 'İade'],
        ['diger', 'Diğer']
    ]
};

// Optional detail: the watch has no keyboard for third-party lite apps, so
// these are one-tap presets (edit freely). The first one means "no note".
export const NOTES = {
    o: ['Not yok', 'Kahve', 'Öğle yemeği', 'Akşam yemeği', 'Atıştırma', 'Su', 'Otobüs', 'Taksi'],
    i: ['Not yok', 'Babam', 'Annem', 'İade', 'Hediye']
};
