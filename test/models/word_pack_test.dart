import 'package:flutter_test/flutter_test.dart';
import 'package:undercover/providers/game_provider.dart';

void main() {
  group('CustomWordPack.fromJson', () {
    Map<String, dynamic> validJson({List<Map<String, String>>? pairs}) => {
          'name': 'Animals',
          'language': 'fr',
          'difficulty': 'easy',
          'pairs': pairs ??
              [
                {'citizenWord': 'Cat', 'undercoverWord': 'Dog'},
                {'citizenWord': 'Lion', 'undercoverWord': 'Tiger'},
              ],
        };

    test('parses a valid pack', () {
      final pack = CustomWordPack.fromJson(validJson());
      expect(pack.name, 'Animals');
      expect(pack.language, AppLanguage.fr);
      expect(pack.difficulty, GameDifficulty.easy);
      expect(pack.pairs.length, 2);
      expect(pack.pairs.first.citizenWord, 'Cat');
      expect(pack.pairs.first.undercoverWord, 'Dog');
    });

    test('throws FormatException when pairs key is missing', () {
      expect(
        () => CustomWordPack.fromJson({
          'name': 'Test',
          'language': 'fr',
          'difficulty': 'easy',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when pairs list is empty after filtering', () {
      expect(
        () => CustomWordPack.fromJson(validJson(pairs: [
          {'citizenWord': 'Cat', 'undercoverWord': 'cat'},
        ])),
        throwsA(isA<FormatException>()),
      );
    });

    test('filters pairs where citizenWord == undercoverWord (case-insensitive)',
        () {
      final pack = CustomWordPack.fromJson(validJson(pairs: [
        {'citizenWord': 'Cat', 'undercoverWord': 'cat'},
        {'citizenWord': 'Lion', 'undercoverWord': 'Tiger'},
      ]));
      expect(pack.pairs.length, 1);
      expect(pack.pairs.first.citizenWord, 'Lion');
    });

    test('deduplicates identical pairs', () {
      final pack = CustomWordPack.fromJson(validJson(pairs: [
        {'citizenWord': 'Cat', 'undercoverWord': 'Dog'},
        {'citizenWord': 'Cat', 'undercoverWord': 'Dog'},
        {'citizenWord': 'Lion', 'undercoverWord': 'Tiger'},
      ]));
      expect(pack.pairs.length, 2);
    });

    test('deduplicates pairs case-insensitively', () {
      final pack = CustomWordPack.fromJson(validJson(pairs: [
        {'citizenWord': 'Cat', 'undercoverWord': 'Dog'},
        {'citizenWord': 'cat', 'undercoverWord': 'dog'},
        {'citizenWord': 'Lion', 'undercoverWord': 'Tiger'},
      ]));
      expect(pack.pairs.length, 2);
    });

    test('silently skips pairs with words exceeding 50 characters', () {
      final longWord = 'A' * 51;
      final pack = CustomWordPack.fromJson(validJson(pairs: [
        {'citizenWord': longWord, 'undercoverWord': 'Dog'},
        {'citizenWord': 'Cat', 'undercoverWord': longWord},
        {'citizenWord': 'Lion', 'undercoverWord': 'Tiger'},
      ]));
      expect(pack.pairs.length, 1);
      expect(pack.pairs.first.citizenWord, 'Lion');
    });

    test('accepts words of exactly 50 characters', () {
      final word50 = 'A' * 50;
      final pack = CustomWordPack.fromJson(validJson(pairs: [
        {'citizenWord': word50, 'undercoverWord': 'Dog'},
      ]));
      expect(pack.pairs.length, 1);
    });

    test('limits to 2000 pairs', () {
      final pairs = List.generate(
        2500,
        (i) => {'citizenWord': 'Word$i', 'undercoverWord': 'Other$i'},
      );
      final pack = CustomWordPack.fromJson(validJson(pairs: pairs));
      expect(pack.pairs.length, 2000);
    });

    test('throws FormatException on invalid language', () {
      expect(
        () => CustomWordPack.fromJson({
          'name': 'Test',
          'language': 'xx',
          'difficulty': 'easy',
          'pairs': [
            {'citizenWord': 'Cat', 'undercoverWord': 'Dog'},
          ],
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException on invalid difficulty', () {
      expect(
        () => CustomWordPack.fromJson({
          'name': 'Test',
          'language': 'fr',
          'difficulty': 'medium',
          'pairs': [
            {'citizenWord': 'Cat', 'undercoverWord': 'Dog'},
          ],
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('assigns new id when id field is absent', () {
      final pack = CustomWordPack.fromJson(validJson());
      expect(pack.id, isNotEmpty);
    });

    test('trims whitespace from name', () {
      final json = validJson();
      json['name'] = '  Animals  ';
      final pack = CustomWordPack.fromJson(json);
      expect(pack.name, 'Animals');
    });
  });
}
