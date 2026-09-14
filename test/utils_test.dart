import 'package:atom/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Utils.normalizePhoneNumber', () {
    final utils = Utils();

    test('converts local 07 numbers to Kenyan country code format', () {
      expect(utils.normalizePhoneNumber('0710560190'), '254710560190');
    });

    test('converts local 01 numbers to Kenyan country code format', () {
      expect(utils.normalizePhoneNumber('0110560190'), '254110560190');
    });

    test('leaves already-normalized numbers unchanged', () {
      expect(utils.normalizePhoneNumber('254710560190'), '254710560190');
    });

    test('removes common phone formatting before normalizing', () {
      expect(utils.normalizePhoneNumber('+254 710-560-190'), '254710560190');
    });

    test('leaves empty values empty', () {
      expect(utils.normalizePhoneNumber('  '), '');
    });
  });
}
