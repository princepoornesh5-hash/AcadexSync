import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_widgets.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface), onPressed: () => context.pop()),
        title: Text("Appearance", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err", style: const TextStyle(color: AppColors.warning))),
        data: (settings) => SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Theme", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 16),
                  ThemeSelector(
                    currentMode: settings.themeMode,
                    onChanged: (mode) {
                      ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(themeMode: mode));
                    },
                  ),
                  const SizedBox(height: 32),
                  Text("Font Size", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text("A", style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
                            Expanded(
                              child: Slider(
                                value: settings.fontScale,
                                min: 0.8,
                                max: 1.4,
                                divisions: 3,
                                activeColor: AppColors.primary,
                                inactiveColor: AppColors.surfaceDarkElevated,
                                onChanged: (val) {
                                  ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(fontScale: val));
                                },
                              ),
                            ),
                            Text("A", style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 24)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text("Adjust the text size for better readability.", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
