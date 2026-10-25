import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/receipt.dart';
import '../providers/receipt_provider.dart';
import '../providers/theme_provider.dart';
import '../services/ocr_service.dart';
import '../services/receipt_parser.dart';
import '../widgets/receipt_editor_dialog.dart';
import 'dashboard_screen.dart';
import 'receipts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isScanning = false;
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _scanReceipt() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp bằng camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn ảnh từ thư viện'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2200,
      );
      if (picked == null || !mounted) return;

      setState(() => _isScanning = true);
      final rawText = await _ocrService.recognizeText(picked.path);
      final parsed = ReceiptParser.parse(rawText);
      if (!mounted) return;

      final suggestedDate = _parseDate(parsed.date) ?? DateTime.now();
      final result = await showDialog<Receipt>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ReceiptEditorDialog(
          initialMerchant: parsed.merchant ?? '',
          initialAmount: parsed.amount ?? 0,
          initialDate: suggestedDate,
          initialCategory: 'Khác',
          imagePath: picked.path,
          rawText: rawText,
        ),
      );

      if (result != null && mounted) {
        await context.read<ReceiptProvider>().addReceipt(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã lưu hóa đơn')),
          );
          setState(() => _selectedIndex = 1);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không xử lý được hóa đơn: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  DateTime? _parseDate(String? value) {
    if (value == null) return null;
    final formats = [
      DateFormat('d/M/yyyy'),
      DateFormat('dd/MM/yyyy'),
      DateFormat('d-M-yyyy'),
      DateFormat('dd-MM-yyyy'),
      DateFormat('d.M.yyyy'),
      DateFormat('yyyy-MM-dd'),
      DateFormat('yyyy/MM/dd'),
    ];
    for (final format in formats) {
      try {
        return format.parseStrict(value);
      } catch (_) {}
    }
    // Two-digit years are handled separately.
    for (final pattern in [DateFormat('d/M/yy'), DateFormat('dd/MM/yy')]) {
      try {
        return pattern.parseStrict(value);
      } catch (_) {}
    }
    return DateTime.tryParse(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final pages = const [DashboardScreen(), ReceiptsScreen()];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiêu của tôi'),
        actions: [
          IconButton(
            tooltip: 'Đổi giao diện: ${theme.themeLabel}',
            onPressed: theme.cycleTheme,
            icon: Icon(switch (theme.themeMode) {
              ThemeMode.system => Icons.brightness_auto,
              ThemeMode.light => Icons.light_mode,
              ThemeMode.dark => Icons.dark_mode,
            }),
          ),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: pages),
          if (_isScanning)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black45,
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Đang nhận diện văn bản...'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isScanning ? null : _scanReceipt,
        icon: const Icon(Icons.document_scanner),
        label: const Text('Quét hóa đơn'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard), label: 'Tổng quan'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Hóa đơn'),
        ],
      ),
    );
  }
}
