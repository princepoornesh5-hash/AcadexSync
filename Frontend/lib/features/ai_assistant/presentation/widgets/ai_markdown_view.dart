import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';

class AiMarkdownView extends StatelessWidget {
  final String text;
  final Color? textColor;
  final double fontSize;

  const AiMarkdownView({
    super.key,
    required this.text,
    this.textColor,
    this.fontSize = 15.0,
  });

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? const Color(0xFF1E293B);
    final blocks = _parseBlocks(text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map((block) => _buildBlock(context, block, color)).toList(),
    );
  }

  List<_MdBlock> _parseBlocks(String input) {
    final List<_MdBlock> blocks = [];
    final lines = input.split('\n');
    int i = 0;

    while (i < lines.length) {
      final line = lines[i];

      // Code Block start
      if (line.trim().startsWith('```')) {
        final lang = line.trim().substring(3).trim();
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        blocks.add(_MdBlock(
          type: _BlockType.code,
          content: codeLines.join('\n'),
          extra: lang.isEmpty ? 'code' : lang,
        ));
        i++;
        continue;
      }

      // Heading 1
      if (line.startsWith('# ')) {
        blocks.add(_MdBlock(type: _BlockType.h1, content: line.substring(2).trim()));
        i++;
        continue;
      }

      // Heading 2
      if (line.startsWith('## ')) {
        blocks.add(_MdBlock(type: _BlockType.h2, content: line.substring(3).trim()));
        i++;
        continue;
      }

      // Heading 3
      if (line.startsWith('### ')) {
        blocks.add(_MdBlock(type: _BlockType.h3, content: line.substring(4).trim()));
        i++;
        continue;
      }

      // Bullet List
      if (RegExp(r'^\s*[-*]\s+').hasMatch(line)) {
        final content = line.replaceFirst(RegExp(r'^\s*[-*]\s+'), '');
        blocks.add(_MdBlock(type: _BlockType.bullet, content: content));
        i++;
        continue;
      }

      // Numbered List
      if (RegExp(r'^\s*\d+\.\s+').hasMatch(line)) {
        final match = RegExp(r'^\s*(\d+)\.\s+(.*)').firstMatch(line);
        final numStr = match?.group(1) ?? '1';
        final content = match?.group(2) ?? '';
        blocks.add(_MdBlock(type: _BlockType.numbered, content: content, extra: numStr));
        i++;
        continue;
      }

      // Empty line / paragraph break
      if (line.trim().isEmpty) {
        blocks.add(_MdBlock(type: _BlockType.spacer, content: ''));
        i++;
        continue;
      }

      // Normal paragraph
      final paragraphLines = <String>[line];
      i++;
      while (i < lines.length &&
          lines[i].trim().isNotEmpty &&
          !lines[i].trim().startsWith('```') &&
          !lines[i].startsWith('# ') &&
          !lines[i].startsWith('## ') &&
          !lines[i].startsWith('### ') &&
          !RegExp(r'^\s*[-*]\s+').hasMatch(lines[i]) &&
          !RegExp(r'^\s*\d+\.\s+').hasMatch(lines[i])) {
        paragraphLines.add(lines[i]);
        i++;
      }
      blocks.add(_MdBlock(type: _BlockType.paragraph, content: paragraphLines.join(' ')));
    }

    return blocks;
  }

  Widget _buildBlock(BuildContext context, _MdBlock block, Color baseColor) {
    switch (block.type) {
      case _BlockType.h1:
        return Padding(
          padding: const EdgeInsets.only(top: 14.0, bottom: 6.0),
          child: SelectableText.rich(
            TextSpan(
              children: _parseInlineSpans(
                block.content,
                TextStyle(
                  fontSize: fontSize + 5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  height: 1.3,
                ),
              ),
            ),
          ),
        );
      case _BlockType.h2:
        return Padding(
          padding: const EdgeInsets.only(top: 12.0, bottom: 5.0),
          child: SelectableText.rich(
            TextSpan(
              children: _parseInlineSpans(
                block.content,
                TextStyle(
                  fontSize: fontSize + 2.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                  height: 1.35,
                ),
              ),
            ),
          ),
        );
      case _BlockType.h3:
        return Padding(
          padding: const EdgeInsets.only(top: 10.0, bottom: 4.0),
          child: SelectableText.rich(
            TextSpan(
              children: _parseInlineSpans(
                block.content,
                TextStyle(
                  fontSize: fontSize + 1,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                  height: 1.4,
                ),
              ),
            ),
          ),
        );
      case _BlockType.code:
        return _CodeBlockWidget(
          code: block.content,
          language: block.extra ?? 'code',
        );
      case _BlockType.bullet:
        return Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8.0, right: 10.0),
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: baseColor.withValues(alpha: 0.7),
                ),
              ),
              Expanded(
                child: SelectableText.rich(
                  TextSpan(
                    children: _parseInlineSpans(
                      block.content,
                      TextStyle(
                        fontSize: fontSize,
                        color: baseColor,
                        height: 1.55,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case _BlockType.numbered:
        return Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                child: Text(
                  '${block.extra}.',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: baseColor.withValues(alpha: 0.85),
                    height: 1.55,
                  ),
                ),
              ),
              Expanded(
                child: SelectableText.rich(
                  TextSpan(
                    children: _parseInlineSpans(
                      block.content,
                      TextStyle(
                        fontSize: fontSize,
                        color: baseColor,
                        height: 1.55,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case _BlockType.spacer:
        return const SizedBox(height: 8);
      case _BlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: SelectableText.rich(
            TextSpan(
              children: _parseInlineSpans(
                block.content,
                TextStyle(
                  fontSize: fontSize,
                  color: baseColor,
                  height: 1.6,
                ),
              ),
            ),
          ),
        );
    }
  }

  List<InlineSpan> _parseInlineSpans(String text, TextStyle baseStyle) {
    final List<InlineSpan> spans = [];
    final regex = RegExp(r'(\*\*([^*]+)\*\*|\*([^*]+)\*|`([^`]+)`)');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: baseStyle,
        ));
      }

      if (match.group(2) != null) {
        // Bold: **text**
        spans.add(TextSpan(
          text: match.group(2),
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (match.group(3) != null) {
        // Italic: *text*
        spans.add(TextSpan(
          text: match.group(3),
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (match.group(4) != null) {
        // Inline code: `code`
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              match.group(4)!,
              style: GoogleFonts.firaCode(
                fontSize: baseStyle.fontSize != null ? baseStyle.fontSize! * 0.9 : 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: baseStyle,
      ));
    }

    return spans;
  }
}

enum _BlockType { h1, h2, h3, code, bullet, numbered, paragraph, spacer }

class _MdBlock {
  final _BlockType type;
  final String content;
  final String? extra;

  _MdBlock({
    required this.type,
    required this.content,
    this.extra,
  });
}

class _CodeBlockWidget extends StatefulWidget {
  final String code;
  final String language;

  const _CodeBlockWidget({
    required this.code,
    required this.language,
  });

  @override
  State<_CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<_CodeBlockWidget> {
  bool _copied = false;

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: const Color(0xFF1E293B),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.language.toUpperCase(),
                  style: GoogleFonts.firaCode(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                InkWell(
                  onTap: _copyToClipboard,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _copied ? LucideIcons.check : LucideIcons.copy,
                          size: 13,
                          color: _copied ? AcadexColors.success : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _copied ? 'Copied!' : 'Copy',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _copied ? AcadexColors.success : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Code Area
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              widget.code,
              style: GoogleFonts.firaCode(
                fontSize: 13,
                color: const Color(0xFFE2E8F0),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
