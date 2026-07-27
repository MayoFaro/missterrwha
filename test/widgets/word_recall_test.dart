import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:undercover/providers/game_provider.dart';
import 'package:undercover/screens/game_screen.dart';

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

  testWidgets('reveals a selected player word only while holding', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = GameProvider();
    for (final name in ['Alice', 'Bob', 'Charlie', 'Dave']) {
      provider.addPlayer(name);
    }
    provider.startGame();
    provider.startPlayingPhase();
    final player = provider.alivePlayers.first;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: GameScreen()),
      ),
    );

    await tester.tap(find.text('Revoir mon mot'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(player.name).last);
    await tester.pumpAndSettle();

    expect(find.text('Passez le téléphone à ${player.name}.'), findsOneWidget);
    expect(find.text(player.word ?? "Vous n'avez pas de mot."), findsNothing);

    await tester.tap(find.text('Je suis prêt'));
    await tester.pumpAndSettle();
    final holdButton = find.text('Maintenir pour révéler');
    final gesture = await tester.startGesture(tester.getCenter(holdButton));
    await tester.pump();

    expect(find.text(player.word ?? "Vous n'avez pas de mot."), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Maintenir pour révéler'), findsNothing);
    expect(find.text('Manche en cours'), findsOneWidget);
  });

  testWidgets('tells Mr White their role instead of saying there is no word', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = GameProvider();
    for (final name in ['Alice', 'Bob', 'Charlie', 'Dave', 'Eve']) {
      provider.addPlayer(name);
    }
    provider.startGame();
    provider.startPlayingPhase();
    final mrWhite = provider.alivePlayers.firstWhere(
      (player) => player.role?.name == 'mrWhite',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: GameScreen()),
      ),
    );

    await tester.tap(find.text('Revoir mon mot'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(mrWhite.name).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Je suis prêt'));
    await tester.pumpAndSettle();

    final holdButton = find.text('Maintenir pour révéler');
    final gesture = await tester.startGesture(tester.getCenter(holdButton));
    await tester.pump();

    expect(find.text('Vous êtes Mr White.'), findsOneWidget);
    expect(find.text("Vous n'avez pas de mot."), findsNothing);

    await gesture.up();
    await tester.pumpAndSettle();
  });
}
