import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../responsive/breakpoints.dart';
import '../theme/app_theme.dart';

/// Adaptive grid layout that adjusts columns based on breakpoint
class AdaptiveGrid extends StatefulWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final double? aspectRatio;
  final EdgeInsetsGeometry padding;

  const AdaptiveGrid({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.aspectRatio,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  State<AdaptiveGrid> createState() => _AdaptiveGridState();
}

class _AdaptiveGridState extends State<AdaptiveGrid> {
  static const String _aspectRatioKey = 'grid_aspect_ratio';
  double _aspectRatio = 1.0;

  @override
  void initState() {
    super.initState();
    _loadAspectRatio();
  }

  Future<void> _loadAspectRatio() async {
    if (widget.aspectRatio != null) {
      setState(() {
        _aspectRatio = widget.aspectRatio!;
      });
      return;
    }
    
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _aspectRatio = prefs.getDouble(_aspectRatioKey) ?? 1.0;
    });
  }

  Future<void> _saveAspectRatio(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_aspectRatioKey, value);
    setState(() {
      _aspectRatio = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = MediaQuery.of(context).size.width;
        final breakpoint = BreakpointUtils.getBreakpoint(width);
        final columns = breakpoint.columns;

        return Column(
          children: [
            // Aspect ratio control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Aspect Ratio',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Expanded(
                    child: Slider(
                      value: _aspectRatio,
                      min: 0.5,
                      max: 2.0,
                      onChanged: _saveAspectRatio,
                    ),
                  ),
                  Text(
                    _aspectRatio.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: context.appThemeColors.info,
                    ),
                  ),
                ],
              ),
            ),
            // Grid
            Expanded(
              child: Padding(
                padding: widget.padding,
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: widget.spacing,
                    mainAxisSpacing: widget.runSpacing,
                    childAspectRatio: _aspectRatio,
                  ),
                  itemCount: widget.children.length,
                  itemBuilder: (context, index) {
                    return KeyedSubtree(
                      key: Key('grid-item-$index'),
                      child: widget.children[index],
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A simple grid item widget for demonstration
class AdaptiveGridItem extends StatelessWidget {
  final int index;
  final Color? color;
  final String? label;

  const AdaptiveGridItem({
    super.key,
    required this.index,
    this.color,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF17324D),
      const Color(0xFF1C4E6E),
      const Color(0xFF245A9B),
      const Color(0xFF2E6F95),
      const Color(0xFF355C7D),
      const Color(0xFF1F7A5A),
      const Color(0xFF3A506B),
      const Color(0xFF476A86),
    ];
    final tileColor = color ?? colors[index % colors.length];
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tileColor, tileColor.withOpacity(0.82)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: tileColor.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Module ${index + 1}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
            Text(
              label ?? 'Adaptive Item ${index + 1}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Index: $index',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.78),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Demo widget showcasing the adaptive grid
class AdaptiveGridDemo extends StatelessWidget {
  const AdaptiveGridDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveGrid(
      children: List.generate(
        12,
        (index) => AdaptiveGridItem(index: index),
      ),
    );
  }
}
