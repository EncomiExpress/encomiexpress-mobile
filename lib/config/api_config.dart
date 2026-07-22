class ApiConfig {
  // Por defecto apunta a localhost:3000 (sirve para Windows/Chrome/Edge en la
  // misma máquina donde corre el backend). Para emulador Android usar
  // 10.0.2.2 en vez de localhost; para dispositivo físico, la IP LAN de la
  // máquina que corre el backend. Override sin tocar código:
  //   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
  static const Duration timeout = Duration(seconds: 30);
}