import '../entities/anticipo.dart';
import '../repositories/anticipo_repository.dart';

class GetAnticipos {
  final AnticipoRepository repository;

  GetAnticipos(this.repository);

  Future<List<Anticipo>> call() async {
    return await repository.getAnticipos();
  }
}