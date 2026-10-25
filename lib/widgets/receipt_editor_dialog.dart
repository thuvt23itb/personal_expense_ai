import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/receipt.dart';

const receiptCategories = ['Ăn uống', 'Mua sắm', 'Di chuyển', 'Hóa đơn', 'Sức khỏe', 'Giải trí', 'Khác'];

class ReceiptEditorDialog extends StatefulWidget {
  const ReceiptEditorDialog({
    super.key,
    required this.initialMerchant,
    required this.initialAmount,
    required this.initialDate,
    required this.initialCategory,
    required this.imagePath,
    required this.rawText,
    this.existing,
  });

  final String initialMerchant;
  final double initialAmount;
  final DateTime initialDate;
  final String initialCategory;
  final String? imagePath;
  final String rawText;
  final Receipt? existing;

  @override
  State<ReceiptEditorDialog> createState() => _ReceiptEditorDialogState();
}

class _ReceiptEditorDialogState extends State<ReceiptEditorDialog> {
  late final TextEditingController _merchant;
  late final TextEditingController _amount;
  late DateTime _date;
  late String _category;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _merchant = TextEditingController(text: widget.initialMerchant);
    _amount = TextEditingController(
      text: widget.initialAmount == 0 ? '' : widget.initialAmount.toStringAsFixed(0),
    );
    _date = widget.initialDate;
    _category = receiptCategories.contains(widget.initialCategory) ? widget.initialCategory : 'Khác';
  }

  @override
  void dispose() {
    _merchant.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.existing == null ? 'Kiểm tra hóa đơn' : 'Sửa hóa đơn'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _merchant,
                    decoration: const InputDecoration(labelText: 'Tên cửa hàng'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Nhập tên cửa hàng' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Tổng tiền (VND)'),
                    validator: (v) {
                      final parsed = double.tryParse((v ?? '').replaceAll(',', '').trim());
                      if (parsed == null || parsed < 0) return 'Nhập số tiền hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ngày mua'),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(_date)),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(labelText: 'Danh mục'),
                    items: receiptCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _category = value);
                    },
                  ),
                  if (widget.rawText.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Văn bản OCR gốc'),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SelectableText(widget.rawText),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              final amount = double.parse(_amount.text.replaceAll(',', '').trim());
              final old = widget.existing;
              final receipt = Receipt(
                id: old?.id,
                merchant: _merchant.text.trim(),
                amount: amount,
                date: DateFormat('yyyy-MM-dd').format(_date),
                category: _category,
                imagePath: widget.imagePath,
                rawText: widget.rawText,
                createdAt: old?.createdAt ?? DateTime.now().toIso8601String(),
              );
              Navigator.pop(context, receipt);
            },
            child: const Text('Lưu hóa đơn'),
          ),
        ],
      );
}
