import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';
import 'screens/consent_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService().load();
  runApp(const ResearchHealthApp());
}

class ResearchHealthApp extends StatelessWidget {
  const ResearchHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService();
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'Health Research Study',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          locale: settings.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          debugShowCheckedModeBanner: false,
          home: ConsentScreen(settings: settings),
        );
      },
    );
  }
}
