import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_strings.dart';
import '../providers/game_provider.dart';
import '../screens/player_setup_screen.dart';

class RoundExitGuard extends StatefulWidget {
  final Widget child;

  const RoundExitGuard({required this.child, super.key});

  @override
  State<RoundExitGuard> createState() => _RoundExitGuardState();
}

class _RoundExitGuardState extends State<RoundExitGuard> {
  bool _confirmationOpen = false;

  Future<void> _requestExit() async {
    if (_confirmationOpen) return;
    _confirmationOpen = true;
    final gameProvider = context.read<GameProvider>();
    final strings = AppStrings(gameProvider.appLanguage);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.exitRoundTitle),
        content: Text(strings.exitRoundMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.no),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.yes),
          ),
        ],
      ),
    );

    if (!mounted) return;
    _confirmationOpen = false;
    if (confirmed != true) return;

    gameProvider.resetGame();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PlayerSetupScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestExit();
      },
      child: widget.child,
    );
  }
}
