import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/receipt.dart';

class ReceiptTile extends StatelessWidget {
  const ReceiptTile({
    super.key,
    required this.receipt,
    required this.onEdit,
    required this.onDelete,
  });

  final Receipt receipt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final date = DateTime.tryParse(receipt.date);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 54,
            height: 54,
            child: receipt.imagePath != null && File(receipt.imagePath!).existsSync()
                ? Image.file(File(receipt.imagePath!), fit: BoxFit.cover)
                : Container(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: const Icon(Icons.receipt_long),
                  ),
          ),
        ),
        title: Text(receipt.merchant, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${date == null ? receipt.date : DateFormat('dd/MM/yyyy').format(date)} • ${receipt.category}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
            PopupMenuItem(value: 'delete', child: Text('Xóa')),
          ],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(money.format(receipt.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
              const Icon(Icons.more_horiz, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
