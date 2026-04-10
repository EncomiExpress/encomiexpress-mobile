import '../repositories/anticipo_repository.dart';

class AprobarAnticipo {
  final AnticipoRepository repository;

  AprobarAnticipo(this.repository);

  Future<bool> call(String id) async {
    return await repository.aprobarAnticipo(id);
  }
}