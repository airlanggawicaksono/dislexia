import 'package:dyslexia/src/features/reader/data/datasources/local_syllabifier_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LocalSyllabifierDatasource datasource;

  setUp(() {
    datasource = LocalSyllabifierDatasource();
  });

  group('syllabify', () {
    test('empty string returns empty', () {
      expect(datasource.syllabify(''), '');
    });

    test('short words (< 4 chars) are not syllabified', () {
      expect(datasource.syllabify('cat'), 'cat');
      expect(datasource.syllabify('a'), 'a');
      expect(datasource.syllabify('in'), 'in');
      expect(datasource.syllabify('the'), 'the');
    });

    test('words that already contain middle dot are skipped', () {
      expect(datasource.syllabify('al·ready'), 'al·ready');
    });

    test('V-CV pattern inserts a syllable break', () {
      // "paper" -> pa·per  (V-CV: a=consonant=p, vowel=a)
      final result = datasource.syllabify('paper');
      expect(result, contains('·'));
    });

    test('C-C pattern (consonant clusters) inserts a syllable break', () {
      // "apple" -> ap·ple (C-C: p=p)
      final result = datasource.syllabify('apple');
      expect(result, contains('·'));
    });

    test('common digraphs are not split (th, sh, ch, ng, ny, kh, sy)', () {
      final result = datasource.syllabify('bathroom');
      // "th" should stay together
      expect(result, contains('th'));
    });

    test('multi-word text syllabifies each word independently', () {
      final result = datasource.syllabify('hello world');
      expect(result.split(' ').length, 2);
      expect(result, contains('·'));
    });

    test('newlines are preserved', () {
      final result = datasource.syllabify('hello\nworld');
      expect(result.split('\n').length, 2);
    });

    test('blank lines are preserved', () {
      final result = datasource.syllabify('hello\n\nworld');
      expect(result.split('\n').length, 3);
    });

    test('long word gets multiple syllable breaks', () {
      final result = datasource.syllabify('beautiful');
      // should have at least 2 dots for 3+ syllable word
      expect(result.split('·').length, greaterThanOrEqualTo(3));
    });

    test('non-alphabetic characters are preserved', () {
      final result = datasource.syllabify("don't 123");
      expect(result, contains("'"));
      expect(result, contains('123'));
    });
  });
}
