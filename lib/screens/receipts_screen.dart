import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/receipt.dart';
import '../providers/receipt_provider.dart';
import '../widgets/receipt_editor_dialog.dart';
import '../widgets/receipt_tile.dart';

class ReceiptsScreen extends StatelessWidget {
  const ReceiptsScreen({super.key});

  Future<void> _edit(BuildContext context, Receipt receipt) async {
    final updated = await showDialog<Receipt>(
      context: context,
      builder: (_) => ReceiptEditorDialog(
        initialMerchant: receipt.merchant,
        initialAmount: receipt.amount,
        initialDate: DateTime.tryParse(receipt.date) ?? DateTime.now(),
        initialCategory: receipt.category,
        imagePath: receipt.imagePath,
        rawText: receipt.rawText,
        existing: receipt,
      ),
    );
    if (updated != null && context.mounted) {
      await context.read<ReceiptProvider>().updateReceipt(updated);
    }
  }

  Future<void> _delete(BuildContext context, Receipt receipt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa hóa đơn?'),
        content: Text('Bạn có chắc muốn xóa "${receipt.merchant}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirmed == true && context.mounted && receipt.id != null) {
      await context.read<ReceiptProvider>().deleteReceipt(receipt.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReceiptProvider>();
    if (provider.isLoading) return const Center(child: CircularProgressIndicator());
    if (provider.error != null) return Center(child: Text(provider.error!));
    if (provider.receipts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long, size: 64),
              SizedBox(height: 12),
              Text('Chưa có hóa đơn', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('Nhấn nút + để chụp hoặc thêm hóa đơn đầu tiên.'),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: provider.receipts.length,
      itemBuilder: (context, index) {
        final receipt = provider.receipts[index];
        return ReceiptTile(
          receipt: receipt,
          onEdit: () => _edit(context, receipt),
          onDelete: () => _delete(context, receipt),
        );
      },
    );
  }
}
