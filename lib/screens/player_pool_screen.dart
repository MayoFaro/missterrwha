import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_strings.dart';
import '../providers/game_provider.dart';

class PlayerPoolScreen extends StatefulWidget {
  const PlayerPoolScreen({super.key});

  @override
  State<PlayerPoolScreen> createState() => _PlayerPoolScreenState();
}

class _PlayerPoolScreenState extends State<PlayerPoolScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addPlayer() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    context.read<GameProvider>().registerPlayer(name);
    _nameController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final strings = AppStrings(gameProvider.appLanguage);
        final registeredPlayers = gameProvider.registeredPlayerNames;

        return Scaffold(
          appBar: AppBar(title: Text(strings.savedPlayers)),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: strings.playerName,
                              border: const OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _addPlayer(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addPlayer,
                          child: Text(strings.add),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    child: registeredPlayers.isEmpty
                        ? Center(child: Text(strings.noRegisteredPlayers))
                        : ListView.builder(
                            itemCount: registeredPlayers.length,
                            itemBuilder: (context, index) {
                              final playerName = registeredPlayers[index];

                              return ListTile(
                                title: Text(playerName),
                                trailing: IconButton(
                                  tooltip: strings.deletePermanently,
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => gameProvider
                                      .deleteRegisteredPlayer(playerName),
                                ),
                              );
                            },
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
