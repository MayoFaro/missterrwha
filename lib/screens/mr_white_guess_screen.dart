import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import 'player_setup_screen.dart';

class MrWhiteGuessScreen extends StatefulWidget {
  const MrWhiteGuessScreen({super.key});

  @override
  State<MrWhiteGuessScreen> createState() => _MrWhiteGuessScreenState();
}

class _MrWhiteGuessScreenState extends State<MrWhiteGuessScreen> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mrWhites = context.read<GameProvider>().mrWhitePlayers;

    for (final player in mrWhites) {
      _controllers.putIfAbsent(player.id, () => TextEditingController());
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submitGuesses() {
    final gameProvider = context.read<GameProvider>();
    final guesses = {
      for (final entry in _controllers.entries) entry.key: entry.value.text,
    };

    if (guesses.values.any((guess) => guess.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Every Mr White must enter a word.')),
      );
      return;
    }

    gameProvider.submitMrWhiteGuesses(guesses);
    _showResultDialog();
  }

  Future<void> _showResultDialog() async {
    final gameProvider = context.read<GameProvider>();
    final scoreSummary = gameProvider.getScoreSummary();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final correctGuessers = scoreSummary.mrWhiteCorrectGuessers;

        return AlertDialog(
          title: const Text('Game Over'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(gameProvider.getWinner()),
              const SizedBox(height: 16),
              Text('Civil points: ${scoreSummary.citizenPoints}'),
              Text('Undercover points: ${scoreSummary.undercoverPoints}'),
              Text('Mr White points: ${scoreSummary.mrWhitePoints}'),
              const SizedBox(height: 16),
              Text(
                correctGuessers.isEmpty
                    ? 'Mr White did not find the civilian word.'
                    : 'Correct guess: ${correctGuessers.join(', ')}',
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Play Again'),
              onPressed: () {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mr White Guess'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          final mrWhites = gameProvider.mrWhitePlayers;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Mr White must guess the civilian word.',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: mrWhites.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final player = mrWhites[index];

                      return TextField(
                        controller: _controllers[player.id],
                        decoration: InputDecoration(
                          labelText: '${player.name} guess',
                          border: const OutlineInputBorder(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submitGuesses,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Text(
                    'Submit Guess',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
