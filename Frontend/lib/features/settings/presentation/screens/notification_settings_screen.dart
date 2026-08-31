import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_widgets.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface), onPressed: () => context.safePop(fallbackRoute: '/settings')),
        title: Text("Notifications", style: AcadexTypography.title(color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: prefsAsync.when(
        loading: () => const AcadexLoadingState(message: "Loading notification preferences..."),
        error: (err, _) => AcadexErrorState(message: "Error: $err", onRetry: () => ref.refresh(notificationPreferencesProvider)),
        data: (prefs) => AcadexPageContainer(
          maxWidth: AcadexLayout.formMaxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsSection(
                title: "Academic Alerts",
                children: [
                  ToggleTile(
                    icon: LucideIcons.calendarCheck,
                    title: "Attendance Alerts",
                    subtitle: "Get notified for daily attendance",
                    value: prefs.attendanceAlerts,
                    onChanged: (val) => ref.read(notificationPreferencesProvider.notifier).updatePreferences(prefs.copyWith(attendanceAlerts: val)),
                  ),
                  ToggleTile(
                    icon: LucideIcons.bookOpen,
                    title: "Academic Updates",
                    subtitle: "Assignments, marks, and timetable changes",
                    value: prefs.academicUpdates,
                    onChanged: (val) => ref.read(notificationPreferencesProvider.notifier).updatePreferences(prefs.copyWith(academicUpdates: val)),
                  ),
                ],
              ),
              SettingsSection(
                title: "Resources & Documents",
                children: [
                  ToggleTile(
                    icon: LucideIcons.fileText,
                    title: "Notes Uploaded",
                    subtitle: "Notify when new study materials are added",
                    value: prefs.notesUploaded,
                    onChanged: (val) => ref.read(notificationPreferencesProvider.notifier).updatePreferences(prefs.copyWith(notesUploaded: val)),
                  ),
                ],
              ),
              SettingsSection(
                title: "General",
                children: [
                  ToggleTile(
                    icon: LucideIcons.megaphone,
                    title: "Announcements",
                    subtitle: "Important college-wide messages",
                    value: prefs.announcements,
                    onChanged: (val) => ref.read(notificationPreferencesProvider.notifier).updatePreferences(prefs.copyWith(announcements: val)),
                  ),
                  ToggleTile(
                    icon: LucideIcons.bell,
                    title: "General Notifications",
                    subtitle: "Other system notifications",
                    value: prefs.generalNotifications,
                    onChanged: (val) => ref.read(notificationPreferencesProvider.notifier).updatePreferences(prefs.copyWith(generalNotifications: val)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
