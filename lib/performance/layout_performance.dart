import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../responsive/breakpoints.dart';
import '../theme/app_theme.dart';

/// Model for a single rebuild event
class RebuildEvent {
  final String widgetName;
  final double rebuildDurationMs;
  final DateTime timestamp;
  final String breakpoint;

  const RebuildEvent({
    required this.widgetName,
    required this.rebuildDurationMs,
    required this.timestamp,
    required this.breakpoint,
  });

  Map<String, dynamic> toJson() {
    return {
      'widgetName': widgetName,
      'rebuildDuration_ms': rebuildDurationMs,
      'timestamp': timestamp.toIso8601String(),
      'breakpoint': breakpoint,
    };
  }

  factory RebuildEvent.fromJson(Map<String, dynamic> json) {
    return RebuildEvent(
      widgetName: json['widgetName'] as String,
      rebuildDurationMs: (json['rebuildDuration_ms'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      breakpoint: json['breakpoint'] as String,
    );
  }
}

/// Manager for performance monitoring and logging
class LayoutPerformanceMonitor {
  static final LayoutPerformanceMonitor _instance = LayoutPerformanceMonitor._internal();
  factory LayoutPerformanceMonitor() => _instance;
  LayoutPerformanceMonitor._internal();

  static const String _logFileName = 'layout_performance.json';
  final List<RebuildEvent> _rebuilds = [];
  final Map<String, Stopwatch> _activeTimers = {};

  List<RebuildEvent> get rebuilds => List.unmodifiable(_rebuilds);

  /// Starts timing a widget rebuild
  void startRebuild(String widgetName) {
    _activeTimers[widgetName] = Stopwatch()..start();
  }

  /// Ends timing a widget rebuild and logs the event
  Future<void> endRebuild(String widgetName, Breakpoint breakpoint) async {
    final timer = _activeTimers.remove(widgetName);
    if (timer != null) {
      timer.stop();
      final event = RebuildEvent(
        widgetName: widgetName,
        rebuildDurationMs: timer.elapsedMicroseconds / 1000.0,
        timestamp: DateTime.now(),
        breakpoint: breakpoint.name,
      );
      _rebuilds.add(event);
      await _saveToFile();
    }
  }

  /// Logs a rebuild event directly
  Future<void> logRebuild(RebuildEvent event) async {
    _rebuilds.add(event);
    await _saveToFile();
  }

  /// Measures the duration of a build operation
  Future<T> measureBuild<T>(
    String widgetName,
    Breakpoint breakpoint,
    Future<T> Function() buildOperation,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await buildOperation();
      stopwatch.stop();
      
      final event = RebuildEvent(
        widgetName: widgetName,
        rebuildDurationMs: stopwatch.elapsedMicroseconds / 1000.0,
        timestamp: DateTime.now(),
        breakpoint: breakpoint.name,
      );
      _rebuilds.add(event);
      await _saveToFile();
      
      return result;
    } finally {
      if (stopwatch.isRunning) {
        stopwatch.stop();
      }
    }
  }

  /// Measures synchronous build operations
  T measureBuildSync<T>(
    String widgetName,
    Breakpoint breakpoint,
    T Function() buildOperation,
  ) {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = buildOperation();
      stopwatch.stop();
      
      final event = RebuildEvent(
        widgetName: widgetName,
        rebuildDurationMs: stopwatch.elapsedMicroseconds / 1000.0,
        timestamp: DateTime.now(),
        breakpoint: breakpoint.name,
      );
      _rebuilds.add(event);
      _saveToFile();
      
      return result;
    } finally {
      if (stopwatch.isRunning) {
        stopwatch.stop();
      }
    }
  }

  /// Saves all rebuild events to file
  Future<void> _saveToFile() async {
    if (kIsWeb) return;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_logFileName');
      
      final data = {
        'rebuilds': _rebuilds.map((r) => r.toJson()).toList(),
      };
      
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving performance log: $e');
    }
  }

  /// Clears all rebuild events
  Future<void> clearRebuilds() async {
    _rebuilds.clear();
    if (kIsWeb) return;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_logFileName');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error clearing performance log: $e');
    }
  }

  /// Gets the path to the log file
  Future<String> getLogFilePath() async {
    if (kIsWeb) return '(not available on web)';
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_logFileName';
  }

  /// Gets performance statistics
  Map<String, dynamic> getStatistics() {
    if (_rebuilds.isEmpty) {
      return {
        'totalRebuilds': 0,
        'averageDuration': 0.0,
        'maxDuration': 0.0,
        'minDuration': 0.0,
      };
    }

    final durations = _rebuilds.map((r) => r.rebuildDurationMs).toList();
    final total = durations.reduce((a, b) => a + b);
    
    return {
      'totalRebuilds': _rebuilds.length,
      'averageDuration': total / _rebuilds.length,
      'maxDuration': durations.reduce((a, b) => a > b ? a : b),
      'minDuration': durations.reduce((a, b) => a < b ? a : b),
    };
  }
}

/// A widget wrapper that monitors rebuild performance
class PerformanceMonitoredWidget extends StatefulWidget {
  final Widget child;
  final String widgetName;

  const PerformanceMonitoredWidget({
    super.key,
    required this.child,
    required this.widgetName,
  });

  @override
  State<PerformanceMonitoredWidget> createState() => _PerformanceMonitoredWidgetState();
}

class _PerformanceMonitoredWidgetState extends State<PerformanceMonitoredWidget> {
  final LayoutPerformanceMonitor _monitor = LayoutPerformanceMonitor();

  @override
  Widget build(BuildContext context) {
    final stopwatch = Stopwatch()..start();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = MediaQuery.of(context).size.width;
        final currentBreakpoint = BreakpointUtils.getBreakpoint(width);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!stopwatch.isRunning) {
            return;
          }
          stopwatch.stop();
          _monitor.logRebuild(
            RebuildEvent(
              widgetName: widget.widgetName,
              rebuildDurationMs: stopwatch.elapsedMicroseconds / 1000.0,
              timestamp: DateTime.now(),
              breakpoint: currentBreakpoint.name,
            ),
          );
        });

        return widget.child;
      },
    );
  }
}

/// Demo widget for displaying performance metrics
class PerformanceMonitorDemo extends StatefulWidget {
  const PerformanceMonitorDemo({super.key});

  @override
  State<PerformanceMonitorDemo> createState() => _PerformanceMonitorDemoState();
}

class _PerformanceMonitorDemoState extends State<PerformanceMonitorDemo> {
  final LayoutPerformanceMonitor _monitor = LayoutPerformanceMonitor();
  int _rebuildCount = 0;

  @override
  void initState() {
    super.initState();
    _simulateInitialRebuild();
  }

  Future<void> _simulateInitialRebuild() async {
    // Simulate an initial rebuild log entry
    final breakpoint = BreakpointUtils.getBreakpoint(
      WidgetsBinding.instance.platformDispatcher.views.first.physicalSize.width /
      WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio
    );
    
    await _monitor.logRebuild(RebuildEvent(
      widgetName: 'PerformanceMonitorDemo',
      rebuildDurationMs: 1.5,
      timestamp: DateTime.now(),
      breakpoint: breakpoint.name,
    ));
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _monitor.getStatistics();
    final breakpoint = context.breakpoint;
    final theme = Theme.of(context);

    return PerformanceMonitoredWidget(
      widgetName: 'PerformanceMonitorDemo',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Monitor',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Track rebuild timing, clear logs, and inspect recent activity from a single control surface.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _buildStatCard('Total Rebuilds', '${stats['totalRebuilds']}'),
            _buildStatCard('Average Duration', 
              '${(stats['averageDuration'] as double).toStringAsFixed(3)} ms'),
            _buildStatCard('Max Duration', 
              '${(stats['maxDuration'] as double).toStringAsFixed(3)} ms'),
            _buildStatCard('Min Duration', 
              '${(stats['minDuration'] as double).toStringAsFixed(3)} ms'),
            _buildStatCard('Current Breakpoint', breakpoint.label),
            const SizedBox(height: 24),
            Text(
              'Simulate Rebuilds',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    setState(() => _rebuildCount++);
                    await _monitor.logRebuild(RebuildEvent(
                      widgetName: 'SimulatedWidget_$_rebuildCount',
                      rebuildDurationMs: 0.5 + (_rebuildCount % 5) * 0.3,
                      timestamp: DateTime.now(),
                      breakpoint: breakpoint.name,
                    ));
                    if (mounted) setState(() {});
                  },
                  child: const Text('Simulate Rebuild'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _monitor.clearRebuilds();
                    setState(() => _rebuildCount = 0);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Performance log cleared')),
                      );
                    }
                  },
                  child: const Text('Clear Log'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final path = await _monitor.getLogFilePath();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Log: $path')),
                      );
                    }
                  },
                  child: const Text('Show Path'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Recent Rebuilds',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ..._monitor.rebuilds.reversed.take(10).map((rebuild) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(rebuild.widgetName),
                subtitle: Text(
                  '${rebuild.rebuildDurationMs.toStringAsFixed(3)} ms • ${rebuild.breakpoint}',
                ),
                trailing: Text(
                  '${rebuild.timestamp.hour}:${rebuild.timestamp.minute.toString().padLeft(2, '0')}:${rebuild.timestamp.second.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    final theme = Theme.of(context);
    final colors = context.appThemeColors;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.titleMedium),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
