import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:undercover/screens/player_setup_screen.dart';

import '../models/player.dart';
import '../providers/game_provider.dart';
import 'mr_white_guess_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  void _startVotingPhase() {
    final gameProvider = context.read<GameProvider>();
    gameProvider.startVotingPhase();
  }

  Future<void> _showEliminationConfirmationDialog(Player player) async {
    final gameProvider = context.read<GameProvider>();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm elimination'),
          content: Text(
            'Are you sure ${player.name} was eliminated?',
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () {
                gameProvider.eliminatePlayer(player.id);
                Navigator.of(context).pop();
                if (gameProvider.gameState == GameState.gameOver) {
                  _showGameOverFlow();
                } else {
                  _showVotedDialog();
                }
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

    _showWinnerDialog();
  }

  Future<void> _showWinnerDialog() async {
    final gameProvider = context.read<GameProvider>();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Game Over'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(gameProvider.getWinner()),
              const SizedBox(height: 16),
              Text(
                'Civil points: ${gameProvider.getScoreSummary().citizenPoints}',
              ),
              Text(
                'Undercover points: ${gameProvider.getScoreSummary().undercoverPoints}',
              ),
              Text(
                'Mr White points: ${gameProvider.getScoreSummary().mrWhitePoints}',
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Play Again'),
              onPressed: () {
                final gameProvider = context.read<GameProvider>();
                gameProvider.resetGame();
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const PlayerSetupScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showVotedDialog() async {
    final gameProvider = context.read<GameProvider>();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Vote Result"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: "The player "),
                    TextSpan(
                      text: gameProvider.lastEliminatedPlayer?.name ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    TextSpan(text: " was eliminated."),
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Continue'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Phase'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Current round : ${gameProvider.currentRound}",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: gameProvider.gameState == GameState.voting
                        ? Text(
                            "Select the player eliminated by the table vote.",
                            style: Theme.of(context).textTheme.headlineSmall,
                          )
                        : Text(
                            "Discuss your word in the order displayed with the other players.",
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                  ),
                ),
                SizedBox(height: 20),
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
                            trailing: gameProvider.gameState == GameState.voting
                                ? IconButton(
                                    onPressed: () =>
                                        _showEliminationConfirmationDialog(
                                          player,
                                        ),
                                    icon: Icon(Icons.close),
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
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _startVotingPhase,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Text(
                      "Start Voting Phase",
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
