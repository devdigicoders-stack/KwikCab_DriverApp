import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  try {
    String query = 'New Delhi';
    String apiKey = 'AIzaSyBEss4wpsQ0o9WPBjDgHsSByUzFuo2oSNE';
    final response = await http.get(Uri.parse('https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$apiKey'));
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}
