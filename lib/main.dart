import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/services/api_client.dart';
import 'core/theme/theme_controller.dart';
import 'core/models.dart';
import 'features/auth/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await ApiClient().init();
  await ThemeController().init();
  runApp(const EncomiExpressApp());
}

class EncomiExpressApp extends StatelessWidget {
  const EncomiExpressApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Se reconstruye toda la app cuando cambia el modo claro/oscuro o la
    // paleta rojo/azul — AppColors ya viene actualizado por ThemeController
    // antes de notificar, así que cada widget descendiente relee los
    // valores nuevos en su próximo build.
    return ListenableBuilder(
      listenable: ThemeController(),
      builder: (context, _) {
        return MaterialApp(
          title: 'EncomiExpress',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Roboto',
            brightness: ThemeController().darkMode ? Brightness.dark : Brightness.light,
            scaffoldBackgroundColor: AppColors.bgGray,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.adminPrimary,
              brightness: ThemeController().darkMode ? Brightness.dark : Brightness.light,
            ),
          ),
          home: const LoginScreen(),
        );
      },
    );
  }
}
