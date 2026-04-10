import 'package:dio/dio.dart';
import '../../../../config/api_config.dart';
import '../models/anticipo_model.dart';

abstract class AnticipoRemoteDataSource {
  Future<List<AnticipoModel>> getAnticipos();
  Future<AnticipoModel?> getAnticipoById(String id);
  Future<bool> crearAnticipo(AnticipoModel anticipo);
  Future<bool> aprobarAnticipo(String id);
  Future<bool> rechazarAnticipo(String id);
  Future<bool> liquidarAnticipo(String id, double gastado);
}

class AnticipoRemoteDataSourceImpl implements AnticipoRemoteDataSource {
  final Dio dio;

  AnticipoRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<AnticipoModel>> getAnticipos() async {
    try {
      final response = await dio.get(ApiConfig.anticiposEndpoint);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => AnticipoModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<AnticipoModel?> getAnticipoById(String id) async {
    try {
      final response = await dio.get('${ApiConfig.anticiposEndpoint}/$id');
      
      if (response.statusCode == 200) {
        return AnticipoModel.fromJson(response.data['data'] ?? response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> crearAnticipo(AnticipoModel anticipo) async {
    try {
      final response = await dio.post(
        ApiConfig.anticiposEndpoint,
        data: anticipo.toJson(),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> aprobarAnticipo(String id) async {
    try {
      final response = await dio.post(
        '${ApiConfig.anticiposEndpoint}/liquidar/$id',
        data: {'estado': 'Pagado'},
      );
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> rechazarAnticipo(String id) async {
    try {
      final response = await dio.post(
        '${ApiConfig.anticiposEndpoint}/liquidar/$id',
        data: {'estado': 'Rechazado'},
      );
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> liquidarAnticipo(String id, double gastado) async {
    try {
      final response = await dio.post(
        '${ApiConfig.anticiposEndpoint}/liquidar/$id',
        data: {'gastado': gastado},
      );
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}