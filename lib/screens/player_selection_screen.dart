import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_strings.dart';
import '../providers/game_provider.dart';
import 'player_pool_screen.dart';
import 'role_viewing_screen.dart';
import 'statistics_screen.dart';
import 'word_packs_screen.dart';

class PlayerSelectionScreen extends StatefulWidget {
  const PlayerSelectionScreen({super.key});

  @override
  State<PlayerSelectionScreen> createState() => _PlayerSelectionScreenState();
}

class _PlayerSelectionScreenState extends State<PlayerSelectionScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addPlayer() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    context.read<GameProvider>().addPlayer(name);
    _nameController.clear();
  }

  void _startGame(AppStrings strings) {
    final gameProvider = context.read<GameProvider>();
    if (!gameProvider.canStartGame()) return;

    if (gameProvider.selectedPlayerNames.length !=
        gameProvider.targetPlayerCount) {
      _showRoleDistributionDialog(gameProvider, strings);
      return;
    }

    _launchRound();
  }

  void _launchRound() {
    context.read<GameProvider>().startGame();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const RoleViewingScreen()),
    );
  }

  Future<void> _showRoleDistributionDialog(
    GameProvider gameProvider,
    AppStrings strings,
  ) async {
    final playerCount = gameProvider.selectedPlayerNames.length;
    final distribution = gameProvider.roleDistributionForPlayerCount(
      playerCount,
    );
    if (distribution == null) return;

    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.playersCount(playerCount)),
          content: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.newRoleDistribution),
                  const SizedBox(height: 12),
                  Text('${strings.citizens} : ${distribution.citizens}'),
                  Text('${strings.undercovers} : ${distribution.undercovers}'),
                  Text('${strings.mrWhite} : ${distribution.mrWhites}'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _launchRound();
              },
              child: Text(strings.launchRound),
            ),
          ],
        );
      },
    );
  }

  String _buttonText(GameProvider gameProvider, AppStrings strings) {
    if (gameProvider.canStartGame()) return strings.launchRound;

    if (gameProvider.selectedPlayerNames.length < 4) {
      final remaining = 4 - gameProvider.selectedPlayerNames.length;
      return strings.selectMorePlayers(remaining);
    }

    return strings.maxPlayers;
  }

  void _openMenuDestination(String destination) {
    final screen = switch (destination) {
      'players' => const PlayerPoolScreen(),
      'packs' => const WordPacksScreen(),
      'statistics' => const StatisticsScreen(),
      _ => null,
    };
    if (screen == null) return;

    Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final strings = AppStrings(gameProvider.appLanguage);

        return Scaffold(
          appBar: AppBar(
            title: Text(strings.choosePlayers),
            actions: [
              PopupMenuButton<String>(
                tooltip: strings.menu,
                icon: const Icon(Icons.menu),
                onSelected: _openMenuDestination,
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${strings.gameOrder} (${gameProvider.selectedPlayerNames.length}/14)',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(strings.tableOrderHint),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: strings.newPlayerName,
                                    border: const OutlineInputBorder(),
                                  ),
                                  onSubmitted: (_) => _addPlayer(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed:
                                    gameProvider.selectedPlayerNames.length < 14
                                    ? _addPlayer
                                    : null,
                                child: Text(strings.add),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Card(
                      child: gameProvider.registeredPlayerNames.isEmpty
                          ? Center(child: Text(strings.noRegisteredPlayers))
                          : ListView.builder(
                              itemCount:
                                  gameProvider.registeredPlayerNames.length,
                              itemBuilder: (context, index) {
                                final playerName =
                                    gameProvider.registeredPlayerNames[index];
                                final selectedPosition = gameProvider
                                    .selectedPlayerNames
                                    .indexOf(playerName);
                                final selected = selectedPosition != -1;

                                return ListTile(
                                  title: Text(playerName),
                                  leading: Checkbox(
                                    value: selected,
                                    onChanged:
                                        !selected &&
                                            gameProvider
                                                    .selectedPlayerNames
                                                    .length >=
                                                14
                                        ? null
                                        : (value) {
                                            if (value == true) {
                                              gameProvider
                                                  .selectPlayerForNextRound(
                                                    playerName,
                                                  );
                                            } else {
                                              gameProvider
                                                  .removePlayerFromNextRound(
                                                    playerName,
                                                  );
                                            }
                                          },
                                  ),
                                  trailing: selected
                                      ? IconButton(
                                          tooltip: strings.removeFromGame,
                                          icon: const Icon(Icons.close),
                                          onPressed: () {
                                            gameProvider
                                                .removePlayerFromNextRound(
                                                  playerName,
                                                );
                                          },
                                        )
                                      : null,
                                  onTap: () {
                                    if (selected) {
                                      gameProvider.removePlayerFromNextRound(
                                        playerName,
                                      );
                                    } else {
                                      gameProvider.selectPlayerForNextRound(
                                        playerName,
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: gameProvider.canStartGame()
                        ? () => _startGame(strings)
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Text(
                      _buttonText(gameProvider, strings),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
