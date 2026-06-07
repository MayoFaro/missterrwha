import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_strings.dart';
import '../providers/game_provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  Future<void> _confirmResetStatistics(
    BuildContext context,
    AppStrings strings,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.resetStatistics),
          content: Text(strings.resetStatisticsMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.reset),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    context.read<GameProvider>().resetStatistics();
  }

  double _winRate(PlayerStatistics stats) {
    if (stats.totalRounds == 0) return 0;

    return stats.totalWins / stats.totalRounds * 100;
  }

  Widget _statTile(AppStrings strings, String label, int played, int won) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: Text(strings.statLine(played, won)),
    );
  }

  Widget _buildLastLeaderboard(GameProvider gameProvider, AppStrings strings) {
    final leaderboard = gameProvider.lastSessionLeaderboard;

    if (leaderboard.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(strings.noLastLeaderboard, textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: leaderboard.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = leaderboard[index];

        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(entry.key),
            trailing: Text(strings.points(entry.value)),
          ),
        );
      },
    );
  }

  Widget _buildPlayerStatistics(
    BuildContext context,
    GameProvider gameProvider,
    AppStrings strings,
  ) {
    final playerNames = {
      ...gameProvider.registeredPlayerNames,
      ...gameProvider.playerStatistics.keys,
    }.toList()..sort();

    if (playerNames.isEmpty) {
      return Center(child: Text(strings.noRegisteredPlayers));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: playerNames.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final playerName = playerNames[index];
        final stats =
            gameProvider.playerStatistics[playerName] ??
            const PlayerStatistics();
        final winRate = _winRate(stats).round();

        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text(
                    playerName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: Text(
                    strings.statsSummary(
                      stats.totalRounds,
                      stats.totalWins,
                      winRate,
                    ),
                  ),
                ),
                _statTile(
                  strings,
                  strings.citizen,
                  stats.citizenRounds,
                  stats.citizenWins,
                ),
                _statTile(
                  strings,
                  strings.undercovers,
                  stats.undercoverRounds,
                  stats.undercoverWins,
                ),
                _statTile(
                  strings,
                  strings.mrWhite,
                  stats.mrWhiteRounds,
                  stats.mrWhiteWins,
                ),
                ListTile(
                  dense: true,
                  title: Text(strings.wordsGuessedAsMrWhite),
                  trailing: Text('${stats.mrWhiteCorrectGuesses}'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final strings = AppStrings(gameProvider.appLanguage);

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(strings.statistics),
              bottom: TabBar(
                tabs: [
                  Tab(
                    icon: const Icon(Icons.leaderboard),
                    text: strings.leaderboard,
                  ),
                  Tab(
                    icon: const Icon(Icons.query_stats),
                    text: strings.statsPlayersTab,
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: strings.resetStatistics,
                  icon: const Icon(Icons.restart_alt),
                  onPressed: () => _confirmResetStatistics(context, strings),
                ),
              ],
            ),
            body: TabBarView(
              children: [
                _buildLastLeaderboard(gameProvider, strings),
                _buildPlayerStatistics(context, gameProvider, strings),
              ],
            ),
          ),
        );
      },
    );
  }
}
