import 'dart:io';

import 'package:file/memory.dart';
import 'package:test/test.dart';
import '../../bin/split_novels.dart' as app;

void main() {
  group('split novels', () {
    final fs = MemoryFileSystem();
    test('A Path which cannot found will throw [FileSystemException]', () {
      expect(
        () => app.splitNovel(fs, 'D:tetsuhouDownload'),
        throwsA(isA<FileSystemException>()),
      );
    });

    // // 目前 dart:convert 库对 utf16 的支持不够简单
    // test('A file which is not utf16le will throw [FormatException]',
    // () async  {
    //   final tmp= await fs.systemTempDirectory.createTemp('test');
    //   final gbkFile = tmp.childFile('output');
    //   gbkFile.writeAsString('test', encoding: Encoding(utf1))
    //   expect(() => app.splitNovel(fs, path)), matcher)
    // });
  });
}
