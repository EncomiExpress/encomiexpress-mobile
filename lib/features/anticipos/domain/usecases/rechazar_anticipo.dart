import '../repositories/anticipo_repository.dart';

class RechazarAnticipo {
  final AnticipoRepository repository;

  RechazarAnticipo(this.repository);

  Future<bool> call(String id) async {
    return await repository.rechazarAnticipo(id);
  }
}