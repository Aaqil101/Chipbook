import 'package:flutter_test/flutter_test.dart';

import 'package:chipbook/domain/entry_validation.dart';

void main() {
  group('reversalReasonError', () {
    test('requires a non-empty reason', () {
      expect(
        EntryValidation.reversalReasonError(''),
        'Enter a reason for the reversal',
      );
      expect(
        EntryValidation.reversalReasonError('   '),
        'Enter a reason for the reversal',
      );
    });

    test('accepts a reason', () {
      expect(EntryValidation.reversalReasonError('Recorded twice'), isNull);
    });
  });
}
