import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_strings.dart';
import '../models/player.dart';
import '../providers/game_provider.dart';
import '../widgets/round_exit_guard.dart';
import 'mr_white_guess_screen.dart';
import 'round_summary_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const Color _citizenCounterColor = Color(0xFF8A4B00);
  void _startVotingPhase() {
    context.read<GameProvider>().startVotingPhase();
  }

  Widget _roleCounter({
    required IconData icon,
    required Color color,
    required int count,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 42),
        const SizedBox(width: 8),
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontSize: 34,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Future<void> _showEliminationConfirmationDialog(
    Player player,
    AppStrings strings,
  ) async {
    final gameProvider = context.read<GameProvider>();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(strings.confirmElimination),
          content: Text(strings.eliminatedQuestion(player.name)),
          actions: <Widget>[
            TextButton(
              child: Text(strings.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(strings.confirm),
              onPressed: () {
                gameProvider.eliminatePlayer(player.id);
                Navigator.of(context).pop();
                _showVotedDialog(strings);
              },
            ),
          ],
        );
      },
    );
  }

  void _showGameOverFlow() {
    final gameProvider = context.read<GameProvider>();

    if (gameProvider.needsMrWhiteGuess) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MrWhiteGuessScreen()),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const RoundSummaryScreen()),
    );
  }

  Future<void> _showVotedDialog(AppStrings strings) async {
    final gameProvider = context.read<GameProvider>();
    final eliminatedPlayer = gameProvider.lastEliminatedPlayer;
    final eliminatedName = eliminatedPlayer?.name ?? '';

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(strings.eliminationResult),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.eliminatedSentence(eliminatedName),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                strings.roleLabel(
                  strings.roleNameLabel(eliminatedPlayer?.role),
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(strings.eliminationOutcome(gameProvider.winner)),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text(strings.continueText),
              onPressed: () {
                Navigator.of(context).pop();
                if (gameProvider.gameState == GameState.gameOver) {
                  _showGameOverFlow();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    GameProvider gameProvider,
    AppStrings strings,
  ) {
    final firstPlayingPlayer = gameProvider.firstPlayingPlayer;

    if (gameProvider.gameState == GameState.voting) {
      return Text(
        strings.votePrompt,
        style: Theme.of(context).textTheme.headlineSmall,
      );
    }

    if (gameProvider.currentRound == 1) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: strings.discussWord,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (firstPlayingPlayer != null) ...[
              TextSpan(
                text: strings.firstPlayer,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              TextSpan(
                text: firstPlayingPlayer.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                ),
              ),
              TextSpan(
                text: ".",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ],
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 24,
      runSpacing: 12,
      children: [
        _roleCounter(
          icon: Icons.groups,
          color: _citizenCounterColor,
          count: gameProvider.aliveCitizenCount,
        ),
        _roleCounter(
          icon: Icons.visibility_off,
          color: Theme.of(context).colorScheme.primary,
          count: gameProvider.aliveUndercoverCount,
        ),
        _roleCounter(
          icon: Icons.help_outline,
          color: Theme.of(context).colorScheme.tertiary,
          count: gameProvider.aliveMrWhiteCount,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final strings = AppStrings(gameProvider.appLanguage);

        return RoundExitGuard(
          child: Scaffold(
            appBar: AppBar(title: Text(strings.roundInProgress)),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          strings.roundNumber(gameProvider.currentRound),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildStatusCard(context, gameProvider, strings),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Card(
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: ListView.builder(
                            itemCount: gameProvider.alivePlayers.length,
                            itemBuilder: (context, index) {
                              final player = gameProvider.alivePlayers[index];
                              return ListTile(
                                title: Text(
                                  player.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                trailing:
                                    gameProvider.gameState == GameState.voting
                                    ? IconButton(
                                        onPressed: () =>
                                            _showEliminationConfirmationDialog(
                                              player,
                                              strings,
                                            ),
                                        icon: const Icon(Icons.close),
                                      )
                                    : Text(
                                        (index + 1).toString(),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    if (gameProvider.gameState != GameState.voting) ...[
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _startVotingPhase,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                        child: Text(
                          strings.passToVote,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
