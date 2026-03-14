import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../responsive/breakpoints.dart';

/// Typography configuration model
class TypographyConfig {
  final double baselineFontSize;
  final Map<String, double> scaleFactors;
  final double minimumFontSize;
  final double maximumFontSize;

  const TypographyConfig({
    required this.baselineFontSize,
    required this.scaleFactors,
    required this.minimumFontSize,
    required this.maximumFontSize,
  });

  factory TypographyConfig.fromJson(Map<String, dynamic> json) {
    return TypographyConfig(
      baselineFontSize: (json['baselineFontSize'] as num).toDouble(),
      scaleFactors: Map<String, double>.from(
        (json['scaleFactors'] as Map).map(
          (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
        ),
      ),
      minimumFontSize: (json['minimumFontSize'] as num).toDouble(),
      maximumFontSize: (json['maximumFontSize'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baselineFontSize': baselineFontSize,
      'scaleFactors': scaleFactors,
      'minimumFontSize': minimumFontSize,
      'maximumFontSize': maximumFontSize,
    };
  }

  /// Default configuration
  factory TypographyConfig.defaults() {
    return const TypographyConfig(
      baselineFontSize: 14,
      scaleFactors: {
        'compact': 1.0,
        'medium': 1.15,
        'expanded': 1.3,
      },
      minimumFontSize: 12,
      maximumFontSize: 32,
    );
  }

  /// Loads configuration from assets
  static Future<TypographyConfig> loadFromAssets() async {
    try {
      final jsonString = await rootBundle.loadString('assets/typography_config.json');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      return TypographyConfig.fromJson(jsonData);
    } catch (e) {
      debugPrint('Error loading typography config: $e');
      return TypographyConfig.defaults();
    }
  }

  /// Gets the scale factor for a breakpoint
  double getScaleFactor(Breakpoint breakpoint) {
    return scaleFactors[breakpoint.name] ?? 1.0;
  }

  /// Calculates the font size for a given base size and breakpoint
  double calculateFontSize(double baseSize, Breakpoint breakpoint) {
    final scaleFactor = getScaleFactor(breakpoint);
    final scaledSize = baseSize * scaleFactor;
    return scaledSize.clamp(minimumFontSize, maximumFontSize);
  }
}

/// Provider for adaptive typography
class AdaptiveTypographyProvider extends ChangeNotifier {
  TypographyConfig _config = TypographyConfig.defaults();
  bool _isLoaded = false;

  TypographyConfig get config => _config;
  bool get isLoaded => _isLoaded;

  Future<void> loadConfig() async {
    _config = await TypographyConfig.loadFromAssets();
    _isLoaded = true;
    notifyListeners();
  }

  void updateConfig(TypographyConfig config) {
    _config = config;
    notifyListeners();
  }
}

/// Extensions on TextStyle for responsive typography
extension ResponsiveTextStyle on TextStyle {
  TextStyle responsive(BuildContext context, {TypographyConfig? config}) {
    final breakpoint = context.breakpoint;
    final typographyConfig = config ?? TypographyConfig.defaults();
    
    final baseFontSize = fontSize ?? typographyConfig.baselineFontSize;
    final responsiveFontSize = typographyConfig.calculateFontSize(baseFontSize, breakpoint);
    
    return copyWith(fontSize: responsiveFontSize);
  }
}

/// Adaptive text widget that automatically scales based on breakpoint
class AdaptiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TypographyConfig? config;

  const AdaptiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.config,
  });

  @override
  Widget build(BuildContext context) {
    final breakpoint = context.breakpoint;
    final typographyConfig = config ?? TypographyConfig.defaults();
    
    final baseStyle = style ?? const TextStyle(fontSize: 14);
    final baseFontSize = baseStyle.fontSize ?? typographyConfig.baselineFontSize;
    final responsiveFontSize = typographyConfig.calculateFontSize(baseFontSize, breakpoint);

    return Text(
      text,
      style: baseStyle.copyWith(fontSize: responsiveFontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Predefined adaptive text styles
class AdaptiveTextStyles {
  final TypographyConfig config;
  final Breakpoint breakpoint;

  AdaptiveTextStyles({
    required this.config,
    required this.breakpoint,
  });

  TextStyle get headline1 => TextStyle(
    fontSize: config.calculateFontSize(32, breakpoint),
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  TextStyle get headline2 => TextStyle(
    fontSize: config.calculateFontSize(28, breakpoint),
    fontWeight: FontWeight.bold,
  );

  TextStyle get headline3 => TextStyle(
    fontSize: config.calculateFontSize(24, breakpoint),
    fontWeight: FontWeight.w600,
  );

  TextStyle get headline4 => TextStyle(
    fontSize: config.calculateFontSize(20, breakpoint),
    fontWeight: FontWeight.w600,
  );

  TextStyle get bodyLarge => TextStyle(
    fontSize: config.calculateFontSize(16, breakpoint),
    fontWeight: FontWeight.normal,
  );

  TextStyle get bodyMedium => TextStyle(
    fontSize: config.calculateFontSize(14, breakpoint),
    fontWeight: FontWeight.normal,
  );

  TextStyle get bodySmall => TextStyle(
    fontSize: config.calculateFontSize(12, breakpoint),
    fontWeight: FontWeight.normal,
  );

  TextStyle get labelLarge => TextStyle(
    fontSize: config.calculateFontSize(14, breakpoint),
    fontWeight: FontWeight.w500,
  );

  TextStyle get labelMedium => TextStyle(
    fontSize: config.calculateFontSize(12, breakpoint),
    fontWeight: FontWeight.w500,
  );

  TextStyle get caption => TextStyle(
    fontSize: config.calculateFontSize(11, breakpoint),
    fontWeight: FontWeight.w400,
    color: Colors.grey[600],
  );
}

/// Extension on BuildContext for easy access to adaptive text styles
extension AdaptiveTypography on BuildContext {
  AdaptiveTextStyles get adaptiveTextStyles {
    return AdaptiveTextStyles(
      config: TypographyConfig.defaults(),
      breakpoint: breakpoint,
    );
  }

  double responsiveFontSize(double baseSize) {
    final config = TypographyConfig.defaults();
    return config.calculateFontSize(baseSize, breakpoint);
  }
}

/// Demo widget showcasing adaptive typography
class AdaptiveTypographyDemo extends StatelessWidget {
  const AdaptiveTypographyDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final styles = context.adaptiveTextStyles;
    final breakpoint = context.breakpoint;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Breakpoint: ${breakpoint.label}',
            style: styles.headline4,
          ),
          const Divider(height: 32),
          Text('Headline 1', style: styles.headline1),
          const SizedBox(height: 8),
          Text('Headline 2', style: styles.headline2),
          const SizedBox(height: 8),
          Text('Headline 3', style: styles.headline3),
          const SizedBox(height: 8),
          Text('Headline 4', style: styles.headline4),
          const Divider(height: 32),
          Text('Body Large - Lorem ipsum dolor sit amet', style: styles.bodyLarge),
          const SizedBox(height: 8),
          Text('Body Medium - Lorem ipsum dolor sit amet', style: styles.bodyMedium),
          const SizedBox(height: 8),
          Text('Body Small - Lorem ipsum dolor sit amet', style: styles.bodySmall),
          const Divider(height: 32),
          Text('Label Large', style: styles.labelLarge),
          const SizedBox(height: 8),
          Text('Label Medium', style: styles.labelMedium),
          const SizedBox(height: 8),
          Text('Caption Text', style: styles.caption),
          const Divider(height: 32),
          const AdaptiveText(
            'This is Adaptive Text that scales automatically',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
