import '../../domain/entities/usuario.dart';
import '../../domain/repositories/usuario_repository.dart';
import '../datasources/usuario_remote_datasource.dart';

class UsuarioRepositoryImpl implements UsuarioRepository {
  final UsuarioRemoteDataSource remoteDataSource;

  UsuarioRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Usuario?> login(String email, String password) async {
    return await remoteDataSource.login(email, password);
  }

  @override
  Future<bool> logout() async {
    await remoteDataSource.logout();
    return true;
  }

  @override
  Future<Usuario?> getCurrentUser() async {
    return await remoteDataSource.getCurrentUser();
  }
}