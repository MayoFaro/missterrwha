import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_strings.dart';
import '../providers/game_provider.dart';
import 'player_pool_screen.dart';
import 'player_selection_screen.dart';
import 'statistics_screen.dart';
import 'word_packs_screen.dart';

class PlayerSetupScreen extends StatelessWidget {
  const PlayerSetupScreen({super.key});

  void _openMenuDestination(BuildContext context, String destination) {
    final screen = switch (destination) {
      'players' => const PlayerPoolScreen(),
      'packs' => const WordPacksScreen(),
      'statistics' => const StatisticsScreen(),
      _ => null,
    };
    if (screen == null) return;

    Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
  }

  Widget _languageButton(
    BuildContext context,
    GameProvider gameProvider, {
    required AppLanguage language,
    required String flag,
  }) {
    final selected = gameProvider.appLanguage == language;

    return Expanded(
      child: AnimatedScale(
        scale: selected ? 1.04 : 1,
        duration: const Duration(milliseconds: 160),
        child: OutlinedButton(
          onPressed: () => gameProvider.setAppLanguage(language),
          style: OutlinedButton.styleFrom(
            backgroundColor: selected
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            elevation: selected ? 6 : 0,
            side: BorderSide(
              color: selected
                  ? Theme.of(context).colorScheme.tertiary
                  : Theme.of(context).colorScheme.primary,
              width: selected ? 3 : 1.5,
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(flag, style: const TextStyle(fontSize: 34)),
        ),
      ),
    );
  }

  Widget _roleLine(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required int count,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 34),
          const SizedBox(width: 12),
          Text(
            '$label : $count',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final strings = AppStrings(gameProvider.appLanguage);
    final distribution = gameProvider.targetRoleDistribution;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appTitle),
        actions: [
          PopupMenuButton<String>(
            tooltip: strings.menu,
            icon: const Icon(Icons.menu),
            onSelected: (destination) {
              _openMenuDestination(context, destination);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'players',
                child: ListTile(
                  leading: const Icon(Icons.manage_accounts),
                  title: Text(strings.playerManagement),
                ),
              ),
              PopupMenuItem(
                value: 'packs',
                child: ListTile(
                  leading: const Icon(Icons.inventory_2),
                  title: Text(strings.wordPacks),
                ),
              ),
              PopupMenuItem(
                value: 'statistics',
                child: ListTile(
                  leading: const Icon(Icons.query_stats),
                  title: Text(strings.statistics),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _languageButton(
                            context,
                            gameProvider,
                            language: AppLanguage.fr,
                            flag: '🇫🇷',
                          ),
                          const SizedBox(width: 12),
                          _languageButton(
                            context,
                            gameProvider,
                            language: AppLanguage.en,
                            flag: '🇬🇧',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        strings.playerCount,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text('4'),
                          Expanded(
                            child: Slider(
                              min: 4,
                              max: 14,
                              divisions: 10,
                              label: gameProvider.targetPlayerCount.toString(),
                              value: gameProvider.targetPlayerCount.toDouble(),
                              onChanged: (value) {
                                gameProvider.setTargetPlayerCount(
                                  value.round(),
                                );
                              },
                            ),
                          ),
                          const Text('14'),
                        ],
                      ),
                      Center(
                        child: Text(
                          strings.playersCount(gameProvider.targetPlayerCount),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        strings.difficulty,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<GameDifficulty>(
                          segments: [
                            ButtonSegment(
                              value: GameDifficulty.easy,
                              icon: const Icon(Icons.sentiment_satisfied_alt),
                              label: Text(strings.easy),
                            ),
                            ButtonSegment(
                              value: GameDifficulty.hard,
                              icon: const Icon(Icons.psychology_alt),
                              label: Text(strings.hard),
                            ),
                          ],
                          selected: {gameProvider.gameDifficulty},
                          onSelectionChanged: (selection) {
                            gameProvider.setGameDifficulty(selection.first);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _roleLine(
                        context,
                        icon: Icons.groups,
                        color: Theme.of(context).colorScheme.secondary,
                        label: strings.citizens,
                        count: distribution.citizens,
                      ),
                      _roleLine(
                        context,
                        icon: Icons.visibility_off,
                        color: Theme.of(context).colorScheme.primary,
                        label: strings.undercovers,
                        count: distribution.undercovers,
                      ),
                      _roleLine(
                        context,
                        icon: Icons.help_outline,
                        color: Theme.of(context).colorScheme.tertiary,
                        label: strings.mrWhite,
                        count: distribution.mrWhites,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PlayerSelectionScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(18),
                ),
                child: Text(
                  strings.start,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              if (gameProvider.appVersion.isNotEmpty) ...[
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'v${gameProvider.appVersion}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
