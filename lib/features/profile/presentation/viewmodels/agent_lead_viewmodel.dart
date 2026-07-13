import 'package:flutter/material.dart';
import '../../services/agent_lead_service.dart';

class AgentLeadViewModel extends ChangeNotifier {
  final AgentLeadService _service = AgentLeadService.instance;

  List<dynamic> marketplaceLeads = [];
  List<dynamic> acceptedLeads = [];
  bool isLoading = false;
  String? error;

  Future<void> fetchMarketplaceLeads() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final res = await _service.getMarketplaceLeads();
      if (res['success'] == true) {
        marketplaceLeads = res['leads'] ?? [];
      } else {
        error = res['message'] ?? 'Failed to fetch leads';
      }
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAcceptedLeads() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final res = await _service.getMyAcceptedLeads();
      if (res['success'] == true) {
        acceptedLeads = res['leads'] ?? [];
      } else {
        error = res['message'] ?? 'Failed to fetch accepted leads';
      }
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> initiatePayment(String leadId) async {
    return await _service.initiateAcceptPayment(leadId);
  }

  Future<Map<String, dynamic>> completeLead(String leadId) async {
    return await _service.completeLead(leadId);
  }
}
