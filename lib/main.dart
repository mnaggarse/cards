import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/cards_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_fonts.dart';

void main() {
  runApp(const CardsApp());
}

class CardsApp extends StatelessWidget {
  const CardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CardsProvider()),
      ],
      child: MaterialApp(
        title: 'بطاقات',
        debugShowCheckedModeBanner: false,

        // RTL + Arabic locale
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.black,
            brightness: Brightness.light,
          ).copyWith(
            primary: Colors.black,
            secondary: Colors.black,
            surface: Colors.white,
          ),
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
          fontFamily: AppFonts.ibm,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            titleTextStyle: AppFonts.ibmStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 3,
          ),
          tabBarTheme: const TabBarThemeData(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black45,
            indicatorColor: Colors.black,
            indicatorSize: TabBarIndicatorSize.label,
          ),
          dividerTheme: const DividerThemeData(color: Colors.black12),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.black12),
            ),
          ),
        ),

        home: const HomeScreen(),
      ),
    );
  }
}
