import 'dart:async';
import 'dart:io';
import 'package:conextar/constants/endpoints.dart';
import 'package:conextar/constants/sp_helper.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ContextarException implements Exception {
  final String message;
  ContextarException(this.message);

  @override
  String toString() => message;
}

class LogOptions {
  final bool requestData;
  final bool responseData;
  final bool requestHeaders;
  final bool responseHeaders;
  final bool errors;

  const LogOptions({
    this.requestData = false,
    this.responseData = false,
    this.requestHeaders = false,
    this.responseHeaders = false,
    this.errors = true,
  });
}

class DioApiClient {
  // static const _storage = FlutterSecureStorage(); // Reference your storage instance

  static final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: Endpoints.BASE_URL,
            connectTimeout: const Duration(milliseconds: 5000),
            receiveTimeout: const Duration(milliseconds: 60000),
          ),
        )
        ..interceptors.addAll([
          // Interceptor 1: Automatic JWT Header Injection
          // Inside api_client.dart -> Interceptor 1:
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              final publicRoutes = [
                '/api/v1/auth/signin',
                '/api/v1/auth/register',
                '/api/v1/auth/verify-email',
                '/api/v1/auth/refresh-session',
                '/api/v1/auth/logout',
              ];

              try {
                print("Hereeeeeeeeeeeeeeee 1");
                if (!publicRoutes.contains(options.path)) {
                  print("Hereeeeeeeeeeeeeeee 2");
                  final String? token = await SpHelper.getAccessToken();

                  if (token != null && token.isNotEmpty) {
                    options.headers['Authorization'] = 'Bearer $token';
                  }
                }
              } catch (e) {
                debugPrint(
                  "Error reading token inside request interceptor: $e",
                );
              }
              return handler.next(options);
            },
          ),

          // Interceptor 2: Console Log Management (Refactored Talker bindings)
          InterceptorsWrapper(
            onRequest: (options, handler) {
              final LogOptions log =
                  options.extra['logOptions'] ?? const LogOptions();
              TalkerDioLogger(
                settings: TalkerDioLoggerSettings(
                  printRequestData: log.requestData,
                  printRequestHeaders: log.requestHeaders,
                  printErrorMessage: log.errors,
                  requestPen: AnsiPen()..white(),
                ),
              ).onRequest(options, handler);
            },
            onResponse: (response, handler) {
              final LogOptions log =
                  response.requestOptions.extra['logOptions'] ??
                  const LogOptions();
              TalkerDioLogger(
                settings: TalkerDioLoggerSettings(
                  printResponseData: log.responseData,
                  printResponseHeaders: log.responseHeaders,
                  responsePen: AnsiPen()..green(),
                ),
              ).onResponse(response, handler);
            },
            onError: (error, handler) {
              final LogOptions log =
                  error.requestOptions.extra['logOptions'] ??
                  const LogOptions();
              TalkerDioLogger(
                settings: TalkerDioLoggerSettings(
                  printErrorMessage: log.errors,
                  printErrorData: log.errors,
                  errorPen: AnsiPen()..red(),
                ),
              ).onError(error, handler);
            },
          ),
        ]);

  static Options _mergeOptions(Options? options, LogOptions? logOptions) {
    final activeOptions = options ?? Options();
    activeOptions.extra ??= <String, dynamic>{};
    activeOptions.extra!['logOptions'] = logOptions ?? const LogOptions();
    return activeOptions;
  }

  // Centralized Request Executor
  static Future<Response<T>> _execute<T>(
    Future<Response<T>> Function() requestBlock,
  ) async {
    try {
      return await requestBlock();
    } on DioException catch (err) {
      String errorMessage = 'Something went wrong';

      if (err.response?.data != null && err.response?.data is Map) {
        final data = err.response?.data as Map;
        errorMessage = data['message'] ?? data['error'] ?? errorMessage;
      } else if (err.response?.statusCode != null) {
        switch (err.response!.statusCode) {
          case 400:
            errorMessage = 'Bad Request (400)';
            break;
          case 401:
            errorMessage = 'Unauthorized Access (401)';
            break;
          case 403:
            errorMessage = 'Forbidden Action (403)';
            break;
          case 404:
            errorMessage = 'Endpoint Not Found (404)';
            break;
          case 500:
            errorMessage = 'Internal Server Error (500)';
            break;
          default:
            errorMessage =
                'Error Occurred: Status Code ${err.response!.statusCode}';
        }
      } else {
        if (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout) {
          errorMessage = "Server Timeout Please try again ";
        } else {
          errorMessage = err.message ?? errorMessage;
        }
      }
      throw ContextarException(errorMessage);
    } on SocketException catch (_) {
      throw ContextarException("No Internet exception found");
    } on FormatException catch (_) {
      throw ContextarException("Format Exception found");
    } catch (e) {
      throw ContextarException(e.toString());
    }
  }

  // Simplified REST Verb Interface
  static Future<Response<T>> getRequest<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    LogOptions? logs,
  }) {
    return _execute(
      () => _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: _mergeOptions(options, logs),
      ),
    );
  }

  static Future<Response<T>> postRequest<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    LogOptions? logs,
  }) {
    return _execute(
      () => _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _mergeOptions(options, logs),
      ),
    );
  }

  static Future<Response<T>> patchRequest<T>(
    String path, {
    dynamic data,
    Options? options,
    LogOptions? logs,
  }) {
    return _execute(
      () => _dio.patch<T>(
        path,
        data: data,
        options: _mergeOptions(options, logs),
      ),
    );
  }

  static Future<Response<T>> deleteRequest<T>(
    String path, {
    dynamic data,
    Options? options,
    LogOptions? logs,
  }) {
    return _execute(
      () => _dio.delete<T>(
        path,
        data: data,
        options: _mergeOptions(options, logs),
      ),
    );
  }

  static Future<Response<T>> uploadFile<T>(
    String path, {
    required String filePath,
    required String fileType,
    Map<String, dynamic>? additionalFields,
    Options? options,
    LogOptions? logs,
  }) async {
    final extension = filePath.split('.').last.toLowerCase();
    final formData = FormData.fromMap({
      ...?additionalFields,
      'file': await MultipartFile.fromFile(
        filePath,
        filename: '$fileType.$extension',
      ),
    });
    return _execute(
      () => _dio.post<T>(
        path,
        data: formData,
        options: _mergeOptions(options, logs),
      ),
    );
  }
}
