import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_scripts/parse/parse_to_int.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as p;

const measure = 'measure';
const start = 'start';
const end = 'end';

const replaceCharMap = {
  '“': '「',
  '”': '」',
  '‘': '『',
  '’': '』',
};

final titleExp = RegExp(
  '\\s*第\\s*'
  '(\\d+|[${addMap.keys.join()}${multiplyMap.keys.join()}]+)'
  '\\s*[章话話].*',
);

class Task {
  Task(this.filename);

  String filename;
  late List<Future<File>> futureList;
}

Future<void> main(List<String> args) async {
  try {
    final parser = ArgParser()
      ..addOption(
        measure,
        help: '拆分多少章节为一个文件，章节数解析不一定正确，所以可能存在误差。',
        abbr: 'm',
        defaultsTo: '100',
      )
      ..addOption(
        start,
        help: '开始截取的章节（含）。\n' '如果它可以被正确解析，将被用于参数中的所有小说文件。',
        abbr: 's',
      )
      ..addOption(
        end,
        help: '终止截取的章节（含）。\n' '如果它可以被正确解析，将被用于参数中的所有小说文件。',
        abbr: 'e',
      )
      ..addFlag('help', abbr: 'h', negatable: false);

    final argResults = parser.parse(args);
    final paths = argResults.rest;

    if (argResults.wasParsed('help')) {
      stdout.write('一个根据章节数拆分小说的脚本程序，目的是减少文件大小方便上传到 Notion\n');
      stdout.write('用法：split-novels [options] 小说路径……\n\n');
      stdout.write(parser.usage);
      exitCode = 0;
    }

    var measureNumber = parseToInt(argResults[measure] as String);
    final startChapter = argResults[start] == null
        ? null
        : parseToInt(argResults[start] as String);
    final endChapter =
        argResults[end] == null ? null : parseToInt(argResults[end] as String);

    if (startChapter != null && endChapter != null) {
      // 我觉得设置了「开始截取的章节」以及「终止截取的章节」后就不需要拆分小说了
      measureNumber = endChapter >= startChapter
          ? endChapter
          : throw ArgParserException('「开始截取的章节」不能大于「终止截取的章节」');
    }

    final tasks = <Task>[];
    for (final path in paths) {
      try {
        tasks.add(
          await splitNovel(
            const LocalFileSystem(),
            path,
            measureNumber: measureNumber,
            startChapter: startChapter,
            endChapter: endChapter,
          ),
        );
      } on FileSystemException {
        stderr.writeln('系统找不到文件「$path」');
      } on FormatException catch (e) {
        final filename =
            p.split(path).last.replaceAll(RegExp(r'\.(txt|md)$'), '');
        stderr.writeln('「$filename」格式异常: ${e.message}');
      }
    }

    await Future.wait<void>(
      tasks.map((task) async {
        await Future.wait(task.futureList);
        stdout.writeln('「${task.filename}」已处理完成');
      }),
    );
  } on ArgParserException catch (e) {
    stderr.writeln('程序参数异常: ${e.message}');
  } catch (e) {
    stderr.writeln(e.toString());
  }
}

Future<Task> splitNovel(
  FileSystem fs,
  String path, {
  int measureNumber = 100,
  int? startChapter,
  int? endChapter,
}) async {
  final file = fs.file(path);
  // final lines =
  //     file.openRead()
  //.transform(utf8.decoder).transform(const LineSplitter());
  // 为了和 test 中的 MemoryFileSystem 配合
  // 等 dart:convert 库支持简单的调用 utf16 后改成使用 utf16
  final lines =
      utf8.decoder.bind(file.openRead()).transform(const LineSplitter());
  final filename = p.split(path).last.replaceAll(RegExp(r'\.(txt|md)$'), '');
  final parentPath = file.parent.path;
  final buffer = StringBuffer();
  final subTasks = <Future<File>>[];

  var chapterNumber = 0;
  var startNum = 1;
  var endNum = startNum;

  await for (final line in lines) {
    final trimmedLine = replaceCharMap.entries.fold<String>(
      line.trim(),
      (previousValue, element) =>
          previousValue.replaceAll(element.key, element.value),
    );
    if (trimmedLine.isEmpty) {
      continue;
    }
    final chaptereString = titleExp.firstMatch(line)?.group(1);
    if (chaptereString != null) {
      chapterNumber = parseToInt(chaptereString);

      if (startChapter != null && startChapter > chapterNumber) {
        continue;
      } else if (startChapter == chapterNumber) {
        startNum = startChapter!;
        endNum = startNum;
      } else if (endChapter != null && endChapter == endNum) {
        break;
      }

      if ((chapterNumber % measureNumber == 1 && buffer.isNotEmpty) ||
          endNum - startNum + 1 == measureNumber) {
        buffer.write('```');
        final outputFile = '$parentPath\\$filename\\'
            '${startNum.toString().padLeft(4, '0')}-'
            '${endNum.toString().padLeft(4, '0')}.md';
        subTasks.add(
          (await fs.file(outputFile).create(recursive: true))
              .writeAsString(buffer.toString()),
        );
        startNum = chapterNumber;
        buffer.clear();
      }
      endNum = chapterNumber;
      buffer.write(
        startNum == chapterNumber
            ? '## $trimmedLine\n```\n'
            : '```\n## $trimmedLine\n```\n',
      );
    } else if (chapterNumber > 0) {
      buffer.write('$trimmedLine\n\n');
    }
  }
  buffer.write('```');
  final outputFile = '$parentPath\\$filename\\'
      '${startNum.toString().padLeft(4, '0')}-'
      '${endNum.toString().padLeft(4, '0')}.md';
  subTasks.add(
    (await fs.file(outputFile).create(recursive: true))
        .writeAsString(buffer.toString()),
  );
  return Task(filename)..futureList = subTasks;
}
