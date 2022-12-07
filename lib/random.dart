import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Generate a string of length equal to [number] from
/// characters with ascii code >= 32 and < 127.
///
/// [pattern] is used to limit the selection of characters,
/// the default is RegExp('[A-Za-z0-9]').
///
/// If [number] <= 0, will return null.
///
/// If the pattern is passed, but it does not get a long enough
/// string within 5 seconds, then null will be returned.
String? getRandomString(int number, [RegExp? pattern]) {
  if (number > 0) {
    final ran = Random.secure();
    final buffer = StringBuffer();
    final stopwatch = Stopwatch();
    if (pattern != null) {
      stopwatch.start();
    }
    do {
      final char = ascii.decode([ran.nextInt(127 - 32) + 32]);
      if ((pattern ?? RegExp('[A-Za-z0-9]')).hasMatch(char)) {
        buffer.write(char);
      }
      if (pattern != null && stopwatch.elapsed > const Duration(seconds: 5)) {
        stderr.writeln(
          'warn: '
          'Failure to produce a long enough string in 5 seconds, '
          'might be a pattern matching problem.',
        );
        return null;
      }
    } while (buffer.length != number);
    return buffer.toString();
  } else {
    stderr.writeln('warn: The number should > 0.');
    return null;
  }
}
