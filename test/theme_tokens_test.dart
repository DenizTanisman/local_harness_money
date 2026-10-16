import 'dart:io';

import 'package:local_harness_para/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// CR1-B acceptance: every raw color lives in lib/theme/; data colors don't
/// follow the theme; no BackdropFilter anywhere.
void main() {
  test('no raw Color(0x...) outside lib/theme/', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.contains('lib/theme/')) continue;
      if (entity.path.endsWith('.g.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('Color(0x')) {
          offenders.add('${entity.path}:${i + 1}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'raw colors must move to AppTokens:\n${offenders.join('\n')}',
    );
  });

  test('no BackdropFilter in the app (scroll performance rule)', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      // Constructor usage only — docs may mention the rule by name.
      if (entity.readAsStringSync().contains('BackdropFilter(')) {
        offenders.add(entity.path);
      }
    }
    expect(offenders, isEmpty);
  });

  test('sparkline stays GitHub green, not theme blue (CR1-B rule 3)', () {
    expect(AppTokens.sparkline, const Color(0xFF39D353));
    expect(AppTokens.sparkline, isNot(AppTokens.accentStart));
  });
}
