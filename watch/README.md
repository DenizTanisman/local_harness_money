# 1B$ — Huawei Watch GT 5 quick entry

Tiny lite-wearable (HML/JS) app for quick income/outcome entry into Para.

- Main screen: left half red **Outcome**, right half green **Income**.
- Tap one → full-screen keypad for the amount → category picker →
  optional detail (preset list; lite wearables have no keyboard) → Gönder.
- The entry is sent to Para on the phone over Huawei Wear Engine P2P and
  saved on the day it was entered. If the phone can't be reached it waits
  in a queue on the watch and is resent next time ("N bekliyor").
- Swipe right = one step back (on the main screen: close the app).

## Setup (one time)

1. **Huawei developer account** — developer.huawei.com (individual is fine).
2. **AppGallery Connect project** with two apps:
   - Android: `dev.deniz.local_harness_para`, SHA-256
     `CA:13:E8:08:DE:F8:DA:9E:94:51:E8:D6:5B:6E:AE:C2:DE:FD:71:F0:C8:42:4F:88:59:81:FE:55:F9:29:CB:10`
     (debug key — the one Para is signed with).
   - HarmonyOS lite wearable: bundle `dev.deniz.para.watch`.
3. **Wear Engine** — App services › Development › Wear Engine: apply for
   the Android app (device management + message permissions). Until it is
   approved, Wear Engine returns error 8 and nothing arrives.
4. **DevEco Studio** — open this `watch/` folder. Turn on developer mode on
   the watch (Huawei Health › device › about), connect it, and let DevEco
   create the debug signing config (File › Project Structure › Signing).
5. **Watch fingerprint on the phone side** — put the watch app's signing
   certificate fingerprint (no colons) into `WATCH_FINGERPRINT` in
   `android/app/src/main/kotlin/dev/deniz/local_harness_para/WatchBridge.kt`
   and reinstall Para.
6. Run the watch app from DevEco. Open Para on the phone once and accept
   the Huawei Health authorization prompt.

Para must be running (foreground or background) to receive entries; the
watch queue covers the times it is not.

## Testing without the watch

- Watch logic (keypad, flow, message format, offline queue, category ids,
  hml ↔ js/css bindings), with fakes for the `@system.*` modules:

      node --import ./watch/test/register.mjs --test watch/test/watch.test.mjs

- Phone side end to end (debug builds of Para only): play the watch's part
  with adb — the entry appears in Para, a resend with the same id is ignored:

      adb shell "am broadcast -a dev.deniz.local_harness_para.WATCH_TEST \
        -p dev.deniz.local_harness_para \
        --es json '{\"id\":\"1792180000000\",\"d\":\"o\",\"a\":45,\"c\":\"market\",\"n\":\"Kahve\"}'"

## Files

- `entry/src/main/js/MainAbility/common/config.js` — phone package +
  fingerprint, categories and detail presets (edit freely; category ids must
  exist in `lib/core/watch_bridge.dart`).
- `entry/src/main/js/MainAbility/common/sender.js` — send + offline queue.
- `entry/src/main/js/MainAbility/wearengine/wearengine.js` — Huawei Wear
  Engine JS SDK (Apache-2.0, from Huawei's lite-wearable sample).
