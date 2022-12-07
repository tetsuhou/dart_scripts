import 'dart:io';

import 'package:path/path.dart' as p;

final filenameExp = RegExp(r'^(\d+)-(\d)-LT1.save');

Future<void> main() async {
  final dir = Directory('');
  var fileNum = 1;
  var fileSubNum = 1;

  try {
    final dirList = await dir
        .list()
        .where(
          (event) =>
              event is File && filenameExp.hasMatch(p.split(event.path).last),
        )
        .toList();
    dirList.sort((a, b) {
      final aMatch = filenameExp.firstMatch(p.split(a.path).last)!;
      final bMatch = filenameExp.firstMatch(p.split(b.path).last)!;
      final aNum = int.parse(aMatch.group(1)!);
      final aSubNum = int.parse(aMatch.group(2)!);
      final bNum = int.parse(bMatch.group(1)!);
      final bSubNum = int.parse(bMatch.group(2)!);
      if (aNum < bNum) {
        return -1;
      } else if (aNum > bNum) {
        return 1;
      } else if (aSubNum < bSubNum) {
        return -1;
      } else {
        return 1;
      }
    });
    for (final file in dirList) {
      if (fileSubNum > 6) {
        fileNum += 1;
        fileSubNum = 1;
      }
      file.rename('${file.parent.path}\\$fileNum-$fileSubNum-LT1.save');
      fileSubNum += 1;
    }
  } catch (e) {
    stderr.writeln(e.toString());
  }
}
