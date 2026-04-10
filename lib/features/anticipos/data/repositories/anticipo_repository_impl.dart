import '../../domain/entities/anticipo.dart';
import '../../domain/repositories/anticipo_repository.dart';
import '../datasources/anticipo_remote_datasource.dart';
import '../models/anticipo_model.dart';

class AnticipoRepositoryImpl implements AnticipoRepository {
  final AnticipoRemoteDataSource remoteDataSource;

  AnticipoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Anticipo>> getAnticipos() async {
    final models = await remoteDataSource.getAnticipos();
    return models;
  }

  @override
  Future<Anticipo?> getAnticipoById(String id) async {
    return await remoteDataSource.getAnticipoById(id);
  }

  @override
  Future<bool> crearAnticipo(Anticipo anticipo) async {
    final model = AnticipoModel.fromEntity(anticipo);
    return await remoteDataSource.crearAnticipo(model);
  }

  @override
  Future<bool> aprobarAnticipo(String id) async {
    return await remoteDataSource.aprobarAnticipo(id);
  }

  @override
  Future<bool> rechazarAnticipo(String id) async {
    return await remoteDataSource.rechazarAnticipo(id);
  }

  @override
  Future<bool> liquidarAnticipo(String id, double gastado) async {
    return await remoteDataSource.liquidarAnticipo(id, gastado);
  }
}