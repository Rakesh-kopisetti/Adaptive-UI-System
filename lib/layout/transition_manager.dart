import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../responsive/breakpoints.dart';
import '../theme/app_theme.dart';

/// Represents a single layout transition event
class TransitionEvent {
  final DateTime timestamp;
  final Breakpoint fromBreakpoint;
  final Breakpoint toBreakpoint;
  final int durationMs;

  const TransitionEvent({
    required this.timestamp,
    required this.fromBreakpoint,
    required this.toBreakpoint,
    required this.durationMs,
  });

  String toLogFormat() {
    return '[${timestamp.toIso8601String()}] ${fromBreakpoint.name} ${toBreakpoint.name} $durationMs';
  }
}

/// Manager for handling and logging layout transitions
class TransitionManager {
  static final TransitionManager _instance = TransitionManager._internal();
  factory TransitionManager() => _instance;
  TransitionManager._internal();

  static const String _logFileName = 'layout_transitions.log';
  
  final List<TransitionEvent> _transitions = [];
  DateTime? _transitionStartTime;
  Breakpoint? _previousBreakpoint;

  List<TransitionEvent> get transitions => List.unmodifiable(_transitions);

  /// Starts tracking a potential transition
  void startTransition(Breakpoint currentBreakpoint) {
    _transitionStartTime = DateTime.now();
    _previousBreakpoint = currentBreakpoint;
  }

  /// Completes a transition if one was in progress
  Future<void> completeTransition(Breakpoint newBreakpoint) async {
    if (_transitionStartTime != null && 
        _previousBreakpoint != null &&
        _previousBreakpoint != newBreakpoint) {
      
      final duration = DateTime.now().difference(_transitionStartTime!).inMilliseconds;
      
      final event = TransitionEvent(
        timestamp: DateTime.now(),
        fromBreakpoint: _previousBreakpoint!,
        toBreakpoint: newBreakpoint,
        durationMs: duration,
      );
      
      _transitions.add(event);
      await _logTransition(event);
    }
    
    _transitionStartTime = null;
    _previousBreakpoint = newBreakpoint;
  }

  /// Logs a single transition immediately
  Future<void> logTransition(Breakpoint from, Breakpoint to, int durationMs) async {
    final event = TransitionEvent(
      timestamp: DateTime.now(),
      fromBreakpoint: from,
      toBreakpoint: to,
      durationMs: durationMs,
    );
    
    _transitions.add(event);
    await _logTransition(event);
  }

  /// Writes a transition event to the log file
  Future<void> _logTransition(TransitionEvent event) async {
    if (kIsWeb) return;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_logFileName');
      
      await file.writeAsString(
        '${event.toLogFormat()}\n',
        mode: FileMode.append,
      );
    } catch (e) {
      debugPrint('Error logging transition: $e');
    }
  }

  /// Clears all logged transitions
  Future<void> clearTransitions() async {
    _transitions.clear();
    if (kIsWeb) return;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_logFileName');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error clearing transitions: $e');
    }
  }

  /// Exports the transition log file path
  Future<String> getLogFilePath() async {
    if (kIsWeb) return '(not available on web)';
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_logFileName';
  }
}

/// Widget that animates between different layouts
class LayoutTransitionWrapper extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const LayoutTransitionWrapper({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  @override
  State<LayoutTransitionWrapper> createState() => _LayoutTransitionWrapperState();
}

class _LayoutTransitionWrapperState extends State<LayoutTransitionWrapper> {
  final TransitionManager _transitionManager = TransitionManager();
  Breakpoint? _lastBreakpoint;
  DateTime? _transitionStartTime;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = MediaQuery.of(context).size.width;
        final currentBreakpoint = BreakpointUtils.getBreakpoint(width);
        
        if (_lastBreakpoint != null && _lastBreakpoint != currentBreakpoint) {
          // Transition detected
          final startTime = _transitionStartTime ?? DateTime.now();
          final duration = DateTime.now().difference(startTime).inMilliseconds;
          
          _transitionManager.logTransition(
            _lastBreakpoint!,
            currentBreakpoint,
            duration > 0 ? duration : widget.duration.inMilliseconds,
          );
        }
        
        _lastBreakpoint = currentBreakpoint;
        _transitionStartTime = DateTime.now();
        
        return AnimatedSwitcher(
          duration: widget.duration,
          switchInCurve: widget.curve,
          switchOutCurve: widget.curve,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: KeyedSubtree(
            key: ValueKey(currentBreakpoint),
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Widget for demonstrating layout transitions
class LayoutTransitionDemo extends StatelessWidget {
  const LayoutTransitionDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutTransitionWrapper(
      duration: const Duration(milliseconds: 300),
      child: _buildLayoutForBreakpoint(context),
    );
  }

  Widget _buildLayoutForBreakpoint(BuildContext context) {
    final breakpoint = context.breakpoint;
    
    switch (breakpoint) {
      case Breakpoint.compact:
        return _CompactLayout(key: const Key('compact-layout'));
      case Breakpoint.medium:
        return _MediumLayout(key: const Key('medium-layout'));
      case Breakpoint.expanded:
        return _ExpandedLayout(key: const Key('expanded-layout'));
    }
  }
}

class _CompactLayout extends StatelessWidget {
  const _CompactLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return _TransitionPreview(
      icon: Icons.phone_android_rounded,
      title: 'Compact Layout',
      description: 'Single-column prioritization for smaller screens.',
      accent: context.breakpoint.color,
    );
  }
}

class _MediumLayout extends StatelessWidget {
  const _MediumLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return _TransitionPreview(
      icon: Icons.tablet_android_rounded,
      title: 'Medium Layout',
      description: 'Balanced navigation and content density for tablet widths.',
      accent: context.breakpoint.color,
    );
  }
}

class _ExpandedLayout extends StatelessWidget {
  const _ExpandedLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return _TransitionPreview(
      icon: Icons.desktop_windows_rounded,
      title: 'Expanded Layout',
      description: 'Persistent navigation and generous workspace for large displays.',
      accent: context.breakpoint.color,
    );
  }
}

class _TransitionPreview extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accent;

  const _TransitionPreview({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appThemeColors;
    final theme = Theme.of(context);

    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: colors.surfaceSecondary,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 42, color: accent),
            ),
            const SizedBox(height: 20),
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 10),
            SizedBox(
              width: 320,
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
