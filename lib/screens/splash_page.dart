import 'package:material_ui/material_ui.dart';

import '../app_info.dart';

/// Animated splash shown while the app starts on mobile.
///
/// Colours come from the active scheme, so the splash matches the app in both
/// light and dark mode and the hand-off after startup is a fade, not a flash.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _glow;
  late final AnimationController _bar;
  bool? _animated;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _bar = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animated = !MediaQuery.disableAnimationsOf(context);
    if (_animated == animated) {
      return;
    }
    _animated = animated;
    if (animated) {
      _glow.repeat(reverse: true);
      _bar.repeat();
    } else {
      _glow.value = 0.5;
      _bar.stop();
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animated = _animated ?? true;
    final scheme = Theme.of(context).colorScheme;
    final surface = scheme.surface;
    final highlight = Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.05),
      surface,
    );
    final edge = Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.12),
      surface,
    );

    return Scaffold(
      backgroundColor: surface,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.4),
            radius: 0.95,
            colors: [highlight, surface, edge],
          ),
        ),
        child: SizedBox.expand(
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: animated
                  ? const Duration(milliseconds: 650)
                  : Duration.zero,
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - value)),
                  child: child,
                ),
              ),
              child: Semantics(
                liveRegion: true,
                label: 'Loading ${AppInfo.name}',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _mark(animated, scheme),
                    const SizedBox(height: 22),
                    Text(
                      AppInfo.name,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppInfo.tagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _progress(animated, scheme),
                    const SizedBox(height: 12),
                    Text(
                      'LOADING…',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2.2,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mark(bool animated, ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final shadow = Colors.black.withValues(alpha: isDark ? 0.5 : 0.18);
    final softShadow = Colors.black.withValues(alpha: isDark ? 0.32 : 0.1);

    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _glow,
            builder: (context, _) {
              final value = animated
                  ? Curves.easeInOut.transform(_glow.value)
                  : 0.5;
              final size = 138 + 22 * value;
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      scheme.primary.withValues(alpha: 0.2),
                      scheme.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _glow,
            builder: (context, child) {
              final value = animated
                  ? Curves.easeInOut.transform(_glow.value)
                  : 0.5;
              return Transform.scale(scale: 1 + 0.035 * value, child: child);
            },
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: shadow,
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                  ),
                  BoxShadow(
                    color: softShadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/app_icon.png',
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progress(bool animated, ColorScheme scheme) {
    final bar = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.65),
            scheme.primary,
            scheme.primary.withValues(alpha: 0.65),
          ],
        ),
      ),
    );

    return SizedBox(
      width: 176,
      height: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            const barFactor = 0.42;
            final barWidth = width * barFactor;

            if (!animated) {
              return bar;
            }

            return Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: scheme.primary.withValues(alpha: 0.12),
                  ),
                ),
                AnimatedBuilder(
                  animation: _bar,
                  builder: (context, child) {
                    final left = (width - barWidth) * _bar.value;
                    return Positioned(
                      left: left,
                      top: 0,
                      bottom: 0,
                      width: barWidth,
                      child: child!,
                    );
                  },
                  child: bar,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
