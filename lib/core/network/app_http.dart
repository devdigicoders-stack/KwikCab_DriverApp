export 'package:http/http.dart' hide get, post, put, delete, patch;

import 'dart:convert';
import 'package:http/http.dart' as original_http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kwikcabdriver/main.dart'; 
import 'package:kwikcabdriver/routes/app_routes.dart';

Future<void> _handle401(original_http.Response response) async {
  if (response.statusCode == 401) {
    try {
      final body = jsonDecode(response.body);
      if (body['message']?.toString().toLowerCase().contains('another device') == true || body['message']?.toString().toLowerCase().contains('session expired') == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('driver_token');
        await prefs.remove('driver_isLoggedIn');
        
        final context = navigatorKey.currentContext;
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(body['message'] ?? 'Session expired. Logged in from another device.'),
                backgroundColor: Colors.red,
            ),
          );
        }
        navigatorKey.currentState?.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }
}

Future<original_http.Response> get(Uri url, {Map<String, String>? headers}) async {
  final response = await original_http.get(url, headers: headers);
  await _handle401(response);
  return response;
}

Future<original_http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  final response = await original_http.post(url, headers: headers, body: body, encoding: encoding);
  await _handle401(response);
  return response;
}

Future<original_http.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  final response = await original_http.put(url, headers: headers, body: body, encoding: encoding);
  await _handle401(response);
  return response;
}

Future<original_http.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  final response = await original_http.delete(url, headers: headers, body: body, encoding: encoding);
  await _handle401(response);
  return response;
}

Future<original_http.Response> patch(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  final response = await original_http.patch(url, headers: headers, body: body, encoding: encoding);
  await _handle401(response);
  return response;
}
