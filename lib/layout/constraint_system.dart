import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Constraint types for the constraint layout system
enum ConstraintType {
  centerX,
  centerY,
  topToTopOf,
  bottomToBottomOf,
  leftToRightOf,
  rightToLeftOf,
}

/// Extension to parse constraint from string
extension ConstraintTypeExtension on ConstraintType {
  static ConstraintType fromString(String value) {
    switch (value) {
      case 'centerX':
        return ConstraintType.centerX;
      case 'centerY':
        return ConstraintType.centerY;
      case 'topToTopOf':
        return ConstraintType.topToTopOf;
      case 'bottomToBottomOf':
        return ConstraintType.bottomToBottomOf;
      case 'leftToRightOf':
        return ConstraintType.leftToRightOf;
      case 'rightToLeftOf':
        return ConstraintType.rightToLeftOf;
      default:
        throw ArgumentError('Unknown constraint type: $value');
    }
  }
}

/// Model representing a single constraint
class LayoutConstraint {
  final String widgetId;
  final ConstraintType constraint;
  final String targetId;
  final double margin;

  const LayoutConstraint({
    required this.widgetId,
    required this.constraint,
    required this.targetId,
    required this.margin,
  });

  factory LayoutConstraint.fromJson(Map<String, dynamic> json) {
    return LayoutConstraint(
      widgetId: json['widgetId'] as String,
      constraint: ConstraintTypeExtension.fromString(json['constraint'] as String),
      targetId: json['targetId'] as String,
      margin: (json['margin'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'widgetId': widgetId,
      'constraint': constraint.name,
      'targetId': targetId,
      'margin': margin,
    };
  }
}

/// Configuration model for the constraint layout system
class ConstraintConfig {
  final List<LayoutConstraint> constraints;

  const ConstraintConfig({required this.constraints});

  factory ConstraintConfig.fromJson(Map<String, dynamic> json) {
    final constraintsList = (json['constraints'] as List)
        .map((e) => LayoutConstraint.fromJson(e as Map<String, dynamic>))
        .toList();
    return ConstraintConfig(constraints: constraintsList);
  }

  Map<String, dynamic> toJson() {
    return {
      'constraints': constraints.map((c) => c.toJson()).toList(),
    };
  }

  /// Loads the constraint configuration from the assets
  static Future<ConstraintConfig> loadFromAssets() async {
    try {
      final jsonString = await rootBundle.loadString('assets/layout_constraints.json');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      return ConstraintConfig.fromJson(jsonData);
    } catch (e) {
      debugPrint('Error loading constraint config: $e');
      return const ConstraintConfig(constraints: []);
    }
  }
}

/// Constraint layout builder that positions widgets based on constraints
class ConstraintLayoutBuilder extends StatefulWidget {
  final Map<String, Widget> children;
  final ConstraintConfig? config;
  final String? configAssetPath;

  const ConstraintLayoutBuilder({
    super.key,
    required this.children,
    this.config,
    this.configAssetPath,
  });

  @override
  State<ConstraintLayoutBuilder> createState() => _ConstraintLayoutBuilderState();
}

class _ConstraintLayoutBuilderState extends State<ConstraintLayoutBuilder> {
  ConstraintConfig? _config;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    if (widget.config != null) {
      setState(() {
        _config = widget.config;
        _isLoading = false;
      });
    } else if (widget.configAssetPath != null) {
      try {
        final jsonString = await rootBundle.loadString(widget.configAssetPath!);
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        setState(() {
          _config = ConstraintConfig.fromJson(jsonData);
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _config = const ConstraintConfig(constraints: []);
          _isLoading = false;
        });
      }
    } else {
      _config = await ConstraintConfig.loadFromAssets();
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: _buildPositionedChildren(constraints),
        );
      },
    );
  }

  List<Widget> _buildPositionedChildren(BoxConstraints constraints) {
    final List<Widget> positionedChildren = [];
    final Map<String, Rect> resolvedPositions = {};

    // First pass: calculate positions for each widget based on constraints
    for (final entry in widget.children.entries) {
      final widgetId = entry.key;
      final child = entry.value;

      // Get all constraints for this widget
      final widgetConstraints = _config?.constraints
              .where((c) => c.widgetId == widgetId)
              .toList() ??
          [];

      if (widgetConstraints.isEmpty) {
        // No constraints, place at origin
        positionedChildren.add(
          Positioned(
            left: 0,
            top: 0,
            child: child,
          ),
        );
        continue;
      }

      // Resolve position based on constraints
      double? left;
      double? top;
      double? right;
      double? bottom;

      for (final constraint in widgetConstraints) {
        switch (constraint.constraint) {
          case ConstraintType.centerX:
            // Center horizontally
            left = null;
            right = null;
            break;
          case ConstraintType.centerY:
            // Center vertically
            top = null;
            bottom = null;
            break;
          case ConstraintType.topToTopOf:
            if (constraint.targetId == 'parent') {
              top = constraint.margin;
            } else if (resolvedPositions.containsKey(constraint.targetId)) {
              top = resolvedPositions[constraint.targetId]!.top + constraint.margin;
            }
            break;
          case ConstraintType.bottomToBottomOf:
            if (constraint.targetId == 'parent') {
              bottom = constraint.margin;
            } else if (resolvedPositions.containsKey(constraint.targetId)) {
              bottom = constraints.maxHeight -
                  resolvedPositions[constraint.targetId]!.bottom +
                  constraint.margin;
            }
            break;
          case ConstraintType.leftToRightOf:
            if (constraint.targetId == 'parent') {
              left = constraint.margin;
            } else if (resolvedPositions.containsKey(constraint.targetId)) {
              left = resolvedPositions[constraint.targetId]!.right + constraint.margin;
            }
            break;
          case ConstraintType.rightToLeftOf:
            if (constraint.targetId == 'parent') {
              right = constraint.margin;
            } else if (resolvedPositions.containsKey(constraint.targetId)) {
              right = constraints.maxWidth -
                  resolvedPositions[constraint.targetId]!.left +
                  constraint.margin;
            }
            break;
        }
      }

      // Check for centering constraints
      final hasCenterX = widgetConstraints.any((c) => c.constraint == ConstraintType.centerX);
      final hasCenterY = widgetConstraints.any((c) => c.constraint == ConstraintType.centerY);

      Widget positionedWidget;

      if (hasCenterX && hasCenterY) {
        positionedWidget = Positioned.fill(
          child: Center(child: child),
        );
      } else if (hasCenterX) {
        positionedWidget = Positioned(
          left: 0,
          right: 0,
          top: top,
          bottom: bottom,
          child: Center(child: child),
        );
      } else if (hasCenterY) {
        positionedWidget = Positioned(
          left: left,
          right: right,
          top: 0,
          bottom: 0,
          child: Center(child: child),
        );
      } else {
        positionedWidget = Positioned(
          left: left ?? 0,
          top: top ?? 0,
          right: right,
          bottom: bottom,
          child: child,
        );
      }

      positionedChildren.add(positionedWidget);

      // Store resolved position for dependent widgets
      resolvedPositions[widgetId] = Rect.fromLTWH(
        left ?? 0,
        top ?? 0,
        100, // Default size, actual size would need measurement
        100,
      );
    }

    return positionedChildren;
  }
}

/// Widget for demonstrating the constraint layout system
class ConstraintLayoutDemo extends StatelessWidget {
  const ConstraintLayoutDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appThemeColors;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.surfaceSecondary, colors.backgroundAccent],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: ConstraintLayoutBuilder(
        configAssetPath: 'assets/layout_constraints.json',
        children: {
          'header': Container(
            key: const Key('constraint-header'),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.info,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'Header Widget',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          'content': Container(
            key: const Key('constraint-content'),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.success,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Content Widget',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          'footer': Container(
            key: const Key('constraint-footer'),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.warning,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'Footer Widget',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        },
      ),
    );
  }
}
