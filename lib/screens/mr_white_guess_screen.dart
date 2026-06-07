import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_strings.dart';
import '../providers/game_provider.dart';
import 'round_summary_screen.dart';

class MrWhiteGuessScreen extends StatefulWidget {
  const MrWhiteGuessScreen({super.key});

  @override
  State<MrWhiteGuessScreen> createState() => _MrWhiteGuessScreenState();
}

class _MrWhiteGuessScreenState extends State<MrWhiteGuessScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _guessSubmitted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mrWhites = context.read<GameProvider>().mrWhiteGuessPlayers;

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

  void _submitGuesses(AppStrings strings) {
    final gameProvider = context.read<GameProvider>();
    final guesses = {
      for (final entry in _controllers.entries) entry.key: entry.value.text,
    };

    if (guesses.values.any((guess) => guess.trim().isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.everyMrWhiteMustGuess)));
      return;
    }

    gameProvider.submitMrWhiteGuesses(guesses);
    setState(() => _guessSubmitted = true);
  }

  void _goToRoundSummary() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const RoundSummaryScreen()),
    );
  }

  Widget _buildGuessResultCard(
    BuildContext context,
    GameProvider gameProvider,
    AppStrings strings,
  ) {
    final guesses = gameProvider.mrWhiteGuesses.values.toList();
    final hasCorrectGuess = guesses.any(gameProvider.isCorrectMrWhiteGuess);

    return Card(
      color: hasCorrectGuess
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasCorrectGuess ? strings.correctAnswer : strings.wrongAnswer,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: hasCorrectGuess
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onErrorContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasCorrectGuess
                  ? strings.mrWhiteFoundWord
                  : strings.mrWhiteMissedWord,
              style: TextStyle(
                color: hasCorrectGuess
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final strings = AppStrings(gameProvider.appLanguage);
        final mrWhites = gameProvider.mrWhiteGuessPlayers;

        return Scaffold(
          appBar: AppBar(title: Text(strings.mrWhiteGuessTitle)),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        strings.mrWhiteGuessPrompt,
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
                          enabled: !_guessSubmitted,
                          decoration: InputDecoration(
                            labelText: strings.mrWhiteGuessLabel(player.name),
                            border: const OutlineInputBorder(),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_guessSubmitted) ...[
                    const SizedBox(height: 16),
                    _buildGuessResultCard(context, gameProvider, strings),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _guessSubmitted
                        ? _goToRoundSummary
                        : () => _submitGuesses(strings),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Text(
                      _guessSubmitted ? strings.viewSummary : strings.submit,
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
