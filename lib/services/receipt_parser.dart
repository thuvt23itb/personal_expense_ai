class ParsedReceipt {
  const ParsedReceipt({
    required this.merchant,
    required this.date,
    required this.amount,
  });

  final String? merchant;
  /// Returns a date string in the original OCR format, or null.
  final String? date;
  final double? amount;
}

class ReceiptParser {
  static final RegExp _datePattern = RegExp(
    r'\b(\d{1,2}[./-]\d{1,2}[./-]\d{2,4}|\d{4}[./-]\d{1,2}[./-]\d{1,2})\b',
  );

  static final RegExp _totalLabel = RegExp(
    r'(grand\s*total|total\s*due|amount\s*due|total|tổng\s*cộng|thành\s*tiền|cộng\s*tiền|tổng\s*thanh\s*toán|phải\s*trả)',
    caseSensitive: false,
  );

  static ParsedReceipt parse(String text) {
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    String? merchant;
    for (final line in lines.take(6)) {
      final cleaned = line.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (cleaned.length >= 2 &&
          !_datePattern.hasMatch(cleaned) &&
          !_totalLabel.hasMatch(cleaned) &&
          !RegExp(r'^\d+([.,]\d+)?$').hasMatch(cleaned)) {
        merchant = cleaned;
        break;
      }
    }

    final dateMatch = _datePattern.firstMatch(text);
    final date = dateMatch?.group(1);

    double? amount;
    // Prefer the last matching total line because receipts commonly repeat subtotal/tax.
    for (final line in lines.reversed) {
      if (_totalLabel.hasMatch(line)) {
        final candidate = _lastAmountOnLine(line);
        if (candidate != null) {
          amount = candidate;
          break;
        }
      }
    }

    // Fallback: the largest amount-like number in the text.
    if (amount == null) {
      final values = <double>[];
      final amountPattern = RegExp(r'(?<!\w)(\d{1,3}(?:[.,]\d{3})+|\d+(?:[.,]\d{1,2})?)(?!\w)');
      for (final match in amountPattern.allMatches(text)) {
        final parsed = _parseNumber(match.group(1)!);
        if (parsed != null) values.add(parsed);
      }
      if (values.isNotEmpty) {
        values.sort();
        amount = values.last;
      }
    }

    return ParsedReceipt(merchant: merchant, date: date, amount: amount);
  }

  static double? _lastAmountOnLine(String line) {
    final pattern = RegExp(
      r'(?<!\w)(\d{1,3}(?:[.,]\d{3})+|\d+(?:[.,]\d{1,2})?)(?!\w)',
    );
    final matches = pattern.allMatches(line).toList();
    if (matches.isEmpty) return null;
    // Ignore a leading label's incidental digits; the final number on total line is most likely.
    for (final match in matches.reversed) {
      final parsed = _parseNumber(match.group(1)!);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static double? _parseNumber(String raw) {
    var value = raw.replaceAll(RegExp(r'[^0-9.,]'), '');
    if (value.isEmpty) return null;

    final lastDot = value.lastIndexOf('.');
    final lastComma = value.lastIndexOf(',');
    if (lastDot >= 0 && lastComma >= 0) {
      // The last separator is treated as decimal separator.
      if (lastDot > lastComma) {
        value = value.replaceAll(',', '');
      } else {
        value = value.replaceAll('.', '').replaceAll(',', '.');
      }
    } else if (lastComma >= 0) {
      final decimals = value.length - lastComma - 1;
      value = decimals == 2 ? value.replaceAll(',', '.') : value.replaceAll(',', '');
    } else if (lastDot >= 0) {
      final decimals = value.length - lastDot - 1;
      if (decimals != 2) value = value.replaceAll('.', '');
    }

    return double.tryParse(value);
  }
}
