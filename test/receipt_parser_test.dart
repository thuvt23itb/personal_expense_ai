import 'package:flutter_test/flutter_test.dart';
import 'package:personal_expense_ai/services/receipt_parser.dart';

void main() {
  test('parses merchant, date and total from simple receipt', () {
    const text = '''
ABC COFFEE
Da Nang
Date: 18/10/2026
Coffee 35,000
Cake 25,000
TOTAL 60,000 VND
''';
    final parsed = ReceiptParser.parse(text);
    expect(parsed.merchant, 'ABC COFFEE');
    expect(parsed.date, '18/10/2026');
    expect(parsed.amount, 60000);
  });
}
