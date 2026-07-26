import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/player_setup_screen.dart';
import 'providers/game_provider.dart';
import 'screens/role_viewing_screen.dart';

void main() {
  runApp(const UndercoverApp());
}

class AppColors {
  static const purpleDark = Color(0xFF3B057A);
  static const purpleMain = Color(0xFF7B1FFF);
  static const purpleLight = Color(0xFFB84DFF);
  static const magentaGlow = Color(0xFFFF4DFF);
  static const yellowMain = Color(0xFFFFD21F);
  static const yellowDark = Color(0xFFFFA800);
  static const orange = Color(0xFFFF8A2A);
  static const cardPurple = Color(0xFF5A16C8);
  static const cardPurpleLight = Color(0xFF8B35FF);
  static const cardLavender = Color(0xFFF4E7FF);
  static const screenPurple = Color(0xFF681BCE);
  static const textWhite = Color(0xFFFFFFFF);
  static const textSoft = Color(0xFFEFDFFF);
  static const textDark = Color(0xFF1D102E);
  static const blackMask = Color(0xFF111820);
  static const success = Color(0xFF45E07F);
  static const danger = Color(0xFFFF4D6D);
}

class UndercoverApp extends StatelessWidget {
  const UndercoverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GameProvider(),
      child: MaterialApp(
        title: 'Undercover',
        theme: ThemeData(
          colorScheme: const ColorScheme.light(
            primary: AppColors.purpleMain,
            onPrimary: AppColors.textWhite,
            primaryContainer: AppColors.success,
            onPrimaryContainer: AppColors.textDark,
            secondary: AppColors.yellowMain,
            onSecondary: AppColors.textDark,
            secondaryContainer: AppColors.cardPurpleLight,
            onSecondaryContainer: AppColors.textWhite,
            tertiary: AppColors.orange,
            onTertiary: AppColors.textDark,
            surface: AppColors.cardLavender,
            onSurface: AppColors.textDark,
            error: AppColors.danger,
            errorContainer: AppColors.danger,
            onErrorContainer: AppColors.textWhite,
          ),
          scaffoldBackgroundColor: AppColors.screenPurple,
          fontFamily: 'serif',
          textTheme: const TextTheme(
            displaySmall: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
            headlineMedium: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
            headlineSmall: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
            titleLarge: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
            bodyLarge: TextStyle(fontSize: 20, color: AppColors.textDark),
            bodyMedium: TextStyle(fontSize: 18, color: AppColors.textDark),
            labelLarge: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.purpleDark,
            foregroundColor: AppColors.textWhite,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontFamily: 'serif',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textWhite,
            ),
          ),
          tabBarTheme: const TabBarThemeData(
            indicatorColor: AppColors.yellowMain,
            labelColor: AppColors.yellowMain,
            unselectedLabelColor: AppColors.textWhite,
          ),
          cardTheme: CardThemeData(
            color: AppColors.cardLavender,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppColors.purpleLight, width: 1.2),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.textWhite,
            labelStyle: const TextStyle(color: AppColors.textDark),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.purpleLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.yellowMain,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.purpleLight),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.yellowMain,
              foregroundColor: AppColors.textDark,
              disabledBackgroundColor: AppColors.blackMask,
              disabledForegroundColor: AppColors.textSoft,
              textStyle: const TextStyle(
                fontFamily: 'serif',
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.purpleMain,
              textStyle: const TextStyle(
                fontFamily: 'serif',
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              side: const BorderSide(color: AppColors.purpleMain, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          sliderTheme: const SliderThemeData(
            activeTrackColor: AppColors.yellowMain,
            inactiveTrackColor: AppColors.textSoft,
            thumbColor: AppColors.orange,
            valueIndicatorColor: AppColors.purpleMain,
          ),
          checkboxTheme: CheckboxThemeData(
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.yellowMain;
              }
              return AppColors.textWhite;
            }),
            checkColor: WidgetStateProperty.all(AppColors.textDark),
          ),
          iconTheme: const IconThemeData(color: AppColors.purpleMain, size: 30),
          useMaterial3: true,
        ),
        home: const _AppBootstrap(),
      ),
    );
  }
}

class _AppBootstrap extends StatelessWidget {
  const _AppBootstrap();

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    if (!gameProvider.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (gameProvider.gameState == GameState.roleViewing) {
      return const RoleViewingScreen();
    }

    return const PlayerSetupScreen();
  }
}
