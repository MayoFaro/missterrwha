import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/word_pairs.dart';
import '../data/word_pairs_en.dart';
import '../data/word_pairs_en_lvl2.dart';
import '../data/word_pairs_lvl2.dart';
import '../models/player.dart';
import '../models/word_pairs.dart';

enum GameState { setup, roleViewing, playing, voting, gameOver }

enum GameDifficulty { easy, hard }

enum AppLanguage { fr, en }

enum WinningTeam { citizens, undercovers, mrWhite }

class CustomWordPack {
  final String id;
  final String name;
  final AppLanguage language;
  final GameDifficulty difficulty;
  final List<WordPair> pairs;
  final DateTime importedAt;

  const CustomWordPack({
    required this.id,
    required this.name,
    required this.language,
    required this.difficulty,
    required this.pairs,
    required this.importedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'language': language.name,
      'difficulty': difficulty.name,
      'importedAt': importedAt.toIso8601String(),
      'pairs': pairs
          .map(
            (pair) => {
              'citizenWord': pair.citizenWord,
              'undercoverWord': pair.undercoverWord,
            },
          )
          .toList(),
    };
  }

  factory CustomWordPack.fromJson(Map<String, dynamic> json) {
    final pairsJson = json['pairs'];
    if (pairsJson is! List) {
      throw const FormatException('Missing pairs list.');
    }

    return CustomWordPack(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: (json['name'] as String?)?.trim() ?? 'Pack',
      language: _languageFromString(json['language'] as String?),
      difficulty: _difficultyFromString(json['difficulty'] as String?),
      importedAt:
          DateTime.tryParse(json['importedAt'] as String? ?? '') ??
          DateTime.now(),
      pairs: pairsJson.map((pairJson) {
        if (pairJson is! Map<String, dynamic>) {
          throw const FormatException('Invalid pair entry.');
        }

        final citizenWord = (pairJson['citizenWord'] as String?)?.trim();
        final undercoverWord = (pairJson['undercoverWord'] as String?)?.trim();
        if (citizenWord == null ||
            citizenWord.isEmpty ||
            undercoverWord == null ||
            undercoverWord.isEmpty) {
          throw const FormatException('Invalid pair words.');
        }

        return WordPair(
          citizenWord: citizenWord,
          undercoverWord: undercoverWord,
        );
      }).toList(),
    );
  }

  static AppLanguage _languageFromString(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'fr' || 'french' || 'français' || 'francais' => AppLanguage.fr,
      'en' || 'english' || 'anglais' => AppLanguage.en,
      _ => throw const FormatException('Invalid language.'),
    };
  }

  static GameDifficulty _difficultyFromString(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'easy' || 'facile' || '1' || 'level1' || 'lvl1' => GameDifficulty.easy,
      'hard' ||
      'difficult' ||
      'difficile' ||
      '2' ||
      'level2' ||
      'lvl2' => GameDifficulty.hard,
      _ => throw const FormatException('Invalid difficulty.'),
    };
  }
}

class PlayerStatistics {
  final int citizenRounds;
  final int undercoverRounds;
  final int mrWhiteRounds;
  final int citizenWins;
  final int undercoverWins;
  final int mrWhiteWins;
  final int mrWhiteCorrectGuesses;

  const PlayerStatistics({
    this.citizenRounds = 0,
    this.undercoverRounds = 0,
    this.mrWhiteRounds = 0,
    this.citizenWins = 0,
    this.undercoverWins = 0,
    this.mrWhiteWins = 0,
    this.mrWhiteCorrectGuesses = 0,
  });

  int get totalRounds => citizenRounds + undercoverRounds + mrWhiteRounds;
  int get totalWins => citizenWins + undercoverWins + mrWhiteWins;

  PlayerStatistics copyWith({
    int? citizenRounds,
    int? undercoverRounds,
    int? mrWhiteRounds,
    int? citizenWins,
    int? undercoverWins,
    int? mrWhiteWins,
    int? mrWhiteCorrectGuesses,
  }) {
    return PlayerStatistics(
      citizenRounds: citizenRounds ?? this.citizenRounds,
      undercoverRounds: undercoverRounds ?? this.undercoverRounds,
      mrWhiteRounds: mrWhiteRounds ?? this.mrWhiteRounds,
      citizenWins: citizenWins ?? this.citizenWins,
      undercoverWins: undercoverWins ?? this.undercoverWins,
      mrWhiteWins: mrWhiteWins ?? this.mrWhiteWins,
      mrWhiteCorrectGuesses:
          mrWhiteCorrectGuesses ?? this.mrWhiteCorrectGuesses,
    );
  }

  Map<String, int> toJson() {
    return {
      'citizenRounds': citizenRounds,
      'undercoverRounds': undercoverRounds,
      'mrWhiteRounds': mrWhiteRounds,
      'citizenWins': citizenWins,
      'undercoverWins': undercoverWins,
      'mrWhiteWins': mrWhiteWins,
      'mrWhiteCorrectGuesses': mrWhiteCorrectGuesses,
    };
  }

  factory PlayerStatistics.fromJson(Map<String, dynamic> json) {
    return PlayerStatistics(
      citizenRounds: json['citizenRounds'] as int? ?? 0,
      undercoverRounds: json['undercoverRounds'] as int? ?? 0,
      mrWhiteRounds: json['mrWhiteRounds'] as int? ?? 0,
      citizenWins: json['citizenWins'] as int? ?? 0,
      undercoverWins: json['undercoverWins'] as int? ?? 0,
      mrWhiteWins: json['mrWhiteWins'] as int? ?? 0,
      mrWhiteCorrectGuesses: json['mrWhiteCorrectGuesses'] as int? ?? 0,
    );
  }
}

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
  static const String _savedPlayerNamesKey = 'saved_player_names';
  static const String _playerStatisticsKey = 'player_statistics';
  static const String _lastSessionLeaderboardKey = 'last_session_leaderboard';
  static const String _appLanguageKey = 'app_language';
  static const String _customWordPacksKey = 'custom_word_packs';
  final List<Player> _players = [];
  final List<String> _registeredPlayerNames = [];
  final List<String> _selectedPlayerNames = [];
  final List<String> _roleViewingPlayerIds = [];
  final List<String> _playingPlayerIds = [];
  final Map<String, int> _sessionScores = {};
  final Map<String, PlayerStatistics> _playerStatistics = {};
  final List<MapEntry<String, int>> _lastSessionLeaderboard = [];
  final List<CustomWordPack> _customWordPacks = [];
  final Set<String> _usedWordPairKeys = {};
  GameState _gameState = GameState.setup;
  WordPair? _currentWordPair;
  WinningTeam? _winner;
  Player? _lastEliminatedPlayer;
  int _targetPlayerCount = 4;
  GameDifficulty _gameDifficulty = GameDifficulty.easy;
  AppLanguage _appLanguage = AppLanguage.fr;
  String _appVersion = '';
  int _currentRound = 1;
  bool _roundScoresCommitted = false;
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
  List<String> get registeredPlayerNames =>
      List.unmodifiable(_registeredPlayerNames);
  List<String> get selectedPlayerNames =>
      List.unmodifiable(_selectedPlayerNames);
  int get targetPlayerCount => _targetPlayerCount;
  GameDifficulty get gameDifficulty => _gameDifficulty;
  AppLanguage get appLanguage => _appLanguage;
  String get appVersion => _appVersion;
  RoleDistribution get targetRoleDistribution =>
      _roleDistributions[_targetPlayerCount]!;
  RoleDistribution? get selectedRoleDistribution =>
      roleDistributionForPlayerCount(_selectedPlayerNames.length);
  Map<String, int> get sessionScores => Map.unmodifiable(_sessionScores);
  Map<String, PlayerStatistics> get playerStatistics =>
      Map.unmodifiable(_playerStatistics);
  List<MapEntry<String, int>> get lastSessionLeaderboard =>
      List.unmodifiable(_lastSessionLeaderboard);
  List<CustomWordPack> get customWordPacks =>
      List.unmodifiable(_customWordPacks);
  List<MapEntry<String, int>> get leaderboard {
    final entries = _sessionScores.entries.toList()
      ..sort((a, b) {
        final scoreComparison = b.value.compareTo(a.value);
        if (scoreComparison != 0) return scoreComparison;
        return a.key.compareTo(b.key);
      });

    return entries;
  }

  List<Player> get alivePlayers =>
      _playersInOrder(_playingPlayerIds).where((p) => !p.isEliminated).toList();
  List<Player> get roleViewingPlayers => _playersInOrder(_roleViewingPlayerIds);
  Player? get firstPlayingPlayer {
    final alivePlayers = _playersInOrder(
      _playingPlayerIds,
    ).where((p) => !p.isEliminated).toList();
    return alivePlayers.isEmpty ? null : alivePlayers.first;
  }

  int get aliveCitizenCount =>
      alivePlayers.where((p) => p.role == PlayerRole.citizen).length;
  int get aliveUndercoverCount =>
      alivePlayers.where((p) => p.role == PlayerRole.undercover).length;
  int get aliveMrWhiteCount =>
      alivePlayers.where((p) => p.role == PlayerRole.mrWhite).length;

  GameState get gameState => _gameState;
  WordPair? get currentWordPair => _currentWordPair;
  WinningTeam? get winner => _winner;
  Player? get lastEliminatedPlayer => _lastEliminatedPlayer;
  int get currentRound => _currentRound;
  Map<String, String> get mrWhiteGuesses => Map.unmodifiable(_mrWhiteGuesses);
  bool get hasMrWhite => _players.any((p) => p.role == PlayerRole.mrWhite);
  bool get needsMrWhiteGuess =>
      _lastEliminatedPlayer?.role == PlayerRole.mrWhite &&
      _mrWhiteGuesses.isEmpty;
  List<Player> get mrWhiteGuessPlayers {
    final eliminatedPlayer = _lastEliminatedPlayer;
    if (eliminatedPlayer?.role != PlayerRole.mrWhite) return [];

    return [eliminatedPlayer!];
  }

  List<Player> get mrWhitePlayers =>
      _players.where((p) => p.role == PlayerRole.mrWhite).toList();

  GameProvider() {
    _loadAppLanguage();
    _loadAppVersion();
    _loadSavedPlayers();
    _loadStatistics();
    _loadCustomWordPacks();
  }

  // Player management
  void setTargetPlayerCount(int playerCount) {
    if (!_roleDistributions.containsKey(playerCount)) return;

    _targetPlayerCount = playerCount;
    if (_selectedPlayerNames.length > _targetPlayerCount) {
      _selectedPlayerNames.removeRange(
        _targetPlayerCount,
        _selectedPlayerNames.length,
      );
    }
    notifyListeners();
  }

  void setGameDifficulty(GameDifficulty difficulty) {
    if (_gameDifficulty == difficulty) return;

    _gameDifficulty = difficulty;
    notifyListeners();
  }

  void setAppLanguage(AppLanguage language) {
    if (_appLanguage == language) return;

    _appLanguage = language;
    _saveAppLanguage();
    notifyListeners();
  }

  RoleDistribution? roleDistributionForPlayerCount(int playerCount) {
    return _roleDistributions[playerCount];
  }

  bool registerPlayer(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return false;

    if (!_registeredPlayerNames.contains(trimmedName)) {
      _registeredPlayerNames.add(trimmedName);
      _sessionScores.putIfAbsent(trimmedName, () => 0);
      _playerStatistics.putIfAbsent(
        trimmedName,
        () => const PlayerStatistics(),
      );
      _savePlayerPool();
      _saveStatistics();
      notifyListeners();
      return true;
    }

    return false;
  }

  void addPlayer(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    registerPlayer(trimmedName);
    selectPlayerForNextRound(trimmedName);
  }

  void selectPlayerForNextRound(String name) {
    if (_selectedPlayerNames.length >= 14 ||
        _selectedPlayerNames.contains(name)) {
      return;
    }

    _selectedPlayerNames.add(name);
    notifyListeners();
  }

  void removePlayer(String playerId) {
    _players.removeWhere((player) => player.id == playerId);
    notifyListeners();
  }

  void removePlayerFromNextRound(String name) {
    _selectedPlayerNames.remove(name);
    notifyListeners();
  }

  void deleteRegisteredPlayer(String name) {
    _registeredPlayerNames.remove(name);
    _selectedPlayerNames.remove(name);
    _sessionScores.remove(name);
    _players.removeWhere((player) => player.name == name);
    _savePlayerPool();
    notifyListeners();
  }

  Future<void> _loadSavedPlayers() async {
    final preferences = await SharedPreferences.getInstance();
    final savedNames = preferences.getStringList(_savedPlayerNamesKey) ?? [];

    if (_registeredPlayerNames.isNotEmpty) return;

    _registeredPlayerNames.addAll(savedNames);
    for (final name in _registeredPlayerNames) {
      _sessionScores.putIfAbsent(name, () => 0);
      _playerStatistics.putIfAbsent(name, () => const PlayerStatistics());
    }
    notifyListeners();
  }

  Future<void> _loadAppLanguage() async {
    final preferences = await SharedPreferences.getInstance();
    final languageName = preferences.getString(_appLanguageKey);
    _appLanguage = AppLanguage.values.firstWhere(
      (language) => language.name == languageName,
      orElse: () => AppLanguage.fr,
    );
    notifyListeners();
  }

  Future<void> _saveAppLanguage() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_appLanguageKey, _appLanguage.name);
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    notifyListeners();
  }

  Future<void> _loadStatistics() async {
    final preferences = await SharedPreferences.getInstance();
    final statisticsJson = preferences.getString(_playerStatisticsKey);
    final leaderboardJson = preferences.getString(_lastSessionLeaderboardKey);

    if (statisticsJson != null) {
      final decoded = jsonDecode(statisticsJson) as Map<String, dynamic>;
      _playerStatistics
        ..clear()
        ..addAll(
          decoded.map((name, value) {
            return MapEntry(
              name,
              PlayerStatistics.fromJson(value as Map<String, dynamic>),
            );
          }),
        );
    }

    if (leaderboardJson != null) {
      final decoded = jsonDecode(leaderboardJson) as List<dynamic>;
      _lastSessionLeaderboard
        ..clear()
        ..addAll(
          decoded.map((entry) {
            final map = entry as Map<String, dynamic>;
            return MapEntry(map['name'] as String, map['score'] as int);
          }),
        );
    }

    for (final name in _registeredPlayerNames) {
      _playerStatistics.putIfAbsent(name, () => const PlayerStatistics());
    }
    notifyListeners();
  }

  Future<void> _saveStatistics() async {
    final preferences = await SharedPreferences.getInstance();
    final statisticsJson = jsonEncode(
      _playerStatistics.map((name, stats) => MapEntry(name, stats.toJson())),
    );
    final leaderboardJson = jsonEncode(
      _lastSessionLeaderboard
          .map((entry) => {'name': entry.key, 'score': entry.value})
          .toList(),
    );

    await preferences.setString(_playerStatisticsKey, statisticsJson);
    await preferences.setString(_lastSessionLeaderboardKey, leaderboardJson);
  }

  Future<void> _savePlayerPool() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _savedPlayerNamesKey,
      _registeredPlayerNames,
    );
  }

  Future<void> _loadCustomWordPacks() async {
    final preferences = await SharedPreferences.getInstance();
    final packsJson = preferences.getString(_customWordPacksKey);
    if (packsJson == null) return;

    final decoded = jsonDecode(packsJson);
    if (decoded is! List) return;

    _customWordPacks
      ..clear()
      ..addAll(
        decoded.whereType<Map<String, dynamic>>().map((packJson) {
          try {
            return CustomWordPack.fromJson(packJson);
          } on FormatException {
            return null;
          }
        }).whereType<CustomWordPack>(),
      );
    notifyListeners();
  }

  Future<void> _saveCustomWordPacks() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _customWordPacksKey,
      jsonEncode(_customWordPacks.map((pack) => pack.toJson()).toList()),
    );
  }

  Future<CustomWordPack> importCustomWordPack(String source) async {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('The pack root must be a JSON object.');
    }

    final pack = CustomWordPack.fromJson({
      ...decoded,
      'id': _uuid.v4(),
      'importedAt': DateTime.now().toIso8601String(),
    });
    if (pack.name.isEmpty || pack.pairs.isEmpty) {
      throw const FormatException('The pack must have a name and pairs.');
    }

    _customWordPacks.add(pack);
    await _saveCustomWordPacks();
    notifyListeners();
    return pack;
  }

  Future<void> addCustomWordPack(CustomWordPack pack) async {
    _customWordPacks.add(pack);
    await _saveCustomWordPacks();
    notifyListeners();
  }

  Future<void> removeCustomWordPack(String packId) async {
    _customWordPacks.removeWhere((pack) => pack.id == packId);
    await _saveCustomWordPacks();
    notifyListeners();
  }

  bool canStartGame() {
    return _roleDistributions.containsKey(_selectedPlayerNames.length);
  }

  // Game initialization
  void startGame() {
    if (!canStartGame()) return;

    _targetPlayerCount = _selectedPlayerNames.length;
    _players
      ..clear()
      ..addAll(
        _selectedPlayerNames.map((name) => Player(id: _uuid.v4(), name: name)),
      );
    _winner = null;
    _lastEliminatedPlayer = null;
    _mrWhiteGuesses.clear();
    _roundScoresCommitted = false;
    _assignRoles();
    _assignWords();
    _assignRoundOrders();
    _gameState = GameState.roleViewing;
    notifyListeners();
  }

  List<Player> _playersInOrder(List<String> playerIds) {
    return playerIds
        .map((id) {
          final matches = _players.where((player) => player.id == id);
          return matches.isEmpty ? null : matches.first;
        })
        .whereType<Player>()
        .toList();
  }

  void _assignRoundOrders() {
    if (_players.isEmpty) return;

    final roleViewingOrder = List<Player>.from(_players)..shuffle(_random);
    _roleViewingPlayerIds
      ..clear()
      ..addAll(roleViewingOrder.map((player) => player.id));

    final playingOrder = List<Player>.from(_players)..shuffle(_random);
    final firstNonMrWhite = playingOrder.indexWhere(
      (player) => player.role != PlayerRole.mrWhite,
    );
    if (firstNonMrWhite > 0) {
      final first = playingOrder.removeAt(firstNonMrWhite);
      playingOrder.insert(0, first);
    }
    _playingPlayerIds
      ..clear()
      ..addAll(playingOrder.map((player) => player.id));
  }

  void _assignRoles() {
    final distribution = _roleDistributions[_players.length];
    if (distribution == null) return;

    final roles = <PlayerRole>[
      for (var i = 0; i < distribution.undercovers; i++) PlayerRole.undercover,
      for (var i = 0; i < distribution.mrWhites; i++) PlayerRole.mrWhite,
      for (var i = 0; i < distribution.citizens; i++) PlayerRole.citizen,
    ]..shuffle(_random);

    for (var i = 0; i < _players.length; i++) {
      _players[i] = _players[i].copyWith(role: roles[i]);
    }
    notifyListeners();
  }

  void _assignWords() {
    final availableWordPairs = _availableWordPairs();

    if (availableWordPairs.isEmpty) {
      throw StateError(
        _appLanguage == AppLanguage.fr
            ? "Aucune paire de mots disponible pour cette partie."
            : "No word pair is available for this game.",
      );
    }

    _currentWordPair =
        availableWordPairs[_random.nextInt(availableWordPairs.length)];
    _usedWordPairKeys.add(_wordPairKey(_currentWordPair!));

    for (int i = 0; i < _players.length; i++) {
      final word = switch (_players[i].role) {
        PlayerRole.undercover => _currentWordPair!.undercoverWord,
        PlayerRole.mrWhite => null,
        PlayerRole.citizen || null => _currentWordPair!.citizenWord,
      };

      _players[i] = _players[i].copyWith(word: word);
    }
  }

  List<WordPair> _availableWordPairs() {
    final levelOneWordPairs = switch (_appLanguage) {
      AppLanguage.fr => WordPairsData.wordPairs,
      AppLanguage.en => WordPairsDataEn.wordPairs,
    };
    final levelTwoWordPairs = switch (_appLanguage) {
      AppLanguage.fr => WordPairsDataLvl2.wordPairs,
      AppLanguage.en => WordPairsDataEnLvl2.wordPairs,
    };
    final customLevelOneWordPairs = _customWordPacks
        .where(
          (pack) =>
              pack.language == _appLanguage &&
              pack.difficulty == GameDifficulty.easy,
        )
        .expand((pack) => pack.pairs)
        .toList();
    final customLevelTwoWordPairs = _customWordPacks
        .where(
          (pack) =>
              pack.language == _appLanguage &&
              pack.difficulty == GameDifficulty.hard,
        )
        .expand((pack) => pack.pairs)
        .toList();
    final wordPairPools = switch (_gameDifficulty) {
      GameDifficulty.easy => [
        [...levelOneWordPairs, ...customLevelOneWordPairs],
      ],
      GameDifficulty.hard => [
        [...levelOneWordPairs, ...customLevelOneWordPairs],
        [...levelTwoWordPairs, ...customLevelTwoWordPairs],
      ]..shuffle(_random),
    };

    for (final wordPairPool in wordPairPools) {
      final availableWordPairs = wordPairPool.where((wordPair) {
        return !_usedWordPairKeys.contains(_wordPairKey(wordPair));
      }).toList();

      if (availableWordPairs.isNotEmpty) {
        return availableWordPairs;
      }
    }

    return [];
  }

  String _wordPairKey(WordPair wordPair) {
    final words = [
      wordPair.citizenWord.trim().toLowerCase(),
      wordPair.undercoverWord.trim().toLowerCase(),
    ]..sort();

    return words.join('|');
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
    return switch ((_winner, _appLanguage)) {
      (WinningTeam.citizens, AppLanguage.fr) => "Les civils gagnent !",
      (WinningTeam.undercovers, AppLanguage.fr) => "Les Undercover gagnent !",
      (WinningTeam.mrWhite, AppLanguage.fr) => "Mr White gagne !",
      (WinningTeam.citizens, AppLanguage.en) => "Citizens win!",
      (WinningTeam.undercovers, AppLanguage.en) => "Undercovers win!",
      (WinningTeam.mrWhite, AppLanguage.en) => "Mr White wins!",
      (null, _) => "",
    };
  }

  String getRoleLabel(PlayerRole? role) {
    return switch ((role, _appLanguage)) {
      (PlayerRole.citizen, AppLanguage.fr) => "Civil",
      (PlayerRole.citizen, AppLanguage.en) => "Citizen",
      (PlayerRole.undercover, _) => "Undercover",
      (PlayerRole.mrWhite, _) => "Mr White",
      (null, AppLanguage.fr) => "Inconnu",
      (null, AppLanguage.en) => "Unknown",
    };
  }

  String getLastEliminationOutcome() {
    if (_winner != null) {
      return _appLanguage == AppLanguage.fr
          ? "${getWinner()} Une condition de victoire est atteinte."
          : "${getWinner()} A win condition has been reached.";
    }

    return _appLanguage == AppLanguage.fr
        ? "Aucune condition de victoire n'est atteinte. La manche continue."
        : "No win condition has been reached. The round continues.";
  }

  void submitMrWhiteGuesses(Map<String, String> guesses) {
    _mrWhiteGuesses
      ..clear()
      ..addAll(
        guesses.map(
          (playerId, guess) => MapEntry(playerId, _capitalizeWord(guess)),
        ),
      );
    notifyListeners();
  }

  String _capitalizeWord(String word) {
    final trimmedWord = word.trim();
    if (trimmedWord.isEmpty) return trimmedWord;

    return trimmedWord[0].toUpperCase() + trimmedWord.substring(1);
  }

  bool isCorrectMrWhiteGuess(String guess) {
    final citizenWord = _currentWordPair?.citizenWord.trim().toLowerCase();
    return citizenWord != null && guess.trim().toLowerCase() == citizenWord;
  }

  ScoreSummary getScoreSummary() {
    final eliminatedUndercoverCount = _players
        .where((p) => p.role == PlayerRole.undercover && p.isEliminated)
        .length;
    final eliminatedMrWhiteCount = _players
        .where((p) => p.role == PlayerRole.mrWhite && p.isEliminated)
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

  Map<String, int> getRoundScores() {
    final summary = getScoreSummary();
    final roundScores = {for (final player in _players) player.name: 0};

    for (final player in _players) {
      if (player.role == PlayerRole.citizen) {
        roundScores[player.name] =
            (roundScores[player.name] ?? 0) + summary.citizenPoints;
      } else if (player.role == PlayerRole.undercover) {
        roundScores[player.name] =
            (roundScores[player.name] ?? 0) + summary.undercoverPoints;
      } else if (player.role == PlayerRole.mrWhite) {
        final guess = _mrWhiteGuesses[player.id];
        final guessPoints = guess != null && isCorrectMrWhiteGuess(guess)
            ? 3
            : 0;
        final victoryPoints = _winner == WinningTeam.mrWhite ? 7 : 0;
        roundScores[player.name] =
            (roundScores[player.name] ?? 0) + victoryPoints + guessPoints;
      }
    }

    return roundScores;
  }

  void commitRoundScores() {
    if (_roundScoresCommitted) return;

    for (final entry in getRoundScores().entries) {
      _sessionScores[entry.key] =
          (_sessionScores[entry.key] ?? 0) + entry.value;
    }
    _commitRoundStatistics();
    _roundScoresCommitted = true;
    _saveStatistics();
    notifyListeners();
  }

  void _commitRoundStatistics() {
    final correctMrWhiteGuessers = getScoreSummary().mrWhiteCorrectGuessers;

    for (final player in _players) {
      final currentStats =
          _playerStatistics[player.name] ?? const PlayerStatistics();
      final wonAsCitizen =
          player.role == PlayerRole.citizen && _winner == WinningTeam.citizens;
      final wonAsUndercover =
          player.role == PlayerRole.undercover &&
          _winner == WinningTeam.undercovers;
      final wonAsMrWhite =
          player.role == PlayerRole.mrWhite && _winner == WinningTeam.mrWhite;
      final correctMrWhiteGuess =
          player.role == PlayerRole.mrWhite &&
          correctMrWhiteGuessers.contains(player.name);

      _playerStatistics[player.name] = switch (player.role) {
        PlayerRole.citizen => currentStats.copyWith(
          citizenRounds: currentStats.citizenRounds + 1,
          citizenWins: currentStats.citizenWins + (wonAsCitizen ? 1 : 0),
        ),
        PlayerRole.undercover => currentStats.copyWith(
          undercoverRounds: currentStats.undercoverRounds + 1,
          undercoverWins:
              currentStats.undercoverWins + (wonAsUndercover ? 1 : 0),
        ),
        PlayerRole.mrWhite => currentStats.copyWith(
          mrWhiteRounds: currentStats.mrWhiteRounds + 1,
          mrWhiteWins: currentStats.mrWhiteWins + (wonAsMrWhite ? 1 : 0),
          mrWhiteCorrectGuesses:
              currentStats.mrWhiteCorrectGuesses +
              (correctMrWhiteGuess ? 1 : 0),
        ),
        null => currentStats,
      };
    }
  }

  void resetStatistics() {
    _playerStatistics
      ..clear()
      ..addEntries(
        _registeredPlayerNames.map(
          (name) => MapEntry(name, const PlayerStatistics()),
        ),
      );
    _lastSessionLeaderboard.clear();
    _saveStatistics();
    notifyListeners();
  }

  void prepareNextRound() {
    _players.clear();
    _roleViewingPlayerIds.clear();
    _playingPlayerIds.clear();
    _gameState = GameState.setup;
    _currentWordPair = null;
    _winner = null;
    _lastEliminatedPlayer = null;
    _currentRound = 1;
    _mrWhiteGuesses.clear();
    _roundScoresCommitted = false;
    notifyListeners();
  }

  void endSession() {
    _lastSessionLeaderboard
      ..clear()
      ..addAll(leaderboard);
    _players.clear();
    _selectedPlayerNames.clear();
    _roleViewingPlayerIds.clear();
    _playingPlayerIds.clear();
    _targetPlayerCount = 4;
    _gameDifficulty = GameDifficulty.easy;
    for (final name in _registeredPlayerNames) {
      _sessionScores[name] = 0;
    }
    _gameState = GameState.setup;
    _currentWordPair = null;
    _winner = null;
    _lastEliminatedPlayer = null;
    _currentRound = 1;
    _mrWhiteGuesses.clear();
    _roundScoresCommitted = false;
    _usedWordPairKeys.clear();
    _saveStatistics();
    notifyListeners();
  }

  void resetGame() {
    prepareNextRound();
  }
}
