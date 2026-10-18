# README screenshots

Taken on an Android emulator with made-up demo data only — never from a real phone.

```sh
adb -s emulator-5554 shell pm clear dev.deniz.local_harness_para
flutter build apk --release --target-platform android-arm64 -t tool/screenshots/seed_demo.dart
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-release.apk
adb -s emulator-5554 shell am start -n dev.deniz.local_harness_para/.MainActivity
# wait for "Demo hazır", then build and install the app itself over it
flutter build apk --release --target-platform android-arm64
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-release.apk
```

The seed fills the current month (salary, rent, a bill, daily spending), two recurring
rules and three category budgets, and marks the app's one-shot fresh start as done so
it does not wipe them. Save the shots to `docs/screenshots/` at 1200 px height.
