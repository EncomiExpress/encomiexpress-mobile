import '../entities/usuario.dart';

abstract class UsuarioRepository {
  Future<Usuario?> login(String email, String password);
  Future<bool> logout();
  Future<Usuario?> getCurrentUser();
}