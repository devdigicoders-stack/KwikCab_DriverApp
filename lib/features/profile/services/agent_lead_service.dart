import 'dart:convert';
import 'package:kwikcabdriver/core/network/app_http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_constants.dart';

class AgentLeadService {
  static final AgentLeadService instance = AgentLeadService._internal();
  AgentLeadService._internal();

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('driver_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getMarketplaceLeads() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(ApiConstants.agentLeadMarketplace), headers: headers);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Failed to load marketplace leads'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getMyAcceptedLeads() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(ApiConstants.agentLeadMyAccepted), headers: headers);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Failed to load accepted leads'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> initiateAcceptPayment(String leadId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(Uri.parse(ApiConstants.agentLeadInitiatePayment(leadId)), headers: headers);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Failed to initiate payment'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> completeLead(String leadId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(Uri.parse(ApiConstants.agentLeadComplete(leadId)), headers: headers);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Failed to complete lead'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
