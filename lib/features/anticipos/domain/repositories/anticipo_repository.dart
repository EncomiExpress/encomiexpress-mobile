import '../entities/anticipo.dart';

abstract class AnticipoRepository {
  Future<List<Anticipo>> getAnticipos();
  Future<Anticipo?> getAnticipoById(String id);
  Future<bool> crearAnticipo(Anticipo anticipo);
  Future<bool> aprobarAnticipo(String id);
  Future<bool> rechazarAnticipo(String id);
  Future<bool> liquidarAnticipo(String id, double gastado);
}