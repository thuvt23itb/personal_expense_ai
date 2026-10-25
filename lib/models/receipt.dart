class Receipt {
  const Receipt({
    this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    this.imagePath,
    this.rawText = '',
    required this.createdAt,
  });

  final int? id;
  final String merchant;
  final double amount;
  /// Stored as ISO-8601 date, e.g. 2026-10-18.
  final String date;
  final String category;
  final String? imagePath;
  final String rawText;
  final String createdAt;

  Receipt copyWith({
    int? id,
    String? merchant,
    double? amount,
    String? date,
    String? category,
    String? imagePath,
    String? rawText,
    String? createdAt,
    bool clearImagePath = false,
  }) {
    return Receipt(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      rawText: rawText ?? this.rawText,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'merchant': merchant,
        'amount': amount,
        'date': date,
        'category': category,
        'imagePath': imagePath,
        'rawText': rawText,
        'createdAt': createdAt,
      };

  factory Receipt.fromMap(Map<String, Object?> map) => Receipt(
        id: map['id'] as int?,
        merchant: map['merchant'] as String? ?? 'Unknown merchant',
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        date: map['date'] as String? ?? DateTime.now().toIso8601String(),
        category: map['category'] as String? ?? 'Khác',
        imagePath: map['imagePath'] as String?,
        rawText: map['rawText'] as String? ?? '',
        createdAt: map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      );
}
