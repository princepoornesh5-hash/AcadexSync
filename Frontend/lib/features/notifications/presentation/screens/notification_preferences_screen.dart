import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../settings/domain/models/settings_models.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends ConsumerState<NotificationPreferencesScreen> {
  bool _attendanceAlerts = true;
  bool _academicUpdates = true;
  bool _announcements = true;
  bool _notesUploaded = true;
  bool _certificateUpdates = true;
  bool _generalNotifications = true;
  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(notificationPreferencesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: AcadexTypography.title(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
      ),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.alertCircle, size: 48, color: AcadexColors.error),
                const SizedBox(height: 16),
                Text('Failed to load preferences: $err', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(notificationPreferencesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (prefs) {
          if (!_isInitialized) {
            _attendanceAlerts = prefs.attendanceAlerts;
            _academicUpdates = prefs.academicUpdates;
            _announcements = prefs.announcements;
            _notesUploaded = prefs.notesUploaded;
            _certificateUpdates = prefs.certificateUpdates;
            _generalNotifications = prefs.generalNotifications;
            _isInitialized = true;
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Mandatory System Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AcadexColors.primary.withValues(alpha: 0.08),
                  borderRadius: AcadexRadius.borderRadiusMd,
                  border: Border.all(color: AcadexColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.shieldCheck, color: AcadexColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'System & Security Alerts',
                            style: AcadexTypography.body(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Critical security notifications, account authentications, and emergency college broadcasts are mandatory and cannot be disabled.',
                            style: AcadexTypography.bodySmall(
                              color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Academic Category Group
              Text(
                'Academic & Teaching',
                style: AcadexTypography.heading3(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ),
              ),
              const SizedBox(height: 12),

              _buildPreferenceTile(
                title: 'Attendance Alerts',
                subtitle: 'Low attendance warnings, drop threshold notices, and daily attendance logs.',
                icon: LucideIcons.calendarCheck,
                value: _attendanceAlerts,
                onChanged: (val) => setState(() => _attendanceAlerts = val),
              ),
              const SizedBox(height: 10),

              _buildPreferenceTile(
                title: 'Academic Updates',
                subtitle: 'Course assignments, semester milestones, exam timetables, and grade releases.',
                icon: LucideIcons.bookOpen,
                value: _academicUpdates,
                onChanged: (val) => setState(() => _academicUpdates = val),
              ),
              const SizedBox(height: 10),

              _buildPreferenceTile(
                title: 'Study Notes & Materials',
                subtitle: 'New study guides, chapter PDFs, and lecture slides uploaded by your professors.',
                icon: LucideIcons.fileText,
                value: _notesUploaded,
                onChanged: (val) => setState(() => _notesUploaded = val),
              ),
              const SizedBox(height: 24),

              // College Life Category Group
              Text(
                'Campus & Broadcasts',
                style: AcadexTypography.heading3(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ),
              ),
              const SizedBox(height: 12),

              _buildPreferenceTile(
                title: 'Announcements',
                subtitle: 'Official broadcasts from Department Heads and College Administration.',
                icon: LucideIcons.megaphone,
                value: _announcements,
                onChanged: (val) => setState(() => _announcements = val),
              ),
              const SizedBox(height: 10),

              _buildPreferenceTile(
                title: 'Certificates & Documents',
                subtitle: 'Status updates on digital diploma requests, transcripts, and verified certificates.',
                icon: LucideIcons.award,
                value: _certificateUpdates,
                onChanged: (val) => setState(() => _certificateUpdates = val),
              ),
              const SizedBox(height: 10),

              _buildPreferenceTile(
                title: 'General Campus Notifications',
                subtitle: 'Library reminders, campus club updates, and scheduled maintenance notices.',
                icon: LucideIcons.bell,
                value: _generalNotifications,
                onChanged: (val) => setState(() => _generalNotifications = val),
              ),
              const SizedBox(height: 32),

              // Save Action
              SizedBox(
                width: double.infinity,
                child: AcadexButton(
                  label: _isSaving ? 'Saving Preferences...' : 'Save Preferences',
                  icon: LucideIcons.save,
                  isLoading: _isSaving,
                  onPressed: _savePreferences,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPreferenceTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AcadexColors.primary.withValues(alpha: 0.1),
              borderRadius: AcadexRadius.borderRadiusSm,
            ),
            child: Icon(icon, color: AcadexColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AcadexTypography.body(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AcadexTypography.caption(
                    color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            activeColor: AcadexColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    try {
      final updated = NotificationPreferences(
        attendanceAlerts: _attendanceAlerts,
        academicUpdates: _academicUpdates,
        announcements: _announcements,
        notesUploaded: _notesUploaded,
        certificateUpdates: _certificateUpdates,
        generalNotifications: _generalNotifications,
      );

      await ref.read(notificationPreferencesProvider.notifier).updatePreferences(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification preferences saved successfully'),
            backgroundColor: AcadexColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: $e'),
            backgroundColor: AcadexColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
