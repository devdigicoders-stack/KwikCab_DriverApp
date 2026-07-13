import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../viewmodels/help_support_viewmodel.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HelpSupportViewModel(),
      child: const _HelpSupportBody(),
    );
  }
}

class _HelpSupportBody extends StatefulWidget {
  const _HelpSupportBody();

  @override
  State<_HelpSupportBody> createState() => _HelpSupportBodyState();
}

class _HelpSupportBodyState extends State<_HelpSupportBody> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HelpSupportViewModel>().fetchSupportData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter subject and message')));
      return;
    }

    setState(() => _isSubmitting = true);
    final vm = context.read<HelpSupportViewModel>();
    final success = await vm.createTicket(subject, message);
    setState(() => _isSubmitting = false);

    if (success) {
      _subjectController.clear();
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket Submitted Successfully!')));
      _tabController.animateTo(1); // Switch to My Tickets tab
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit ticket. Check network.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HelpSupportViewModel>();

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text('Help & Support', style: TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.yellow,
          labelColor: AppColors.yellow,
          unselectedLabelColor: AppColors.grey500,
          tabs: const [
            Tab(text: 'New Ticket'),
            Tab(text: 'My Tickets'),
            Tab(text: 'Summary'),
          ],
        ),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.yellow))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNewTicketTab(),
                _buildMyTicketsTab(vm),
                _buildSummaryTab(vm),
              ],
            ),
    );
  }

  Widget _buildNewTicketTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Create New Support Ticket', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: _subjectController,
            style: const TextStyle(color: AppColors.white),
            decoration: InputDecoration(
              labelText: 'Subject',
              labelStyle: const TextStyle(color: AppColors.grey500),
              filled: true,
              fillColor: AppColors.grey900,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            style: const TextStyle(color: AppColors.white),
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Message (describe your issue)',
              labelStyle: const TextStyle(color: AppColors.grey500),
              filled: true,
              fillColor: AppColors.grey900,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitTicket,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.yellow,
              foregroundColor: AppColors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.black, strokeWidth: 2))
                : const Text('Submit Ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMyTicketsTab(HelpSupportViewModel vm) {
    if (vm.tickets.isEmpty) {
      return const Center(child: Text('No tickets found.', style: TextStyle(color: AppColors.grey500)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vm.tickets.length,
      itemBuilder: (context, index) {
        final t = vm.tickets[index];
        final dateObj = DateTime.tryParse(t.createdAt);
        final dateStr = dateObj != null ? DateFormat('dd MMM, hh:mm a').format(dateObj) : t.createdAt;

        Color statusColor = AppColors.yellow;
        if (t.status == 'Closed' || t.status == 'Completed') statusColor = AppColors.success;
        if (t.status == 'Open') statusColor = AppColors.error;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.grey900,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey800),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(t.subject, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text(t.status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(t.message, style: const TextStyle(color: AppColors.grey400, fontSize: 14)),
              const SizedBox(height: 8),
              Text(dateStr, style: const TextStyle(color: AppColors.grey600, fontSize: 12)),
              if (t.adminReply != null && t.adminReply!.isNotEmpty) ...[
                const Divider(color: AppColors.grey800, height: 20),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.support_agent, color: AppColors.yellow, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Admin Reply:', style: TextStyle(color: AppColors.yellow, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(t.adminReply!, style: const TextStyle(color: AppColors.white, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryTab(HelpSupportViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Support Summary', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildSummaryCard('Total Tickets', vm.summary['total'].toString(), AppColors.white),
              const SizedBox(width: 12),
              _buildSummaryCard('Open', vm.summary['open'].toString(), AppColors.error),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryCard('In Progress', vm.summary['inProgress'].toString(), AppColors.yellow),
              const SizedBox(width: 12),
              _buildSummaryCard('Closed', vm.summary['closed'].toString(), AppColors.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 14, color: AppColors.grey400, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
