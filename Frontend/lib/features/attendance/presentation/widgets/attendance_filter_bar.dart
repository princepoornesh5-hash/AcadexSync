import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

class AttendanceFilterBar extends StatelessWidget {
  final ValueChanged<String> onSearch;
  final VoidCallback onMarkAllPresent;
  
  const AttendanceFilterBar({
    super.key,
    required this.onSearch,
    required this.onMarkAllPresent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFFAFAFA),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by Name or Roll No...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: DashboardColors.primary)),
              ),
              onChanged: onSearch,
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text("Mark All Present"),
            onPressed: onMarkAllPresent,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green.shade700,
              side: BorderSide(color: Colors.green.shade700),
              backgroundColor: Colors.green.shade50,
            ),
          )
        ],
      ),
    );
  }
}
