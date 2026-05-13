import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/word_pairs.dart';
import '../models/player.dart';
import '../models/word_pairs.dart';

enum GameState { setup, roleViewing, playing, voting, gameOver }

enum WinningTeam { citizens, undercovers, mrWhite }

class RoleDistribution {
  final int citizens;
  final int undercovers;
  final int mrWhites;

  const RoleDistribution({
    required this.citizens,
    required this.undercovers,
    required this.mrWhites,
  });
}

class ScoreSummary {
  final int citizenPoints;
  final int undercoverPoints;
  final int mrWhitePoints;
  final List<String> mrWhiteCorrectGuessers;

  const ScoreSummary({
    required this.citizenPoints,
    required this.undercoverPoints,
    required this.mrWhitePoints,
    required this.mrWhiteCorrectGuessers,
  });
}

class GameProvider extends ChangeNotifier {
  final List<Player> _players = [];
  GameState _gameState = GameState.setup;
  WordPair? _currentWordPair;
  WinningTeam? _winner;
  Player? _lastEliminatedPlayer;
  int _currentRound = 1;
  final Map<String, String> _mrWhiteGuesses = {}; // playerId -> guessed word
  final Random _random = Random();
  final Uuid _uuid = const Uuid();
  static const Map<int, RoleDistribution> _roleDistributions = {
    4: RoleDistribution(citizens: 3, undercovers: 1, mrWhites: 0),
    5: RoleDistribution(citizens: 3, undercovers: 1, mrWhites: 1),
    6: RoleDistribution(citizens: 4, undercovers: 1, mrWhites: 1),
    7: RoleDistribution(citizens: 4, undercovers: 2, mrWhites: 1),
    8: RoleDistribution(citizens: 5, undercovers: 2, mrWhites: 1),
    9: RoleDistribution(citizens: 5, undercovers: 3, mrWhites: 1),
    10: RoleDistribution(citizens: 6, undercovers: 3, mrWhites: 1),
    11: RoleDistribution(citizens: 6, undercovers: 3, mrWhites: 2),
    12: RoleDistribution(citizens: 7, undercovers: 3, mrWhites: 2),
    13: RoleDistribution(citizens: 7, undercovers: 4, mrWhites: 2),
    14: RoleDistribution(citizens: 8, undercovers: 4, mrWhites: 2),
  };

  // Getters
  List<Player> get players => List.unmodifiable(_players);
  List<Player> get alivePlayers =>
      _players.where((p) => !p.isEliminated).toList();
  GameState get gameState => _gameState;
  WordPair? get currentWordPair => _currentWordPair;
  WinningTeam? get winner => _winner;
  Player? get lastEliminatedPlayer => _lastEliminatedPlayer;
  int get currentRound => _currentRound;
  Map<String, String> get mrWhiteGuesses => Map.unmodifiable(_mrWhiteGuesses);
  bool get hasMrWhite => _players.any((p) => p.role == PlayerRole.mrWhite);
  bool get needsMrWhiteGuess => hasMrWhite && _mrWhiteGuesses.isEmpty;
  List<Player> get mrWhitePlayers =>
      _players.where((p) => p.role == PlayerRole.mrWhite).toList();

  // Player management
  void addPlayer(String name) {
    if (name.trim().isEmpty || _players.length >= 14) return;

    final player = Player(id: _uuid.v4(), name: name.trim());
    _players.add(player);
    notifyListeners();
  }

  void removePlayer(String playerId) {
    _players.removeWhere((player) => player.id == playerId);
    notifyListeners();
  }

  bool canStartGame() {
    return _roleDistributions.containsKey(_players.length);
  }

  // Game initialization
  void startGame() {
    if (!canStartGame()) return;

    _winner = null;
    _lastEliminatedPlayer = null;
    _mrWhiteGuesses.clear();
    _assignRoles();
    _assignWords();
    _gameState = GameState.roleViewing;
    notifyListeners();
  }

  void _assignRoles() {
    final distribution = _roleDistributions[_players.length];
    if (distribution == null) return;

    _players.shuffle(_random);

    var playerIndex = 0;

    for (var i = 0; i < distribution.undercovers; i++) {
      _players[playerIndex] = _players[playerIndex].copyWith(
        role: PlayerRole.undercover,
      );
      playerIndex++;
    }

    for (var i = 0; i < distribution.mrWhites; i++) {
      _players[playerIndex] = _players[playerIndex].copyWith(
        role: PlayerRole.mrWhite,
      );
      playerIndex++;
    }

    for (var i = 0; i < distribution.citizens; i++) {
      _players[playerIndex] = _players[playerIndex].copyWith(
        role: PlayerRole.citizen,
      );
      playerIndex++;
    }

    _players.shuffle(_random);
    notifyListeners();
  }

  void _assignWords() {
    _currentWordPair = WordPairsData
        .wordPairs[_random.nextInt(WordPairsData.wordPairs.length)];

    for (int i = 0; i < _players.length; i++) {
      final word = switch (_players[i].role) {
        PlayerRole.undercover => _currentWordPair!.undercoverWord,
        PlayerRole.mrWhite => null,
        PlayerRole.citizen || null => _currentWordPair!.citizenWord,
      };

      _players[i] = _players[i].copyWith(word: word);
    }
  }

  // Game flow
  void startPlayingPhase() {
    _gameState = GameState.playing;
    notifyListeners();
  }

  void startVotingPhase() {
    _gameState = GameState.voting;
    notifyListeners();
  }

  void eliminatePlayer(String playerId) {
    final playerIndex = _players.indexWhere((p) => p.id == playerId);
    if (playerIndex != -1) {
      _lastEliminatedPlayer = _players[playerIndex];
      _players[playerIndex] = _players[playerIndex].copyWith(
        isEliminated: true,
      );
      _checkWinConditions();
      _currentRound++;
    }
    notifyListeners();
  }

  void _checkWinConditions() {
    final alive = alivePlayers;
    final aliveCitizens = alive
        .where((p) => p.role == PlayerRole.citizen)
        .length;
    final aliveUndercovers = alive
        .where((p) => p.role == PlayerRole.undercover)
        .length;
    final aliveMrWhites = alive
        .where((p) => p.role == PlayerRole.mrWhite)
        .length;

    if (!hasMrWhite && aliveUndercovers == 0) {
      _winner = WinningTeam.citizens;
      _gameState = GameState.gameOver;
    } else if (hasMrWhite && aliveMrWhites == 0) {
      _winner = WinningTeam.citizens;
      _gameState = GameState.gameOver;
    } else if (hasMrWhite && aliveCitizens <= 1) {
      _winner = WinningTeam.mrWhite;
      _gameState = GameState.gameOver;
    } else if (aliveUndercovers >= aliveCitizens) {
      _winner = WinningTeam.undercovers;
      _gameState = GameState.gameOver;
    } else {
      _gameState = GameState.playing;
    }

    notifyListeners();
  }

  String getWinner() {
    return switch (_winner) {
      WinningTeam.citizens => "Citizens Win!",
      WinningTeam.undercovers => "Undercovers Win!",
      WinningTeam.mrWhite => "Mr White Wins!",
      null => "",
    };
  }

  void submitMrWhiteGuesses(Map<String, String> guesses) {
    _mrWhiteGuesses
      ..clear()
      ..addAll(
        guesses.map((playerId, guess) => MapEntry(playerId, guess.trim())),
      );
    notifyListeners();
  }

  bool isCorrectMrWhiteGuess(String guess) {
    final citizenWord = _currentWordPair?.citizenWord.trim().toLowerCase();
    return citizenWord != null && guess.trim().toLowerCase() == citizenWord;
  }

  ScoreSummary getScoreSummary() {
    final eliminatedUndercoverCount = _players
        .where(
          (p) => p.role == PlayerRole.undercover && p.isEliminated,
        )
        .length;
    final eliminatedMrWhiteCount = _players
        .where(
          (p) => p.role == PlayerRole.mrWhite && p.isEliminated,
        )
        .length;
    final correctGuessers = _mrWhiteGuesses.entries
        .where((entry) => isCorrectMrWhiteGuess(entry.value))
        .map((entry) {
          return _players.firstWhere((p) => p.id == entry.key).name;
        })
        .toList();

    return ScoreSummary(
      citizenPoints: eliminatedMrWhiteCount * 2 + eliminatedUndercoverCount,
      undercoverPoints: _winner == WinningTeam.undercovers ? 5 : 0,
      mrWhitePoints:
          (_winner == WinningTeam.mrWhite ? 7 : 0) + correctGuessers.length * 3,
      mrWhiteCorrectGuessers: correctGuessers,
    );
  }

  void resetGame() {
    _players.clear();
    _gameState = GameState.setup;
    _currentWordPair = null;
    _winner = null;
    _lastEliminatedPlayer = null;
    _currentRound = 1;
    _mrWhiteGuesses.clear();
    notifyListeners();
  }
}
