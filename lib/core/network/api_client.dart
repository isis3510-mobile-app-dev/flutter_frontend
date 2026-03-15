import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';

typedef AuthTokenProvider = Future<String?> Function();

class ApiClient {
  ApiClient({http.Client? httpClient, AuthTokenProvider? tokenProvider})
    : _httpClient = httpClient ?? http.Client(),
      _tokenProvider = tokenProvider;

  final http.Client _httpClient;
  final AuthTokenProvider? _tokenProvider;

  Future<dynamic> getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = ApiConfig.resolve(path, queryParameters: queryParameters);

    try {
      final response = await _httpClient
          .get(uri, headers: await _buildHeaders(headers))
          .timeout(ApiConfig.requestTimeout);

      return _decodeResponse(response);
    } on TimeoutException {
      throw const ApiException(message: 'The request timed out.');
    } on http.ClientException catch (error) {
      throw ApiException(message: error.message);
    } on FormatException {
      throw const ApiException(message: 'The server returned invalid JSON.');
    }
  }

  Future<Map<String, String>> _buildHeaders(
    Map<String, String>? headers,
  ) async {
    final token = await _resolveAuthToken();

    return <String, String>{
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      ...?headers,
    };
  }

  Future<String?> _resolveAuthToken() async {
    final providerToken = await _tokenProvider?.call();
    if (providerToken != null && providerToken.isNotEmpty) {
      return providerToken;
    }

    final envToken = dotenv.env['BEARER_TOKEN']?.trim();
    if (envToken != null && envToken.isNotEmpty) {
      return envToken;
    }

    return null;
  }

  dynamic _decodeResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        message: _extractErrorMessage(response.body),
        statusCode: response.statusCode,
      );
    }

    if (response.body.isEmpty) {
      return null;
    }

    return jsonDecode(response.body);
  }

  String _extractErrorMessage(String body) {
    if (body.isEmpty) {
      return 'The server returned an empty error response.';
    }

    final trimmedBody = body.trim();

    if (_looksLikeHtml(trimmedBody)) {
      return 'The server returned an HTML error page instead of JSON. Check the API URL and backend server.';
    }

    try {
      final decoded = jsonDecode(trimmedBody);
      if (decoded is Map<String, dynamic>) {
        final message =
            decoded['message'] ?? decoded['error'] ?? decoded['detail'];
        if (message is String && message.trim().isNotEmpty) {
          return _truncate(message.trim());
        }
      }
    } on FormatException {
      return _truncate(trimmedBody);
    }

    return 'The request failed.';
  }

  bool _looksLikeHtml(String body) {
    final lowerCased = body.toLowerCase();
    return lowerCased.startsWith('<!doctype html') ||
        lowerCased.startsWith('<html') ||
        lowerCased.contains('<body');
  }

  String _truncate(String message) {
    const maxLength = 240;
    if (message.length <= maxLength) {
      return message;
    }
    return '${message.substring(0, maxLength)}...';
  }
}
