import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  try {
    final response = await http.get(Uri.parse('https://api.kwikcabs.in/api/car-categories/active'));
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}
