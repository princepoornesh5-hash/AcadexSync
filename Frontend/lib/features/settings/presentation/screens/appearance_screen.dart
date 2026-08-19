import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_widgets.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Appearance",
          style: AcadexTypography.title(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
      ),
      body: settingsAsync.when(
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
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
              const SizedBox(height: 12),
              ThemeSelector(
                currentMode: settings.themeMode,
                onChanged: (mode) {
                  ref.read(appSettingsProvider.notifier).updateSettings(
                        settings.copyWith(themeMode: mode),
                      );
                },
              ),
              const SizedBox(height: 32),
              Text(
                "TEXT SCALING",
                style: AcadexTypography.eyebrow(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
              const SizedBox(height: 12),
              AcadexCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "A",
                          style: AcadexTypography.body(
                            color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                          ).copyWith(fontSize: 13),
                        ),
                        Expanded(
                          child: Slider(
                            value: settings.fontScale,
                            min: 0.8,
                            max: 1.4,
                            divisions: 3,
                            activeColor: AcadexColors.primary,
                            onChanged: (val) {
                              ref.read(appSettingsProvider.notifier).updateSettings(
                                    settings.copyWith(fontScale: val),
                                  );
                            },
                          ),
                        ),
                        Text(
                          "A",
                          style: AcadexTypography.heading2(
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Adjust the application font scale for optimal reading comfort.",
                      style: AcadexTypography.caption(
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
