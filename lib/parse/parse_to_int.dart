/// The mapping from Chinese
/// representing numbers to [int]
const addMap = {
  '〇': 0,
  '零': 0,
  '一': 1,
  '壹': 1,
  '幺': 1,
  '二': 2,
  '貳': 2,
  '两': 2,
  '三': 3,
  '叁': 3,
  '參': 3,
  '四': 4,
  '肆': 4,
  '五': 5,
  '伍': 5,
  '六': 6,
  '陆': 6,
  '陸': 6,
  '七': 7,
  '柒': 7,
  '八': 8,
  '捌': 8,
  '九': 9,
  '玖': 9,
};

/// The mapping from Chinese representing
/// orders of magnitude to [int]
const multiplyMap = {
  '十': 10,
  '拾': 10,
  '百': 100,
  '佰': 100,
  '千': 1000,
  '仟': 1000,
  '万': 10000,
  '萬': 10000,
  '亿': 100000000,
  '億': 100000000,
};

/// Parsing (Chinese) numeric strings to [int]
///
/// If the passed string is not a number or has
/// unhandleable characters, it will throw a
/// [FormatException]
int parseToInt(
  String str, {
  Map<String, int> addMap = addMap,
  Map<String, int> multiplyMap = multiplyMap,
}) {
  final maybeNumber = int.tryParse(str);
  if (maybeNumber != null) {
    return maybeNumber;
  } else {
    var number = 0;
    final numberStr = RegExp('([〇零百佰]十|^十|[〇零百佰]拾|^拾)').hasMatch(str)
        ? str.replaceAll('十', '一十').replaceAll('拾', '壹拾')
        : str;
    final isOnlyAddMap =
        RegExp('^[${addMap.keys.join()}]+\$').hasMatch(numberStr);
    for (final char in numberStr.split('')) {
      if (addMap.keys.join().contains(char)) {
        number =
            isOnlyAddMap ? number * 10 + addMap[char]! : number + addMap[char]!;
      } else if (multiplyMap.keys.join().contains(char)) {
        number += number % multiplyMap[char]! * (multiplyMap[char]! - 1);
      } else if (char == ' ') {
        continue;
      } else {
        throw FormatException(
          'warn: Cannot handle "$char" characters in "$numberStr"',
        );
      }
    }
    return number;
  }
}
