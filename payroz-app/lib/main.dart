import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'theme.dart';
import 'providers/payroz_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard_navigation.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PayRozProvider()),
      ],
      child: const PayRozApp(),
    ),
  );
}

class PayRozApp extends StatelessWidget {
  const PayRozApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PayRozProvider>(context);
    
    return MaterialApp(
      title: 'PAYROZ B2C App',
      debugShowCheckedModeBanner: false,
      theme: PayRozTheme.lightTheme,
      locale: provider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('bn'),
      ],
      home: const AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<PayRozProvider>(context);

    // If authenticated, navigate to dashboard navigation, otherwise login
    if (authProvider.isAuthenticated) {
      return const DashboardNavigation();
    } else {
      return const LoginScreen();
    }
  }
}
