import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../services/auth_service.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({AuthService? authService, http.Client? client})
      : _authService = authService ?? AuthService(),
        _client = client ?? http.Client();

  final AuthService _authService;
  final http.Client _client;

  String get _baseUrl {
    try {
      final url = dotenv.env['API_BASE_URL']?.trim();
      if (url != null && url.isNotEmpty) return url;
    } catch (_) {
      // dotenv not loaded (no .env file) — fall through to default
    }
    return 'https://twigless-sabrina-nonexaggeratory.ngrok-free.dev';
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
    bool authenticated = true,
  }) {
    return _send(
      method: 'GET',
      path: path,
      headers: headers,
      authenticated: authenticated,
    );
  }

  Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
    bool authenticated = true,
  }) {
    return _send(
      method: 'POST',
      path: path,
      headers: headers,
      body: body,
      authenticated: authenticated,
    );
  }

  Future<http.Response> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
    bool authenticated = true,
  }) {
    return _send(
      method: 'PUT',
      path: path,
      headers: headers,
      body: body,
      authenticated: authenticated,
    );
  }

  Future<http.Response> delete(
    String path, {
    Map<String, String>? headers,
    Object? body,
    bool authenticated = true,
  }) {
    return _send(
      method: 'DELETE',
      path: path,
      headers: headers,
      body: body,
      authenticated: authenticated,
    );
  }

  Future<http.Response> _send({
    required String method,
    required String path,
    Map<String, String>? headers,
    Object? body,
    required bool authenticated,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');

    try {
      final response = await _request(
        uri: uri,
        method: method,
        headers: headers,
        body: body,
        authenticated: authenticated,
        forceRefresh: false,
      );

      if (response.statusCode != 401) {
        return _handleResponse(response);
      }

      final retriedResponse = await _request(
        uri: uri,
        method: method,
        headers: headers,
        body: body,
        authenticated: authenticated,
        forceRefresh: true,
      );

      return _handleResponse(retriedResponse);
    } on SocketException {
      throw const ApiException(
        type: ApiErrorType.network,
        message: 'Network connection failed.',
      );
    }
  }

  Future<http.Response> _request({
    required Uri uri,
    required String method,
    Map<String, String>? headers,
    Object? body,
    required bool authenticated,
    required bool forceRefresh,
  }) async {
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };

    if (authenticated) {
      final token = await _authService.getIdToken(forceRefresh: forceRefresh);
      if (token != null && token.isNotEmpty) {
        requestHeaders['Authorization'] = 'Bearer $token';
      }
    }

    switch (method) {
      case 'GET':
        return _client.get(uri, headers: requestHeaders);
      case 'POST':
        return _client.post(
          uri,
          headers: requestHeaders,
          body: _encodeBody(body),
        );
      case 'PUT':
        return _client.put(
          uri,
          headers: requestHeaders,
          body: _encodeBody(body),
        );
      case 'DELETE':
        return _client.delete(
          uri,
          headers: requestHeaders,
          body: _encodeBody(body),
        );
      default:
        throw const ApiException(
          type: ApiErrorType.unknown,
          message: 'Unsupported HTTP method.',
        );
    }
  }

  String? _encodeBody(Object? body) {
    if (body == null) {
      return null;
    }

    if (body is String) {
      return body;
    }

    return jsonEncode(body);
  }

  http.Response _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    throw ApiException.fromStatusCode(
      response.statusCode,
      message: _extractMessage(response.body),
    );
  }

  String _extractMessage(String responseBody) {
    if (responseBody.isEmpty) {
      return 'Request failed.';
    }

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        if (decoded['detail'] is String) {
          return decoded['detail'] as String;
        }
        if (decoded['error'] is String) {
          return decoded['error'] as String;
        }
        if (decoded['message'] is String) {
          return decoded['message'] as String;
        }
      }
    } catch (_) {
      // Fall back to the raw response body.
    }

    return responseBody;
  }
}