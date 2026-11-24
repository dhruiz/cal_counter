import 'package:cal_counter/presentation/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeNotifier.isDarkFor', () {
    test('con "sistema" refleja el brillo del sistema (antes el interruptor '
        'mostraba "claro" con el tema oscuro)', () {
      expect(
        ThemeNotifier.isDarkFor(ThemeMode.system, Brightness.dark),
        isTrue,
      );
      expect(
        ThemeNotifier.isDarkFor(ThemeMode.system, Brightness.light),
        isFalse,
      );
    });

    test('modos explícitos ignoran el sistema', () {
      expect(ThemeNotifier.isDarkFor(ThemeMode.dark, Brightness.light), isTrue);
      expect(
        ThemeNotifier.isDarkFor(ThemeMode.light, Brightness.dark),
        isFalse,
      );
    });
  });
}
