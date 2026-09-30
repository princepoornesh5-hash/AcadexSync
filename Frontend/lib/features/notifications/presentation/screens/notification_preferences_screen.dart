import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../settings/domain/models/settings_models.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends ConsumerState<NotificationPreferencesScreen> {
  bool _inAppEnabled = true;
  bool _pushEnabled = true;
  bool _assignments = true;
  bool _practicals = true;
  bool _assessments = true;
  bool _calendar = true;
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/notifications'),
        ),
        title: Text(
          'Notification Settings',
          style: AcadexTypography.title(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
        backgroundColor: Colors.white,
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
            _inAppEnabled = prefs.inAppEnabled;
            _pushEnabled = prefs.pushEnabled;
            _assignments = prefs.assignments;
            _practicals = prefs.practicals;
            _assessments = prefs.assessments;
            _calendar = prefs.calendar;
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
                            'System & Official Academic Results',
                            style: AcadexTypography.body(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Critical security notifications, official academic result releases, and emergency broadcasts are mandatory and cannot be disabled.',
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

              // Delivery Channels Group
              Text(
                'Delivery Channels',
                style: AcadexTypography.heading3(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ),
              ),
              const SizedBox(height: 12),

              _buildPreferenceTile(
                title: 'In-App Notifications',
                subtitle: 'Receive alerts in the ACADEX Notification Center.',
                icon: LucideIcons.bell,
                value: _inAppEnabled,
                onChanged: (val) => setState(() => _inAppEnabled = val),
              ),
              const SizedBox(height: 10),

              _buildPreferenceTile(
                title: 'Push Notifications (FCM)',
                subtitle: 'Receive background push banners when ACADEX is closed.',
                icon: LucideIcons.smartphone,
                value: _pushEnabled,
                onChanged: (val) => setState(() => _pushEnabled = val),
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
                title: 'Assignments & Tasks',
                subtitle: 'New homework, due date reminders, and grading notices.',
                icon: LucideIcons.bookMarked,
                value: _assignments,
                onChanged: (val) => setState(() => _assignments = val),
              ),
              const SizedBox(height: 10),

              _buildPreferenceTile(
                title: 'Practical Lab Sessions',
                subtitle: 'Lab scheduling, rescheduling, and session completion notices.',
                icon: LucideIcons.flaskConical,
                value: _practicals,
                onChanged: (val) => setState(() => _practicals = val),
              ),
              const SizedBox(height: 10),

              _buildPreferenceTile(
                title: 'Assessments & Internal Tests',
                subtitle: 'Test schedules, syllabus updates, and internal mark releases.',
                icon: LucideIcons.clipboardCheck,
                value: _assessments,
                onChanged: (val) => setState(() => _assessments = val),
              ),
              const SizedBox(height: 10),

              _buildPreferenceTile(
                title: 'Academic Calendar & Holidays',
                subtitle: 'Declared holidays, term dates, and calendar event updates.',
                icon: LucideIcons.calendar,
                value: _calendar,
                onChanged: (val) => setState(() => _calendar = val),
              ),
              const SizedBox(height: 10),

              _buildPreferenceTile(
                title: 'Attendance Alerts',
                subtitle: 'Low attendance warnings, drop threshold notices, and daily logs.',
                icon: LucideIcons.calendarCheck,
                value: _attendanceAlerts,
                onChanged: (val) => setState(() => _attendanceAlerts = val),
              ),
              const SizedBox(height: 10),

              _buildPreferenceTile(
                title: 'Study Notes & Materials',
                subtitle: 'New study guides, chapter PDFs, and lecture slides.',
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
                subtitle: 'Status updates on digital diploma requests and verified certificates.',
                icon: LucideIcons.award,
                value: _certificateUpdates,
                onChanged: (val) => setState(() => _certificateUpdates = val),
              ),
              const SizedBox(height: 10),

              _buildPreferenceTile(
                title: 'General Campus Notifications',
                subtitle: 'Library reminders, campus club updates, and scheduled maintenance notices.',
                icon: LucideIcons.bellRing,
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
        inAppEnabled: _inAppEnabled,
        pushEnabled: _pushEnabled,
        attendanceAlerts: _attendanceAlerts,
        academicUpdates: _academicUpdates,
        assignments: _assignments,
        practicals: _practicals,
        assessments: _assessments,
        calendar: _calendar,
        announcements: _announcements,
        notesUploaded: _notesUploaded,
        certificateUpdates: _certificateUpdates,
        generalNotifications: _generalNotifications,
      );

      await ref.read(notificationPreferencesProvider.notifier).updatePreferences(updated);

      if (mounted) {
        AcadexSnackBar.showSuccess(
          context,
          'Notification preferences saved successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        AcadexSnackBar.showError(
          context,
          e,
          fallbackMessage: 'Failed to save preferences',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
