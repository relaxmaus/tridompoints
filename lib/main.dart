import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:tridompoints/widgets/intro.dart';

import 'blocs/bloc_player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await EasyLocalization.ensureInitialized();
  String? savedLanguage = prefs.getString('language');
  debugPrint("caswi: $savedLanguage");
  Locale initialLocale;
  if (savedLanguage != null && savedLanguage.isNotEmpty) {
    initialLocale = Locale(savedLanguage);
  } else {
    initialLocale = PlatformDispatcher.instance.locale;
  }
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('de')],
      path: 'assets/langs',
      fallbackLocale: const Locale('en'),
      startLocale: initialLocale,
      useOnlyLangCode: true,
      child: ShowCaseWidget(
        builder: (BuildContext context) => BlocProvider(
          create: (context) => PlayerBloc(),
          child: const MyApp(),
        ),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      title: 'Tridom Scorekeeper',
      home: BlocProvider(
        create: (context) => PlayerBloc(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          title: 'Tridom Scorekeeper',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Colors.amber,
            ),
            inputDecorationTheme: const InputDecorationTheme(
              labelStyle: TextStyle(fontSize: 20),
              hintStyle: TextStyle(fontSize: 18),
            ),
            textTheme: const TextTheme(
              headlineSmall: TextStyle(fontSize: 24),
              headlineLarge: TextStyle(fontSize: 36),
              headlineMedium: TextStyle(fontSize: 30),
              bodyLarge: TextStyle(fontSize: 24),
              bodyMedium: TextStyle(fontSize: 20),
              bodySmall: TextStyle(fontSize: 16),
            ),
          ),
          home: const Intro(),
        ),
      ),
    );
  }
}
