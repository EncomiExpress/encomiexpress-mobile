import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/services/api_client.dart';
import 'core/services/auth_service.dart';
import 'core/theme/theme_controller.dart';
import 'core/models.dart';
import 'features/auth/screens/login_screen.dart';

// Único navigator de la app — permite volver al login desde fuera del árbol
// de widgets (ApiClient.onSessionExpired) cuando el token vence a mitad de
// una pantalla que no es el login.
final navigatorKey = GlobalKey<NavigatorState>();

// Por defecto Flutter solo deja arrastrar para hacer scroll (y por lo tanto
// disparar un RefreshIndicator con "pull to refresh") con touch/stylus — el
// mouse queda afuera adrede, porque MaterialScrollBehavior asume que en
// desktop/web se usa la ruedita o la barra de scroll. Como esta app corre
// como app de escritorio (Windows), sin eso arrastrar con el mouse no
// funciona en ninguna lista, incluido el "pull to refresh".
// También quita la barra de scroll que Flutter dibuja sola en plataformas de
// escritorio (Windows/macOS/Linux) — en Android/iOS nunca aparece por
// defecto, así que se saca acá para que la app se vea igual en ambos.
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        ...super.dragDevices,
        PointerDeviceKind.mouse,
      };

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await ApiClient().init();
  await ThemeController().init();

  // Cualquier 401 de una sesión que ya tenía token (ver ApiClient.onError)
  // dispara esto: limpia la sesión guardada y saca al usuario de vuelta al
  // login, descartando todas las pantallas intermedias — antes el token
  // vencido no desloguéaba y la app seguía dejando "cargar" datos que en
  // realidad el backend rechazaba en silencio.
  ApiClient.onSessionExpired = () async {
    await AuthService().logout();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(
          initialError: 'Tu sesión expiró. Inicia sesión de nuevo.',
        ),
      ),
      (route) => false,
    );
  };

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
          navigatorKey: navigatorKey,
          scrollBehavior: _AppScrollBehavior(),
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
