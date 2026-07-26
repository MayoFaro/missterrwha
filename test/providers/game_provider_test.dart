import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:undercover/data/word_pairs.dart';
import 'package:undercover/models/player.dart';
import 'package:undercover/providers/game_provider.dart';

// Helper: setup a GameProvider with [playerCount] players, game started and in playing phase.
Future<GameProvider> setupGame(int playerCount) async {
  final names = [
    'Alice',
    'Bob',
    'Charlie',
    'Dave',
    'Eve',
    'Frank',
    'Grace',
    'Henry',
    'Iris',
    'Jack',
    'Kate',
    'Leo',
    'Mia',
    'Nick',
  ];
  assert(playerCount >= 4 && playerCount <= 14);

  final provider = GameProvider();
  while (!provider.isInitialized) {
    await Future<void>.delayed(Duration.zero);
  }

  for (var i = 0; i < playerCount; i++) {
    provider.addPlayer(names[i]);
  }
  provider.startGame(); // → roleViewing
  provider.startPlayingPhase(); // → playing
  return provider;
}

// Helper: transition to voting and eliminate a player in one call.
void voteEliminate(GameProvider provider, String playerId) {
  provider.startVotingPhase(); // playing → voting
  provider.eliminatePlayer(playerId); // → playing or gameOver
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    PackageInfo.setMockInitialValues(
      appName: 'test',
      packageName: 'com.test',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ──────────────────────────────────────────────
  // needsMrWhiteGuess  (Fix 1)
  // ──────────────────────────────────────────────
  group('needsMrWhiteGuess', () {
    test('false when no player has been eliminated', () async {
      final provider = await setupGame(5);
      expect(provider.needsMrWhiteGuess, false);
    });

    test('false when eliminated player is not Mr. White', () async {
      final provider = await setupGame(5);
      final nonMrWhite = provider.players.firstWhere(
        (p) => p.role != PlayerRole.mrWhite,
      );
      voteEliminate(provider, nonMrWhite.id);
      expect(provider.needsMrWhiteGuess, false);
    });

    test('true when Mr. White is eliminated and has not guessed', () async {
      final provider = await setupGame(5);
      final mrWhite = provider.players.firstWhere(
        (p) => p.role == PlayerRole.mrWhite,
      );
      voteEliminate(provider, mrWhite.id);
      expect(provider.needsMrWhiteGuess, true);
    });

    test('false after Mr. White submits a guess', () async {
      final provider = await setupGame(5);
      final mrWhite = provider.players.firstWhere(
        (p) => p.role == PlayerRole.mrWhite,
      );
      voteEliminate(provider, mrWhite.id);
      provider.submitMrWhiteGuesses({mrWhite.id: 'SomeWord'});
      expect(provider.needsMrWhiteGuess, false);
    });

    test('true for second Mr. White after first has already guessed', () async {
      // 11 players → 6 citizens, 3 undercovers, 2 Mr. Whites
      final provider = await setupGame(11);
      final mrWhites = provider.players
          .where((p) => p.role == PlayerRole.mrWhite)
          .toList();
      expect(mrWhites.length, 2);

      // Eliminate and process first Mr. White
      voteEliminate(provider, mrWhites[0].id);
      expect(provider.needsMrWhiteGuess, true);
      provider.submitMrWhiteGuesses({mrWhites[0].id: 'Word1'});
      expect(provider.needsMrWhiteGuess, false);

      // Later, eliminate second Mr. White — must trigger guess again
      voteEliminate(provider, mrWhites[1].id);
      expect(provider.needsMrWhiteGuess, true);
    });
  });

  // ──────────────────────────────────────────────
  // Win conditions
  // ──────────────────────────────────────────────
  group('Win conditions (4 players — no Mr. White)', () {
    test('citizens win when the single undercover is eliminated', () async {
      final provider = await setupGame(4);
      // 4 players: 3 citizens, 1 undercover, 0 Mr. White
      final undercover = provider.players.firstWhere(
        (p) => p.role == PlayerRole.undercover,
      );
      voteEliminate(provider, undercover.id);
      expect(provider.winner, WinningTeam.citizens);
      expect(provider.gameState, GameState.gameOver);
    });

    test('undercovers win when alive undercovers >= alive citizens', () async {
      final provider = await setupGame(4);
      // Eliminate 2 of 3 citizens → 1 citizen vs 1 undercover → undercovers win
      final citizens = provider.players
          .where((p) => p.role == PlayerRole.citizen)
          .toList();
      voteEliminate(provider, citizens[0].id);
      if (provider.gameState != GameState.gameOver) {
        voteEliminate(provider, citizens[1].id);
      }
      expect(provider.winner, WinningTeam.undercovers);
      expect(provider.gameState, GameState.gameOver);
    });
  });

  group('Win conditions (5 players — with Mr. White)', () {
    test('citizens win when Mr. White is eliminated', () async {
      // 5 players: 3 citizens, 1 undercover, 1 Mr. White
      // Citizens win only when Mr. White AND all undercovers are gone.
      // Simplest path: eliminate undercover first, then Mr. White.
      final provider = await setupGame(5);
      final undercover = provider.players.firstWhere(
        (p) => p.role == PlayerRole.undercover,
      );
      final mrWhite = provider.players.firstWhere(
        (p) => p.role == PlayerRole.mrWhite,
      );

      voteEliminate(provider, undercover.id);
      expect(provider.gameState, isNot(GameState.gameOver));

      voteEliminate(provider, mrWhite.id);
      // Mr. White can guess before game over; submit wrong answer if prompted
      if (provider.needsMrWhiteGuess) {
        provider.submitMrWhiteGuesses({mrWhite.id: '__wrong__'});
      }
      expect(provider.winner, WinningTeam.citizens);
      expect(provider.gameState, GameState.gameOver);
    });

    test('Mr. White wins when only 1 citizen remains alive', () async {
      // 5 players: 3 citizens, 1 undercover, 1 Mr. White.
      // Eliminate 2 citizens → 1 citizen + 1 undercover + 1 Mr. White
      // → alive citizens == 1 → Mr. White wins.
      final provider = await setupGame(5);
      final citizens = provider.players
          .where((p) => p.role == PlayerRole.citizen)
          .toList();

      voteEliminate(provider, citizens[0].id);
      if (provider.gameState != GameState.gameOver) {
        voteEliminate(provider, citizens[1].id);
      }
      expect(provider.winner, WinningTeam.mrWhite);
      expect(provider.gameState, GameState.gameOver);
    });
  });

  // ──────────────────────────────────────────────
  // Scoring
  // ──────────────────────────────────────────────
  group('commitRoundScores', () {
    test('is idempotent — calling twice does not double-count', () async {
      final provider = await setupGame(4);
      final undercover = provider.players.firstWhere(
        (p) => p.role == PlayerRole.undercover,
      );
      voteEliminate(provider, undercover.id);

      provider.commitRoundScores();
      final afterFirst = Map<String, int>.from(provider.sessionScores);

      provider.commitRoundScores(); // second call must be a no-op
      expect(provider.sessionScores, afterFirst);
    });

    test('citizens receive points when undercover is eliminated', () async {
      final provider = await setupGame(4);
      final undercover = provider.players.firstWhere(
        (p) => p.role == PlayerRole.undercover,
      );
      voteEliminate(provider, undercover.id);
      provider.commitRoundScores();

      for (final player in provider.players) {
        if (player.role == PlayerRole.citizen) {
          expect(provider.sessionScores[player.name], greaterThan(0));
        }
      }
    });

    test('prepareNextRound resets in-memory round state', () async {
      final provider = await setupGame(4);
      voteEliminate(provider, provider.players.first.id);
      provider.commitRoundScores();
      provider.prepareNextRound();
      expect(provider.gameState, GameState.setup);
      expect(provider.players, isEmpty);
    });
  });

  // ──────────────────────────────────────────────
  // isCorrectMrWhiteGuess
  // ──────────────────────────────────────────────
  group('isCorrectMrWhiteGuess', () {
    test('true for exact citizen word (case-insensitive)', () async {
      final provider = await setupGame(5);
      final citizenWord = provider.currentWordPair!.citizenWord;
      expect(provider.isCorrectMrWhiteGuess(citizenWord), true);
      expect(provider.isCorrectMrWhiteGuess(citizenWord.toUpperCase()), true);
    });

    test('false for wrong word', () async {
      final provider = await setupGame(5);
      expect(provider.isCorrectMrWhiteGuess('__definitely_wrong__'), false);
    });
  });

  // ──────────────────────────────────────────────
  // Player management
  // ──────────────────────────────────────────────
  group('Player management', () {
    test('registerPlayer returns false for duplicate name', () async {
      final provider = GameProvider();
      await Future.delayed(Duration.zero);
      expect(provider.registerPlayer('Alice'), true);
      expect(provider.registerPlayer('Alice'), false);
    });

    test('registerPlayer trims whitespace', () async {
      final provider = GameProvider();
      await Future.delayed(Duration.zero);
      provider.registerPlayer('  Alice  ');
      expect(provider.registeredPlayerNames.contains('Alice'), true);
    });

    test('deleteRegisteredPlayer removes from all lists', () async {
      final provider = GameProvider();
      await Future.delayed(Duration.zero);
      provider.addPlayer('Alice');
      provider.deleteRegisteredPlayer('Alice');
      expect(provider.registeredPlayerNames.contains('Alice'), false);
      expect(provider.selectedPlayerNames.contains('Alice'), false);
    });

    test('canStartGame is false below minimum player count', () async {
      final provider = GameProvider();
      await Future.delayed(Duration.zero);
      provider.addPlayer('Alice');
      provider.addPlayer('Bob');
      provider.addPlayer('Charlie');
      expect(provider.canStartGame(), false);
      provider.addPlayer('Dave');
      expect(provider.canStartGame(), true);
    });
  });

  group("Balanced word pair selection", () {
    String pairKey(String first, String second) {
      final words = [first.toLowerCase(), second.toLowerCase()]..sort();
      return words.join("|");
    }

    test("contains the reviewed initial counters", () {
      expect(WordPairsData.initialUsageCounts["magasin|marché"], 2);
      expect(WordPairsData.initialUsageCounts["chaise|fauteuil"], 1);
      expect(WordPairsData.initialUsageCounts["accueil|guichet"], 1);
      expect(WordPairsData.initialUsageCounts.length, 23);
    });

    test("removes the three rejected easy pairs", () {
      final keys = WordPairsData.wordPairs
          .map((pair) => pairKey(pair.citizenWord, pair.undercoverWord))
          .toSet();
      expect(WordPairsData.wordPairs.length, 121);
      expect(keys, isNot(contains("affiche|panneau")));
      expect(keys, isNot(contains("sandwich|wrap")));
      expect(keys, isNot(contains("journaliste|reporter")));
    });

    test("selects a uniquely least-used pair", () async {
      final target = WordPairsData.wordPairs.first;
      final targetKey = pairKey(target.citizenWord, target.undercoverWord);
      final counts = {
        for (final pair in WordPairsData.wordPairs)
          pairKey(pair.citizenWord, pair.undercoverWord): 1,
        targetKey: 0,
      };
      SharedPreferences.setMockInitialValues({
        "word_pair_usage_counts": jsonEncode(counts),
      });

      final provider = GameProvider();
      while (!provider.isInitialized) {
        await Future<void>.delayed(Duration.zero);
      }
      for (final name in ["Alice", "Bob", "Charlie", "Dave"]) {
        provider.addPlayer(name);
      }
      provider.startGame();

      expect(
        pairKey(
          provider.currentWordPair!.citizenWord,
          provider.currentWordPair!.undercoverWord,
        ),
        targetKey,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final preferences = await SharedPreferences.getInstance();
      final persistedCounts =
          jsonDecode(preferences.getString("word_pair_usage_counts")!)
              as Map<String, dynamic>;
      expect(persistedCounts[targetKey], 1);
      expect(
        preferences.getStringList("recent_word_pair_keys"),
        contains(targetKey),
      );
    });

    test("does not select a recent pair even if it is less used", () async {
      final recent = WordPairsData.wordPairs.first;
      final recentKey = pairKey(recent.citizenWord, recent.undercoverWord);
      final counts = {
        for (final pair in WordPairsData.wordPairs)
          pairKey(pair.citizenWord, pair.undercoverWord): 1,
        recentKey: 0,
      };
      SharedPreferences.setMockInitialValues({
        "word_pair_usage_counts": jsonEncode(counts),
        "recent_word_pair_keys": [recentKey],
      });

      final provider = GameProvider();
      while (!provider.isInitialized) {
        await Future<void>.delayed(Duration.zero);
      }
      for (final name in ["Alice", "Bob", "Charlie", "Dave"]) {
        provider.addPlayer(name);
      }
      provider.startGame();

      expect(
        pairKey(
          provider.currentWordPair!.citizenWord,
          provider.currentWordPair!.undercoverWord,
        ),
        isNot(recentKey),
      );
    });
  });

  group("Playing order after a vote", () {
    test("keeps the same first player while that player is alive", () async {
      final provider = await setupGame(7);
      final initialFirst = provider.firstPlayingPlayer!;
      final eliminated = provider.alivePlayers.firstWhere(
        (player) =>
            player.id != initialFirst.id && player.role == PlayerRole.citizen,
      );

      voteEliminate(provider, eliminated.id);

      expect(provider.gameState, GameState.playing);
      expect(provider.firstPlayingPlayer!.id, initialFirst.id);
      expect(
        provider.alivePlayers.map((player) => player.id),
        isNot(contains(eliminated.id)),
      );
    });

    test(
      "chooses a non-Mr White first player if the first is eliminated",
      () async {
        final provider = await setupGame(7);
        final initialFirst = provider.firstPlayingPlayer!;

        voteEliminate(provider, initialFirst.id);

        expect(provider.gameState, GameState.playing);
        expect(provider.firstPlayingPlayer!.id, isNot(initialFirst.id));
        expect(provider.firstPlayingPlayer!.role, isNot(PlayerRole.mrWhite));
      },
    );
  });

  group("Role viewing progress", () {
    test(
      "restores the current player and assigned round after restart",
      () async {
        final provider = GameProvider();
        while (!provider.isInitialized) {
          await Future<void>.delayed(Duration.zero);
        }
        for (final name in ["Alice", "Bob", "Charlie", "Dave", "Eve"]) {
          provider.addPlayer(name);
        }
        provider.startGame();
        provider.advanceRoleViewing();
        provider.advanceRoleViewing();
        final expectedPlayerId = provider.roleViewingPlayers[2].id;
        final expectedPair = provider.currentWordPair!;
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final restored = GameProvider();
        while (!restored.isInitialized) {
          await Future<void>.delayed(Duration.zero);
        }

        expect(restored.gameState, GameState.roleViewing);
        expect(restored.currentRoleViewingIndex, 2);
        expect(restored.roleViewingPlayers[2].id, expectedPlayerId);
        expect(restored.currentWordPair!.citizenWord, expectedPair.citizenWord);
        expect(
          restored.currentWordPair!.undercoverWord,
          expectedPair.undercoverWord,
        );
      },
    );
  });
}
