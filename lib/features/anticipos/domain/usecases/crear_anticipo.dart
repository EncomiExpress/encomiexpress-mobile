import '../entities/anticipo.dart';
import '../repositories/anticipo_repository.dart';

class CrearAnticipo {
  final AnticipoRepository repository;

  CrearAnticipo(this.repository);

  Future<bool> call(Anticipo anticipo) async {
    return await repository.crearAnticipo(anticipo);
  }
}