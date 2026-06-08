import 'package:flutter_test/flutter_test.dart';
import 'package:undercover/models/player.dart';

void main() {
  group('Player', () {
    test('creates with required fields and defaults', () {
      const player = Player(id: '1', name: 'Alice');
      expect(player.id, '1');
      expect(player.name, 'Alice');
      expect(player.role, isNull);
      expect(player.word, isNull);
      expect(player.isEliminated, false);
    });

    test('copyWith updates only specified fields', () {
      const player = Player(id: '1', name: 'Alice');
      final updated = player.copyWith(role: PlayerRole.citizen, word: 'Cat');
      expect(updated.id, '1');
      expect(updated.name, 'Alice');
      expect(updated.role, PlayerRole.citizen);
      expect(updated.word, 'Cat');
      expect(updated.isEliminated, false);
    });

    test('copyWith preserves unchanged fields', () {
      const player = Player(
        id: '1',
        name: 'Alice',
        role: PlayerRole.undercover,
        word: 'Dog',
        isEliminated: false,
      );
      final updated = player.copyWith(isEliminated: true);
      expect(updated.role, PlayerRole.undercover);
      expect(updated.word, 'Dog');
      expect(updated.isEliminated, true);
    });

    test('original is unchanged after copyWith', () {
      const player = Player(id: '1', name: 'Alice', role: PlayerRole.citizen);
      player.copyWith(role: PlayerRole.mrWhite);
      expect(player.role, PlayerRole.citizen);
    });

    test('copyWith produces a different instance', () {
      const player = Player(id: '1', name: 'Alice');
      final updated = player.copyWith(word: 'Tree');
      expect(identical(player, updated), false);
    });

    test('all fields are final', () {
      // Verified at compile-time by the const constructor.
      const player = Player(
        id: 'x',
        name: 'Bob',
        role: PlayerRole.mrWhite,
        word: 'Sun',
        isEliminated: true,
      );
      expect(player.id, 'x');
      expect(player.name, 'Bob');
      expect(player.role, PlayerRole.mrWhite);
      expect(player.word, 'Sun');
      expect(player.isEliminated, true);
    });
  });
}
