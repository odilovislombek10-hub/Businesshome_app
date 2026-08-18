import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/api/api_client.dart';
import '../../shared/widgets/prose_html.dart';
import '../../shared/widgets/site_footer_section.dart';
import '../../shared/widgets/site_header.dart';

/// Saytning `/privacy` va `/terms` sahifalari — bitta `legal-page.component.ts`, farqi faqat
/// `slug` da. Sarlavha ham, matn ham adminkadan keladi.
class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key, required this.slug});

  /// `privacy` yoki `terms`.
  final String slug;

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  final _scroll = ScrollController();
  late final Future<({String title, String content})?> _future = _load();
  bool _scrolled = false;

  Future<({String title, String content})?> _load() async {
    try {
      final res = await ApiClient.instance.get<dynamic>('/market/content/legal/${widget.slug}');
      final data = res.data;
      if (data is! Map) return null;
      String pick(String field) =>
          (data['${field}_uz'] ?? data['${field}_ru'] ?? '').toString().trim();
      return (title: pick('title'), content: pick('content'));
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final scrolled = _scroll.offset > 10;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.surfaceAltLight, // main bg-gray-50
      body: Stack(
        children: [
          FutureBuilder<({String title, String content})?>(
            future: _future,
            builder: (context, snapshot) {
              final loading = snapshot.connectionState == ConnectionState.waiting;
              final page = snapshot.data;
              return CustomScrollView(
                controller: _scroll,
                slivers: [
                  // Hero — oq fonli, pastida chiziq.
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        // `container-custom py-12` + qat'iy header.
                        96 + MediaQuery.paddingOf(context).top,
                        16,
                        48,
                      ),
                      child: Text(
                        page?.title ?? '',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontSize: 30, // text-3xl
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 0), // py-10
                    sliver: SliverList.list(
                      children: [
                        if (loading)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 80), // py-20
                            child: Center(
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.olive,
                                ),
                              ),
                            ),
                          )
                        else if ((page?.content ?? '').isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32), // p-8
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: ProseHtml(page!.content),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 80), // py-20
                            child: Center(
                              child: Text(
                                // Saytda ham aynan shu matn qattiq yozilgan.
                                "Bu sahifa hali to'ldirilmagan",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontSize: 18, // text-lg
                                  color: AppColors.dark.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 48)),
                  const SliverToBoxAdapter(child: SiteFooterSection()),
                ],
              );
            },
          ),
          // Shablonda `[transparent]="false"`.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SiteHeader(scrolled: _scrolled, showSearch: false),
          ),
        ],
      ),
    );
  }
}
