import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'transaction_details_screen.dart';
import '../screens/earnings_viewmodel.dart';
import '../../../../core/constants/app_colors.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EarningsViewModel(),
      child: const _EarningsBody(),
    );
  }
}

class _EarningsBody extends StatefulWidget {
  const _EarningsBody();

  @override
  State<_EarningsBody> createState() => _EarningsBodyState();
}

class _EarningsBodyState extends State<_EarningsBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EarningsViewModel>().fetchWalletDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EarningsViewModel>();
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Earnings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.white)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.grey900, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.grey800)),
                    child: const Text('Transactions', style: TextStyle(fontSize: 12, color: AppColors.yellow, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Row(
                    children: [
                      _EarningCard(label: 'Wallet Balance', amount: '₹${vm.walletBalance.toInt()}', subtitle: 'Available to withdraw', color: AppColors.yellow),
                      const SizedBox(width: 12),
                      _EarningCard(label: 'Total Earnings', amount: '₹${vm.totalEarnings.toInt()}', subtitle: 'Lifetime earned', color: AppColors.success),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showWithdrawDialog(context, vm),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.yellow,
                      foregroundColor: AppColors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Withdraw Money', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                  // Performance row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.grey900, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.grey800)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _PerfStat(label: 'Acceptance', value: '92%', icon: Icons.check_circle_outline),
                        _PerfStat(label: 'Completion', value: '98%', icon: Icons.flag_rounded),
                        _PerfStat(label: 'Rating', value: '4.8★', icon: Icons.star_rounded),
                        _PerfStat(label: 'Online Hrs', value: '6.2h', icon: Icons.access_time_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Recent Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white)),
                  const SizedBox(height: 12),
                  if (vm.isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.yellow)))
                  else if (vm.entries.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No transactions found', style: TextStyle(color: AppColors.grey500))))
                  else
                    ...vm.entries.map((e) => _TripTile(entry: e)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, EarningsViewModel vm) {
    final TextEditingController amountController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.grey900,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Withdraw Money', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.white), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('Available Balance: ₹${vm.walletBalance.toInt()}', style: const TextStyle(fontSize: 14, color: AppColors.grey500), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.white, fontSize: 18),
                    decoration: InputDecoration(
                      hintText: 'Enter amount',
                      hintStyle: const TextStyle(color: AppColors.grey600),
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(color: AppColors.white, fontSize: 18),
                      filled: true,
                      fillColor: AppColors.black,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isSubmitting ? null : () async {
                      final amountText = amountController.text.trim();
                      if (amountText.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an amount')));
                        return;
                      }
                      final amount = double.tryParse(amountText);
                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid amount')));
                        return;
                      }
                      if (amount > vm.walletBalance) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient balance')));
                        return;
                      }

                      setState(() => isSubmitting = true);
                      final success = await vm.requestWithdrawal(amount, 'Driver payout request');
                      setState(() => isSubmitting = false);

                      if (success) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal request submitted!')));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit request!')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.yellow,
                      foregroundColor: AppColors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.black, strokeWidth: 2))
                        : const Text('Submit Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _EarningCard extends StatelessWidget {
  final String label;
  final String amount;
  final String subtitle;
  final Color color;
  const _EarningCard({required this.label, required this.amount, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(amount, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.white)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
          ],
        ),
      ),
    );
  }
}

class _PerfStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _PerfStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.yellow),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.grey500)),
      ],
    );
  }
}

class _TripTile extends StatelessWidget {
  final EarningEntry entry;
  const _TripTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isCredit = entry.type == 'Credit';
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailsScreen(entry: entry),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.grey900, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.grey800)),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: (isCredit ? AppColors.success : AppColors.error).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(entry.icon, color: isCredit ? AppColors.success : AppColors.error, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.white)),
                if (entry.description.isNotEmpty)
                  Text(entry.description, style: const TextStyle(fontSize: 12, color: AppColors.grey500), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(entry.date, style: const TextStyle(fontSize: 11, color: AppColors.grey600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text((isCredit ? '+' : '-') + entry.amount, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isCredit ? AppColors.success : AppColors.error)),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isCredit ? AppColors.success.withValues(alpha: 0.15) : AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(entry.type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isCredit ? AppColors.success : AppColors.error)),
              ),
            ],
          ),
        ],
      ),
    ));
  }
}
