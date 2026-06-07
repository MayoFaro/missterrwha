import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../localization/app_strings.dart';
import '../models/word_pairs.dart';
import '../providers/game_provider.dart';

class CreateWordPackScreen extends StatefulWidget {
  const CreateWordPackScreen({super.key});

  @override
  State<CreateWordPackScreen> createState() => _CreateWordPackScreenState();
}

class _CreateWordPackScreenState extends State<CreateWordPackScreen> {
  final _nameController = TextEditingController();
  final _civilController = TextEditingController();
  final _undercoverController = TextEditingController();
  final _civilFocusNode = FocusNode();
  final _uuid = const Uuid();

  AppLanguage _language = AppLanguage.fr;
  GameDifficulty _difficulty = GameDifficulty.easy;
  final List<(String, String)> _pairs = [];
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _language = context.read<GameProvider>().appLanguage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _civilController.dispose();
    _undercoverController.dispose();
    _civilFocusNode.dispose();
    super.dispose();
  }

  void _addPair() {
    final civil = _civilController.text.trim();
    final undercover = _undercoverController.text.trim();
    if (civil.isEmpty || undercover.isEmpty) return;
    setState(() {
      _pairs.add((civil, undercover));
      _civilController.clear();
      _undercoverController.clear();
    });
    _civilFocusNode.requestFocus();
  }

  void _removePair(int index) {
    setState(() => _pairs.removeAt(index));
  }

  Future<void> _save(AppStrings strings) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.packNameRequired)),
      );
      return;
    }
    if (_pairs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.atLeastOnePair)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final pack = CustomWordPack(
        id: _uuid.v4(),
        name: name,
        language: _language,
        difficulty: _difficulty,
        pairs: _pairs
            .map((p) => WordPair(citizenWord: p.$1, undercoverWord: p.$2))
            .toList(),
        importedAt: DateTime.now(),
      );
      if (!mounted) return;
      await context.read<GameProvider>().addCustomWordPack(pack);
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _languageButton(
    BuildContext context, {
    required AppLanguage language,
    required String flag,
  }) {
    final selected = _language == language;
    return Expanded(
      child: OutlinedButton(
        onPressed: () => setState(() => _language = language),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected
              ? Theme.of(context).colorScheme.secondary
              : Theme.of(context).colorScheme.surface,
          side: BorderSide(
            color: selected
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.primary,
            width: selected ? 3 : 1.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: Text(flag, style: const TextStyle(fontSize: 26)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final strings = AppStrings(gameProvider.appLanguage);

        return Scaffold(
          appBar: AppBar(title: Text(strings.createWordPackTitle)),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: strings.packName,
                          border: const OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _languageButton(
                            context,
                            language: AppLanguage.fr,
                            flag: '🇫🇷',
                          ),
                          const SizedBox(width: 12),
                          _languageButton(
                            context,
                            language: AppLanguage.en,
                            flag: '🇬🇧',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<GameDifficulty>(
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
                        selected: {_difficulty},
                        onSelectionChanged: (s) =>
                            setState(() => _difficulty = s.first),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _pairs.isEmpty
                      ? Center(child: Text(strings.noPairsYet))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: _pairs.length,
                          itemBuilder: (context, index) {
                            final pair = _pairs[index];
                            return ListTile(
                              dense: true,
                              title: Text('${pair.$1}  ·  ${pair.$2}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => _removePair(index),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _civilController,
                              focusNode: _civilFocusNode,
                              decoration: InputDecoration(
                                labelText: strings.civilWord,
                                border: const OutlineInputBorder(),
                              ),
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: (_) =>
                                  FocusScope.of(context).nextFocus(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _undercoverController,
                              decoration: InputDecoration(
                                labelText: strings.undercoverWord,
                                border: const OutlineInputBorder(),
                              ),
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: (_) => _addPair(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _addPair,
                            icon: const Icon(Icons.add),
                            tooltip: strings.addPair,
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _saving ? null : () => _save(strings),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                        child: Text(
                          strings.savePack,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
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
