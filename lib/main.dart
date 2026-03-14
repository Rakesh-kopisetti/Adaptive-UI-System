import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'responsive/breakpoints.dart';
import 'navigation/adaptive_navigation.dart';
import 'layout/adaptive_grid.dart';
import 'layout/constraint_system.dart';
import 'layout/transition_manager.dart';
import 'theme/app_theme.dart';
import 'theme/adaptive_typography.dart';
import 'gestures/custom_gestures.dart';
import 'utils/screen_metrics.dart';
import 'performance/layout_performance.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AdaptiveUIApp());
}

class AdaptiveUIApp extends StatelessWidget {
  const AdaptiveUIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BreakpointProvider()),
        ChangeNotifierProvider(create: (_) => AdaptiveTypographyProvider()..loadConfig()),
      ],
      child: ScreenMetricsWrapper(
        child: MaterialApp(
          title: 'Adaptive UI System',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          home: const MainScreen(),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final NavigationStateManager _navigationStateManager = NavigationStateManager();
  final List<_ScreenEntry> _screenEntries = const [
    _ScreenEntry(route: '/home', child: HomeScreen()),
    _ScreenEntry(route: '/grid', child: GridScreen()),
    _ScreenEntry(route: '/gestures', child: GestureScreen()),
    _ScreenEntry(route: '/layout', child: LayoutScreen()),
    _ScreenEntry(route: '/settings', child: SettingsScreen()),
  ];

  @override
  void initState() {
    super.initState();
    _restoreNavigationState();
  }

  Future<void> _restoreNavigationState() async {
    await _navigationStateManager.loadState();
    final restoredIndex = _screenEntries.indexWhere(
      (entry) => entry.route == _navigationStateManager.state.currentRoute,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedIndex = restoredIndex >= 0 ? restoredIndex : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = MediaQuery.of(context).size.width;
        final currentBreakpoint = BreakpointUtils.getBreakpoint(width);

        // Update breakpoint provider
        final breakpointProvider = context.read<BreakpointProvider>();
        if (breakpointProvider.currentBreakpoint != currentBreakpoint) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              breakpointProvider.updateBreakpoint(width);
            }
          });
        }
        
        return LayoutTransitionWrapper(
          child: Stack(
            children: [
              AdaptiveNavigationScaffold(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() => _selectedIndex = index);
                },
                navigationStateManager: _navigationStateManager,
                body: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: KeyedSubtree(
                    key: ValueKey(_screenEntries[_selectedIndex].route),
                    child: _screenEntries[_selectedIndex].child,
                  ),
                ),
              ),
              const Positioned(
                top: 16,
                right: 16,
                child: BreakpointIndicator(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScreenEntry {
  final String route;
  final Widget child;

  const _ScreenEntry({required this.route, required this.child});
}

// Home Screen
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final styles = context.adaptiveTextStyles;
    final theme = Theme.of(context);
    final colors = context.appThemeColors;
    
    return Scaffold(
      body: AppPageShell(
        title: 'Adaptive UI System',
        subtitle:
            'A polished responsive workspace for navigation, layout orchestration, '
            'gesture input, typography scaling, and runtime diagnostics.',
        headerAction: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current mode',
                style: theme.textTheme.labelMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                context.breakpoint.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _InsightCard(
                    label: 'Breakpoint',
                    value: context.breakpoint.label,
                    icon: Icons.devices_outlined,
                    accent: colors.info,
                  ),
                  _InsightCard(
                    label: 'Grid Capacity',
                    value: '${context.breakpoint.columns} columns',
                    icon: Icons.grid_view_rounded,
                    accent: colors.success,
                  ),
                  _InsightCard(
                    label: 'Type Scale',
                    value: '${context.breakpoint.typographyScale.toStringAsFixed(2)}x',
                    icon: Icons.text_fields_rounded,
                    accent: theme.colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Capabilities', style: styles.headline3),
              const SizedBox(height: 14),
              _buildFeatureCard(
                context,
                icon: Icons.dashboard_customize_outlined,
                title: 'Responsive Breakpoints',
                description: 'Layouts adapt automatically to compact, medium, and expanded widths.',
              ),
              _buildFeatureCard(
                context,
                icon: Icons.account_tree_outlined,
                title: 'Adaptive Navigation',
                description: 'Navigation changes form while preserving routes and interaction flow.',
              ),
              _buildFeatureCard(
                context,
                icon: Icons.view_quilt_outlined,
                title: 'Adaptive Grid',
                description: 'Content density and proportions stay controlled across screen classes.',
              ),
              _buildFeatureCard(
                context,
                icon: Icons.pan_tool_alt_outlined,
                title: 'Custom Gestures',
                description: 'Swipe, pinch, and multi-touch interactions are normalized in one layer.',
              ),
              _buildFeatureCard(
                context,
                icon: Icons.format_size_outlined,
                title: 'Adaptive Typography',
                description: 'Readable type scales are applied consistently across responsive states.',
              ),
              _buildFeatureCard(
                context,
                icon: Icons.analytics_outlined,
                title: 'Performance Monitoring',
                description: 'Rebuild timings and environment metrics stay visible during tuning.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final colors = context.appThemeColors;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppSurfaceCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.arrow_outward_rounded, color: colors.info),
          ],
        ),
      ),
    );
  }
}

// Grid Screen
class GridScreen extends StatelessWidget {
  const GridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final styles = context.adaptiveTextStyles;
    final breakpoint = context.breakpoint;
    
    return Scaffold(
      body: AppPageShell(
        title: 'Adaptive Grid',
        subtitle: 'A denser, cleaner card system tuned to each breakpoint and aspect ratio.',
        headerAction: Chip(label: Text('${breakpoint.columns} columns • ${breakpoint.label}')),
        child: AppSurfaceCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(
                  'Content grid with adjustable proportions and consistent spacing.',
                  style: styles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: AdaptiveGrid(
                  padding: const EdgeInsets.all(20),
                  children: List.generate(
                    12,
                    (index) => AdaptiveGridItem(index: index),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Gesture Screen
class GestureScreen extends StatelessWidget {
  const GestureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const AppPageShell(
        title: 'Custom Gestures',
        subtitle: 'Test swipes, pinch scaling, and multi-touch behaviors inside a cleaner interaction canvas.',
        child: AppSurfaceCard(
          padding: EdgeInsets.zero,
          child: GestureDemo(),
        ),
      ),
    );
  }
}

// Layout Screen
class LayoutScreen extends StatefulWidget {
  const LayoutScreen({super.key});

  @override
  State<LayoutScreen> createState() => _LayoutScreenState();
}

class _LayoutScreenState extends State<LayoutScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPageShell(
        title: 'Layout Systems',
        subtitle: 'Constraint rules, typography scaling, transitions, and live metrics in one workspace.',
        child: AppSurfaceCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              TabBar(
                controller: _tabController,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                tabs: const [
                  Tab(text: 'Constraints'),
                  Tab(text: 'Typography'),
                  Tab(text: 'Transitions'),
                  Tab(text: 'Metrics'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    ConstraintLayoutDemo(),
                    AdaptiveTypographyDemo(),
                    LayoutTransitionDemo(),
                    ScreenMetricsDemo(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Settings Screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const AppPageShell(
        title: 'Settings & Performance',
        subtitle: 'Observe rebuild behavior and runtime diagnostics with calmer, production-style surfaces.',
        child: AppSurfaceCard(
          padding: EdgeInsets.zero,
          child: PerformanceMonitorDemo(),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _InsightCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 220,
      child: AppSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(height: 18),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
