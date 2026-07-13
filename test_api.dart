import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  try {
    final response = await http.post(
      Uri.parse('https://api.kwikcabs.in/driver/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': 'shivawww@gmail.com', 'password': '123'}),
    );
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
  } catch (e) {
    print('Error1: $e');
  }

  try {
    final response2 = await http.post(
      Uri.parse('https://api.kwikcabs.in/api/driver/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': 'shivawww@gmail.com', 'password': '123'}),
    );
    print('Status2: ${response2.statusCode}');
    print('Body2: ${response2.body}');
  } catch (e) {
    print('Error2: $e');
  }
}
