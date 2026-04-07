import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const EncomiExpressApp());
}

class EncomiExpressApp extends StatelessWidget {
  const EncomiExpressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EncomiExpress',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7B2FBE)),
      ),
      home: const LoginScreen(),
    );
  }
}