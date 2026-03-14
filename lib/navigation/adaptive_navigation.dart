import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../responsive/breakpoints.dart';
import '../theme/app_theme.dart';

/// Model class for navigation state
class NavigationState {
  String currentRoute;
  List<String> navigationHistory;
  DateTime lastNavigationTimestamp;

  NavigationState({
    required this.currentRoute,
    required this.navigationHistory,
    required this.lastNavigationTimestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentRoute': currentRoute,
      'navigationHistory': navigationHistory,
      'lastNavigationTimestamp': lastNavigationTimestamp.toIso8601String(),
    };
  }

  factory NavigationState.fromJson(Map<String, dynamic> json) {
    return NavigationState(
      currentRoute: json['currentRoute'] as String,
      navigationHistory: List<String>.from(json['navigationHistory']),
      lastNavigationTimestamp: DateTime.parse(json['lastNavigationTimestamp'] as String),
    );
  }

  factory NavigationState.initial() {
    return NavigationState(
      currentRoute: '/home',
      navigationHistory: ['/home'],
      lastNavigationTimestamp: DateTime.now(),
    );
  }
}

/// Navigation state manager for persistence
class NavigationStateManager {
  static const String _fileName = 'navigation_state.json';
  NavigationState _state = NavigationState.initial();

  NavigationState get state => _state;

  Future<void> loadState() async {
    if (kIsWeb) return;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');
      if (await file.exists()) {
        final contents = await file.readAsString();
        _state = NavigationState.fromJson(jsonDecode(contents));
      }
    } catch (e) {
      _state = NavigationState.initial();
    }
  }

  Future<void> saveState() async {
    if (kIsWeb) return;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');
      await file.writeAsString(jsonEncode(_state.toJson()));
    } catch (e) {
      debugPrint('Error saving navigation state: $e');
    }
  }

  void navigate(String route) {
    _state.currentRoute = route;
    _state.navigationHistory.add(route);
    _state.lastNavigationTimestamp = DateTime.now();
    saveState();
  }

  void goBack() {
    if (_state.navigationHistory.length > 1) {
      _state.navigationHistory.removeLast();
      _state.currentRoute = _state.navigationHistory.last;
      _state.lastNavigationTimestamp = DateTime.now();
      saveState();
    }
  }
}

/// Navigation item model
class NavigationItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;

  const NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });
}

/// Default navigation items
const List<NavigationItem> defaultNavigationItems = [
  NavigationItem(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    route: '/home',
  ),
  NavigationItem(
    label: 'Grid',
    icon: Icons.grid_view_outlined,
    selectedIcon: Icons.grid_view,
    route: '/grid',
  ),
  NavigationItem(
    label: 'Gestures',
    icon: Icons.touch_app_outlined,
    selectedIcon: Icons.touch_app,
    route: '/gestures',
  ),
  NavigationItem(
    label: 'Layout',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    route: '/layout',
  ),
  NavigationItem(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    route: '/settings',
  ),
];

/// Adaptive Navigation Scaffold that switches between different navigation
/// components based on the current breakpoint
class AdaptiveNavigationScaffold extends StatefulWidget {
  final Widget body;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationItem> destinations;
  final NavigationStateManager? navigationStateManager;

  const AdaptiveNavigationScaffold({
    super.key,
    required this.body,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.destinations = defaultNavigationItems,
    this.navigationStateManager,
  });

  @override
  State<AdaptiveNavigationScaffold> createState() => _AdaptiveNavigationScaffoldState();
}

class _AdaptiveNavigationScaffoldState extends State<AdaptiveNavigationScaffold> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = MediaQuery.of(context).size.width;
        final breakpoint = BreakpointUtils.getBreakpoint(width);

        switch (breakpoint) {
          case Breakpoint.compact:
            return _buildCompactLayout();
          case Breakpoint.medium:
            return _buildMediumLayout();
          case Breakpoint.expanded:
            return _buildExpandedLayout();
        }
      },
    );
  }

  /// Build layout for compact screens with bottom navigation bar
  Widget _buildCompactLayout() {
    return Scaffold(
      body: widget.body,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: context.appThemeColors.surfacePrimary.withOpacity(0.96),
          border: Border(top: BorderSide(color: context.appThemeColors.borderSubtle)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: BottomNavigationBar(
          key: const Key('adaptive-nav-bottom-bar'),
          currentIndex: widget.selectedIndex,
          onTap: _handleDestinationSelected,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: widget.destinations.map((dest) {
            return BottomNavigationBarItem(
              icon: Icon(dest.icon),
              activeIcon: Icon(dest.selectedIcon),
              label: dest.label,
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Build layout for medium screens with navigation rail
  Widget _buildMediumLayout() {
    return Scaffold(
      body: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: context.appThemeColors.surfacePrimary,
              border: Border(right: BorderSide(color: context.appThemeColors.borderSubtle)),
            ),
            child: NavigationRail(
              key: const Key('adaptive-nav-rail'),
              selectedIndex: widget.selectedIndex,
              onDestinationSelected: _handleDestinationSelected,
              labelType: NavigationRailLabelType.all,
              minWidth: 92,
              leading: Padding(
                padding: const EdgeInsets.only(top: 18, bottom: 24),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [context.appThemeColors.heroStart, context.appThemeColors.heroEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.layers_rounded, color: Colors.white),
                ),
              ),
              destinations: widget.destinations.map((dest) {
                return NavigationRailDestination(
                  icon: Icon(dest.icon),
                  selectedIcon: Icon(dest.selectedIcon),
                  label: Text(dest.label),
                );
              }).toList(),
            ),
          ),
          Expanded(child: widget.body),
        ],
      ),
    );
  }

  /// Build layout for expanded screens with permanent navigation drawer
  Widget _buildExpandedLayout() {
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 304,
            child: Drawer(
              key: const Key('adaptive-nav-drawer'),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [context.appThemeColors.heroStart, context.appThemeColors.heroEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.dashboard_customize_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Adaptive UI',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Responsive workspace',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.78),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                      itemCount: widget.destinations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final dest = widget.destinations[index];
                        final isSelected = index == widget.selectedIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            leading: Icon(
                              isSelected ? dest.selectedIcon : dest.icon,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            title: Text(
                              dest.label,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? theme.colorScheme.primary : null,
                              ),
                            ),
                            selected: isSelected,
                            onTap: () => _handleDestinationSelected(index),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: widget.body),
        ],
      ),
    );
  }

  void _handleDestinationSelected(int index) {
    widget.onDestinationSelected(index);
    if (widget.navigationStateManager != null) {
      widget.navigationStateManager!.navigate(widget.destinations[index].route);
    }
  }
}
