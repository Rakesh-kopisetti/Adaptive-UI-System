import 'package:flutter/material.dart';

/// Enum representing the different screen size breakpoints
enum Breakpoint {
  compact,
  medium,
  expanded,
}

/// Extension on Breakpoint to get display properties
extension BreakpointExtension on Breakpoint {
  String get label {
    switch (this) {
      case Breakpoint.compact:
        return 'Compact';
      case Breakpoint.medium:
        return 'Medium';
      case Breakpoint.expanded:
        return 'Expanded';
    }
  }

  Color get color {
    switch (this) {
      case Breakpoint.compact:
        return const Color(0xFF245A9B);
      case Breakpoint.medium:
        return const Color(0xFF1F7A5A);
      case Breakpoint.expanded:
        return const Color(0xFF184E77);
    }
  }

  int get columns {
    switch (this) {
      case Breakpoint.compact:
        return 1;
      case Breakpoint.medium:
        return 2;
      case Breakpoint.expanded:
        return 3;
    }
  }

  double get typographyScale {
    switch (this) {
      case Breakpoint.compact:
        return 1.0;
      case Breakpoint.medium:
        return 1.15;
      case Breakpoint.expanded:
        return 1.3;
    }
  }
}

/// Utility class for breakpoint calculations
class BreakpointUtils {
  static const double compactMaxWidth = 599;
  static const double mediumMaxWidth = 839;

  /// Determines the current breakpoint based on screen width
  static Breakpoint getBreakpoint(double width) {
    if (width < 600) {
      return Breakpoint.compact;
    } else if (width < 840) {
      return Breakpoint.medium;
    } else {
      return Breakpoint.expanded;
    }
  }

  /// Returns true if the screen is compact
  static bool isCompact(double width) {
    return getBreakpoint(width) == Breakpoint.compact;
  }

  /// Returns true if the screen is medium
  static bool isMedium(double width) {
    return getBreakpoint(width) == Breakpoint.medium;
  }

  /// Returns true if the screen is expanded
  static bool isExpanded(double width) {
    return getBreakpoint(width) == Breakpoint.expanded;
  }
}

/// Extension on BuildContext for easy access to responsive values
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  
  Breakpoint get breakpoint => BreakpointUtils.getBreakpoint(screenWidth);
  
  bool get isCompact => breakpoint == Breakpoint.compact;
  bool get isMedium => breakpoint == Breakpoint.medium;
  bool get isExpanded => breakpoint == Breakpoint.expanded;
  
  int get gridColumns => breakpoint.columns;
  double get typographyScale => breakpoint.typographyScale;
}

/// Provider for managing breakpoint state
class BreakpointProvider extends ChangeNotifier {
  Breakpoint _currentBreakpoint = Breakpoint.compact;
  Breakpoint? _previousBreakpoint;
  DateTime? _lastTransitionTime;

  Breakpoint get currentBreakpoint => _currentBreakpoint;
  Breakpoint? get previousBreakpoint => _previousBreakpoint;
  DateTime? get lastTransitionTime => _lastTransitionTime;

  void updateBreakpoint(double width) {
    final newBreakpoint = BreakpointUtils.getBreakpoint(width);
    if (newBreakpoint != _currentBreakpoint) {
      _previousBreakpoint = _currentBreakpoint;
      _currentBreakpoint = newBreakpoint;
      _lastTransitionTime = DateTime.now();
      notifyListeners();
    }
  }
}

/// Widget that displays the current breakpoint indicator
class BreakpointIndicator extends StatelessWidget {
  const BreakpointIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = MediaQuery.of(context).size.width;
        final breakpoint = BreakpointUtils.getBreakpoint(width);
        
        return Material(
          color: Colors.transparent,
          child: Chip(
            key: const Key('breakpoint-indicator'),
            avatar: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            label: Text(
              breakpoint.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            backgroundColor: breakpoint.color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );
      },
    );
  }
}
