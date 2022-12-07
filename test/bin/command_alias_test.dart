import 'dart:io';

import 'package:test/test.dart';
import '../../bin/command_alias.dart' as app;

void main() {
  group('command alias', () {
    test('A Path which cannot found will throw [FileSystemException]', () {
      expect(
        () => app.main(['D:tetsuhouDownload']),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}
