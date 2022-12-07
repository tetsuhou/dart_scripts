import 'dart:io';

import 'package:args/args.dart';

final aliasMap = {
  RegExp(r'D:\\tetsuhou\\OneDrive\\Videos\\Captures\\(.+).mp4\s?(.+)?'):
      r'ffmpeg.exe -i "D:\tetsuhou\OneDrive\Videos\Captures\$1.mp4" '
          r'-c:v hevc $2 '
          r'"D:\tetsuhou\OneDrive\Videos\Captures\$1.hevc.mp4"',
};

Future<void> main(List<String> args) async {
  try {
    final parser = ArgParser()
      ..addFlag('check', abbr: 'c', negatable: false, help: '检查指令。')
      ..addFlag('force', abbr: 'f', negatable: false, help: '跳过确认。')
      ..addFlag('help', abbr: 'h', negatable: false);

    final argResults = parser.parse(args);
    final isCheck = argResults.wasParsed('check');
    final isForce = argResults.wasParsed('force');
    final inputStrs = argResults.rest;

    if (argResults.wasParsed('help')) {
      stdout.write('自定义指令别名\n');
      stdout.write('用法：myalias [options] 字符串……\n\n');
      stdout.write(parser.usage);
      exit(0);
    }

    for (final str in inputStrs) {
      final matches = aliasMap..removeWhere((key, value) => !key.hasMatch(str));
      final commands = List<String>.from(
        matches.map((key, value) => MapEntry(value, key.firstMatch(str)!)).map(
          (key, value) {
            for (var i = 1; i <= value.groupCount; i++) {
              if (key.contains(r'$' + i.toString())) {
                key = key.replaceAll(r'$' + i.toString(), value.group(i) ?? '');
              }
            }
            return MapEntry(key, value);
          },
        ).keys,
      );

      stdout.writeln('找到 ${commands.length} 条匹配指令');

      if (commands.length == 1) {
        if (isCheck) {
          stdout.writeln('执行的指令将是「${commands.first}」。');
        } else if (isForce) {
          final process = await Process.start(
            commands.first.split(' ').first,
            commands.first.split(' ')..removeAt(0),
          );
          stdout.addStream(process.stdout);
          stderr.addStream(process.stderr);
        } else {
          stdout.writeln('请问您希望执行的指令是「${commands.first}」吗？[yN]');
          if (stdin.readLineSync() == 'y' || stdin.readLineSync() == 'Y') {
            final process = await Process.start(
              commands.first.split(' ').first,
              commands.first.split(' ')..removeAt(0),
            );
            stdout.addStream(process.stdout);
            stderr.addStream(process.stderr);
          }
        }
      } else if (commands.length > 1) {
        if (isCheck) {
          stdout.writeln('执行的指令将是以下 ${commands.length} 条。');
          for (var i = 1; i < commands.length + 1; i++) {
            stdout.writeln('$i. ${commands[i]}');
          }
        } else if (isForce) {
          for (final command in commands) {
            final process = await Process.start(
              command.split(' ').first,
              command.split(' ')..removeAt(0),
            );
            stdout.addStream(process.stdout);
            stderr.addStream(process.stderr);
          }
        } else {
          for (var i = 1; i < commands.length + 1; i++) {
            stdout.writeln('$i. ${commands[i]}');
          }
          stdout.writeln('请问您希望执行的指令是以上 ${commands.length} 条吗？[yN]');
          if (stdin.readLineSync() == 'y' || stdin.readLineSync() == 'Y') {
            for (final command in commands) {
              final process = await Process.start(
                command.split(' ').first,
                command.split(' ')..removeAt(0),
              );
              stdout.addStream(process.stdout);
              stderr.addStream(process.stderr);
            }
          }
        }
      }
    }
  } catch (e) {
    stderr.writeln(e.toString());
  }
}
