import 'dart:io';

import 'package:dio/dio.dart';

import 'api_exception.dart';

class ApiHelper {
  final Dio _dio;
  const ApiHelper(this._dio);

  Future<Map<String, dynamic>> execute({
    required Method method,
    required String url,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    // Per-request headers are merged on top of whatever the shared Dio /
    // interceptors already set (e.g. the Authorization bearer). Passing null
    // leaves the default headers untouched.
    final options = headers == null ? null : Options(headers: headers);
    try {
      Response? response;
      switch (method) {
        case Method.get:
          response = await _dio.get(url,
              queryParameters: queryParameters, options: options);
          break;
        case Method.post:
          response = await _dio.post(url,
              data: data, queryParameters: queryParameters, options: options);
          break;
        case Method.put:
          response = await _dio.put(url,
              data: data, queryParameters: queryParameters, options: options);
          break;
        case Method.patch:
          response = await _dio.patch(url,
              data: data, queryParameters: queryParameters, options: options);
          break;
        case Method.delete:
          response = await _dio.delete(url,
              data: data, queryParameters: queryParameters, options: options);
          break;
      }

      return _returnResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet connection');
    } on DioException catch (e) {
      // Timeouts / connection failures carry no response — surface them as a
      // clean network failure instead of a null-assertion TypeError.
      final response = e.response;
      if (response == null) {
        throw FetchDataException('No Internet connection');
      }
      return _returnResponse(response);
    }
  }

  /// Human-readable error text from an error body. The backend (FastAPI)
  /// puts it under `detail`; keep `message` as a fallback for other hosts.
  String _errorMessage(Response response) {
    final data = response.data;
    if (data is Map) {
      final msg = data['detail'] ?? data['message'];
      if (msg != null) return msg.toString();
    }
    return data?.toString() ?? 'Unknown error';
  }

  Map<String, dynamic> _returnResponse(Response response) {
    switch (response.statusCode) {
      case 200:
        return response.data;
      case 201:
        return response.data;
      case 400:
        throw BadRequestException(_errorMessage(response));
      case 401:
        throw UnauthorizedException(_errorMessage(response));
      case 403:
        throw ForbiddenException(_errorMessage(response));
      case 404:
        throw NotFoundException(_errorMessage(response));
      case 422:
        throw UnprocessableContentException(_errorMessage(response));
      case 500:
        throw InternalServerException(_errorMessage(response));
      default:
        throw FetchDataException(
            'Error occured while Communication with Server with StatusCode : ${response.statusCode}');
    }
  }
}

enum Method { get, post, put, patch, delete }
