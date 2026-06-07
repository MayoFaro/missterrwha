import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_strings.dart';
import '../models/player.dart';
import '../providers/game_provider.dart';
import 'game_screen.dart';

class RoleViewingScreen extends StatefulWidget {
  const RoleViewingScreen({super.key});

  @override
  State<RoleViewingScreen> createState() => _RoleViewingScreenState();
}

class _RoleViewingScreenState extends State<RoleViewingScreen> {
  int _currentPlayerIndex = 0;
  bool _showRole = false;

  void _nextPlayer() {
    final gameProvider = context.read<GameProvider>();

    if (_currentPlayerIndex < gameProvider.roleViewingPlayers.length - 1) {
      setState(() {
        _currentPlayerIndex++;
        _showRole = false;
      });
    } else {
      gameProvider.startPlayingPhase();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const GameScreen()),
      );
    }
  }

  String _roleLabel(PlayerRole? role, AppStrings strings) {
    return switch (role) {
      PlayerRole.undercover => strings.undercovers,
      PlayerRole.mrWhite => strings.mrWhite,
      PlayerRole.citizen || null => strings.citizen,
    };
  }

  Widget _adaptiveWordText(BuildContext context, String text) {
    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final strings = AppStrings(gameProvider.appLanguage);
        final roleViewingPlayers = gameProvider.roleViewingPlayers;
        final currentPlayer = roleViewingPlayers[_currentPlayerIndex];

        return Scaffold(
          appBar: AppBar(title: Text(strings.roleDiscovery)),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(
                          strings.playerProgress(
                            _currentPlayerIndex + 1,
                            roleViewingPlayers.length,
                          ),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentPlayer.name,
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 24),
                        if (!_showRole) ...[
                          Text(
                            strings.revealRoleHint,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => setState(() => _showRole = true),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                            child: Text(
                              strings.revealMyRole,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ] else ...[
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const SizedBox(height: 16),
                                if (currentPlayer.role ==
                                    PlayerRole.mrWhite) ...[
                                  Text(
                                    strings.yourRole,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _roleLabel(currentPlayer.role, strings),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    strings.noWord,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ] else ...[
                                  Text(
                                    strings.yourWord,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  _adaptiveWordText(
                                    context,
                                    currentPlayer.word ?? '',
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _nextPlayer,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                            child: Text(
                              _currentPlayerIndex <
                                      roleViewingPlayers.length - 1
                                  ? strings.nextPlayer
                                  : strings.start,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
