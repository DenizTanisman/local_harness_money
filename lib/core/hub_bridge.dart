import 'dart:convert';

import 'package:flutter/services.dart';

/// Dart side of the `local_harness/hub` MethodChannel (docs/HUB_CONTRACT.md
/// §3). Same API in every Local Harness app. Every call is null-safe and a
/// no-op off-device (widget tests, non-Android hosts).
class HubBridge {
  HubBridge._();

  static const channel = MethodChannel('local_harness/hub');

  /// Writes [snapshot] to filesDir/hub_snapshot.json (atomic on the
  /// Kotlin side), where this app's HubProvider serves it to the hub.
  static Future<void> publishSnapshot(Map<String, Object?> snapshot) async {
    await _invoke<void>('publishSnapshot', jsonEncode(snapshot));
  }

  /// Another app's last published snapshot, or null when it is not
  /// installed, has never published, or refuses access.
  static Future<Map<String, Object?>?> readPeerSnapshot(String app) async {
    final raw = await _invoke<String>('readPeerSnapshot', app);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as Map).cast<String, Object?>();
    } on FormatException {
      return null;
    }
  }

  static Future<bool> isInstalled(String app) async =>
      await _invoke<bool>('isInstalled', app) ?? false;

  static Future<bool> launchApp(String app, {String? route}) async =>
      await _invoke<bool>('launchApp', {'app': app, 'route': route}) ?? false;

  static Future<T?> _invoke<T>(String method, Object? args) async {
    try {
      return await channel.invokeMethod<T>(method, args);
    } on MissingPluginException {
      return null; // Tests / non-Android hosts.
    } on PlatformException {
      return null;
    }
  }
}
