import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:undercover/providers/game_provider.dart';
import 'package:undercover/widgets/round_exit_guard.dart';

Future<GameProvider> createPlayingGame() async {
  final provider = GameProvider();
  for (final name in ['Alice', 'Bob', 'Charlie', 'Dave']) {
    provider.addPlayer(name);
  }
  provider.startGame();
  provider.startPlayingPhase();
  return provider;
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    PackageInfo.setMockInitialValues(
      appName: 'test',
      packageName: 'com.test',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('asks before leaving and handles both answers', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = await createPlayingGame();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RoundExitGuard(
                      child: Scaffold(appBar: AppBar(title: Text('Protected'))),
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Quitter la manche ?'), findsOneWidget);
    expect(
      find.text('Êtes-vous sûr de vouloir sortir de la manche en cours ?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Non'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Protected'), findsOneWidget);
    expect(provider.gameState, GameState.playing);

    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Oui'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Undercover'), findsOneWidget);
    expect(provider.gameState, GameState.setup);
    expect(provider.players, isEmpty);
  });
}
