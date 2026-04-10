import '../entities/usuario.dart';
import '../repositories/usuario_repository.dart';

class Login {
  final UsuarioRepository repository;

  Login(this.repository);

  Future<Usuario?> call(String email, String password) async {
    return await repository.login(email, password);
  }
}