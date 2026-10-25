import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/receipt_provider.dart';
import '../widgets/donut_chart.dart';
import '../widgets/weekly_bar_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReceiptProvider>();
    final money = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final now = DateTime.now();
    final monthTotal = provider.receipts.where((r) {
      final d = DateTime.tryParse(r.date);
      return d != null && d.year == now.year && d.month == now.month;
    }).fold<double>(0, (sum, r) => sum + r.amount);

    return RefreshIndicator(
      onRefresh: provider.loadReceipts,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Tổng quan', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(DateFormat('MMMM yyyy', 'vi_VN').format(now)),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chi tiêu tháng này'),
                  const SizedBox(height: 8),
                  Text(money.format(monthTotal),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${provider.receipts.length} hóa đơn đã lưu'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chi tiêu theo danh mục', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  DonutChart(values: provider.categoryTotals),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chi tiêu tuần này', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  WeeklyBarChart(values: provider.weeklyTotals),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
