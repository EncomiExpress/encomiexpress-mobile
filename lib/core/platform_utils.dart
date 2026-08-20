import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// image_picker no tiene implementación de cámara/galería en escritorio (Windows/
// macOS/Linux) ni en web — solo en Android/iOS. Fuera de esos dos, hay que usar
// el selector de archivos genérico.
bool get esMovil => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
