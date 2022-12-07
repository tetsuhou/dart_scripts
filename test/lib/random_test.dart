import 'package:dart_scripts/random.dart';
import 'package:test/test.dart';

void main() {
  group('random.dart getRandomString: ', () {
    test('input RegExp("x") to limit the result', () {
      expect(getRandomString(5, RegExp('x')), equals('xxxxx'));
    });

    test('input number which <= 0 will get null', () {
      expect(getRandomString(-3), isNull);
    });
    test('input wrong RegExp like RegExp("我") will get null', () {
      expect(getRandomString(5, RegExp('我')), isNull);
    });
  });
}
