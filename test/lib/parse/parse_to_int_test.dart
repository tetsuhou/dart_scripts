import 'package:dart_scripts/parse/parse_to_int.dart';
import 'package:test/test.dart';

void main() {
  group('parse/parse_to_int.dart parseToInt(): ', () {
    const numberMap = {
      '零八': 8,
      '七零九': 709,
      '八九六四': 8964,
      '二〇二二一一二四':20221124,
      '一千零十四': 1014,
      '十一': 11,
    };
    for (final item in numberMap.entries) {
      test('"${item.key}" = ${item.value}', () {
        expect(parseToInt(item.key), equals(item.value));
      });
    }

    test('unhandleable characters "X"', () {
      expect(() => parseToInt('X'), throwsFormatException);
    });
  });
}
