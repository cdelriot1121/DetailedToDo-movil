import 'package:flutter/material.dart';
import '../../../app/theme.dart';

class MarkdownNoteContent extends StatelessWidget {
  final String data;
  const MarkdownNoteContent({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final lines = data.replaceAll('\r\n', '\n').split('\n');
    final blocks = <Widget>[];
    final paragraph = <String>[];
    var index = 0;

    void flushParagraph() {
      if (paragraph.isEmpty) return;
      blocks.add(_paragraph(context, paragraph.join(' ')));
      paragraph.clear();
    }

    while (index < lines.length) {
      final line = lines[index].trimRight();
      final trimmed = line.trimLeft();
      if (trimmed.isEmpty) {
        flushParagraph();
        index++;
        continue;
      }

      final heading = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(trimmed);
      if (heading != null) {
        flushParagraph();
        blocks.add(_heading(context, heading.group(2)!, heading.group(1)!.length));
        index++;
        continue;
      }

      if (trimmed.startsWith('```')) {
        flushParagraph();
        final code = <String>[];
        index++;
        while (index < lines.length && !lines[index].trimLeft().startsWith('```')) {
          code.add(lines[index]);
          index++;
        }
        if (index < lines.length) index++;
        blocks.add(_codeBlock(context, code.join('\n')));
        continue;
      }

      if (RegExp(r'^([-*+]\s+|\d+[.)]\s+)').hasMatch(trimmed)) {
        flushParagraph();
        final items = <String>[];
        while (index < lines.length) {
          final item = RegExp(r'^\s*(?:[-*+]\s+|\d+[.)]\s+)(.+)$').firstMatch(lines[index]);
          if (item == null) break;
          items.add(item.group(1)!);
          index++;
        }
        blocks.add(_list(context, items));
        continue;
      }

      if (trimmed.startsWith('>')) {
        flushParagraph();
        final quote = <String>[];
        while (index < lines.length && lines[index].trimLeft().startsWith('>')) {
          quote.add(lines[index].trimLeft().replaceFirst(RegExp(r'^>\s?'), ''));
          index++;
        }
        blocks.add(_quote(context, quote.join(' ')));
        continue;
      }

      paragraph.add(trimmed);
      index++;
    }
    flushParagraph();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: blocks);
  }

  Widget _heading(BuildContext context, String text, int level) {
    final palette = context.palette;
    return Padding(
      padding: EdgeInsets.only(top: level <= 2 ? 10 : 6, bottom: 8),
      child: _inline(context, text, TextStyle(
        color: palette.primaryText,
        fontSize: level == 1 ? 23 : level == 2 ? 19 : 16,
        fontWeight: FontWeight.bold,
        height: 1.3,
      )),
    );
  }

  Widget _paragraph(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: _inline(context, text, TextStyle(
      color: context.palette.primaryText, fontSize: 15, height: 1.7,
    )),
  );

  Widget _list(BuildContext context, List<String> items) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final item in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(top: 7, right: 10),
              child: Icon(Icons.circle, size: 6, color: context.palette.accent),
            ),
            Expanded(child: _inline(context, item, TextStyle(
              color: context.palette.primaryText, fontSize: 15, height: 1.6,
            ))),
          ]),
        ),
    ]),
  );

  Widget _quote(BuildContext context, String text) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
    decoration: BoxDecoration(
      color: context.palette.surfaceSecondary,
      border: Border(left: BorderSide(color: context.palette.accent, width: 3)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: _inline(context, text, TextStyle(
      color: context.palette.secondaryText, fontStyle: FontStyle.italic, height: 1.6,
    )),
  );

  Widget _codeBlock(BuildContext context, String code) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: context.palette.surfaceSecondary, borderRadius: BorderRadius.circular(8)),
    child: SelectableText(code, style: TextStyle(
      color: context.palette.primaryText, fontFamily: 'monospace', height: 1.5,
    )),
  );

  Widget _inline(BuildContext context, String text, TextStyle base) {
    final pattern = RegExp(r'(\*\*.+?\*\*|__.+?__|\*[^*]+\*|_[^_]+_|`[^`]+`)');
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > cursor) spans.add(TextSpan(text: text.substring(cursor, match.start)));
      final token = match.group(0)!;
      final bold = token.startsWith('**') || token.startsWith('__');
      final code = token.startsWith('`');
      final delimiter = bold || code ? 2 : 1;
      spans.add(TextSpan(
        text: token.substring(delimiter, token.length - delimiter),
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : null,
          fontStyle: !bold && !code ? FontStyle.italic : null,
          fontFamily: code ? 'monospace' : null,
          backgroundColor: code ? context.palette.surfaceSecondary : null,
        ),
      ));
      cursor = match.end;
    }
    if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
    return RichText(text: TextSpan(style: base, children: spans));
  }
}
