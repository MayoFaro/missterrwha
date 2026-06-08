import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_strings.dart';
import '../providers/game_provider.dart';
import 'player_selection_screen.dart';
import 'player_setup_screen.dart';

class RoundSummaryScreen extends StatefulWidget {
  const RoundSummaryScreen({super.key});

  @override
  State<RoundSummaryScreen> createState() => _RoundSummaryScreenState();
}

class _RoundSummaryScreenState extends State<RoundSummaryScreen> {
  Map<String, int>? _roundScores;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_roundScores != null) return;

    final gameProvider = context.read<GameProvider>();
    _roundScores = gameProvider.getRoundScores();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GameProvider>().commitRoundScores();
      }
    });
  }

  void _startNextRound() {
    final gameProvider = context.read<GameProvider>();
    gameProvider.prepareNextRound();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const PlayerSelectionScreen()),
    );
  }

  void _endSession() {
    final gameProvider = context.read<GameProvider>();
    gameProvider.endSession();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const PlayerSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final strings = AppStrings(gameProvider.appLanguage);
        final scoreSummary = gameProvider.getScoreSummary();
        final roundScores = _roundScores ?? gameProvider.getRoundScores();

        return Scaffold(
          appBar: AppBar(
            title: Text(strings.roundSummary),
            automaticallyImplyLeading: false,
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
                            strings.winnerMessage(gameProvider.winner),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${strings.citizenPoints} : ${scoreSummary.citizenPoints}',
                          ),
                          Text(
                            '${strings.undercoverPoints} : ${scoreSummary.undercoverPoints}',
                          ),
                          Text(
                            '${strings.mrWhitePoints} : ${scoreSummary.mrWhitePoints}',
                          ),
                          if (scoreSummary
                              .mrWhiteCorrectGuessers
                              .isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              strings.mrWhiteFoundBy(
                                scoreSummary.mrWhiteCorrectGuessers.join(', '),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Card(
                      child: ListView(
                        padding: const EdgeInsets.all(8.0),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              strings.leaderboard,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          ...gameProvider.leaderboard.map((entry) {
                            final roundPoints = roundScores[entry.key] ?? 0;

                            return ListTile(
                              title: Text(entry.key),
                              trailing: Text(strings.points(entry.value)),
                              subtitle: Text(strings.roundPoints(roundPoints)),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _startNextRound,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Text(
                      strings.nextRound,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _endSession,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                        width: 2,
                      ),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Text(
                      strings.stopGame,
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
