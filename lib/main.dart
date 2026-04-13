import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'config/api_config.dart';
import 'features/usuarios/presentation/providers/usuario_provider.dart';
import 'features/anticipos/presentation/providers/anticipo_provider.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  
  final prefs = await SharedPreferences.getInstance();
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));
  
  runApp(EncomiExpressApp(prefs: prefs, dio: dio));
}

class EncomiExpressApp extends StatelessWidget {
  final SharedPreferences prefs;
  final Dio dio;

  const EncomiExpressApp({
    super.key,
    required this.prefs,
    required this.dio,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UsuarioProvider(prefs: prefs, dio: dio),
        ),
        ChangeNotifierProvider(
          create: (_) => AnticipoProvider(dio: dio),
        ),
      ],
      child: MaterialApp(
        title: 'EncomiExpress',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Roboto',
          scaffoldBackgroundColor: const Color(0xFFF5F6FA),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7B2FBE)),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}