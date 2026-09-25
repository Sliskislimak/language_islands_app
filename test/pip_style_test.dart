import 'package:flutter_test/flutter_test.dart';
import 'package:language_islands_app/features/practice/pip_style.dart';

void main() {
  group('PipFontSize', () {
    test('maps the three levels to 0 / 2 / 4 pt', () {
      expect(PipFontSize.standard.delta, 0);
      expect(PipFontSize.medium.delta, 2);
      expect(PipFontSize.large.delta, 4);
    });

    test('cycles standard → medium → large → standard', () {
      expect(PipFontSize.standard.next, PipFontSize.medium);
      expect(PipFontSize.medium.next, PipFontSize.large);
      expect(PipFontSize.large.next, PipFontSize.standard);
    });
  });

  group('PipTranslationSize', () {
    test('maps the three levels to 0 / 2 / 4 pt', () {
      expect(PipTranslationSize.small.delta, 0);
      expect(PipTranslationSize.medium.delta, 2);
      expect(PipTranslationSize.large.delta, 4);
    });

    test('cycles small → medium → large → small', () {
      expect(PipTranslationSize.small.next, PipTranslationSize.medium);
      expect(PipTranslationSize.medium.next, PipTranslationSize.large);
      expect(PipTranslationSize.large.next, PipTranslationSize.small);
    });

    test('chip label prefixes the size with PL', () {
      expect(PipTranslationSize.small.chipLabel, 'PL: S');
      expect(PipTranslationSize.medium.chipLabel, 'PL: M');
      expect(PipTranslationSize.large.chipLabel, 'PL: L');
    });
  });
}
