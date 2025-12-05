import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fasalmitra/firebase_options.dart';
import 'package:fasalmitra/screens/home_page.dart';

import 'package:fasalmitra/screens/phone_login.dart';
import 'package:fasalmitra/screens/create_listing_screen.dart';
import 'package:fasalmitra/screens/marketplace_screen.dart';
import 'package:fasalmitra/screens/register_screen.dart';
import 'package:fasalmitra/services/auth_service.dart';
import 'package:fasalmitra/services/language_service.dart';
import 'package:fasalmitra/services/tip_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await SharedPreferences.getInstance();
  await AuthService.instance.init(prefs);

  await LanguageService.instance.init(prefs);
  await TipService.instance.init();

  runApp(const FasalMitraApp());
}

class FasalMitraApp extends StatelessWidget {
  const FasalMitraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        final localeCode = LanguageService.instance.currentLanguage;
        return MaterialApp(
          title: 'FasalMitra',
          debugShowCheckedModeBanner: false,
          locale: Locale(localeCode),
          supportedLocales: LanguageService.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
            useMaterial3: true,
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
            ),
          ),
          home: const HomePage(),
          routes: {
            PhoneLoginScreen.routeName: (_) => const PhoneLoginScreen(),
            RegisterScreen.routeName: (_) => const RegisterScreen(),

            HomePage.routeName: (_) => const HomePage(),
            CreateListingScreen.routeName: (_) => const CreateListingScreen(),
            MarketplaceScreen.routeName: (_) => const MarketplaceScreen(),
          },
        );
      },
    );
  }
}
