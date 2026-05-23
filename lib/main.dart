import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'services/settings_service.dart';
import 'services/supabase_service.dart';
import 'screens/login_screen.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';
import 'screens/consent_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  await SettingsService().load();

  bool consentGiven = false;
  final userId = SupabaseService().currentUser?.id;
  if (userId != null) {
    consentGiven = await SettingsService.checkConsent(userId);
  }

  runApp(ResearchHealthApp(consentGiven: consentGiven));
}

class ResearchHealthApp extends StatelessWidget {
  final bool consentGiven;
  const ResearchHealthApp({super.key, required this.consentGiven});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService();
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        Widget home;
        if (!SupabaseService().isLoggedIn) {
          home = LoginScreen(settings: settings);
        } else if (consentGiven) {
          home = WelcomeScreen(settings: settings);
        } else {
          home = ConsentScreen(settings: settings);
        }
        return MaterialApp(
          title: 'Healife',
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
          scrollBehavior: const MaterialScrollBehavior().copyWith(overscroll: false),
          debugShowCheckedModeBanner: false,
          home: home,
        );
      },
    );
  }
}
