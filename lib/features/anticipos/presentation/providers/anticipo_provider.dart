import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../data/datasources/anticipo_remote_datasource.dart';
import '../../data/repositories/anticipo_repository_impl.dart';
import '../../domain/entities/anticipo.dart';
import '../../domain/usecases/get_anticipos.dart';
import '../../domain/usecases/aprobar_anticipo.dart';
import '../../domain/usecases/crear_anticipo.dart';
import '../../domain/usecases/rechazar_anticipo.dart';

class AnticipoProvider extends ChangeNotifier {
  late final GetAnticipos _getAnticipos;
  late final AprobarAnticipo _aprobarAnticipo;
  late final CrearAnticipo _crearAnticipo;
  late final RechazarAnticipo _rechazarAnticipo;

  List<Anticipo> _anticipos = [];
  bool _loading = false;
  String? _error;

  AnticipoProvider({required Dio dio}) {
    final dataSource = AnticipoRemoteDataSourceImpl(dio: dio);
    final repository = AnticipoRepositoryImpl(remoteDataSource: dataSource);
    
    _getAnticipos = GetAnticipos(repository);
    _aprobarAnticipo = AprobarAnticipo(repository);
    _crearAnticipo = CrearAnticipo(repository);
    _rechazarAnticipo = RechazarAnticipo(repository);
  }

  List<Anticipo> get anticipos => _anticipos;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadAnticipos() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _anticipos = await _getAnticipos.call();
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> crearAnticipo(Anticipo anticipo) async {
    try {
      final success = await _crearAnticipo.call(anticipo);
      if (success) {
        await loadAnticipos();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> aprobarAnticipo(String id) async {
    try {
      final success = await _aprobarAnticipo.call(id);
      if (success) {
        await loadAnticipos();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> rechazarAnticipo(String id) async {
    try {
      final success = await _rechazarAnticipo.call(id);
      if (success) {
        await loadAnticipos();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  List<Anticipo> filtrarPorEstado(String estado) {
    if (estado == 'Todos') return _anticipos;
    return _anticipos.where((a) => a.estado == estado).toList();
  }

  List<Anticipo> filtrarPorConductor(String conductor) {
    if (conductor == 'Todos') return _anticipos;
    return _anticipos.where((a) => a.conductorNombre == conductor).toList();
  }

  List<String> get conductoresUnicos {
    return _anticipos.map((a) => a.conductorNombre).toSet().toList();
  }

  double get totalAnticipos => _anticipos.fold(0, (s, a) => s + a.anticipo);
  double get totalGastado => _anticipos.fold(0, (s, a) => s + a.gastado);
  int get pendientes => _anticipos.where((a) => a.estado == 'Pendiente').length;
}