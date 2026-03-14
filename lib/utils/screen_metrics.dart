import 'dart:convert';
import 'dart:io' show File, Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Model for screen metrics
class ScreenMetrics {
  final double screenWidth;
  final double screenHeight;
  final double pixelDensity;
  final double textScaleFactor;
  final String orientation;
  final String platform;
  final String platformVersion;

  const ScreenMetrics({
    required this.screenWidth,
    required this.screenHeight,
    required this.pixelDensity,
    required this.textScaleFactor,
    required this.orientation,
    required this.platform,
    required this.platformVersion,
  });

  Map<String, dynamic> toJson() {
    return {
      'screenWidth': screenWidth,
      'screenHeight': screenHeight,
      'pixelDensity': pixelDensity,
      'textScaleFactor': textScaleFactor,
      'orientation': orientation,
      'platform': platform,
      'platformVersion': platformVersion,
    };
  }

  factory ScreenMetrics.fromJson(Map<String, dynamic> json) {
    return ScreenMetrics(
      screenWidth: (json['screenWidth'] as num).toDouble(),
      screenHeight: (json['screenHeight'] as num).toDouble(),
      pixelDensity: (json['pixelDensity'] as num).toDouble(),
      textScaleFactor: (json['textScaleFactor'] as num).toDouble(),
      orientation: json['orientation'] as String,
      platform: json['platform'] as String,
      platformVersion: json['platformVersion'] as String,
    );
  }

  factory ScreenMetrics.fromContext(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    
    return ScreenMetrics(
      screenWidth: size.width,
      screenHeight: size.height,
      pixelDensity: mediaQuery.devicePixelRatio,
      textScaleFactor: mediaQuery.textScaler.scale(1.0),
      orientation: size.width > size.height ? 'landscape' : 'portrait',
      platform: _getPlatformName(),
      platformVersion: _getPlatformVersion(),
    );
  }

  static String _getPlatformName() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  static String _getPlatformVersion() {
    if (kIsWeb) return 'web';
    return Platform.operatingSystemVersion;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScreenMetrics &&
        other.screenWidth == screenWidth &&
        other.screenHeight == screenHeight &&
        other.pixelDensity == pixelDensity &&
        other.textScaleFactor == textScaleFactor &&
        other.orientation == orientation;
  }

  @override
  int get hashCode {
    return Object.hash(
      screenWidth,
      screenHeight,
      pixelDensity,
      textScaleFactor,
      orientation,
    );
  }
}

/// Manager for tracking and exporting screen metrics
class ScreenMetricsTracker {
  static final ScreenMetricsTracker _instance = ScreenMetricsTracker._internal();
  factory ScreenMetricsTracker() => _instance;
  ScreenMetricsTracker._internal();

  static const String _metricsFileName = 'screen_metrics.json';
  ScreenMetrics? _lastMetrics;

  ScreenMetrics? get lastMetrics => _lastMetrics;

  /// Updates metrics if they have changed
  Future<void> updateMetrics(BuildContext context) async {
    final newMetrics = ScreenMetrics.fromContext(context);
    
    if (_lastMetrics != newMetrics) {
      _lastMetrics = newMetrics;
      await _saveMetrics(newMetrics);
    }
  }

  /// Forces a metrics update regardless of changes
  Future<void> forceUpdateMetrics(BuildContext context) async {
    final newMetrics = ScreenMetrics.fromContext(context);
    _lastMetrics = newMetrics;
    await _saveMetrics(newMetrics);
  }

  /// Saves metrics to file
  Future<void> _saveMetrics(ScreenMetrics metrics) async {
    if (kIsWeb) return;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_metricsFileName');
      await file.writeAsString(jsonEncode(metrics.toJson()));
    } catch (e) {
      debugPrint('Error saving screen metrics: $e');
    }
  }

  /// Loads saved metrics from file
  Future<ScreenMetrics?> loadMetrics() async {
    if (kIsWeb) return null;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_metricsFileName');
      
      if (await file.exists()) {
        final contents = await file.readAsString();
        return ScreenMetrics.fromJson(jsonDecode(contents));
      }
    } catch (e) {
      debugPrint('Error loading screen metrics: $e');
    }
    return null;
  }

  /// Gets the path to the metrics file
  Future<String> getMetricsFilePath() async {
    if (kIsWeb) return '(not available on web)';
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_metricsFileName';
  }
}

/// Widget that tracks screen metrics on configuration changes
class ScreenMetricsWrapper extends StatefulWidget {
  final Widget child;

  const ScreenMetricsWrapper({
    super.key,
    required this.child,
  });

  @override
  State<ScreenMetricsWrapper> createState() => _ScreenMetricsWrapperState();
}

class _ScreenMetricsWrapperState extends State<ScreenMetricsWrapper> with WidgetsBindingObserver {
  final ScreenMetricsTracker _tracker = ScreenMetricsTracker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tracker.forceUpdateMetrics(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _tracker.updateMetrics(context);
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Update metrics when layout changes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _tracker.updateMetrics(context);
          });
          return widget.child;
        },
      ),
    );
  }
}

/// Demo widget for displaying screen metrics
class ScreenMetricsDemo extends StatefulWidget {
  const ScreenMetricsDemo({super.key});

  @override
  State<ScreenMetricsDemo> createState() => _ScreenMetricsDemoState();
}

class _ScreenMetricsDemoState extends State<ScreenMetricsDemo> {
  final ScreenMetricsTracker _tracker = ScreenMetricsTracker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tracker.forceUpdateMetrics(context);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ScreenMetrics.fromContext(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Screen Metrics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildMetricCard('Screen Size', 
            '${metrics.screenWidth.toStringAsFixed(1)} x ${metrics.screenHeight.toStringAsFixed(1)}'),
          _buildMetricCard('Pixel Density', 
            '${metrics.pixelDensity.toStringAsFixed(2)}x'),
          _buildMetricCard('Text Scale Factor', 
            metrics.textScaleFactor.toStringAsFixed(2)),
          _buildMetricCard('Orientation', metrics.orientation),
          _buildMetricCard('Platform', metrics.platform),
          _buildMetricCard('Platform Version', metrics.platformVersion),
          const SizedBox(height: 24),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await _tracker.forceUpdateMetrics(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Metrics exported')),
                    );
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Export Metrics'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final path = await _tracker.getMetricsFilePath();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('File: $path')),
                    );
                  }
                },
                icon: const Icon(Icons.folder),
                label: const Text('Show Path'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
