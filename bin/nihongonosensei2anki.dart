/// 下载YouTube视频的话需要安装yt-dlp
import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

void main(List<String> args) async {
  // 从语法列表页面中获取文法的链接集合
  final respList = await Future.wait([
    http.post(Uri.parse('https://nihongonosensei.net/?page_id=10246')),
    http.post(Uri.parse('https://nihongonosensei.net/?page_id=13879')),
  ]);
  if (respList.every((e) => e.statusCode == 200)) {
    final gramartableList = parse(respList[0].body)
        .querySelectorAll('table#mouseover1')
        .sublist(0, 5);
    final onomatopeTable =
        parse(respList[1].body).querySelector('table#mouseover1');
    final Set<String> nihongonosenseiSet = {};

    if (gramartableList.isNotEmpty) {
      for (final table in gramartableList) {
        final elements = table.getElementsByTagName('tr')..removeAt(0);
        final urls = elements
            .where((e) => e.getElementsByTagName('td').length > 2)
            .map((e) {
          return e.querySelector('td > a')!.attributes['href']!.trim();
        });
        nihongonosenseiSet.addAll(urls);
      }
    }

    if (onomatopeTable != null) {
      final elements = onomatopeTable.getElementsByTagName('tr')..removeAt(0);
      final urls = elements
          .where((e) => e.getElementsByTagName('td').length > 2)
          .map((e) {
        return e.querySelector('td > a')!.attributes['href']!.trim();
      });
      nihongonosenseiSet.addAll(urls);
    }

    var filePath = 'temp/nihongonosensei.txt';

    // // Debug
    // filePath = 'temp/test.txt';
    // // Debug

    // 判断是生成新文件还是在原文件添加内容
    final buffer = StringBuffer();
    if (await File(filePath).exists()) {
      final existSet = <String>{};
      for (final line in await File(filePath).readAsLines()) {
        if (RegExp(r'nihongonosensei\d+').hasMatch(line.split('\t').first)) {
          existSet.add(
            line.split('\t').first.replaceFirst(
                  'nihongonosensei',
                  'https://nihongonosensei.net/?p=',
                ),
          );
        }
      }
      nihongonosenseiSet.removeAll(existSet);
    } else {
      buffer.write(
        '#columns:编号\t牌组\t卡片类型\t文法\t説明\t意味\n'
        '#deck column:2\n'
        '#notetype column:3\n',
      );
    }

    try {
      await catchContents(nihongonosenseiSet, buffer);
    } catch (e) {
      stdout.writeln(e.toString());
    } finally {
      await File(filePath)
          .writeAsString(buffer.toString(), mode: FileMode.append);
    }
  }
}

Future<void> catchContents(Set<String> set, StringBuffer buffer) async {
  for (final item in set) {
    final url = Uri.parse(item);
    final id = url.queryParameters['p'];

    // // Debug
    // if (id != '35991') {
    //   continue;
    // }
    // // Debug

    final response = await http.post(url);
    final body = parse(response.body).querySelector('div#mainEntity');

    if (id != null && body != null) {
      final title = body.querySelector('h1.entry-title')!.text;
      stdout.writeln(title);

      final groupAndType = title.replaceAllMapped(
        RegExp('(【Ｎ.文法】|【オノマトペ】)'),
        (match) => '毎日のんびり日本語教師::${match[0]}\tnihongonosensei\t',
      );

      buffer.write(
        'nihongonosensei$id\t'
        '$groupAndType\t',
      );

      var content =
          (body.querySelector('div.clearfix')!.children..removeAt(0)).map((e) {
        if (e.innerHtml.trim().isEmpty ||
            e.querySelectorAll('img[src="./pic/n1top2.png"]').isNotEmpty ||
            e.getElementsByTagName('script').isNotEmpty) {
          // 需要删除的tag
          return '';
        } else if (e.attributes['style'] ==
                'border-bottom: solid 1px #777; font-size:18px;'
                    ' padding-left:10px; font-weight:800; color:#222;' ||
            e.attributes['class'] == 'midashi') {
          // 标题tag
          return '<div class="separator">${e.text}</div>';
        } else {
          // 其它tag

          // 图片
          for (final img in e.getElementsByTagName('img')) {
            final url = img.attributes['src']!.replaceFirst(
              RegExp(r'^\.'),
              'https://nihongonosensei.net',
            );
            img.attributes['src'] = 'nihongonosensei_${url.split('/').last}';
            http.get(Uri.parse(url)).then((response) {
              File('temp/nihongonosensei_media/nihongonosensei_${url.split('/').last}')
                  .writeAsBytes(response.bodyBytes);
            });
          }

          // YouTube视频
          for (final iframe in e.querySelectorAll('span.i-video > iframe')) {
            final url = iframe.attributes['src'];
            if (url != null) {
              Process.run(
                'yt-dlp.exe',
                [
                  url,
                  '-o',
                  'nihongonosensei_${url.split('/').last}.mp4',
                  '-P',
                  'temp/nihongonosensei_media/',
                  '-f',
                  'b[filesize<10M] / w',
                ],
              );
              // stderr.writeln(result.stderr);

              iframe.replaceWith(
                Element.tag('video')
                  ..attributes['src'] =
                      'nihongonosensei_${url.split('/').last}.mp4'
                  ..attributes['controls'] = 'controls',
              );
            }
          }

          // 音频
          for (final audio in e.querySelectorAll('audio > source')) {
            final url = audio.attributes['src']!.replaceFirst(
              RegExp(r'^\.'),
              'https://nihongonosensei.net',
            );
            final path =
                'nihongonosensei_${url.split('/').last.replaceAll(RegExp(r'\?.*'), '')}';
            audio.attributes['src'] = path;
            http.get(Uri.parse(url)).then((response) {
              File('temp/nihongonosensei_media/$path')
                  .writeAsBytes(response.bodyBytes);
            });
          }

          return e.outerHtml
              .replaceAll('\n', '')
              .replaceAll('\t', '')
              .replaceAll(RegExp('(?<!span)>　'), '>')
              .replaceAll('　<', '<')
              .replaceAll('）　', '）')
              .replaceAll(
                '　<span style="color:#a0a0a0;">（',
                '<span style="color:#a0a0a0;">（',
              );
        }
      }).join();

      // 若含有单个「意味」块且内容有意义，则移动到结尾用于生成反向卡片
      final meaningMatches =
          RegExp('<div class="separator">意味</div>').allMatches(content);
      if (meaningMatches.length == 1 &&
          !content.contains('意味</div><p>-<br></p>')) {
        content = content.replaceFirstMapped(
          RegExp(
            '<div class="separator">意味</div>(.+?)(<div class="separator">.+)',
          ),
          (match) => '${match[2]}\t${match[1]}',
        );
      }

      buffer.write('$content\n');
    }
    // 避免频繁访问
    sleep(const Duration(milliseconds: 100));
  }
}
