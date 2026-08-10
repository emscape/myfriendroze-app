import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Configuration for API environments
enum ApiEnvironment { dev, prod }

/// API client configuration
class ApiConfig {
  final String baseUrl;
  final Map<String, String> headers;
  final Duration timeout;

  const ApiConfig({
    required this.baseUrl,
    this.headers = const {},
    this.timeout = const Duration(seconds: 30),
  });

  /// Development configuration using MCP bridge
  static const ApiConfig dev = ApiConfig(
    baseUrl: 'http://127.0.0.1:5001/myfriendroze-platform/us-central1',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );

  /// Production configuration
  static const ApiConfig prod = ApiConfig(
    baseUrl: 'https://us-central1-myfriendroze-platform.cloudfunctions.net',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );

  /// Astro site webhook configuration for product sync
  static const ApiConfig astroWebhook = ApiConfig(
    baseUrl: 'http://localhost:4321/api',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, dynamic>? details;

  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
  });

  @override
  String toString() {
    return 'ApiException: $message (Status: $statusCode, Code: $code)';
  }
}

/// HTTP client wrapper for API calls
class ApiClient {
  final http.Client _client;
  final ApiConfig _config;
  final ApiEnvironment _environment;
  String? _authToken;

  ApiClient({
    required ApiEnvironment environment,
    http.Client? client,
  })  : _environment = environment,
        _config =
            environment == ApiEnvironment.dev ? ApiConfig.dev : ApiConfig.prod,
        _client = client ?? http.Client();

  /// Create ApiClient with custom configuration
  ApiClient.withConfig(
    ApiConfig config, {
    http.Client? client,
  })  : _environment = ApiEnvironment.dev, // Default to dev for custom configs
        _config = config,
        _client = client ?? http.Client();

  /// Set Firebase Auth token for authenticated requests
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Get the current environment
  ApiEnvironment get environment => _environment;

  /// Get the base URL
  String get baseUrl => _config.baseUrl;

  /// Make a GET request
  Future<Map<String, dynamic>> get(String endpoint) async {
    return _makeRequest('GET', endpoint);
  }

  /// Make a POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _makeRequest('POST', endpoint, body: body);
  }

  /// Make a PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _makeRequest('PUT', endpoint, body: body);
  }

  /// Make a DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    return _makeRequest('DELETE', endpoint);
  }

  /// Internal method to make HTTP requests
  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final url = Uri.parse('${_config.baseUrl}$endpoint');
      final headers = Map<String, String>.from(_config.headers);
      
      // Add auth token if available
      if (_authToken != null) {
        headers['Authorization'] = 'Bearer $_authToken';
      }

      if (kDebugMode) {
        print('API Request: $method $url');
        if (body != null) {
          print('Request Body: ${jsonEncode(body)}');
        }
      }

      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response =
              await _client.get(url, headers: headers).timeout(_config.timeout);
          break;
        case 'POST':
          response = await _client
              .post(
                url,
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(_config.timeout);
          break;
        case 'PUT':
          response = await _client
              .put(
                url,
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(_config.timeout);
          break;
        case 'DELETE':
          response = await _client
              .delete(url, headers: headers)
              .timeout(_config.timeout);
          break;
        default:
          throw ApiException(message: 'Unsupported HTTP method: $method');
      }

      if (kDebugMode) {
        print('API Response: ${response.statusCode} ${response.body}');
      }

      return _handleResponse(response);
    } on SocketException {
      throw const ApiException(
        message: 'No internet connection',
        code: 'NETWORK_ERROR',
      );
    } on HttpException {
      throw const ApiException(
        message: 'HTTP error occurred',
        code: 'HTTP_ERROR',
      );
    } on FormatException {
      throw const ApiException(
        message: 'Invalid response format',
        code: 'FORMAT_ERROR',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Unexpected error: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Handle HTTP response and parse JSON
  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    // Try to parse JSON response
    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException(
        message: 'Invalid JSON response',
        statusCode: statusCode,
        code: 'INVALID_JSON',
      );
    }

    // Handle success responses (2xx)
    if (statusCode >= 200 && statusCode < 300) {
      return data;
    }

    // Handle error responses
    final message = data['message'] as String? ??
        data['error'] as String? ??
        'Unknown error occurred';
    final code = data['code'] as String?;
    final details = data['details'] as Map<String, dynamic>?;

    throw ApiException(
      message: message,
      statusCode: statusCode,
      code: code,
      details: details,
    );
  }

  /// Dispose of the client
  void dispose() {
    _client.close();
  }
}

/// Singleton API client instance
class ApiClientManager {
  static ApiClient? _instance;
  static ApiEnvironment _currentEnvironment =
      kDebugMode ? ApiEnvironment.dev : ApiEnvironment.prod;

  /// Get the current API client instance
  static ApiClient get instance {
    _instance ??= ApiClient(environment: _currentEnvironment);
    return _instance!;
  }

  /// Switch environment (useful for testing)
  static void switchEnvironment(ApiEnvironment environment) {
    if (_currentEnvironment != environment) {
      _instance?.dispose();
      _instance = null;
      _currentEnvironment = environment;
    }
  }

  /// Dispose of the current instance
  static void dispose() {
    _instance?.dispose();
    _instance = null;
  }
}
