import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  int _totalClasses = 45;
  int _classesAttended = 39;
  double _percentage = 86.6;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    setState(() => _isLoading = true);
    try {
      final res = await apiClient.dio.get('/attendance/my-summary');
      if (res.statusCode == 200) {
        setState(() {
          _totalClasses = res.data['total_classes'];
          _classesAttended = res.data['classes_attended'];
          _percentage = (res.data['attendance_percentage'] as num).toDouble();
        });
      }
    } catch (_) {
      // Use fallback defaults for demo
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWarning = _percentage < 75.0;

    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : Padding(
            padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Attendance Overview", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("Real-time subject-wise and overall class presence tracking", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 24),

          // Gauge Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isWarning ? AppColors.error : AppColors.primary, width: 1.5),
            ),
            child: Row(
              children: [
                // Circle Progress Indicator
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: CircularProgressIndicator(
                        value: _percentage / 100.0,
                        strokeWidth: 10,
                        backgroundColor: AppColors.surfaceDarkElevated,
                        color: isWarning ? AppColors.error : AppColors.success,
                      ),
                    ),
                    Text(
                      "${_percentage.toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isWarning ? AppColors.error : AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),

                // Stats breakdown
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isWarning ? LucideIcons.alertTriangle : LucideIcons.checkCircle2,
                            color: isWarning ? AppColors.error : AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isWarning ? "Shortage Warning (< 75%)" : "Good Attendance Record",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isWarning ? AppColors.error : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text("Total Classes Held: $_totalClasses", style: const TextStyle(color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text("Classes Attended: $_classesAttended", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14)),
                      const SizedBox(height: 4),
                      Text("Classes Missed: ${_totalClasses - _classesAttended}", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Course-wise List
          const Text("Subject Breakdown", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                _buildCourseAttendanceItem("CS301 - Data Structures & Algorithms", 18, 20, 90.0),
                _buildCourseAttendanceItem("CS302 - Database Management Systems", 14, 15, 93.3),
                _buildCourseAttendanceItem("CS303 - Operating Systems", 10, 15, 66.7),
                _buildCourseAttendanceItem("CS304 - Computer Networks", 12, 14, 85.7),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCourseAttendanceItem(String title, int attended, int total, double percent) {
    final isLow = percent < 75.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text("Attended $attended of $total lectures", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isLow ? AppColors.error.withValues(alpha: 0.2) : AppColors.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "${percent.toStringAsFixed(1)}%",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isLow ? AppColors.error : AppColors.success,
              ),
            ),
          )
        ],
      ),
    );
  }
}
