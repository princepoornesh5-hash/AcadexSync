import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension SafeNavigationExtension on BuildContext {
  /// Safely pops the current screen if possible, falling back to a specified route or the root.
  /// Prevents `Bad state: There is nothing to pop` exceptions when deep-linking, refreshing,
  /// or navigating via `context.go()`.
  void safePop({String? fallbackRoute}) {
    if (canPop()) {
      pop();
    } else if (Navigator.of(this).canPop()) {
      Navigator.of(this).pop();
    } else if (fallbackRoute != null && fallbackRoute.isNotEmpty) {
      go(fallbackRoute);
    } else {
      go('/');
    }
  }
}
