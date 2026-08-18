import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';

/// Adminkadan keladigan HTML matnni saytdagi `prose` uslubi bilan chizadi.
///
/// Sayt bu yerda Tailwind'ning `prose prose-lg` sinfini ishlatadi va faqat sanoqli teglarni
/// bezaydi — `h2/h3/h4`, `p`, `li`, `a`, `strong`. Shu ro'yxatdan tashqarisi oddiy matn bo'lib
/// chiqadi, chunki `DomSanitizer` script/style'larni allaqachon olib tashlagan bo'ladi.
///
/// Umumiy HTML kutubxonasi o'rniga shu tor render tanlandi: o'lchamlar (`prose-h2:text-2xl`,
/// `prose-p:text-dark/70` va h.k.) shablonda aniq yozilgan va ularni aynan takrorlash kerak.
class ProseHtml extends StatelessWidget {
  const ProseHtml(this.html, {super.key});

  final String html;

  @override
  Widget build(BuildContext context) {
    final blocks = _parseBlocks(html);
    if (blocks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final block in blocks) _block(context, block)],
    );
  }

  Widget _block(BuildContext context, _Block block) {
    final theme = Theme.of(context);
    final (top, bottom, style) = switch (block.tag) {
      'h2' => (
        40.0, // mt-10
        16.0, // mb-4
        theme.textTheme.displaySmall?.copyWith(
          fontSize: 24, // text-2xl
          fontWeight: FontWeight.w700,
          color: AppColors.dark,
        ),
      ),
      'h3' => (
        32.0, // mt-8
        12.0, // mb-3
        theme.textTheme.displaySmall?.copyWith(
          fontSize: 20, // text-xl
          fontWeight: FontWeight.w700,
          color: AppColors.dark,
        ),
      ),
      'h4' => (
        24.0, // mt-6
        8.0, // mb-2
        theme.textTheme.displaySmall?.copyWith(
          fontSize: 18, // text-lg
          fontWeight: FontWeight.w700,
          color: AppColors.dark,
        ),
      ),
      _ => (
        0.0,
        24.0, // prose-lg paragraf oralig'i
        theme.textTheme.bodyMedium?.copyWith(
          fontSize: 18, // prose-lg
          height: 1.78, // leading-relaxed
          color: AppColors.dark.withValues(alpha: 0.7),
        ),
      ),
    };

    final text = Text.rich(TextSpan(children: _inline(block.spans, style)));
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: bottom),
      child: block.bullet
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8, top: 8),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.dark.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(child: text),
              ],
            )
          : text,
    );
  }

  List<InlineSpan> _inline(List<_Span> spans, TextStyle? base) => [
    for (final span in spans)
      TextSpan(
        text: span.text,
        style: base?.copyWith(
          fontWeight: span.bold ? FontWeight.w600 : null,
          fontStyle: span.italic ? FontStyle.italic : null,
          color: span.href != null ? AppColors.olive : (span.bold ? AppColors.dark : null),
        ),
        recognizer: span.href == null
            ? null
            : (TapGestureRecognizer()
                ..onTap = () =>
                    launchUrl(Uri.parse(span.href!), mode: LaunchMode.externalApplication)),
      ),
  ];
}

class _Span {
  const _Span(this.text, {this.bold = false, this.italic = false, this.href});

  final String text;
  final bool bold;
  final bool italic;
  final String? href;
}

class _Block {
  const _Block(this.tag, this.spans, {this.bullet = false});

  final String tag;
  final List<_Span> spans;
  final bool bullet;
}

final _tagPattern = RegExp(r'<\s*(/?)\s*([a-zA-Z0-9]+)([^>]*)>');
final _hrefPattern = RegExp('''href\\s*=\\s*["']([^"']*)["']''');

/// Teglarni bosqichma-bosqich o'qib, blok va ichki bo'laklarga ajratadi.
List<_Block> _parseBlocks(String html) {
  if (html.trim().isEmpty) return const [];

  final blocks = <_Block>[];
  var spans = <_Span>[];
  var tag = 'p';
  var bullet = false;
  var bold = 0;
  var italic = 0;
  String? href;

  void flush() {
    final joined = spans.map((s) => s.text).join().trim();
    if (joined.isNotEmpty) blocks.add(_Block(tag, List.of(spans), bullet: bullet));
    spans = <_Span>[];
  }

  void addText(String raw) {
    // HTML'da qator uzilishi va ketma-ket bo'shliqlar bitta probelga aylanadi.
    final text = _unescape(raw).replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty) return;
    if (spans.isEmpty && text.trim().isEmpty) return;
    spans.add(_Span(text, bold: bold > 0, italic: italic > 0, href: href));
  }

  var cursor = 0;
  for (final match in _tagPattern.allMatches(html)) {
    addText(html.substring(cursor, match.start));
    cursor = match.end;

    final closing = match.group(1) == '/';
    final name = match.group(2)!.toLowerCase();

    switch (name) {
      case 'h2' || 'h3' || 'h4' || 'p' || 'div' || 'ul' || 'ol' || 'blockquote':
        flush();
        tag = (name == 'div' || name == 'ul' || name == 'ol' || name == 'blockquote') ? 'p' : name;
        if (name == 'ul' || name == 'ol') bullet = !closing;
      case 'li':
        flush();
        tag = 'p';
      case 'br':
        addText('\n');
      case 'strong' || 'b':
        bold += closing ? -1 : 1;
        if (bold < 0) bold = 0;
      case 'em' || 'i':
        italic += closing ? -1 : 1;
        if (italic < 0) italic = 0;
      case 'a':
        if (closing) {
          href = null;
        } else {
          href = _hrefPattern.firstMatch(match.group(3) ?? '')?.group(1);
        }
    }
  }
  addText(html.substring(cursor));
  flush();
  return blocks;
}

String _unescape(String value) => value
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'");
