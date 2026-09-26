import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_adaptive_gradient_text.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/acadex_hero_card.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';
import '../../../reports/presentation/providers/reports_providers.dart';

class SuperAdminDashboard extends ConsumerWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(superAdminStatsProvider);
    final quickActions = ref.watch(superAdminQuickActionsProvider);
    final authState = ref.watch(authProvider);

    UserModel? user;
    if (authState is AuthAuthenticated) user = authState.user;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AcadexBreakpoints.isMobile(context);
    final firstName = user?.name.split(' ').first ?? 'Super Admin';

    return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final statCols = AcadexLayout.statGridColumns(context);

          return AcadexPageContainer(
            topPadding: isMobile ? 16 : 24,
            onRefresh: () async {
              ref.invalidate(superAdminStatsProvider);
              ref.invalidate(roleDashboardReportProvider);
              ref.invalidate(superAdminActivityProvider);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Unboxed Greeting (Adaptive Gradient Text) ──────────
                _buildGreeting(context, isDark, isMobile, firstName),
                SizedBox(height: isMobile ? 14 : 20),

                // ── 2. Platform Status Hero Card (Solid White Surface) ────
                AcadexHeroCard(
                  eyebrow: 'Platform Command Center',
                  badge: const AcadexBadge(
                    label: 'ALL SYSTEMS LIVE',
                    variant: AcadexBadgeVariant.success,
                  ),
                  icon: LucideIcons.shieldCheck,
                  title: 'Multi-Tenant Ecosystem Health',
                  subtitle: 'Real-time monitoring across all provisioned institutions and colleges.',
                  primaryActionLabel: 'Register College',
                  primaryActionIcon: LucideIcons.plus,
                  onPrimaryAction: () => context.go('/academics/colleges/new'),
                  secondaryActionLabel: 'Global Analytics',
                  onSecondaryAction: () => context.go('/analytics'),
                ),
                SizedBox(height: isMobile ? 18 : 24),

                // ── 3. Platform Overview Header (Adaptive Gradient Text) ──
                SectionHeader(
                  title: 'Platform Overview',
                  actionLabel: 'View Analytics →',
                  showAccent: true,
                  onAction: () => context.go('/analytics'),
                ),
                const SizedBox(height: 12),
                stats.when(
                  loading: () => const AcadexLoadingState(message: 'Loading platform metrics...'),
                  error: (err, _) => AcadexErrorState(
                    message: 'Failed to load platform metrics: $err',
                    onRetry: () => ref.refresh(superAdminStatsProvider),
                  ),
                  data: (data) => GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: data.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: statCols,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: isMobile
                          ? (width >= 375 ? 1.05 : 0.98)
                          : (width > 600 ? 1.25 : 1.1),
                    ),
                    itemBuilder: (_, i) => StatCard(stat: data[i]),
                  ),
                ),
                SizedBox(height: isMobile ? 18 : 24),

                // ── 4. Quick Operations Header (Adaptive Gradient Text) ───
                SectionHeader(
                  title: 'Quick Operations',
                  actionLabel: 'More Actions →',
                  showAccent: true,
                  onAction: () => context.go('/academics/colleges'),
                ),
                const SizedBox(height: 12),
                QuickActionsRow(actions: quickActions),
                const SizedBox(height: 24),

                // ── 5. Recent Institutions (Live API Data) ────────────────
                Consumer(
                  builder: (context, ref, _) {
                    final reportAsync = ref.watch(roleDashboardReportProvider);
                    return reportAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (report) {
                        if (report == null || report.recentActivity.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final colleges = report.recentActivity;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHeader(
                              title: 'Recent Institutions',
                              actionLabel: 'View All →',
                              showAccent: true,
                              onAction: () => context.go('/academics/colleges'),
                            ),
                            const SizedBox(height: 12),
                            if (isMobile)
                              _buildMobileInstitutionList(context, isDark, colleges)
                            else
                              _buildDesktopInstitutionCard(context, isDark, colleges),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
  }

  Widget _buildGreeting(
    BuildContext context,
    bool isDark,
    bool isMobile,
    String firstName,
  ) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    final heading = '$greeting, $firstName 👋';
    const subtitle = 'Platform oversight and cross-institutional management dashboard.';

    if (isMobile) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AcadexAdaptiveGradientText(
                  heading,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const AcadexAdaptiveGradientText(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                  isSecondary: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const AcadexBadge(
            label: 'SUPER ADMIN',
            variant: AcadexBadgeVariant.primary,
          ),
        ],
      );
    }

    // Desktop greeting
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AcadexAdaptiveGradientText(
                heading,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              const AcadexAdaptiveGradientText(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                isSecondary: true,
              ),
            ],
          ),
        ),
        const AcadexBadge(
          label: 'SUPER ADMIN',
          variant: AcadexBadgeVariant.primary,
        ),
      ],
    );
  }

  Widget _buildMobileInstitutionList(
    BuildContext context,
    bool isDark,
    List<dynamic> colleges,
  ) {
    final items = colleges.take(5).toList();
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          width: 1,
        ),
        boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
      ),
      child: Column(
        children: List.generate(items.length, (idx) {
          final col = items[idx];
          final name = col['name']?.toString() ?? 'College';
          final city = col['city']?.toString() ?? col['address']?.toString() ?? 'India';
          final isActive = col['isActive'] != false;
          final initials = _initials(name);
          final isLast = idx == items.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    // Avatar circle with initials
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AcadexColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: AcadexTypography.caption(
                            color: AcadexColors.primary,
                          ).copyWith(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Name + location
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AcadexTypography.bodyMedium(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ).copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            city,
                            style: AcadexTypography.caption(
                              color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive ? AcadexColors.successLight : AcadexColors.errorLight,
                        borderRadius: AcadexRadius.borderRadiusXs,
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isActive ? AcadexColors.success : AcadexColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildDesktopInstitutionCard(
    BuildContext context,
    bool isDark,
    List<dynamic> colleges,
  ) {
    final items = colleges.take(5).toList();
    return AcadexCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          thickness: 1,
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        ),
        itemBuilder: (context, idx) {
          final col = items[idx];
          final name = col['name']?.toString() ?? 'College';
          final city = col['city']?.toString() ?? col['address']?.toString() ?? 'India';
          final code = col['code']?.toString() ?? '';
          final isActive = col['isActive'] != false;
          final initials = _initials(name);

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AcadexColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: AcadexTypography.caption(
                    color: AcadexColors.primary,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            title: Text(
              name,
              style: AcadexTypography.body(
                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              [code, city].where((s) => s.isNotEmpty).join(' • '),
              style: AcadexTypography.caption(
                color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isActive ? AcadexColors.successLight : AcadexColors.errorLight,
                borderRadius: AcadexRadius.borderRadiusXs,
              ),
              child: Text(
                isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AcadexColors.success : AcadexColors.error,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'CO';
    if (parts.length == 1) return parts[0].substring(0, parts[0].length.clamp(1, 2)).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
