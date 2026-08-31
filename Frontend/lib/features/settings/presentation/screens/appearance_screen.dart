import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/settings_providers.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isSuperAdmin = authState is AuthAuthenticated && authState.user.role == AppRole.superAdmin;
    final settingsAsync = ref.watch(appSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasEnclosingScaffold = Scaffold.maybeOf(context) != null;

    final content = settingsAsync.when(
      loading: () => const AcadexLoadingState(message: "Loading appearance settings..."),
      error: (err, _) => AcadexErrorState(
        message: "Unable to load settings: $err",
        onRetry: () => ref.refresh(appSettingsProvider),
      ),
      data: (settings) => AcadexPageContainer(
        maxWidth: AcadexLayout.formMaxWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "INTERFACE THEME",
              style: AcadexTypography.eyebrow(
                color: isSuperAdmin ? const Color(0xFF07111F) : AcadexColors.inkMuted,
              ),
            ),
            const SizedBox(height: 12),
            AcadexCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSuperAdmin ? const Color(0xFFE6F2FF) : AcadexColors.primaryLight,
                      borderRadius: AcadexRadius.borderRadiusSm,
                    ),
                    child: Icon(
                      LucideIcons.sun,
                      color: isSuperAdmin ? const Color(0xFF003366) : AcadexColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Notion White Interface",
                          style: AcadexTypography.body(color: AcadexColors.ink).copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Acadex is optimized for a permanent, high-clarity interface.",
                          style: AcadexTypography.caption(color: AcadexColors.inkSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AcadexColors.successLight,
                      borderRadius: AcadexRadius.borderRadiusXs,
                    ),
                    child: const Text(
                      "Active",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AcadexColors.success),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "TEXT SCALING",
              style: AcadexTypography.eyebrow(
                color: isSuperAdmin ? const Color(0xFF07111F) : AcadexColors.inkMuted,
              ),
            ),
            const SizedBox(height: 12),
            AcadexCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Font Scale",
                        style: AcadexTypography.body(color: AcadexColors.ink).copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "${(settings.fontScale * 100).toInt()}%",
                        style: AcadexTypography.caption(color: isSuperAdmin ? const Color(0xFF003366) : AcadexColors.primary).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: settings.fontScale,
                    min: 0.85,
                    max: 1.30,
                    divisions: 9,
                    activeColor: isSuperAdmin ? const Color(0xFF003366) : AcadexColors.primary,
                    inactiveColor: AcadexColors.hairline,
                    onChanged: (val) {
                      ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(fontScale: val));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );

    if (hasEnclosingScaffold) {
      return content;
    }

    return Scaffold(
      backgroundColor: isSuperAdmin ? Colors.transparent : (isDark ? AcadexColors.darkCanvas : AcadexColors.canvas),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
          onPressed: () => context.safePop(fallbackRoute: '/settings'),
        ),
        title: Text(
          "Appearance",
          style: AcadexTypography.title(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
      ),
      body: content,
    );
  }
}
