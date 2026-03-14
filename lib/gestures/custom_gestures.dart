import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../theme/app_theme.dart';

/// Model for a single gesture event
class GestureEvent {
  final String type;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const GestureEvent({
    required this.type,
    required this.timestamp,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory GestureEvent.fromJson(Map<String, dynamic> json) {
    return GestureEvent(
      type: json['type'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
    );
  }
}

/// Manager for logging gesture events
class GestureLogger {
  static final GestureLogger _instance = GestureLogger._internal();
  factory GestureLogger() => _instance;
  GestureLogger._internal();

  static const String _logFileName = 'gesture_log.json';
  final List<GestureEvent> _gestures = [];

  List<GestureEvent> get gestures => List.unmodifiable(_gestures);

  /// Logs a gesture event
  Future<void> logGesture(GestureEvent event) async {
    _gestures.add(event);
    await _saveToFile();
  }

  /// Logs a swipe gesture
  Future<void> logSwipe({
    required Offset startPosition,
    required Offset endPosition,
    required Offset velocity,
    String? direction,
  }) async {
    final calculatedDirection = direction ?? _calculateSwipeDirection(startPosition, endPosition);
    await logGesture(GestureEvent(
      type: 'swipe',
      timestamp: DateTime.now(),
      metadata: {
        'startPosition': {'x': startPosition.dx, 'y': startPosition.dy},
        'endPosition': {'x': endPosition.dx, 'y': endPosition.dy},
        'velocity': {'x': velocity.dx, 'y': velocity.dy},
        'direction': calculatedDirection,
      },
    ));
  }

  /// Logs a pinch-to-zoom gesture
  Future<void> logPinchToZoom({
    required double scale,
    required Offset focalPoint,
    double? startScale,
    double? endScale,
  }) async {
    await logGesture(GestureEvent(
      type: 'pinch-to-zoom',
      timestamp: DateTime.now(),
      metadata: {
        'scale': scale,
        'focalPoint': {'x': focalPoint.dx, 'y': focalPoint.dy},
        'startScale': startScale ?? 1.0,
        'endScale': endScale ?? scale,
      },
    ));
  }

  /// Logs a two-finger tap gesture
  Future<void> logTwoFingerTap({
    required Offset position,
  }) async {
    await logGesture(GestureEvent(
      type: 'two-finger-tap',
      timestamp: DateTime.now(),
      metadata: {
        'position': {'x': position.dx, 'y': position.dy},
      },
    ));
  }

  String _calculateSwipeDirection(Offset start, Offset end) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;

    if (dx.abs() > dy.abs()) {
      return dx > 0 ? 'right' : 'left';
    } else {
      return dy > 0 ? 'down' : 'up';
    }
  }

  /// Saves all gestures to the log file
  Future<void> _saveToFile() async {
    if (kIsWeb) return; // dart:io File is not supported on web
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_logFileName');
      
      final data = {
        'gestures': _gestures.map((g) => g.toJson()).toList(),
      };
      
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving gesture log: $e');
    }
  }

  /// Clears all logged gestures
  Future<void> clearGestures() async {
    _gestures.clear();
    if (kIsWeb) return;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_logFileName');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error clearing gesture log: $e');
    }
  }

  /// Gets the path to the log file
  Future<String> getLogFilePath() async {
    if (kIsWeb) return '(not available on web)';
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_logFileName';
  }
}

/// Custom gesture recognizer for detecting various gestures
class CustomGestureDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final ValueChanged<double>? onPinchZoom;
  final VoidCallback? onTwoFingerTap;
  final bool enableLogging;

  const CustomGestureDetector({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.onSwipeDown,
    this.onPinchZoom,
    this.onTwoFingerTap,
    this.enableLogging = true,
  });

  @override
  State<CustomGestureDetector> createState() => _CustomGestureDetectorState();
}

class _CustomGestureDetectorState extends State<CustomGestureDetector> {
  final GestureLogger _logger = GestureLogger();

  Offset? _startFocalPoint;
  Offset _lastFocalPoint = Offset.zero;
  double _baseScale = 1.0;
  double _currentScale = 1.0;
  bool _isScaling = false;
  int _maxPointerCount = 0;

  @override
  Widget build(BuildContext context) {
    // onScale* is a superset of onPan* — using only onScale* handles both
    // single-finger drags (swipes) and multi-finger gestures (pinch, two-finger tap).
    return GestureDetector(
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: _onScaleEnd,
      child: widget.child,
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _startFocalPoint = details.localFocalPoint;
    _lastFocalPoint = details.localFocalPoint;
    _baseScale = _currentScale;
    _isScaling = false;
    _maxPointerCount = details.pointerCount;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    _lastFocalPoint = details.localFocalPoint;
    if (details.pointerCount > _maxPointerCount) {
      _maxPointerCount = details.pointerCount;
    }
    // Only mark as scaling when two+ fingers move with a significant scale change
    if (details.pointerCount >= 2 && (details.scale - 1.0).abs() > 0.05) {
      _isScaling = true;
      setState(() {
        _currentScale = (_baseScale * details.scale).clamp(0.5, 3.0);
      });
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_startFocalPoint == null) return;

    if (_isScaling) {
      _handlePinchZoom(_currentScale, _lastFocalPoint);
    } else if (_maxPointerCount >= 2) {
      // Two fingers landed but no significant scale change → two-finger tap
      _handleTwoFingerTap(_lastFocalPoint);
    } else {
      // Single-finger drag → detect swipe from focal-point delta + velocity
      final velocity = details.velocity.pixelsPerSecond;
      _handleSwipe(_startFocalPoint!, _lastFocalPoint, velocity);
    }

    _startFocalPoint = null;
    _isScaling = false;
    _maxPointerCount = 0;
  }

  void _handleSwipe(Offset start, Offset end, Offset velocity) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    
    // Minimum distance for a swipe
    const minDistance = 50.0;
    
    if (dx.abs() < minDistance && dy.abs() < minDistance) {
      return;
    }

    String direction;
    
    if (dx.abs() > dy.abs()) {
      if (dx > 0) {
        direction = 'right';
        widget.onSwipeRight?.call();
      } else {
        direction = 'left';
        widget.onSwipeLeft?.call();
      }
    } else {
      if (dy > 0) {
        direction = 'down';
        widget.onSwipeDown?.call();
      } else {
        direction = 'up';
        widget.onSwipeUp?.call();
      }
    }

    if (widget.enableLogging) {
      _logger.logSwipe(
        startPosition: start,
        endPosition: end,
        velocity: velocity,
        direction: direction,
      );
    }
  }

  void _handlePinchZoom(double scale, Offset focalPoint) {
    widget.onPinchZoom?.call(scale);
    
    if (widget.enableLogging) {
      _logger.logPinchToZoom(
        scale: scale,
        focalPoint: focalPoint,
        startScale: _baseScale,
        endScale: scale,
      );
    }
  }

  void _handleTwoFingerTap(Offset position) {
    widget.onTwoFingerTap?.call();
    
    if (widget.enableLogging) {
      _logger.logTwoFingerTap(position: position);
    }
  }
}

/// Demo widget for showcasing gesture recognition
class GestureDemo extends StatefulWidget {
  const GestureDemo({super.key});

  @override
  State<GestureDemo> createState() => _GestureDemoState();
}

class _GestureDemoState extends State<GestureDemo> {
  String _lastGesture = 'None';
  double _scale = 1.0;
  final GestureLogger _logger = GestureLogger();

  Future<void> _simulateSwipe() async {
    await _logger.logSwipe(
      startPosition: const Offset(20, 20),
      endPosition: const Offset(180, 20),
      velocity: const Offset(800, 0),
      direction: 'right',
    );
    _updateGesture('Swipe Right');
  }

  Future<void> _simulatePinch() async {
    const scale = 1.4;
    await _logger.logPinchToZoom(
      scale: scale,
      focalPoint: const Offset(120, 160),
      startScale: 1.0,
      endScale: scale,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _scale = scale;
      _lastGesture = 'Pinch to Zoom: ${scale.toStringAsFixed(2)}x';
    });
  }

  Future<void> _simulateTwoFingerTap() async {
    await _logger.logTwoFingerTap(position: const Offset(120, 160));
    _updateGesture('Two Finger Tap');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appThemeColors;

    return Column(
      children: [
        Expanded(
          child: CustomGestureDetector(
            onSwipeLeft: () => _updateGesture('Swipe Left'),
            onSwipeRight: () => _updateGesture('Swipe Right'),
            onSwipeUp: () => _updateGesture('Swipe Up'),
            onSwipeDown: () => _updateGesture('Swipe Down'),
            onPinchZoom: (scale) {
              setState(() {
                _scale = scale;
                _lastGesture = 'Pinch to Zoom: ${scale.toStringAsFixed(2)}x';
              });
            },
            onTwoFingerTap: () => _updateGesture('Two Finger Tap'),
            enableLogging: true,
            child: Container(
              key: const Key('gesture-demo-area'),
              margin: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colors.surfaceSecondary, colors.backgroundAccent],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Transform.scale(
                    scale: _scale,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 132,
                          height: 132,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [colors.heroStart, colors.heroEnd],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(34),
                            boxShadow: [
                              BoxShadow(
                                color: colors.heroStart.withOpacity(0.18),
                                blurRadius: 28,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.touch_app_rounded,
                            size: 72,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Gesture Demo Area',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Last Gesture: $_lastGesture',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Scale: ${_scale.toStringAsFixed(2)}x',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.78),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: colors.borderSubtle),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Try these gestures',
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Swipe in any direction • Pinch to zoom • Two finger tap',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _scale = 1.0;
                    _lastGesture = 'None';
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await _logger.clearGestures();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gesture log cleared')),
                    );
                  }
                },
                icon: const Icon(Icons.delete),
                label: const Text('Clear Log'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final path = await _logger.getLogFilePath();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Log: $path')),
                    );
                  }
                },
                icon: const Icon(Icons.folder),
                label: const Text('Show Path'),
              ),
              ElevatedButton.icon(
                key: const Key('simulate-swipe-button'),
                onPressed: _simulateSwipe,
                icon: const Icon(Icons.swipe),
                label: const Text('Simulate Swipe'),
              ),
              ElevatedButton.icon(
                key: const Key('simulate-pinch-button'),
                onPressed: _simulatePinch,
                icon: const Icon(Icons.zoom_out_map),
                label: const Text('Simulate Pinch'),
              ),
              ElevatedButton.icon(
                key: const Key('simulate-two-finger-tap-button'),
                onPressed: _simulateTwoFingerTap,
                icon: const Icon(Icons.pan_tool_alt),
                label: const Text('Simulate Two-Finger Tap'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _updateGesture(String gesture) {
    setState(() {
      _lastGesture = gesture;
    });
  }
}
