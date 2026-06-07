import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_strings.dart';
import '../providers/game_provider.dart';

class WordPacksScreen extends StatefulWidget {
  const WordPacksScreen({super.key});

  @override
  State<WordPacksScreen> createState() => _WordPacksScreenState();
}

class _WordPacksScreenState extends State<WordPacksScreen> {
  bool _importing = false;

  Future<void> _importPack(AppStrings strings) async {
    setState(() => _importing = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      final file = result?.files.single;
      final bytes = file?.bytes;
      if (bytes == null) return;

      final source = utf8.decode(bytes);
      if (!mounted) return;

      final pack = await context.read<GameProvider>().importCustomWordPack(
        source,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.importPackSuccess(pack.name, pack.pairs.length),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.importPackFailure(error.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }

  String _languageLabel(AppLanguage language) {
    return language == AppLanguage.fr ? 'FR' : 'EN';
  }

  String _difficultyLabel(AppStrings strings, GameDifficulty difficulty) {
    return difficulty == GameDifficulty.easy ? strings.easy : strings.hard;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final strings = AppStrings(gameProvider.appLanguage);
        final packs = gameProvider.customWordPacks;

        return Scaffold(
          appBar: AppBar(title: Text(strings.wordPacks)),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: _importing ? null : () => _importPack(strings),
                    icon: _importing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.file_open),
                    label: Text(strings.importWordPack),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Card(
                      child: packs.isEmpty
                          ? Center(child: Text(strings.noCustomPacks))
                          : ListView.separated(
                              padding: const EdgeInsets.all(8.0),
                              itemCount: packs.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final pack = packs[index];

                                return ListTile(
                                  title: Text(pack.name),
                                  subtitle: Text(
                                    '${_languageLabel(pack.language)} • ${_difficultyLabel(strings, pack.difficulty)} • ${strings.pairsCount(pack.pairs.length)}',
                                  ),
                                  trailing: IconButton(
                                    tooltip: strings.deletePack,
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      gameProvider.removeCustomWordPack(
                                        pack.id,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
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
