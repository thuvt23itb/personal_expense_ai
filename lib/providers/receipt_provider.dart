import 'package:flutter/foundation.dart';

import '../models/receipt.dart';
import '../services/database_service.dart';
import '../services/image_service.dart';

class ReceiptProvider extends ChangeNotifier {
  ReceiptProvider({
    DatabaseService? database,
    ImageService? imageService,
  })  : _database = database ?? DatabaseService.instance,
        _imageService = imageService ?? ImageService();

  final DatabaseService _database;
  final ImageService _imageService;
  List<Receipt> _receipts = [];
  bool _isLoading = false;
  String? _error;

  List<Receipt> get receipts => List.unmodifiable(_receipts);
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalSpent => _receipts.fold(0, (sum, receipt) => sum + receipt.amount);

  Future<void> loadReceipts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _receipts = await _database.getAllReceipts();
    } catch (e) {
      _error = 'Không thể tải dữ liệu: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addReceipt(Receipt receipt) async {
    String? savedImagePath;
    try {
      if (receipt.imagePath != null && receipt.imagePath!.isNotEmpty) {
        savedImagePath = await _imageService.persistImage(receipt.imagePath!);
      }
      final persistent = receipt.copyWith(imagePath: savedImagePath ?? receipt.imagePath);
      final id = await _database.insertReceipt(persistent);
      _receipts = [persistent.copyWith(id: id), ..._receipts];
      _sort();
      notifyListeners();
    } catch (e) {
      if (savedImagePath != null) {
        try { await _imageService.deleteImage(savedImagePath); } catch (_) {}
      }
      rethrow;
    }
  }

  Future<void> updateReceipt(Receipt receipt) async {
    if (receipt.id == null) throw ArgumentError('Thiếu ID hóa đơn');
    final old = _receipts.firstWhere((r) => r.id == receipt.id);
    var updated = receipt;
    String? newSavedPath;
    final imageChanged = receipt.imagePath != old.imagePath;
    if (imageChanged && receipt.imagePath != null && receipt.imagePath!.isNotEmpty) {
      newSavedPath = await _imageService.persistImage(receipt.imagePath!);
      updated = receipt.copyWith(imagePath: newSavedPath);
    }
    await _database.updateReceipt(updated);
    _receipts = _receipts.map((r) => r.id == updated.id ? updated : r).toList();
    _sort();
    notifyListeners();

    if (imageChanged && old.imagePath != updated.imagePath) {
      try { await _imageService.deleteImage(old.imagePath); } catch (_) {}
    }
  }

  Future<void> deleteReceipt(int id) async {
    final old = _receipts.firstWhere((r) => r.id == id);
    await _database.deleteReceipt(id);
    _receipts = _receipts.where((r) => r.id != id).toList();
    notifyListeners();
    try { await _imageService.deleteImage(old.imagePath); } catch (_) {}
  }

  Map<String, double> get categoryTotals {
    final result = <String, double>{};
    for (final receipt in _receipts) {
      result.update(receipt.category, (value) => value + receipt.amount,
          ifAbsent: () => receipt.amount);
    }
    return result;
  }

  List<double> get weeklyTotals {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final totals = List<double>.filled(7, 0);
    for (final receipt in _receipts) {
      final parsed = DateTime.tryParse(receipt.date);
      if (parsed == null) continue;
      final date = DateTime(parsed.year, parsed.month, parsed.day);
      final index = date.difference(monday).inDays;
      if (index >= 0 && index < 7) totals[index] += receipt.amount;
    }
    return totals;
  }

  void _sort() {
    _receipts.sort((a, b) => b.date.compareTo(a.date));
  }
}
